#!/bin/bash
#
# Build a Droidspaces-ready Arch Linux ARM rootfs with Omarchy on top.
#
# Runs as root on an aarch64 Linux host. Written for GitHub's ubuntu-24.04-arm
# runner: the CPU is already aarch64, so every package install runs natively
# through chroot instead of qemu-user binfmt emulation.
#
# Result: dist/Arch-Omarchy-<stamp>.tar.xz, importable as a Droidspaces rootfs.
#
# What is inside, and why:
#   Arch Linux ARM base        current ALARM userland
#   omarchy                    Omarchy 4.0.6 from pkgs.omarchy.org (aarch64)
#   hyprland-anland            Hyprland 0.56.0.r52 patched for Anland v5. It
#                              PROVIDES hyprland and CONFLICTS hyprland, so
#                              omarchy's dependency resolves to it and the
#                              stock compositor is never pulled in
#   xorg-xwayland (patched)    same release; version 0.0.0.r19533 is
#                              deliberately lower than the repo package, so it
#                              must be held or a later upgrade reverts it
#   mesa-for-android-container Adreno kgsl driver, 26.3.0-devel
#   systemd 257.9-2            the last release the 4.14 Android kernel this
#                              tablet runs is known to boot
#
# Usage:
#   sudo ./build-omarchy-rootfs.sh
#
# Environment:
#   WORK=/path            scratch dir (default ./work)
#   USERNAME=Gold         container user (default Gold)
#   PASSWORD=1234         its password (default 1234)
#   CHANNEL=stable        omarchy channel: stable, rc or edge
#   ALARM_URL=...         base tarball, only used when docker is unavailable
#   SKIP_UPGRADE=1        skip the full ALARM system upgrade
#
set -euo pipefail

WORK=${WORK:-$PWD/work}
ROOTFS=$WORK/rootfs
DIST=$WORK/dist
CACHE=$WORK/cache
CHANNEL=${CHANNEL:-stable}
USERNAME=${USERNAME:-Gold}
PASSWORD=${PASSWORD:-1234}
STAMP=$(date -u +%Y%m%d-%H%M%S)
OUT=$DIST/Arch-Omarchy-aarch64-$STAMP.tar.xz

OMARCHY_SERVER=https://pkgs.omarchy.org/$CHANNEL
ALARM_MIRROR=https://arm-stable-mirror.omarchy.org
ALARM_FALLBACK=https://ca.us.mirror.archlinuxarm.org
ALARM_URL=${ALARM_URL:-$ALARM_FALLBACK/os/ArchLinuxARM-aarch64-latest.tar.gz}

PKG_REPO=Goldzxcbug/droidspaces-package
ANLAND_TAG=anland-hyprland-packages
ANLAND_ARCHIVE=anland-hyprland-arch-0.56.0.r52.gff672deb6-aarch64.tar.gz
MESA_TAG=mesa-for-android-container
MESA_ARCHIVE=mesa-for-android-container_26.3.0-devel-20260824_archlinux_arm64.tar
SYSTEMD_TAG=systemd257-packages
SYSTEMD_ARCHIVE=systemd257-arch-arm64.tar.gz

log()  { printf '\n== %s  %s\n' "$(date -u +%H:%M:%S)" "$*"; }
warn() { printf '\n!! %s\n' "$*" >&2; }
die()  { printf '\n!! FAILED: %s\n' "$*" >&2; exit 1; }

# chroot with a fixed environment: nothing from the runner leaks in, and the
# rootfs never sees the host's locale or PATH.
in_rootfs() {
    chroot "$ROOTFS" /usr/bin/env -i \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        HOME=/root TERM=dumb LANG=C LC_ALL=C "$@"
}

mount_pseudo() {
    mkdir -p "$ROOTFS"/{proc,sys,dev,dev/pts,tmp,run,etc/pacman.d}
    # the official image does not ship an mtab, and pacman needs one
    [ -e "$ROOTFS/etc/mtab" ] || ln -sf /proc/self/mounts "$ROOTFS/etc/mtab"
    printf '127.0.0.1\tlocalhost\n::1\tlocalhost\n' > "$ROOTFS/etc/hosts"
    # glibc falls back to a compiled-in default when this is missing, which on
    # recent versions does not include DNS.
    [ -e "$ROOTFS/etc/nsswitch.conf" ] || \
        printf 'hosts: files dns\n' > "$ROOTFS/etc/nsswitch.conf"
    mount -t proc  proc  "$ROOTFS/proc"
    mount -t sysfs sysfs "$ROOTFS/sys"
    mount --bind /dev      "$ROOTFS/dev"
    mount --bind /dev/pts  "$ROOTFS/dev/pts"
}

# DNS inside the chroot is the one thing that reliably breaks. The runner's
# /etc/resolv.conf points at the systemd-resolved stub on 127.0.0.53, and even
# the real uplink from /run/systemd/resolve/resolv.conf (168.63.129.16) did not
# answer from inside the chroot, while the host resolved everything fine.
#
# Rather than fight it, note what pacman actually needs: three repo hostnames.
# Everything else in this build is downloaded by curl on the host. So resolve
# those three on the host and seed the chroot's /etc/hosts, which makes the
# resolver irrelevant.
resolve_host() {
    local host=$1 ip=""
    ip=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -1)
    if [ -z "$ip" ] && command -v python3 >/dev/null 2>&1; then
        ip=$(python3 -c 'import socket,sys
try:
    print(socket.gethostbyname(sys.argv[1]))
except Exception:
    pass' "$host" 2>/dev/null)
    fi
    [ -n "$ip" ] && printf '%s\n' "$ip"
}

setup_dns() {
    local hosts="pkgs.omarchy.org arm-stable-mirror.omarchy.org ca.us.mirror.archlinuxarm.org"
    local h ip found=0
    printf '127.0.0.1\tlocalhost\n::1\tlocalhost\n' > "$ROOTFS/etc/hosts"
    # keep a resolver configured too, in case anything looks one up directly
    printf 'nameserver 168.63.129.16\nnameserver 1.1.1.1\n' > "$ROOTFS/etc/resolv.conf"
    for h in $hosts; do
        ip=$(resolve_host "$h")
        if [ -n "$ip" ]; then
            printf '%s\t%s\n' "$ip" "$h" >> "$ROOTFS/etc/hosts"
            log "resolved $h -> $ip"
            found=$((found + 1))
        else
            log "WARNING: could not resolve $h on the host"
        fi
    done
    [ "$found" -ge 2 ] || die "host resolved only $found of the repo hostnames"
    log "seeded the chroot /etc/hosts with $found repo hostnames"
}

unmount_pseudo() {
    for m in dev/pts dev proc sys; do
        mountpoint -q "$ROOTFS/$m" && umount -lf "$ROOTFS/$m" || true
    done
}

cleanup() { unmount_pseudo 2>/dev/null || true; }
trap cleanup EXIT

# ------------------------------------------------------------------ 0. preflight
log "preflight"
[ "$(uname -m)" = "aarch64" ] || die "this must run on an aarch64 host, got $(uname -m)"
[ "$(id -u)" = "0" ] || die "run as root"
command -v chroot >/dev/null || die "chroot not found"
command -v curl   >/dev/null || die "curl not found"
mkdir -p "$ROOTFS" "$DIST" "$CACHE"
avail=$(df -Pk "$WORK" | awk 'NR==2 {print int($4/1048576)}')
log "free space at $WORK: ${avail} GiB"
[ "$avail" -ge 12 ] || die "need at least 12 GiB free, have ${avail} GiB"

# ------------------------------------------------------------------ 1. base rootfs
# The ALARM tarball is the default: docker pull is rate-limited from GitHub
# runners (both archlinux:latest and arm64v8/archlinux:latest were denied
# repeatedly), while the tarball came down at 75 MB/s. Set USE_DOCKER=1 to
# prefer docker anyway.
log "staging base rootfs"
BASE_IMAGE=""
if [ "${USE_DOCKER:-0}" = "1" ] && docker info >/dev/null 2>&1; then
    # arm64v8/* was retired on Docker Hub and now returns "pull access denied",
    # so try the official multi-arch image first and keep the old name as a
    # fallback.
    for candidate in archlinux:latest arm64v8/archlinux:latest; do
        if docker pull -q "$candidate" >/dev/null 2>&1; then
            BASE_IMAGE=$candidate
            break
        fi
        log "pull failed: $candidate"
    done
fi

if [ -n "$BASE_IMAGE" ]; then
    log "using $BASE_IMAGE via docker export"
    cid=$(docker create "$BASE_IMAGE")
    docker export "$cid" | tar -xpf - -C "$ROOTFS"
    docker rm -f "$cid" >/dev/null
else
    log "using the ALARM aarch64 tarball ($ALARM_URL)"
    [ -f "$CACHE/alarm.tar.gz" ] || \
        curl -fL --retry 3 --retry-delay 5 -o "$CACHE/alarm.tar.gz" "$ALARM_URL"
    tar -xpf "$CACHE/alarm.tar.gz" -C "$ROOTFS"
fi

[ -x "$ROOTFS/usr/bin/pacman" ] || die "base rootfs has no pacman"
[ -e "$ROOTFS/etc/pacman.conf" ] || die "base rootfs has no /etc/pacman.conf"

# An arm64 runner pulls the arm64 image, but assert it rather than assume it:
# an x86_64 base would fail much later, during pacman, with a confusing error.
# ELF e_machine for AArch64 is 183.
elf_machine=$(od -An -tu1 -j18 -N1 "$ROOTFS/usr/bin/pacman" 2>/dev/null | tr -d ' ')
[ "$elf_machine" = "183" ] || \
    die "base rootfs is not aarch64 (ELF e_machine=${elf_machine:-unknown})"
log "base rootfs is aarch64"

# ------------------------------------------------------------------ 2. pacman
log "writing pacman.conf (repos: omarchy, core, extra, alarm)"
# SigLevel Never: the ALARM databases are published unsigned, and a stale
# keyring on an old base image turns every install into a keyring repair job.
# Signatures are therefore not checked in this build.
cat > "$ROOTFS/etc/pacman.conf" <<'PACMANCONF'
[options]
Architecture = aarch64
SigLevel = Never
LocalFileSigLevel = Never
Color
ParallelDownloads = 5
CheckSpace
VerbosePkgLists

[omarchy]
Server = https://pkgs.omarchy.org/stable/$arch

[core]
Server = https://arm-stable-mirror.omarchy.org/$arch/core
Server = https://ca.us.mirror.archlinuxarm.org/$arch/core

[extra]
Server = https://arm-stable-mirror.omarchy.org/$arch/extra
Server = https://ca.us.mirror.archlinuxarm.org/$arch/extra

[alarm]
Server = https://arm-stable-mirror.omarchy.org/$arch/alarm
Server = https://ca.us.mirror.archlinuxarm.org/$arch/alarm
PACMANCONF
# CHANNEL is substituted separately so the heredoc above stays literal.
if [ "$CHANNEL" != "stable" ]; then
    sed -i "s|pkgs.omarchy.org/stable/|pkgs.omarchy.org/$CHANNEL/|" "$ROOTFS/etc/pacman.conf"
fi

mount_pseudo

setup_dns || die "no working DNS inside the chroot - see the diagnostics above"

# ------------------------------------------------------------------ 3. upgrade
if [ "${SKIP_UPGRADE:-0}" = "1" ]; then
    log "skipping full system upgrade (SKIP_UPGRADE=1)"
else
    log "full system upgrade"
    in_rootfs pacman -Syu --noconfirm || {
        warn "plain -Syu failed, retrying with --overwrite '*'"
        in_rootfs pacman -Syu --noconfirm --overwrite '*'
    }
fi

log "installing the build essentials (sudo, base-devel)"
# The official archlinux image is deliberately minimal and ships neither.
in_rootfs pacman -S --noconfirm --needed base-devel sudo

# ------------------------------------------------------------------ 4. anland
log "installing the Anland-patched compositor"
curl -fL --retry 3 --retry-delay 5 -o "$CACHE/$ANLAND_ARCHIVE" \
    "https://github.com/$PKG_REPO/releases/download/$ANLAND_TAG/$ANLAND_ARCHIVE"
rm -rf "$ROOTFS/tmp/payload"; mkdir -p "$ROOTFS/tmp/payload"
tar -xf "$CACHE/$ANLAND_ARCHIVE" -C "$ROOTFS/tmp/payload"
# pacman runs inside the chroot, so the package paths must be chroot-relative.
mapfile -t ANLAND_PKGS < <(
    find "$ROOTFS/tmp/payload" -name '*.pkg.tar.*' -printf '/%P\n' | sort
)
[ "${#ANLAND_PKGS[@]}" -gt 0 ] || die "no packages inside $ANLAND_ARCHIVE"
log "anland packages: ${ANLAND_PKGS[*]}"
in_rootfs pacman -U --noconfirm "${ANLAND_PKGS[@]}"
in_rootfs pacman -Q hyprland-anland || die "hyprland-anland did not install"

# xorg-xwayland from this release is version 0.0.0.r19533, lower than the repo
# package on purpose. Hold it now, before omarchy's dependency pass, or pacman
# will replace the Anland build with the stock one.
log "holding the Anland xorg-xwayland"
cat >> "$ROOTFS/etc/pacman.conf" <<'HOLD1'

IgnorePkg = hyprland-anland hyprpm-anland xorg-xwayland
HOLD1

# ------------------------------------------------------------------ 5. omarchy
log "installing omarchy from pkgs.omarchy.org ($CHANNEL)"
in_rootfs pacman -S --noconfirm --needed omarchy
in_rootfs pacman -Q omarchy || die "omarchy did not install"
# hyprland-anland provides hyprland and conflicts with it, so the stock
# compositor must not be present.
if in_rootfs pacman -Q hyprland >/dev/null 2>&1; then
    die "stock hyprland got installed alongside hyprland-anland"
fi

# ------------------------------------------------------------------ 6. systemd
log "downgrading systemd to 257.9-2 (4.14 kernel compatibility)"
curl -fL --retry 3 --retry-delay 5 -o "$CACHE/$SYSTEMD_ARCHIVE" \
    "https://github.com/$PKG_REPO/releases/download/$SYSTEMD_TAG/$SYSTEMD_ARCHIVE"
mkdir -p "$ROOTFS/tmp/sd257"
tar -xzf "$CACHE/$SYSTEMD_ARCHIVE" -C "$ROOTFS/tmp/sd257"
in_rootfs pacman -U --noconfirm \
    /tmp/sd257/systemd-257*.pkg.tar.xz \
    /tmp/sd257/systemd-libs-257*.pkg.tar.xz \
    /tmp/sd257/systemd-sysvcompat-257*.pkg.tar.xz \
    /tmp/sd257/systemd-resolvconf-257*.pkg.tar.xz
in_rootfs systemctl --version | head -1

log "holding systemd at 257"
cat >> "$ROOTFS/etc/pacman.conf" <<'HOLD2'

IgnorePkg = systemd systemd-libs systemd-sysvcompat systemd-resolvconf
HOLD2

# ------------------------------------------------------------------ 7. mesa
log "installing mesa for Android containers (kgsl)"
curl -fL --retry 3 --retry-delay 5 -o "$CACHE/$MESA_ARCHIVE" \
    "https://github.com/$PKG_REPO/releases/download/$MESA_TAG/$MESA_ARCHIVE"
mkdir -p "$ROOTFS/tmp/mesa"
tar -xf "$CACHE/$MESA_ARCHIVE" -C "$ROOTFS/tmp/mesa"
mapfile -t MESA_PKGS < <(
    find "$ROOTFS/tmp/mesa" -name '*.pkg.tar.*' -printf '/%P\n' | sort
)
if [ "${#MESA_PKGS[@]}" -gt 0 ]; then
    log "mesa packages: ${MESA_PKGS[*]}"
    in_rootfs pacman -U --noconfirm "${MESA_PKGS[@]}"
else
    warn "no pacman packages in $MESA_ARCHIVE - check its layout"
    find "$ROOTFS/tmp/mesa" -maxdepth 2 | head -20
    exit 1
fi

# ------------------------------------------------------------------ 8. user, env
log "creating user $USERNAME"
in_rootfs useradd -m -G wheel -s /bin/bash "$USERNAME" || true
printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chroot "$ROOTFS" /usr/bin/env -i \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin chpasswd
printf '%%wheel ALL=(ALL:ALL) ALL\n' > "$ROOTFS/etc/sudoers.d/10-wheel"
chmod 0440 "$ROOTFS/etc/sudoers.d/10-wheel"
for f in su su-l; do
    [ -f "$ROOTFS/etc/pam.d/$f" ] && sed -i \
        's/^auth[[:space:]]\+required[[:space:]]\+pam_wheel.so.*/auth optional pam_wheel.so/' \
        "$ROOTFS/etc/pam.d/$f"
done

log "writing /etc/environment for Anland"
cat > "$ROOTFS/etc/environment" <<ENVFILE
XDG_SESSION_CLASS=user
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_DESKTOP=Hyprland
QT_QPA_PLATFORM=wayland
ANLAND=1
ANLAND_PRESENT_BACKEND=legacy
ANLAND_SOCKET=/run/display.sock
ANLAND_DRM_DEVICE=/dev/dri/renderD128
ANLAND_SKIP_IMPLICIT_SYNC_WAIT=1
XWAYLAND_GBM_DEVICE=/dev/dri/renderD128
MESA_LOADER_DRIVER_OVERRIDE=kgsl
GALLIUM_DRIVER=kgsl
FD_FORCE_KGSL=1
MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=1
FD_DEV_FEATURES=enable_tp_ubwc_flag_hint=1
ENVFILE

# sddm is a hard dependency of omarchy but has nothing to attach to in a
# container; mask it so it can never start and steal the session.
log "masking sddm (omarchy dependency, unusable in a container)"
in_rootfs systemctl mask sddm.service || true

# Session unit is installed but left disabled: without the Anland daemon
# running on the Android side it would restart-loop. Enable it once the host
# side is up.
log "installing (disabled) omarchy session unit"
cat > "$ROOTFS/etc/systemd/system/omarchy-session.service" <<UNIT
[Unit]
Description=Omarchy Hyprland session on Anland
After=network.target

[Service]
Type=simple
User=$USERNAME
EnvironmentFile=-/etc/environment
WorkingDirectory=/$USERNAME
ExecStart=/usr/bin/Hyprland
Restart=on-failure
RestartSec=2
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=multi-user.target
UNIT

# ------------------------------------------------------------------ 9. cleanup
log "recording what went in"
in_rootfs pacman -Q > "$DIST/packages.txt" || true
SD_VERSION=$(in_rootfs systemctl --version 2>/dev/null | head -1 || echo "unknown")
OMARCHY_VERSION=$(in_rootfs pacman -Q omarchy 2>/dev/null || echo "unknown")
HYPR_VERSION=$(in_rootfs pacman -Q hyprland-anland 2>/dev/null || echo "unknown")
MESA_VERSION=$(in_rootfs pacman -Q mesa 2>/dev/null || echo "unknown")
KERNEL_HINT=$(in_rootfs pacman -Q linux-aarch64 2>/dev/null || echo "no kernel package (expected: the Android kernel is the host)")

log "cleaning up"
# /etc/hosts carried the CI runner's resolved IPs; the container must resolve
# for itself.
printf '127.0.0.1\tlocalhost\n::1\tlocalhost\n' > "$ROOTFS/etc/hosts"
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > "$ROOTFS/etc/resolv.conf"
rm -rf "$ROOTFS"/tmp/* "$ROOTFS"/var/cache/pacman/pkg/* "$ROOTFS"/var/lib/pacman/sync/*
unmount_pseudo

# ------------------------------------------------------------------ 10. pack
log "packing $OUT"
XZ_OPT="-T0 -6" tar -C "$ROOTFS" --numeric-owner -cJf "$OUT" .
sha256sum "$OUT" > "$OUT.sha256"

{
    echo "built      : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "channel    : $CHANNEL"
    echo "user       : $USERNAME"
    echo "systemd    : $SD_VERSION"
    echo "omarchy    : $OMARCHY_VERSION"
    echo "compositor : $HYPR_VERSION"
    echo "mesa       : $MESA_VERSION"
    echo "kernel pkg : $KERNEL_HINT"
    echo "packages   : $(wc -l < "$DIST/packages.txt")"
    echo "size       : $(du -h "$OUT" | cut -f1)"
    echo "sha256     : $(cut -d' ' -f1 "$OUT.sha256")"
} | tee "$DIST/build-info.txt"

log "done: $OUT"
