# Omarchy rootfs build failure

run: https://github.com/khagav/crdroid-nabu-build/actions/runs/40048144812

```

== 01:05:34  preflight

== 01:05:34  free space at /home/runner/work/crdroid-nabu-build/crdroid-nabu-build/work: 115 GiB

== 01:05:34  staging base rootfs

== 01:05:34  using the ALARM aarch64 tarball (https://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0  790M    0 4576k    0     0  4376k      0  0:03:05  0:00:01  0:03:04 4374k 14  790M   14  117M    0     0  57.5M      0  0:00:13  0:00:02  0:00:11 57.5M 28  790M   28  227M    0     0  74.5M      0  0:00:10  0:00:03  0:00:07 74.5M 43  790M   43  346M    0     0  85.6M      0  0:00:09  0:00:04  0:00:05 85.6M 59  790M   59  468M    0     0  92.6M      0  0:00:08  0:00:05  0:00:03 93.8M 63  790M   63  500M    0     0  82.7M      0  0:00:09  0:00:06  0:00:03 99.1M 76  790M   76  606M    0     0  86.1M      0  0:00:09  0:00:07  0:00:02 97.8M 91  790M   91  721M    0     0  89.6M      0  0:00:08  0:00:08 --:--:-- 98.8M100  790M  100  790M    0     0  91.7M      0  0:00:08  0:00:08 --:--:-- 97.1M
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'

== 01:05:54  base rootfs is aarch64

== 01:05:54  writing pacman.conf (repos: omarchy, core, extra, alarm)

== 01:05:54  host resolv.conf uses a loopback stub - using 1.1.1.1 / 8.8.8.8

== 01:05:54  full system upgrade
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
error: failed retrieving file 'omarchy.db' from pkgs.omarchy.org : Could not resolve host: pkgs.omarchy.org
warning: fatal error from pkgs.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'core.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
warning: fatal error from arm-stable-mirror.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'extra.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'alarm.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'core.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
warning: fatal error from ca.us.mirror.archlinuxarm.org, skipping for the remainder of this transaction
error: failed retrieving file 'extra.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed retrieving file 'alarm.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed to synchronize all databases (invalid url for server)

!! plain -Syu failed, retrying with --overwrite '*'
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
error: failed retrieving file 'omarchy.db' from pkgs.omarchy.org : Could not resolve host: pkgs.omarchy.org
warning: fatal error from pkgs.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'core.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
warning: fatal error from arm-stable-mirror.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'extra.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'alarm.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'core.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
warning: fatal error from ca.us.mirror.archlinuxarm.org, skipping for the remainder of this transaction
error: failed retrieving file 'extra.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed retrieving file 'alarm.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed to synchronize all databases (invalid url for server)
```
