# crDroid nabu — GitHub Actions 构建流水线

给 **小米平板 5（codename `nabu`，骁龙 860 / sm8150）** 的 crDroid **13（Android 17，分支 `17.0`）** 做编译、验证、发布。

---

## 先说结论

| 路线 | 能在 GitHub 托管 runner 上跑吗 | 需要什么 | 产出 |
|---|---|---|---|
| `build-kernel` | ✅ **能**（实测预算见下） | 无 | **`Image.gz`（可换进现有 boot.img）** |
| `runner-check` | ✅ 能 | 无 | 告诉你这台 runner 够不够格 |
| `publish-official` | ✅ 能 | 无 | 官方 17.0 包 + 校验 + GitHub Release |
| `build-rom` | ❌ **不能** | **自托管 runner：≥400 GB 磁盘 / ≥32 GB 内存 / Linux x86_64** | 你自己编的 ROM |

> **要 Droidspaces 不需要编 ROM，只需要编内核。** 上一版把结论写成"云上编不了"，那是对**全量 ROM** 说的，对**内核**不成立：内核树 1.2 GB、工具链 1.3 GB、`out/` 4 GB，托管 runner 的 87 GB / 16 GB / 6 小时全部够用。`build-kernel` 就是这条路，详见下文。

**为什么 `build-rom` 不能在托管 runner 上跑**（这是硬限制，不是配置问题）：

| 项 | GitHub 托管 runner（**实测**，run #2） | AOSP 需要 |
|---|---|---|
| 磁盘 | **87 GB** 空闲（工作卷） | **250 GB** 检出 + 150 GB 构建 |
| 内存 | **15 GB** | 32–64 GB |
| 单任务时长 | **6 小时** | 8 核首次全量 4–8 小时 |
| 更大规格 runner | 仅 **Team / Enterprise 组织**可用，且按分钟计费 | — |

> 实测来源：`runner-check` 在 `ubuntu-latest` 上的真实输出 —— `Linux 7.0.0-1017-azure x86_64`、`glibc 2.43`、`free disk 87 GB`、`memory 15 GB`。官方文档写的 14 GB 是根分区口径；不管哪个口径，都差 4 倍以上。

个人账号用不了 larger runner，所以「在 GitHub 上编」这件事，唯一真实的解法是**给仓库挂一台自托管 runner**。仓库里的 `runner-check` 就是用来当场验证这一点的——它现在跑出来的结论就是上面那张表。

---

## 怎么选：先问两个问题

```
Q1  你要"自己编的"包吗？
     要 ────────────────→ 路线 A：build-rom + 自托管 runner（没有机器就到此为止）
     不要 ↓
Q2  拿现成包时，要不要走 GitHub 这条流水线？
     要 ────────────────→ 路线 B：publish-official
     不要 ──────────────→ 路线 C：直接下
```

B 和 C **拿到的是同一个文件，二进制完全相同**。区别只在"校验、留档、刷机准备"，不在"包"。A 才是真的不一样——那是你自己编的，可以带 Droidspaces 内核支持。

| | B `publish-official` | C 直接下 |
|---|---|---|
| 产物 | Release：zip + `boot.img` + `vendor_boot.img` + `dtbo.img`，sha256 写进 run summary | 只有一个 zip（1.42 GiB） |
| 额外耗时 | 1.4 GB 下行 **+ 1.4 GB 上行** | 只有 1.4 GB 下行 |
| 校验 | 自动四道：zip 完整性、体积下限、`pre-device=nabu`、sha256 落档 | 靠你自己；上游 17.0 没有 OTA json，也就没有公布的 sha256 |
| 刷机准备 | `boot.img` 已拆好，直接 `fastboot flash boot` | 先 `unzip` 解 1.4 GB 才拿到 |
| 防呆 | 下载后立刻比对机型 | 只能现场 `fastboot getvar product` |
| 留档 | 固定在你仓库，上游删包不影响 | 上游 `13.x/` 只留最近几个，旧包会消失 |
| 依赖 | GitHub Actions + 仓库里的校验脚本 | 只依赖 SourceForge |
| 主要失败点 | 排队、上传限速 | 慢速/断线拿到截断包，且没校验发现不了 |

**一句话**：B 没有让包变"更可信"，它只是把"上游给的字节"过一遍机器校验、拆开、留档。信任链还是 crDroid 维护者和 SourceForge。

### B 路线：`publish-official`

在 Actions 里手动跑 `publish-official`，填日期（默认 `20261021`）。它会：

1. 列出 SourceForge `crdroid/files/nabu/13.x/` 当前所有包；
2. 下载指定的那个（约 1.4 GiB）；
3. 校验：zip 完整性、大小、`pre-device=nabu` 断言、sha256；
4. 把 `boot.img` / `vendor_boot.img` / `dtbo.img` 单独拆出来；
5. 建一个 GitHub Release，把这些都挂上去。

适合：想在自己仓库里留一份带校验的版本、或者要给朋友发链接。

> Release asset 单文件上限 2 GB，1.4 GiB 的包放得下。**不要**用 Actions artifact 传它——Free 计划的 artifact 存储只有 500 MB。

### C 路线：直接下

```bash
curl -L -O "https://sourceforge.net/projects/crdroid/files/nabu/13.x/crDroidAndroid-17.0-20261021-nabu-v13.0.zip/download"
shasum -a 256 crDroidAndroid-17.0-20261021-nabu-v13.0.zip   # 自己记下来
unzip -o crDroidAndroid-17.0-20261021-nabu-v13.0.zip 'IMAGES/*' -d rom
```

刷机步骤见本文末尾。

### A 路线：`build-rom` + 自托管 runner

需要一台 Linux 机器（物理机 / 云主机 / 家里闲置 PC），要求：

- **磁盘 ≥ 400 GB SSD**（源码树约 250 GB，`out/` 再加 150 GB）
- 内存 ≥ 32 GB（64 GB 舒服）
- ≥ 8 vCPU
- 64 位 Ubuntu 22.04 / 24.04，大小写敏感文件系统

装 runner：

```bash
# 在 Linux 机器上
mkdir -p ~/actions-runner && cd ~/actions-runner
# 从仓库 Settings -> Actions -> Runners -> New self-hosted runner 拿 token
curl -o actions-runner.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz
tar xzf actions-runner.tar.gz
./config.sh --url https://github.com/<you>/crdroid-nabu-build \
            --token <TOKEN> \
            --labels self-hosted,linux,x64,nabu \
            --name nabu-builder --unattended
sudo ./svc.sh install && sudo ./svc.sh start
```

标签必须是 `self-hosted,linux,x64,nabu`（工作流默认按这四个找）。

然后 `bash scripts/setup-host.sh` 装依赖（apt 包、repo、gh、ccache），再在 Actions 里跑 `build-rom`。

第一次 `repo sync` 约 250 GB，几小时；之后**增量**——源码树和 ccache 都放在 `$HOME/crdroid` / `$HOME/.ccache`（不在 workspace 里，不会被清理），所以第二次开始通常是 20–40 分钟。

---

## 工作流参数

### `runner-check`

| 输入 | 默认 | 说明 |
|---|---|---|
| `runner` | `["ubuntu-latest"]` | runner 标签的 **JSON 数组** |

先拿默认值跑一次，你会看到 `14 GB` 和红色的失败——那就是"托管 runner 编不了"的证据。换成自托管标签再跑，应该是绿的。

### `build-rom`

| 输入 | 默认 | 说明 |
|---|---|---|
| `variant` | `userdebug` | `userdebug` / `user` / `eng` |
| `branch` | `17.0` | crDroid manifest 分支 |
| `runner` | `["self-hosted","linux","x64","nabu"]` | JSON 数组 |
| `droidspaces` | `true` | 合并内核片段并**验证编出来的 .config**（见下一节） |
| `release` | `true` | 是否建 Release 并挂包 |

产物：`out/target/product/nabu/crDroidAndroid-17.0-<日期>-nabu-v13.0.zip`，成功时写进 run summary（内核版本、Droidspaces 状态、大小、sha256），失败时上传 `build-log` artifact。

---

## `build-kernel`：只编内核，托管 runner 就能跑

目标只有一个：**给现有 ROM 换一个支持容器的内核**。ROM 本身不动，userdata 不动，root 不动。

### 为什么这条路成立

| 项 | 托管 runner（实测 `ubuntu-latest`） | 内核编译需要 |
|---|---|---|
| 磁盘 | 87 GB 空闲 | 源码 1.2 GB + 工具链 1.3 GB + `out/` ~4 GB |
| 内存 | 15 GB | LTO 关闭时 4–6 GB |
| 时长 | 6 小时/任务 | 4 核约 30–60 分钟 |

差的只是"全量 AOSP 要 250 GB"，而这条路根本不 checkout AOSP。

### 参数

| 输入 | 默认 | 说明 |
|---|---|---|
| `commit` | `a17239b2eda3ccba274456d87aab4fd6f0bb734d` | 就是设备上正在跑的那个 commit |
| `droidspaces` | `true` | 合并 `kernel/droidspaces-nabu.config` 并**逐项校验编出来的 .config** |
| `lto` | `false` | 保留 `CONFIG_LTO_CLANG`。全量 LTO 在 4 核/16 GB 上容易 OOM 或超时，功能上无差别 |
| `modules` | `false` | 这台机器的内核是单片式，不需要模块（见下） |
| `release` | `true` | 把 `Image.gz` 等挂到 Release |

推到 `main` 且改动命中 `kernel/**`、`scripts/build-kernel.sh`、该 workflow 时会**自动跑一次**，不需要手动点。

### 产物

`Image.gz`（约 24 MB）、`Image`、`kernel.config`、`System.map`、`build-info.txt`（commit / 内核 release 串 / clang 版本 / sha256）。

### 本地换进 boot.img

```bash
python3 scripts/repack-boot.py \
  --template boot.img \
  --kernel Image.gz \
  --out boot-new.img
```

`repack-boot.py` 只替换内核区，header（v3 / page 4096 / cmdline / os_version）和 ramdisk 原样保留。已用真机 `boot.img` 做过往返自测：把原内核抽出来再打回去，除末 64 字节 AVB footer 外**逐字节一致**。AVB footer 会被清零——内容已经变了，旧哈希没有意义，而 bootloader 是解锁的（`orange`）。

刷入与回滚：

```bash
adb reboot bootloader
fastboot flash boot boot-new.img
fastboot reboot
# 不行就回滚：
fastboot flash boot boot.img        # 原厂那份
```

**不要**碰 `vendor_boot` / `dtbo`：前者是 Magisk 的 ramdisk 宿主，后者装 dtb（这个 boot.img 里没有 FDT，已核实）。

### 三个必须一致的东西

换内核而不换 ROM，只有三处会对不上，都已经钉住了：

1. **版本串**。设备是 `4.14.357-perf-ga17239b2eda3`，`scripts/setlocalversion` 会读 `.scmversion`，所以构建脚本把它写成 `-g<commit前12位>`，浅克隆也不会漂。
2. **vermagic**。`msm-geni-ir.ko` 报的是 `4.14.357-perf-ga17239b2eda3 SMP preempt mod_unload modversions aarch64`——版本串一致 + 同一份 .config 就自动一致。
3. **模块 ABI**。`CONFIG_SYSVIPC` 会把 `sysvsem/sysvshm` 插在 `comm` 之后，导致 `task_struct` 后续字段整体位移。实测 `/vendor/lib/modules` 只有 `msm-geni-ir.ko` 一个真模块、`lsmod` 为空，内核实际是单片式，所以这个位移在这里无害。**换 ROM 或厂商加了模块，就必须连模块一起重编。**

---

## Droidspaces 支持（容器 / 内核配置）

想在这台平板上跑 `systemd`、跑 Docker、跑一堆常驻服务，路线是 **Droidspaces**：容器直接跑在 Android 内核上，不需要换内核、不需要动分区，驱动全部继承原厂。代价是内核必须打开一组容器运行时需要的选项。

### 现状（2026-10-22 核实）

| 事实 | 值 | 来源 |
|---|---|---|
| crDroid 17.0 内核版本 | **4.14.357** | `kernel/xiaomi/nabu/Makefile` |
| `CONFIG_PID_NS` | **`# CONFIG_PID_NS is not set`** | `arch/arm64/configs/vendor/sm8150-perf_defconfig` |
| `CONFIG_NAMESPACES` / `CGROUPS` / `MEMCG` / `SECCOMP` / `VETH` / `BRIDGE` / `OVERLAY_FS` / `TUN` | 已经 `=y` | 同上 |
| `CONFIG_BRIDGE_NETFILTER` | **显式关闭**（NAT 模式会缺这一环） | 同上 |
| `CONFIG_SYSVIPC` / `POSIX_MQUEUE` / `USER_NS` / `MACVLAN` / `CGROUP_PIDS` | 未设置 | 同上 |
| 社区特调内核 `Huiyicc/...-Droidspaces-OSS` | **4.14.325** —— 比 crDroid 的更旧 | 该仓库 `Makefile` |

**结论：不要为了 Droidspaces 换掉 crDroid 的内核树。** 那棵特调树是 4.14.325，crDroid 17.0 已经是 4.14.357。正确做法是**在最新的 4.14.357 上叠加一份配置片段**——这正是 `kernel/droidspaces-nabu.config` 干的事。

### 怎么用

`build-rom` 的 `droidspaces` 输入默认就是 `true`，它会：

1. 把 `kernel/droidspaces-nabu.config` 拷进内核树的 `arch/arm64/configs/vendor/xiaomi/droidspaces.config`；
2. 把这一项追加到 `device/xiaomi/nabu/BoardConfig.mk` 的 `TARGET_KERNEL_CONFIG`（幂等，跑两次不会重复）；
3. 编译（`merge_config.sh` 会合并，未知符号只告警不中断）；
4. **编译后读 `out/.../obj/KERNEL_OBJ/.config` 逐项核对**，把表格写进 run summary；缺必需项就直接失败，不会让你刷一个"以为支持其实不支持"的包。

手动跑：

```bash
DROIDSPACES=1 CRDROID_BRANCH=17.0 bash scripts/build-rom.sh
# 单独验证已有构建：
bash scripts/verify-kernel-config.sh --tree ~/crdroid
```

### 片段里放了什么

来源是 Droidspaces 官方 `Documentation/Kernel-Configuration.md` 的 **Non-GKI（3.18–4.19）** 一节，逐条搬过来并注明用途：IPC（`SYSVIPC`/`POSIX_MQUEUE`）、命名空间（`PID_NS`/`UTS_NS`/`IPC_NS`/`NET_NS`/`USER_NS`）、seccomp、cgroups（`CGROUP_PIDS`/`CFS_BANDWIDTH`/`MEMCG_SWAP`）、`DEVTMPFS`、`OVERLAY_FS`、firmware loader、`VETH`/`BRIDGE`/`MACVLAN`、netfilter+NAT（IPv4 与 IPv6）、以及 `CONFIG_ANDROID_PARANOID_NETWORK` 关掉。

⚠️ 两个必须知道的点：

- **`merge_config` 不保证生效**。Kconfig 会按依赖关系裁剪，4.14 上有些符号（如 `NF_NAT_REDIRECT`、`NF_CONNTRACK_NETLINK`）根本不存在，会被静默忽略。所以 `verify-kernel-config.sh` 读的是**编出来的 .config**，不是片段文件。
- **`CONFIG_ANDROID_PARANOID_NETWORK`** 若被其它片段重新打开，容器会没有外网（除非 gid 在 `AID_INET`）。验证脚本会单独告警这一条。

### 刷完怎么确认

```bash
adb shell su -c 'zcat /proc/config.gz | grep -E "CONFIG_(PID_NS|SYSVIPC|DEVTMPFS)="'   # 若内核开了 IKCONFIG
adb shell su -c 'ls /proc/self/ns/'          # 应有 cgroup ipc mnt net pid user uts
adb shell su -c 'unshare -pf --mount-proc true && echo pid-ns-ok'
```

`/proc/self/ns/pid` 存在 + `unshare -p` 不报错，才说明 PID namespace 真的可用。

### `publish-official`

| 输入 | 默认 | 说明 |
|---|---|---|
| `build_date` | `20261021` | SourceForge 上的日期（YYYYMMDD） |
| `cr_version` | `13.0` | 文件名里的 crDroid 版本 |
| `android_version` | `17.0` | 文件名里的 Android 版本 |

日期不存在会直接列出当前可用日期然后失败，不会瞎猜。

---

## 仓库里有什么

```
.github/workflows/
  build-kernel.yml       # 只编内核（托管 runner 可跑）← Droidspaces 走这条
  runner-check.yml       # 这台 runner 够不够格（已在托管 runner 上实跑验证）
  build-rom.yml          # 全量编译（需自托管），可选 Droidspaces 内核片段
  publish-official.yml   # 拉官方包 + 校验 + 发 Release
kernel/
  droidspaces-nabu.config  # 容器所需的 4.14 内核配置片段（按真机实测缺口整理）
scripts/
  build-kernel.sh          # 拉内核树 + 合并片段 + 编 Image.gz，钉版本串
  repack-boot.py           # 把 Image.gz 换进现有 boot.img（往返自测通过）
  setup-host.sh            # apt 依赖 + repo + gh + ccache，幂等
  build-rom.sh             # 增量 sync + brunch，带磁盘守卫和重试
  apply-droidspaces.sh     # 把片段接进内核构建（幂等，已验证）
  verify-kernel-config.sh  # 读编出来的 .config 逐项核对（已验证）
  publish.sh               # 发 Release（gh 优先，curl 兜底）
```

**仓库里没有 AOSP 源码**，也不需要——源码树在 runner 的 `$HOME/crdroid`。

`scripts/` 也可以脱离 Actions 用：

```bash
bash scripts/setup-host.sh
CRDROID_BRANCH=17.0 VARIANT=userdebug bash scripts/build-rom.sh
```

---

## 刷机（A/B + 虚拟 A/B，无独立 recovery 分区）

```bash
fastboot getvar product                 # 必须输出 nabu
unzip -o crDroidAndroid-17.0-*-nabu-v13.0.zip 'IMAGES/*' -d rom
fastboot flash boot rom/IMAGES/boot.img
[ -f rom/IMAGES/vendor_boot.img ] && fastboot flash vendor_boot rom/IMAGES/vendor_boot.img
fastboot reboot recovery
# recovery: Factory reset -> Format data   （换 ROM 必做，userdata 是 f2fs + 元数据加密）
# recovery: Apply update -> Apply from ADB
adb sideload crDroidAndroid-17.0-*-nabu-v13.0.zip
```

`dtbo` / `vbmeta` / `vbmeta_system` 由 OTA 收尾脚本自己补，不用手刷。

**机型核对没有例外**：`nabu` = 平板 5（SD860）；`elish` = 平板 5 Pro；`enuma` = Pro 5G。刷错必砖。

---

## 诚实声明

- **已验证**：`runner-check` 在 GitHub 托管 runner 上真实跑过（run #2，`failure` 且是**预期失败**——它输出的就是上面那张 87 GB / 15 GB 的表）。`apply-droidspaces.sh` 与 `verify-kernel-config.sh` 在伪造的树/配置上跑过通过路径和失败路径。
- **已验证（2026-10-23，真机）**：`boot.img` 结构（header v3 / page 4096 / 内核是 gzip 的 57.5 MB arm64 Image / 内核区**无 FDT** / 尾部有 AVB footer）；`repack-boot.py` 用原内核做往返，除末 64 字节外逐字节一致；设备 `zcat /proc/config.gz` 得到的缺口清单（PID_NS / SYSVIPC / POSIX_MQUEUE / USER_NS / DEVTMPFS / CGROUP_PIDS / MACVLAN / BRIDGE_NETFILTER / NF_TABLES）；`/vendor/lib/modules` 仅 `msm-geni-ir.ko` 一个模块且 `lsmod` 为空；`msm-geni-ir.ko` 的 vermagic。
- **未验证**：`build-kernel` **还没在 CI 上跑过一次**——第一次运行的日志才算数（本地网络到 `android.googlesource.com` 被代理拦成 502，clang 下载地址只能在 CI 上验证）。`build-rom` 没在 ≥400 GB 的 runner 上跑过；`publish-official` 没实际发过 Release；新内核没刷进真机，`unshare -p` 能不能过要刷完才知道。
- 上游事实（分支、内核版本、包名、日期、1.4 GiB 体积、Droidspaces 选项清单）核查于 **2026-10-22**。上游一改，`publish-official` 的日期参数和内核片段都要跟着改。
- 本仓库只做"取包/编译/校验/发布"，不涉及解锁 bootloader（小米需要 Mi Unlock Tool，Windows only，7 天等待）。

---

## 安全

- 工作流只用 `secrets.GITHUB_TOKEN`，权限最小化（`contents: write` 仅用于发 Release）。
- 不需要 PAT、不需要云厂商凭据、不落任何密钥到仓库。
- `setup-host.sh` 会 `apt-get install` 和下载 `repo` 启动器（Google 官方地址）。自托管 runner 上跑之前请自己读一遍。
