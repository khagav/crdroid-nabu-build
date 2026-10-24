# Omarchy rootfs build failure

run: https://github.com/khagav/crdroid-nabu-build/actions/runs/40049159128

```

== 01:18:22  preflight

== 01:18:22  free space at /home/runner/work/crdroid-nabu-build/crdroid-nabu-build/work: 115 GiB

== 01:18:22  staging base rootfs

== 01:18:22  using the ALARM aarch64 tarball (https://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0  790M    0  175k    0     0   515k      0  0:26:10 --:--:--  0:26:10  514k  3  790M    3 25.1M    0     0  18.0M      0  0:00:43  0:00:01  0:00:42 18.0M 10  790M   10 80.9M    0     0  34.4M      0  0:00:22  0:00:02  0:00:20 34.4M 16  790M   16  133M    0     0  39.7M      0  0:00:19  0:00:03  0:00:16 39.7M 24  790M   24  192M    0     0  44.0M      0  0:00:17  0:00:04  0:00:13 44.0M 34  790M   34  274M    0     0  51.2M      0  0:00:15  0:00:05  0:00:10 54.6M 45  790M   45  356M    0     0  56.1M      0  0:00:14  0:00:06  0:00:08 66.9M 55  790M   55  441M    0     0  60.0M      0  0:00:13  0:00:07  0:00:06 72.0M 66  790M   66  526M    0     0  63.0M      0  0:00:12  0:00:08  0:00:04 78.7M 75  790M   75  595M    0     0  63.7M      0  0:00:12  0:00:09  0:00:03 81.2M 85  790M   85  679M    0     0  65.6M      0  0:00:12  0:00:10  0:00:02 81.0M 96  790M   96  763M    0     0  67.3M      0  0:00:11  0:00:11 --:--:-- 81.5M100  790M  100  790M    0     0  67.8M      0  0:00:11  0:00:11 --:--:-- 81.3M
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'

== 01:18:45  base rootfs is aarch64

== 01:18:45  writing pacman.conf (repos: omarchy, core, extra, alarm)

== 01:18:45  resolved pkgs.omarchy.org -> 104.18.3.204

== 01:18:45  resolved arm-stable-mirror.omarchy.org -> 104.18.2.204

== 01:18:45  resolved ca.us.mirror.archlinuxarm.org -> 169.229.200.70

== 01:18:45  seeded the chroot /etc/hosts with 3 repo hostnames

== 01:18:45  full system upgrade
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
:: Starting full system upgrade...
resolving dependencies...
looking for conflicting packages...

Package (78)                  Old Version            New Version            Net Change  Download Size

core/archlinux-keyring        20260727-1             20260909-1               0.00 MiB       1.22 MiB
core/bash                     5.3.15-1               5.3.20-1                 0.00 MiB       1.74 MiB
core/ca-certificates-mozilla  3.126-1                3.131-1                  0.00 MiB       0.36 MiB
core/coreutils                9.11-2                 9.12-2                   0.66 MiB       2.72 MiB
core/cryptsetup               2.8.7-1                2.8.8-1                  0.16 MiB       0.77 MiB
core/curl                     8.21.0-1               8.23.0-1                 0.08 MiB       1.23 MiB
core/dbus                     1.16.2-1               1.16.2-2                -0.12 MiB       0.28 MiB
core/device-mapper            2.03.41-1              2.03.43-2                0.00 MiB       0.27 MiB
extra/dhcpcd                  10.3.2-1               10.5.2-1                 0.00 MiB       0.19 MiB
core/expat                    2.8.2-1                2.9.0-1                  0.03 MiB       0.11 MiB
core/glib2                    2.88.3-1               2.90.1-1                 0.49 MiB       4.74 MiB
core/gnupg                    2.4.9-2                2.4.9-3                  0.00 MiB       2.64 MiB
core/gnutls                   3.8.13-2               3.8.13-3                -0.06 MiB       1.65 MiB
core/gpgme                    2.1.2-1                2.2.0-1                  0.00 MiB       0.30 MiB
core/gpm                      1.20.7.r38.ge82d1a6-6  1.20.7.r38.ge82d1a6-7    0.00 MiB       0.13 MiB
core/gzip                     1.14-2                 1.15-1                   0.00 MiB       0.08 MiB
core/hwdata                   0.410-1                0.412-1                  0.05 MiB       1.62 MiB
core/iana-etc                 20260530-1             20260617-1               0.00 MiB       0.38 MiB
core/iproute2                 7.1.0-1                7.2.0-1                  0.00 MiB       1.10 MiB
core/jansson                  2.15.0-1               2.15.1-1                 0.00 MiB       0.07 MiB
core/leancrypto               1.8.0-1                1.9.1-1                  0.29 MiB       1.33 MiB
core/libarchive               3.8.9-1                3.8.10-1                 0.00 MiB       0.49 MiB
core/libcap-ng                0.9.3-1                0.9.6-1                  0.00 MiB       0.07 MiB
core/libelf                   0.195-1                0.196-1                  0.10 MiB       0.55 MiB
core/libffi                   3.7.1-1                3.8.0-1                  0.00 MiB       0.05 MiB
core/libgcrypt                1.12.2-1               1.12.4-1                 0.00 MiB       0.57 MiB
core/libksba                  1.8.0-1                1.8.1-1                  0.00 MiB       0.13 MiB
core/libldap                  2.6.13-1               2.7.1-1                 -0.04 MiB       0.25 MiB
core/libmakepkg-dropins       20-1                   20-2                     0.00 MiB       0.01 MiB
core/libnftnl                 1.3.1-1                1.3.2-1                  0.00 MiB       0.06 MiB
core/libp11-kit               0.26.4-1               0.26.5-1                 0.00 MiB       0.40 MiB
core/libpcap                  1.10.6-1               1.11.0-1                 0.02 MiB       0.28 MiB
core/libsecret                0.21.7-1               0.21.8.2-1               0.01 MiB       0.17 MiB
extra/libsysprof-capture      50.0-4                 51.0-1                   0.01 MiB       0.05 MiB
core/libtirpc                 1.3.7-1                1.3.8-1                  0.00 MiB       0.16 MiB
core/libxml2                  2.15.3-1               2.15.4-1                 0.00 MiB       0.66 MiB
core/linux-aarch64            7.1.6-1                7.2.11-1                27.08 MiB      65.54 MiB
core/linux-api-headers        7.1-1                  7.3-1                    0.11 MiB       1.45 MiB
core/linux-firmware           20260622-1             20260916-1               0.00 MiB       0.00 MiB
core/linux-firmware-amd                              20260916-1               2.64 MiB       0.47 MiB
core/linux-firmware-amdgpu    20260622-1             20260916-1               4.23 MiB      15.25 MiB
core/linux-firmware-atheros   20260622-1             20260916-1               4.20 MiB      41.58 MiB
core/linux-firmware-broadcom  20260622-1             20260916-1              -0.03 MiB       7.43 MiB
core/linux-firmware-cirrus    20260622-1             20260916-1               0.35 MiB       0.44 MiB
core/linux-firmware-intel     20260622-1             20260916-1              26.45 MiB      53.46 MiB
core/linux-firmware-mediatek  20260622-1             20260916-1               0.23 MiB      33.11 MiB
core/linux-firmware-nvidia    20260622-1             20260916-1               0.00 MiB      99.50 MiB
core/linux-firmware-other     20260622-1             20260916-1             -24.82 MiB      11.98 MiB
core/linux-firmware-radeon    20260622-1             20260916-1               0.00 MiB       0.80 MiB
core/linux-firmware-realtek   20260622-1             20260916-1               9.05 MiB       3.76 MiB
core/linux-firmware-ti                               20260916-1              14.34 MiB       2.10 MiB
core/linux-firmware-whence    20260622-1             20260916-1               0.02 MiB       0.04 MiB
core/mkinitcpio               41-4                   42.2-1                   0.01 MiB       0.07 MiB
core/nano                     9.1-1                  9.2-1                    0.01 MiB       0.59 MiB
extra/nftables                1:1.1.6-3              1:1.1.7-3                0.00 MiB       0.38 MiB
core/openssh                  10.4p1-3               10.6p1-2                 0.19 MiB       1.17 MiB
core/openssl                  3.6.3-1                3.6.5-1                  0.02 MiB       5.62 MiB
core/p11-kit                  0.26.4-1               0.26.5-1                 0.00 MiB       0.24 MiB
core/pacman                   7.1.0.r9.g54d9411-2    7.1.0.r9.g54d9411-3      0.00 MiB       0.86 MiB
core/pam                      1.7.2-2                1.7.3-1                  0.02 MiB       0.57 MiB
core/pcre2                    10.47-1                10.49-1                  0.05 MiB       1.20 MiB
core/procps-ng                4.0.6-3                4.0.7-1                  0.00 MiB       0.95 MiB
core/readline                 8.3.003-1              8.3.6-1                  0.00 MiB       0.38 MiB
core/sed                      4.10-1                 4.10-2                   0.00 MiB       0.23 MiB
core/sqlite                   3.53.4-1               3.54.0-1                 0.07 MiB       1.76 MiB
core/systemd                  261.2-1                262.1-1                 -4.58 MiB       9.29 MiB
core/systemd-libs             261.2-1                262.1-1                 -8.81 MiB       1.24 MiB
core/systemd-resolvconf       261.2-1                262.1-1                  0.00 MiB       0.00 MiB
core/systemd-sysvcompat       261.2-1                262.1-1                  0.00 MiB       0.01 MiB
core/tar                      1.35-2                 1.35-5                   0.02 MiB       0.70 MiB
core/tpm2-tss                 4.1.3-1                4.2.0-2                  0.18 MiB       0.84 MiB
core/tzdata                   2026c-1                2026e-1                  0.03 MiB       0.28 MiB
core/util-linux               2.42.2-1               2.42.4-1                 0.58 MiB       6.53 MiB
core/util-linux-libs          2.42.2-1               2.42.4-1                 0.00 MiB       0.48 MiB
extra/vim                     9.2.0849-1             9.2.1178-1               0.06 MiB       1.99 MiB
extra/vim-runtime             9.2.0849-1             9.2.1178-1               0.27 MiB       7.35 MiB
core/xz                       5.8.3-1                5.8.4-1                 -0.12 MiB       0.78 MiB
core/zlib                     1:1.3.2-3              1:1.3.2-4                0.00 MiB       0.07 MiB

Total Download Size:    407.34 MiB
Total Installed Size:  1738.78 MiB
Net Upgrade Size:        53.56 MiB

:: Proceed with installation? [Y/n] error: could not determine cachedir mount point /var/cache/pacman/pkg
error: failed to commit transaction (not enough free disk space)

Errors occurred, no packages were upgraded.

!! plain -Syu failed, retrying with --overwrite '*'
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
:: Starting full system upgrade...
resolving dependencies...
looking for conflicting packages...

Package (78)                  Old Version            New Version            Net Change  Download Size

core/archlinux-keyring        20260727-1             20260909-1               0.00 MiB       1.22 MiB
core/bash                     5.3.15-1               5.3.20-1                 0.00 MiB       1.74 MiB
core/ca-certificates-mozilla  3.126-1                3.131-1                  0.00 MiB       0.36 MiB
core/coreutils                9.11-2                 9.12-2                   0.66 MiB       2.72 MiB
core/cryptsetup               2.8.7-1                2.8.8-1                  0.16 MiB       0.77 MiB
core/curl                     8.21.0-1               8.23.0-1                 0.08 MiB       1.23 MiB
core/dbus                     1.16.2-1               1.16.2-2                -0.12 MiB       0.28 MiB
core/device-mapper            2.03.41-1              2.03.43-2                0.00 MiB       0.27 MiB
extra/dhcpcd                  10.3.2-1               10.5.2-1                 0.00 MiB       0.19 MiB
core/expat                    2.8.2-1                2.9.0-1                  0.03 MiB       0.11 MiB
core/glib2                    2.88.3-1               2.90.1-1                 0.49 MiB       4.74 MiB
core/gnupg                    2.4.9-2                2.4.9-3                  0.00 MiB       2.64 MiB
core/gnutls                   3.8.13-2               3.8.13-3                -0.06 MiB       1.65 MiB
core/gpgme                    2.1.2-1                2.2.0-1                  0.00 MiB       0.30 MiB
core/gpm                      1.20.7.r38.ge82d1a6-6  1.20.7.r38.ge82d1a6-7    0.00 MiB       0.13 MiB
core/gzip                     1.14-2                 1.15-1                   0.00 MiB       0.08 MiB
core/hwdata                   0.410-1                0.412-1                  0.05 MiB       1.62 MiB
core/iana-etc                 20260530-1             20260617-1               0.00 MiB       0.38 MiB
core/iproute2                 7.1.0-1                7.2.0-1                  0.00 MiB       1.10 MiB
core/jansson                  2.15.0-1               2.15.1-1                 0.00 MiB       0.07 MiB
core/leancrypto               1.8.0-1                1.9.1-1                  0.29 MiB       1.33 MiB
core/libarchive               3.8.9-1                3.8.10-1                 0.00 MiB       0.49 MiB
core/libcap-ng                0.9.3-1                0.9.6-1                  0.00 MiB       0.07 MiB
core/libelf                   0.195-1                0.196-1                  0.10 MiB       0.55 MiB
core/libffi                   3.7.1-1                3.8.0-1                  0.00 MiB       0.05 MiB
core/libgcrypt                1.12.2-1               1.12.4-1                 0.00 MiB       0.57 MiB
core/libksba                  1.8.0-1                1.8.1-1                  0.00 MiB       0.13 MiB
core/libldap                  2.6.13-1               2.7.1-1                 -0.04 MiB       0.25 MiB
core/libmakepkg-dropins       20-1                   20-2                     0.00 MiB       0.01 MiB
core/libnftnl                 1.3.1-1                1.3.2-1                  0.00 MiB       0.06 MiB
core/libp11-kit               0.26.4-1               0.26.5-1                 0.00 MiB       0.40 MiB
core/libpcap                  1.10.6-1               1.11.0-1                 0.02 MiB       0.28 MiB
core/libsecret                0.21.7-1               0.21.8.2-1               0.01 MiB       0.17 MiB
extra/libsysprof-capture      50.0-4                 51.0-1                   0.01 MiB       0.05 MiB
core/libtirpc                 1.3.7-1                1.3.8-1                  0.00 MiB       0.16 MiB
core/libxml2                  2.15.3-1               2.15.4-1                 0.00 MiB       0.66 MiB
core/linux-aarch64            7.1.6-1                7.2.11-1                27.08 MiB      65.54 MiB
core/linux-api-headers        7.1-1                  7.3-1                    0.11 MiB       1.45 MiB
core/linux-firmware           20260622-1             20260916-1               0.00 MiB       0.00 MiB
core/linux-firmware-amd                              20260916-1               2.64 MiB       0.47 MiB
core/linux-firmware-amdgpu    20260622-1             20260916-1               4.23 MiB      15.25 MiB
core/linux-firmware-atheros   20260622-1             20260916-1               4.20 MiB      41.58 MiB
core/linux-firmware-broadcom  20260622-1             20260916-1              -0.03 MiB       7.43 MiB
core/linux-firmware-cirrus    20260622-1             20260916-1               0.35 MiB       0.44 MiB
core/linux-firmware-intel     20260622-1             20260916-1              26.45 MiB      53.46 MiB
core/linux-firmware-mediatek  20260622-1             20260916-1               0.23 MiB      33.11 MiB
core/linux-firmware-nvidia    20260622-1             20260916-1               0.00 MiB      99.50 MiB
core/linux-firmware-other     20260622-1             20260916-1             -24.82 MiB      11.98 MiB
core/linux-firmware-radeon    20260622-1             20260916-1               0.00 MiB       0.80 MiB
core/linux-firmware-realtek   20260622-1             20260916-1               9.05 MiB       3.76 MiB
core/linux-firmware-ti                               20260916-1              14.34 MiB       2.10 MiB
core/linux-firmware-whence    20260622-1             20260916-1               0.02 MiB       0.04 MiB
core/mkinitcpio               41-4                   42.2-1                   0.01 MiB       0.07 MiB
core/nano                     9.1-1                  9.2-1                    0.01 MiB       0.59 MiB
extra/nftables                1:1.1.6-3              1:1.1.7-3                0.00 MiB       0.38 MiB
core/openssh                  10.4p1-3               10.6p1-2                 0.19 MiB       1.17 MiB
core/openssl                  3.6.3-1                3.6.5-1                  0.02 MiB       5.62 MiB
core/p11-kit                  0.26.4-1               0.26.5-1                 0.00 MiB       0.24 MiB
core/pacman                   7.1.0.r9.g54d9411-2    7.1.0.r9.g54d9411-3      0.00 MiB       0.86 MiB
core/pam                      1.7.2-2                1.7.3-1                  0.02 MiB       0.57 MiB
core/pcre2                    10.47-1                10.49-1                  0.05 MiB       1.20 MiB
core/procps-ng                4.0.6-3                4.0.7-1                  0.00 MiB       0.95 MiB
core/readline                 8.3.003-1              8.3.6-1                  0.00 MiB       0.38 MiB
core/sed                      4.10-1                 4.10-2                   0.00 MiB       0.23 MiB
core/sqlite                   3.53.4-1               3.54.0-1                 0.07 MiB       1.76 MiB
core/systemd                  261.2-1                262.1-1                 -4.58 MiB       9.29 MiB
core/systemd-libs             261.2-1                262.1-1                 -8.81 MiB       1.24 MiB
core/systemd-resolvconf       261.2-1                262.1-1                  0.00 MiB       0.00 MiB
core/systemd-sysvcompat       261.2-1                262.1-1                  0.00 MiB       0.01 MiB
core/tar                      1.35-2                 1.35-5                   0.02 MiB       0.70 MiB
core/tpm2-tss                 4.1.3-1                4.2.0-2                  0.18 MiB       0.84 MiB
core/tzdata                   2026c-1                2026e-1                  0.03 MiB       0.28 MiB
core/util-linux               2.42.2-1               2.42.4-1                 0.58 MiB       6.53 MiB
core/util-linux-libs          2.42.2-1               2.42.4-1                 0.00 MiB       0.48 MiB
extra/vim                     9.2.0849-1             9.2.1178-1               0.06 MiB       1.99 MiB
extra/vim-runtime             9.2.0849-1             9.2.1178-1               0.27 MiB       7.35 MiB
core/xz                       5.8.3-1                5.8.4-1                 -0.12 MiB       0.78 MiB
core/zlib                     1:1.3.2-3              1:1.3.2-4                0.00 MiB       0.07 MiB

Total Download Size:    407.34 MiB
Total Installed Size:  1738.78 MiB
Net Upgrade Size:        53.56 MiB

:: Proceed with installation? [Y/n] error: could not determine cachedir mount point /var/cache/pacman/pkg
error: failed to commit transaction (not enough free disk space)

Errors occurred, no packages were upgraded.
```
