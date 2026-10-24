# Omarchy rootfs build failure

run: https://github.com/khagav/crdroid-nabu-build/actions/runs/40048554448

```

== 01:10:45  preflight

== 01:10:45  free space at /home/runner/work/crdroid-nabu-build/crdroid-nabu-build/work: 115 GiB

== 01:10:45  staging base rootfs

== 01:10:45  using the ALARM aarch64 tarball (https://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  2  790M    2 18.0M    0     0  13.7M      0  0:00:57  0:00:01  0:00:56 13.6M  9  790M    9 71.2M    0     0  30.1M      0  0:00:26  0:00:02  0:00:24 30.1M 10  790M   10 86.8M    0     0  21.9M      0  0:00:36  0:00:03  0:00:33 21.9M 10  790M   10 86.8M    0     0  17.5M      0  0:00:45  0:00:04  0:00:41 17.5M 10  790M   10 86.8M    0     0  14.5M      0  0:00:54  0:00:05  0:00:49 15.4M 10  790M   10 86.8M    0     0  12.4M      0  0:01:03  0:00:06  0:00:57 12.2M 10  790M   10 86.8M    0     0  10.9M      0  0:01:12  0:00:07  0:01:05 2862k 10  790M   10 86.8M    0     0  9927k      0  0:01:21  0:00:08  0:01:13     0 10  790M   10 86.8M    0     0  8930k      0  0:01:30  0:00:09  0:01:21     0 10  790M   10 86.9M    0     0  8280k      0  0:01:37  0:00:10  0:01:27 10268 10  790M   10 86.9M    0     0  7575k      0  0:01:46  0:00:11  0:01:35 10268 14  790M   14  114M    0     0  9499k      0  0:01:25  0:00:12  0:01:13 6436k 21  790M   21  168M    0     0  12.6M      0  0:01:02  0:00:13  0:00:49 18.8M 28  790M   28  226M    0     0  15.8M      0  0:00:49  0:00:14  0:00:35 31.9M 35  790M   35  283M    0     0  18.4M      0  0:00:42  0:00:15  0:00:27 42.7M 43  790M   43  341M    0     0  20.9M      0  0:00:37  0:00:16  0:00:21 55.7M 50  790M   50  397M    0     0  22.9M      0  0:00:34  0:00:17  0:00:17 56.5M 57  790M   57  454M    0     0  24.7M      0  0:00:31  0:00:18  0:00:13 56.6M 63  790M   63  504M    0     0  26.1M      0  0:00:30  0:00:19  0:00:11 55.7M 70  790M   70  558M    0     0  27.4M      0  0:00:28  0:00:20  0:00:08 55.2M 77  790M   77  614M    0     0  28.8M      0  0:00:27  0:00:21  0:00:06 54.4M 84  790M   84  668M    0     0  29.9M      0  0:00:26  0:00:22  0:00:04 54.2M 91  790M   91  720M    0     0  30.8M      0  0:00:25  0:00:23  0:00:02 53.5M 98  790M   98  775M    0     0  31.8M      0  0:00:24  0:00:24 --:--:-- 54.0M100  790M  100  790M    0     0  32.1M      0  0:00:24  0:00:24 --:--:-- 54.8M
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.security.capability'

== 01:11:21  base rootfs is aarch64

== 01:11:21  writing pacman.conf (repos: omarchy, core, extra, alarm)
host /etc/resolv.conf:
# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients to the
# internal DNS stub resolver of systemd-resolved. This file lists all
# configured search domains.
#
# Run "resolvectl status" to see details about the uplink DNS servers
# currently in use.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 127.0.0.53
options edns0 trust-ad
search zhg52qm01lne5auqhd3vxei1rd.cx.internal.cloudapp.net
/run/systemd/resolve/resolv.conf:
# This is /run/systemd/resolve/resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients directly to
# all known uplink DNS servers. This file lists all configured search domains.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 168.63.129.16
search zhg52qm01lne5auqhd3vxei1rd.cx.internal.cloudapp.net
candidates: 168.63.129.16 127.0.0.53 168.63.129.16 1.1.1.1 8.8.8.8 8.8.4.4 9.9.9.9

!! FAILED: no working DNS inside the chroot - see the diagnostics above
```
