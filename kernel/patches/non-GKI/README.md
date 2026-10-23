# Droidspaces kernel patches for nabu (Linux 4.14)

Source: `ravindu644/Droidspaces-OSS`, `Documentation/resources/kernel-patches/non-GKI/`.
The upstream doc says, for 3.18-4.19 kernels: "Apply every patch under
Documentation/resources/kernel-patches/non-GKI/".

| file | upstream | applies here | why |
|---|---|---|---|
| `02.fix_restore_cgroup_file_prefix.patch` | yes | **yes** | `kernel/cgroup/cgroup.c` `cgroup_add_file()` in this tree matches the patch context exactly (`cgroup_file_kn_lock`, `CGRP_ROOT_NOPREFIX`). Adds the prefixed cgroup file alias that LXC/Droidspaces expects when the root is mounted `noprefix`. |
| `01.fix_kernel_panic_in_xt_qtaguid.patch.NOT-APPLICABLE` | yes | **no** | Its target `net/netfilter/xt_qtaguid.c` does not exist in this tree (`404` at commit `a17239b2eda3`), and `CONFIG_QTAGUID` is not in the built `.config`. Qualcomm dropped qtaguid here, so there is no `dev_get_stats()` panic to fix. Kept with a `.NOT-APPLICABLE` suffix so the glob in `build-kernel.sh` skips it, but the patch is still on record. |

`build-kernel.sh` applies every `*.patch` in this directory with
`patch -p1 --forward --batch --fuzz=3`, and fails the build if one of them
neither applies cleanly nor is already applied. A silently unpatched kernel
would be worse than a red run.
