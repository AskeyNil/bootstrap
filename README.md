# bootstrap

个人装机脚本，用于在 Ubuntu 和 macOS 上快速恢复常用开发环境。

这个仓库会被用于自己的机器初始化，不追求做成通用发行版安装器。默认配置偏向中国大陆网络环境，并保留若干个人偏好，例如 zsh、Sheldon、Rust 镜像、Docker 清华源和 OpenRGB。

## 支持范围

| 系统 | 默认模块 | 说明 |
| --- | --- | --- |
| Ubuntu | `base rust cli shell docker openrgb` | 使用 `apt-get`，包含 Docker 和 OpenRGB |
| macOS | `base rust cli shell` | 使用 Homebrew，不安装 Docker/OpenRGB |

Linux 目前只支持 Ubuntu。macOS 的包管理只使用 Homebrew。

## 快速开始

一键安装：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AskeyNil/bootstrap/main/install.sh)"
```

一键安装会先把完整仓库落到 `~/.local/share/bootstrap`，再从该目录执行。这样 zsh 配置软链接不会指向临时目录。

先预览再安装：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AskeyNil/bootstrap/main/install.sh)" -- --dry-run
```

需要代理时：

```bash
HTTPS_PROXY=http://127.0.0.1:7890 bash -c 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/AskeyNil/bootstrap/main/install.sh)"'
```

也可以 clone 后执行，方便查看脚本内容和后续更新：

```bash
git clone https://github.com/AskeyNil/bootstrap.git ~/bootstrap
cd ~/bootstrap
./install.sh --dry-run
./install.sh
```

也可以只运行指定模块：

```bash
./install.sh base rust cli shell
./install.sh docker
./install.sh openrgb
```

查看帮助：

```bash
./install.sh --help
```

## dry-run

`--dry-run` 用于预览动作：

```bash
./install.sh --dry-run
./install.sh --dry-run openrgb
```

dry-run 不应下载文件、不调用 `sudo`、不写入系统或用户文件。如果新增模块，请保持这个约束。

## 模块说明

| 模块 | Ubuntu | macOS |
| --- | --- | --- |
| `base` | 安装 `zsh` `git` `curl` `fzf` `eza` `build-essential` `ca-certificates` | 安装 `zsh` `git` `curl` `fzf` `eza` |
| `rust` | 通过 `rsproxy.cn` 安装 Rust stable | 同左 |
| `cli` | 安装 Sheldon、Starship、zoxide、atuin | 同左 |
| `shell` | 链接 zsh 配置、Sheldon 插件清单，并尝试切换默认 shell | 同左 |
| `docker` | 安装 Docker CE，并加入 `docker` 用户组 | 跳过 |
| `openrgb` | 安装 OpenRGB AppImage | 跳过 |

## 代理

脚本会沿用已有代理变量，也支持显式传入：

```bash
PROXY_URL=http://127.0.0.1:7890 ./install.sh
PROXY_HOST=127.0.0.1 PROXY_PORT=7890 ./install.sh
```

不要把个人代理端口硬编码到脚本里。

## zsh 配置

配置源文件：

```text
config/zsh/zshrc
config/zsh/plugins.toml
```

安装后会链接到：

```text
~/.zshrc
~/.config/sheldon/plugins.toml
```

已有文件不会被静默覆盖，会先备份为 `.bak.<timestamp>`。

Sheldon 插件包括：

- zsh-completions
- fzf-tab
- eza-zsh
- zsh-autosuggestions
- fast-syntax-highlighting
- zsh-sudo

## OpenRGB

OpenRGB 是 Ubuntu 专属模块，固定版本为 `1.0rc2` / `0fca93e`。

安装位置：

```text
/opt/apps/openrgb
/usr/local/bin/openrgb
```

OpenRGB AppImage 依赖 FUSE。脚本会自动安装 `libfuse2t64` 或 `libfuse2`。

如果当前网络无法连接 Codeberg，可以先通过浏览器或其他可用网络下载官方 AppImage，再从本地文件安装：

```bash
OPENRGB_SOURCE_FILE="$HOME/Downloads/OpenRGB_1.0rc2_x86_64_0fca93e.AppImage" \
./install.sh openrgb
```

仅验证 OpenRGB 下载或本地 AppImage：

```bash
./install.sh --download-only
```

启动：

```bash
openrgb
```

包装器会通过 `sudo` 启动 OpenRGB，因为部分硬件控制需要 root 权限。

## 目录结构

```text
install.sh                  # 统一入口
lib/common.sh               # 日志、dry-run、通用工具
lib/apt.sh                  # Ubuntu apt-get 工具
lib/brew.sh                 # macOS Homebrew 工具
modules/                    # 安装模块
scripts/install-openrgb.sh  # OpenRGB 专用安装器
config/zsh/                 # zsh 和 Sheldon 配置
tests/                      # smoke test / dry-run test
AGENTS.md                   # 给 coding agent 的维护说明
```

## 验证

修改脚本后运行：

```bash
bash -n install.sh lib/common.sh lib/apt.sh lib/brew.sh modules/*.sh scripts/install-openrgb.sh tests/*.sh
./tests/test-install-openrgb.sh
./tests/test-one-line-bootstrap.sh
./tests/test-bootstrap-dry-run.sh
./tests/test-macos-dry-run.sh
./install.sh --dry-run
BOOTSTRAP_OS=macos ./install.sh --dry-run
```

测试不应执行真实系统安装。

## 设计取舍

- 模块化入口，不使用一个巨大脚本堆所有逻辑。
- Ubuntu 和 macOS 共享入口，平台差异留在模块内部处理。
- `apt-get` 用于 Ubuntu 自动化安装，Homebrew 只用于 macOS。
- OpenRGB 保持独立脚本，避免把下载校验、FUSE 和 sudo 包装器逻辑散落到主入口。
- 版本固定优先于自动追踪最新版，保证装机结果可复现。
