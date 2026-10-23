#!/bin/bash
# build-kernel.sh - build ONLY the nabu kernel (Image.gz) plus optional modules.
#
# Why this exists: a full AOSP checkout is ~250 GB and needs a self-hosted
# runner, but the Droidspaces work only needs the KERNEL. A kernel tree is
# ~1.2 GB and builds on a stock GitHub-hosted runner (4 cores / 16 GB /
# 87 GB free) in well under an hour. The kernel is then swapped into the
# existing boot.img, so the ROM itself is never rebuilt.
#
# Env knobs (all optional):
#   KSRC_COMMIT  commit to build           (default: the one on the device)
#   KSRC_BRANCH  fallback branch           (default: 17.0)
#   KSRC_DIR     source checkout dir       (default: $HOME/kernel-src)
#   OUT          out dir                   (default: $PWD/kout)
#   CLANG_VER    AOSP prebuilt clang       (default: r596125, what crDroid used)
#   DROIDSPACES  1 = merge kernel/droidspaces-nabu.config
#   LTO          1 = keep CONFIG_LTO_CLANG (slow, RAM hungry), 0 = off
#   MODULES      1 = also build modules (not needed: this kernel is monolithic)
#   JOBS         make -j                    (default: nproc)
#
# Exit codes: 0 ok, 1 build/verify failure, 2 missing input.
# ASCII only. Bash 3.2 compatible.

set -euo pipefail

KSRC_COMMIT="${KSRC_COMMIT:-a17239b2eda3ccba274456d87aab4fd6f0bb734d}"
KSRC_BRANCH="${KSRC_BRANCH:-17.0}"
KSRC_DIR="${KSRC_DIR:-$HOME/kernel-src}"
OUT="${OUT:-$PWD/kout}"
CLANG_VER="${CLANG_VER:-r596125}"
DROIDSPACES="${DROIDSPACES:-1}"
LTO="${LTO:-0}"
MODULES="${MODULES:-0}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"
REPO_URL="https://github.com/crdroidandroid/android_kernel_xiaomi_sm8150.git"
ART="$OUT/artifacts"

log()  { echo "[build-kernel] $*"; }
die()  { echo "[build-kernel] ERROR: $*" >&2; exit 1; }
sum()  { [ -n "${GITHUB_STEP_SUMMARY:-}" ] && echo "$*" >> "$GITHUB_STEP_SUMMARY" || true; }
out()  { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1=$2" >> "$GITHUB_OUTPUT" || true; }

# ---------------------------------------------------------------- 1. source
log "kernel commit: $KSRC_COMMIT (branch $KSRC_BRANCH)"
if [ -d "$KSRC_DIR/.git" ] && git -C "$KSRC_DIR" cat-file -e "${KSRC_COMMIT}^{commit}" 2>/dev/null; then
    log "reusing cached checkout"
    git -C "$KSRC_DIR" checkout -q --detach "$KSRC_COMMIT"
else
    rm -rf "$KSRC_DIR"
    mkdir -p "$KSRC_DIR"
    git -C "$KSRC_DIR" init -q
    git -C "$KSRC_DIR" remote add origin "$REPO_URL"
    # Prefer the exact SHA: the device runs it, and the release string (hence
    # module vermagic) is derived from it. Fall back to the branch tip.
    if git -C "$KSRC_DIR" fetch -q --depth 1 origin "$KSRC_COMMIT" 2>/dev/null; then
        log "fetched exact commit"
    else
        log "exact commit not fetchable, falling back to branch $KSRC_BRANCH"
        git -C "$KSRC_DIR" fetch -q --depth 1 origin "$KSRC_BRANCH"
    fi
    git -C "$KSRC_DIR" checkout -q --detach FETCH_HEAD
fi

cd "$KSRC_DIR"
ACTUAL=$(git rev-parse HEAD)
log "HEAD = $ACTUAL"

# ------------------------------------------------- 2. pin the release string
# The device reports: 4.14.357-perf-ga17239b2eda3
#   CONFIG_LOCALVERSION="-perf"  +  setlocalversion -> -g<12 hex>
# scripts/setlocalversion honours .scmversion verbatim, so pinning it makes the
# version string (and therefore every module vermagic) deterministic even when
# the tree is a shallow, detached checkout.
printf '%s\n' "-g$(printf '%s' "$ACTUAL" | cut -c1-12)" > .scmversion
log "pinned localversion: $(cat .scmversion)"

# ------------------------------------------------------------- 3. toolchain
TC="${TC:-$HOME/toolchain/clang}"
if [ ! -x "$TC/bin/clang" ]; then
    log "downloading AOSP clang $CLANG_VER"
    mkdir -p "$TC"
    URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-${CLANG_VER}.tar.gz"
    if ! curl -fsSL --retry 3 --retry-delay 5 "$URL" | tar -xz -C "$TC"; then
        die "could not download clang $CLANG_VER from $URL"
    fi
fi
export PATH="$TC/bin:$PATH"
clang --version | head -2

# ---------------------------------------------------------------- 4. config
mkdir -p "$OUT"
log "generating base config from vendor/sm8150-perf_defconfig"
make -s O="$OUT" ARCH=arm64 vendor/sm8150-perf_defconfig

FRAGS="arch/arm64/configs/vendor/debugfs.config"
FRAGS="$FRAGS arch/arm64/configs/vendor/xiaomi/sm8150-common.config"
FRAGS="$FRAGS arch/arm64/configs/vendor/xiaomi/nabu.config"

if [ "$DROIDSPACES" = "1" ]; then
    [ -f "$WORKSPACE/kernel/droidspaces-nabu.config" ] || die "fragment not found"
    FRAGS="$FRAGS $WORKSPACE/kernel/droidspaces-nabu.config"
    log "merging Droidspaces fragment"
fi

if [ "$LTO" != "1" ]; then
    # Full LTO on 4 cores / 16 GB is the single most likely way to OOM or blow
    # the job timeout. Off by default; it changes nothing functionally.
    printf '# CONFIG_LTO_CLANG is not set\n' > "$OUT/lto-off.config"
    FRAGS="$FRAGS $OUT/lto-off.config"
    log "LTO disabled"
fi

# shellcheck disable=SC2086
scripts/kconfig/merge_config.sh -m -O "$OUT" "$OUT/.config" $FRAGS >/dev/null
make -s O="$OUT" ARCH=arm64 olddefconfig

log "verifying merged config"
bash "$WORKSPACE/scripts/verify-kernel-config.sh" --config "$OUT/.config" || \
    die "required kernel options missing - refusing to build a kernel that claims Droidspaces support"

# ----------------------------------------------------------------- 5. build
MAKE=(make O="$OUT" ARCH=arm64 -j"$JOBS"
      CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu-
      LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip)

log "building Image.gz with $JOBS jobs"
"${MAKE[@]}" Image.gz 2>&1 | tail -40

if [ "$MODULES" = "1" ]; then
    log "building modules"
    "${MAKE[@]}" modules 2>&1 | tail -20
fi

# --------------------------------------------------------------- 6. package
mkdir -p "$ART"
cp "$OUT/arch/arm64/boot/Image.gz" "$ART/Image.gz"
cp "$OUT/arch/arm64/boot/Image"    "$ART/Image"
cp "$OUT/.config"                  "$ART/kernel.config"
if [ -f "$OUT/System.map" ]; then
    cp "$OUT/System.map" "$ART/System.map"
fi

# Sanity: a valid arm64 Image has the magic "ARMd" at offset 0x38.
MAGIC=$(dd if="$ART/Image" bs=1 skip=56 count=4 2>/dev/null || true)
[ "$MAGIC" = "ARMd" ] || die "built Image does not look like an arm64 kernel"
log "arm64 Image magic OK"

if [ "$MODULES" = "1" ]; then
    MODDIR="$ART/modules"
    mkdir -p "$MODDIR"
    find "$OUT" -name '*.ko' -exec cp {} "$MODDIR/" \; 2>/dev/null || true
    log "modules collected: $(ls "$MODDIR" 2>/dev/null | wc -l)"
fi

{
    echo "commit=$ACTUAL"
    echo "localversion=$(cat .scmversion)"
    echo "kernel=$(make -s O="$OUT" ARCH=arm64 kernelrelease 2>/dev/null || echo unknown)"
    echo "droidspaces=$DROIDSPACES"
    echo "lto=$LTO"
    echo "clang=$(clang --version | head -1)"
    echo "imagegz_bytes=$(wc -c < "$ART/Image.gz" | tr -d ' ')"
    echo "imagegz_sha256=$(sha256sum "$ART/Image.gz" | cut -d' ' -f1)"
} > "$ART/build-info.txt"

cat "$ART/build-info.txt"
sum ""
sum "### Kernel build"
sum ""
sum '| field | value |'
sum '|---|---|'
while IFS='=' read -r k v; do sum "| \`$k\` | $v |"; done < "$ART/build-info.txt"

out image_gz "$ART/Image.gz"
out artifacts "$ART"
log "done"
