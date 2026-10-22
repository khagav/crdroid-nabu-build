# crDroid nabu — GitHub Actions 构建流水线

给 **小米平板 5（codename `nabu`，骁龙 860 / sm8150）** 的 crDroid **13（Android 17，分支 `17.0`）** 做编译、验证、发布。

---

## 先说结论

| 路线 | 能在 GitHub 托管 runner 上跑吗 | 需要什么 | 产出 |
|---|---|---|---|
| `runner-check` | ✅ 能 | 无 | 告诉你这台 runner 够不够格 |
| `publish-official` | ✅ 能 | 无 | 官方 17.0 包 + 校验 + GitHub Release |
| `build-rom` | ❌ **不能** | **自托管 runner：≥400 GB 磁盘 / ≥32 GB 内存 / Linux x86_64** | 你自己编的 ROM |

**为什么 `build-rom` 不能在托管 runner 上跑**（这是硬限制，不是配置问题）：

| 项 | GitHub 托管 runner | AOSP 需要 |
|---|---|---|
| 磁盘 | **14 GB** SSD（清缓存最多腾到 ~60 GB） | **250 GB** 检出 + 150 GB 构建 |
| 内存 | 16 GB | 32–64 GB |
| 单任务时长 | **6 小时** | 4 核首次全量 6–12 小时 |
| 更大规格 runner | 仅 **Team / Enterprise 组织**可用，且按分钟计费 | — |

个人账号用不了 larger runner，所以「在 GitHub 上编」这件事，唯一真实的解法是**给仓库挂一台自托管 runner**。仓库里的 `runner-check` 就是用来当场验证这一点的。

---

## 三条路线怎么选

### ① 只想拿到一个能刷的包 → `publish-official`

在 Actions 里手动跑 `publish-official`，填日期（默认 `20261021`）。它会：

1. 列出 SourceForge `crdroid/files/nabu/13.x/` 当前所有包；
2. 下载指定的那个（约 1.4 GiB）；
3. 校验：zip 完整性、大小、`pre-device=nabu` 断言、sha256；
4. 把 `boot.img` / `vendor_boot.img` / `dtbo.img` 单独拆出来；
5. 建一个 GitHub Release，把这些都挂上去。

适合：想在自己仓库里留一份带校验的版本、或者要给朋友发链接。

> Release asset 单文件上限 2 GB，1.4 GiB 的包放得下。**不要**用 Actions artifact 传它——Free 计划的 artifact 存储只有 500 MB。

### ② 真的要自己编 → `build-rom` + 自托管 runner

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

### ③ 没有机器、也不想租 → 用现成的官方包

直接下 `crdroid/files/nabu/13.x/`，用 `publish-official` 的校验逻辑自己验一遍。刷机步骤见本文末尾。

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
| `release` | `true` | 是否建 Release 并挂包 |

产物：`out/target/product/nabu/crDroidAndroid-17.0-<日期>-nabu-v13.0.zip`，成功时写进 run summary（大小 + sha256），失败时上传 `build-log` artifact。

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
  runner-check.yml       # 这台 runner 够不够格
  build-rom.yml          # 全量编译（需自托管）
  publish-official.yml   # 拉官方包 + 校验 + 发 Release
scripts/
  setup-host.sh          # apt 依赖 + repo + gh + ccache，幂等
  build-rom.sh           # 增量 sync + brunch，带磁盘守卫和重试
  publish.sh             # 发 Release（gh 优先，curl 兜底）
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

- `publish-official` 的每一步都是标准工具，但它**没有在本仓库实际跑过**（首次 push 后才会有 run 记录）。
- `build-rom` **没有在真机上验证过**，也**没有在 ≥400 GB 的 runner 上跑过**——本机是 macOS，编不了 AOSP。
- 上游事实（分支、包名、日期、1.4 GiB 体积）核查于 **2026-10-22**，来源见 commit message 与 workflow 里的 URL。上游一改，`publish-official` 的日期参数要跟着改。
- 本仓库只做"取包/编译/校验/发布"，不涉及解锁 bootloader（小米需要 Mi Unlock Tool，Windows only，7 天等待）。

---

## 安全

- 工作流只用 `secrets.GITHUB_TOKEN`，权限最小化（`contents: write` 仅用于发 Release）。
- 不需要 PAT、不需要云厂商凭据、不落任何密钥到仓库。
- `setup-host.sh` 会 `apt-get install` 和下载 `repo` 启动器（Google 官方地址）。自托管 runner 上跑之前请自己读一遍。
