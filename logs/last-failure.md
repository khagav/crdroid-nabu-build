# Omarchy rootfs build failure

run: https://github.com/khagav/crdroid-nabu-build/actions/runs/40048873499

```

== 01:15:10  preflight

== 01:15:10  free space at /home/runner/work/crdroid-nabu-build/crdroid-nabu-build/work: 115 GiB

== 01:15:10  staging base rootfs

== 01:15:10  using the ALARM aarch64 tarball (https://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0  790M    0 6927k    0     0  6051k      0  0:02:13  0:00:01  0:02:12 6050k  9  790M    9 78.9M    0     0  36.7M      0  0:00:21  0:00:02  0:00:19 36.7M 19  790M   19  155M    0     0  49.0M      0  0:00:16  0:00:03  0:00:13 49.0M 29  790M   29  229M    0     0  55.1M      0  0:00:14  0:00:04  0:00:10 55.1M 38  790M   38  303M    0     0  59.0M      0  0:00:13  0:00:05  0:00:08 61.1M 47  790M   47  378M    0     0  61.5M      0  0:00:12  0:00:06  0:00:06 74.3M 57  790M   57  454M    0     0  63.6M      0  0:00:12  0:00:07  0:00:05 75.1M 67  790M   67  531M    0     0  65.1M      0  0:00:12  0:00:08  0:00:04 75.4M 77  790M   77  609M    0     0  66.5M      0  0:00:11  0:00:09  0:00:02 76.1M 86  790M   86  685M    0     0  67.5M      0  0:00:11  0:00:10  0:00:01 76.3M 96  790M   96  762M    0     0  68.4M      0  0:00:11  0:00:11 --:--:-- 76.8M100  790M  100  790M    0     0  68.6M      0  0:00:11  0:00:11 --:--:-- 76.8M
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'

== 01:15:33  base rootfs is aarch64

== 01:15:33  writing pacman.conf (repos: omarchy, core, extra, alarm)

== 01:15:33  resolved pkgs.omarchy.org -> 2606:4700::6812:2cc

== 01:15:33  resolved arm-stable-mirror.omarchy.org -> 2606:4700::6812:3cc

== 01:15:33  resolved ca.us.mirror.archlinuxarm.org -> 2607:f140:0:32::70

== 01:15:33  seeded the chroot /etc/hosts with 3 repo hostnames

== 01:15:33  full system upgrade
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
error: failed retrieving file 'alarm.db' from arm-stable-mirror.omarchy.org : Failed to connect to arm-stable-mirror.omarchy.org:443 after 1 ms: Could not connect to server
error: failed retrieving file 'core.db' from arm-stable-mirror.omarchy.org : Failed to connect to arm-stable-mirror.omarchy.org:443 after 1 ms: Could not connect to server
error: failed retrieving file 'extra.db' from arm-stable-mirror.omarchy.org : Failed to connect to arm-stable-mirror.omarchy.org:443 after 1 ms: Could not connect to server
warning: too many errors from arm-stable-mirror.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'omarchy.db' from pkgs.omarchy.org : Failed to connect to pkgs.omarchy.org:443 after 1 ms: Could not connect to server
error: failed retrieving file 'alarm.db' from ca.us.mirror.archlinuxarm.org : Failed to connect to ca.us.mirror.archlinuxarm.org:443 after 0 ms: Could not connect to server
error: failed retrieving file 'core.db' from ca.us.mirror.archlinuxarm.org : Failed to connect to ca.us.mirror.archlinuxarm.org:443 after 0 ms: Could not connect to server
error: failed retrieving file 'extra.db' from ca.us.mirror.archlinuxarm.org : Failed to connect to ca.us.mirror.archlinuxarm.org:443 after 0 ms: Could not connect to server
warning: too many errors from ca.us.mirror.archlinuxarm.org, skipping for the remainder of this transaction
error: failed to synchronize all databases (download library error)

!! plain -Syu failed, retrying with --overwrite '*'
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
error: failed retrieving file 'omarchy.db' from pkgs.omarchy.org : Failed to connect to pkgs.omarchy.org:443 after 1 ms: Could not connect to server
error: failed retrieving file 'core.db' from arm-stable-mirror.omarchy.org : Failed to connect to arm-stable-mirror.omarchy.org:443 after 1 ms: Could not connect to server
error: failed retrieving file 'extra.db' from arm-stable-mirror.omarchy.org : Failed to connect to arm-stable-mirror.omarchy.org:443 after 1 ms: Could not connect to server
error: failed retrieving file 'alarm.db' from arm-stable-mirror.omarchy.org : Failed to connect to arm-stable-mirror.omarchy.org:443 after 0 ms: Could not connect to server
warning: too many errors from arm-stable-mirror.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'alarm.db' from ca.us.mirror.archlinuxarm.org : Failed to connect to ca.us.mirror.archlinuxarm.org:443 after 0 ms: Could not connect to server
error: failed retrieving file 'core.db' from ca.us.mirror.archlinuxarm.org : Failed to connect to ca.us.mirror.archlinuxarm.org:443 after 0 ms: Could not connect to server
error: failed retrieving file 'extra.db' from ca.us.mirror.archlinuxarm.org : Failed to connect to ca.us.mirror.archlinuxarm.org:443 after 0 ms: Could not connect to server
warning: too many errors from ca.us.mirror.archlinuxarm.org, skipping for the remainder of this transaction
error: failed to synchronize all databases (download library error)
```
