# Omarchy rootfs build failure

run: https://github.com/khagav/crdroid-nabu-build/actions/runs/40047802764

```

== 01:01:42  preflight

== 01:01:42  free space at /home/runner/work/crdroid-nabu-build/crdroid-nabu-build/work: 115 GiB

== 01:01:42  staging base rootfs

== 01:01:43  pull failed: archlinux:latest

== 01:01:43  pull failed: arm64v8/archlinux:latest

!! no docker image available, falling back to the ALARM tarball
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0  790M    0 1103k    0     0  1875k      0  0:07:11 --:--:--  0:07:11 1874k  9  790M    9 72.5M    0     0  45.0M      0  0:00:17  0:00:01  0:00:16 45.0M 19  790M   19  154M    0     0  59.2M      0  0:00:13  0:00:02  0:00:11 59.2M 29  790M   29  236M    0     0  65.7M      0  0:00:12  0:00:03  0:00:09 65.7M 40  790M   40  318M    0     0  69.1M      0  0:00:11  0:00:04  0:00:07 69.1M 50  790M   50  399M    0     0  71.3M      0  0:00:11  0:00:05  0:00:06 79.4M 59  790M   59  474M    0     0  71.9M      0  0:00:10  0:00:06  0:00:04 80.7M 70  790M   70  555M    0     0  73.2M      0  0:00:10  0:00:07  0:00:03 80.5M 80  790M   80  639M    0     0  74.2M      0  0:00:10  0:00:08  0:00:02 80.3M 91  790M   91  721M    0     0  75.1M      0  0:00:10  0:00:09  0:00:01 80.5M100  790M  100  790M    0     0  75.7M      0  0:00:10  0:00:10 --:--:-- 80.8M
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'

== 01:02:05  base rootfs is aarch64

== 01:02:05  writing pacman.conf (repos: omarchy, core, extra, alarm)

== 01:02:05  full system upgrade
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
error: failed retrieving file 'alarm.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
warning: fatal error from arm-stable-mirror.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'core.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'extra.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'omarchy.db' from pkgs.omarchy.org : Could not resolve host: pkgs.omarchy.org
warning: fatal error from pkgs.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'alarm.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
warning: fatal error from ca.us.mirror.archlinuxarm.org, skipping for the remainder of this transaction
error: failed retrieving file 'core.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed retrieving file 'extra.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed to synchronize all databases (invalid url for server)

!! plain -Syu failed, retrying with --overwrite '*'
:: Synchronizing package databases...
 omarchy downloading...
 core downloading...
 extra downloading...
 alarm downloading...
error: failed retrieving file 'alarm.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
warning: fatal error from arm-stable-mirror.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'omarchy.db' from pkgs.omarchy.org : Could not resolve host: pkgs.omarchy.org
warning: fatal error from pkgs.omarchy.org, skipping for the remainder of this transaction
error: failed retrieving file 'core.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'extra.db' from arm-stable-mirror.omarchy.org : Could not resolve host: arm-stable-mirror.omarchy.org
error: failed retrieving file 'alarm.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
warning: fatal error from ca.us.mirror.archlinuxarm.org, skipping for the remainder of this transaction
error: failed retrieving file 'core.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed retrieving file 'extra.db' from ca.us.mirror.archlinuxarm.org : Could not resolve host: ca.us.mirror.archlinuxarm.org
error: failed to synchronize all databases (invalid url for server)
```
