# Omarchy rootfs for Droidspaces on nabu

Arch Linux ARM + Omarchy 4.0.6, with the Anland-patched Hyprland, built on an
aarch64 runner. This directory holds the builder; the artifact lands in the
workflow's Release.

## What is inside

| Component | Version | Why this one |
|---|---|---|
| Arch Linux ARM | current | base userland |
| `omarchy` | 4.0.6 | the whole point |
| `hyprland-anland` | 0.56.0.r52.gff672deb6 | Hyprland patched for Anland v5. It `provides hyprland` and `conflicts hyprland`, so Omarchy's dependency resolves to it and the stock compositor never gets pulled in |
| `xorg-xwayland` | 0.0.0.r19533 | same release. The version is deliberately lower than the repo one, so it is held via `IgnorePkg` |
| `mesa-for-android-container` | 26.3.0-devel | Adreno kgsl driver |
| `systemd` | 257.9-2 | last release known to boot on the 4.14 kernel this tablet runs. Held via `IgnorePkg` |

Held packages are written to `/etc/pacman.conf` as `IgnorePkg`, so a later
`pacman -Syu` inside the container will not quietly undo them.

## Import

1. Download the `.tar.xz` from the Release.
2. In Droidspaces, create a container and pick that file as the rootfs.
3. Container settings: enable hardware access, privileged mode, `nocaps`,
   `noseccomp`.
4. Bind mount, in advanced options:

   ```
   /data/local/tmp/display_daemon.sock -> /run/display.sock
   ```

## Host side (Android), required for the display

Hyprland has no DRM device on Android, so it cannot open a display by itself.
Anland supplies one:

1. Flash `anland-daemon.zip` from the
   [5.23 release](https://github.com/SuperTurtleDev/anland/releases/tag/5.23)
   in Magisk and reboot. It is a userspace daemon, not a kernel module, so it
   does not care which kernel you booted.
2. Install `anland-v5.apk` from the same release.
3. Set SELinux permissive, or allow the daemon's socket explicitly.

Use the 5.x line, not `main`: 6.x states it requires SukiSU or KernelSU, and
this tablet runs Magisk.

## Start the session

The session unit is installed but **disabled**, because it would restart-loop
before the Android-side daemon exists.

```bash
# inside the container, as Gold
systemctl enable --now omarchy-session.service
```

Or run it by hand to watch the output:

```bash
Hyprland
```

Default credentials: user `Gold`, password `1234`. Change it:

```bash
passwd
```

## Things that will not work

- `omarchy-hyprland-titlebars` — depends on patches that exist only in
  Omarchy's own Hyprland build, not in the Anland one.
- `sddm` — installed because `omarchy` depends on it, then masked. A container
  has no seat for a display manager.
- Anything Omarchy drives through the host: `plymouth`, `limine`, UKI, btrfs
  snapshots, firmware extraction.

## Rebuild

Actions -> "Build Omarchy rootfs" -> Run workflow. Inputs: user name, password,
Omarchy channel. `rootfs/build-omarchy-rootfs.sh` also runs standalone on any
aarch64 Linux host:

```bash
sudo ./rootfs/build-omarchy-rootfs.sh
```

## Not verified yet

- Whether Omarchy's lua-style Hyprland config (`default/hypr/*.lua`) loads on
  0.56.0.r52
- Whether quickshell's Qt6 QML renders through Anland's buffer sharing
- systemd 257 behaviour on 4.14 (D-Bus, udev, networking)
