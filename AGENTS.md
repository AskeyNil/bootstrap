# AGENTS.md

给后续 coding agent 的维护说明。

## 项目目标

这个仓库是个人装机脚本。目标是可重复地初始化 Ubuntu 和 macOS 工作站，但不是通用跨平台 provisioning 框架。

主入口是 `./install.sh`。它负责解析参数、选择模块，并调用 `modules/` 下的安装模块。公共逻辑放在 `lib/`。

## 架构

- `install.sh`：参数解析、模块选择、全局 dry-run 和代理初始化。
- `lib/common.sh`：日志、错误处理、dry-run 执行、Ubuntu 检查、软链接备份工具。
- `lib/apt.sh`：Ubuntu 专用的 `apt-get` 封装、代理支持、Debian 包检测和安装。
- `lib/brew.sh`：macOS 专用的 Homebrew 检测、安装和包安装。
- `modules/*.sh`：每个关注点一个模块。每个模块必须暴露 `install_<module>` 函数。
- `scripts/install-openrgb.sh`：独立的 OpenRGB AppImage 安装器。它有自己的下载、校验、FUSE 依赖和 sudo 包装器逻辑，保持独立。
- `config/zsh/`：`shell` 模块链接出去的 zsh 配置源文件。
- `tests/`：shell smoke test 和 dry-run 测试。

优先新增模块，不要把 `install.sh` 变成大脚本。只有两个或更多模块需要同一段行为时，才抽到 `lib/`。

## 行为规则

- 支持 Ubuntu 和 macOS。Linux 只支持 Ubuntu；不要加入其他发行版分支，除非项目目标改变。
- macOS 包管理只使用 Homebrew；不要在 macOS 路径中调用 `apt-get`。
- 保持幂等：重复执行时，应尽量跳过已安装的包和已配置的项目。
- 保持 `--dry-run` 语义：不能下载、不能调用 `sudo`、不能写文件。
- Ubuntu 脚本化包安装使用 `apt-get`。
- OpenRGB 是 Ubuntu 专属模块，版本保持固定，除非用户明确要求更新。
- AppImage 安装到 `/opt/apps/<name>`，命令包装器放到 `/usr/local/bin`。
- 不要添加桌面启动项，除非用户明确要求。
- 不要静默删除或覆盖用户文件。需要替换时，使用 `link_with_backup` 这类备份/链接模式。

## 网络和代理

网络可能需要本地代理。当前支持：

```bash
PROXY_URL=http://127.0.0.1:7890 ./install.sh
PROXY_HOST=127.0.0.1 PROXY_PORT=7890 ./install.sh
```

不要硬编码代理地址。OpenRGB 需要保留本地文件 fallback：

```bash
OPENRGB_SOURCE_FILE=/path/to/OpenRGB.AppImage ./install.sh openrgb
```

raw `install.sh` 一键安装会自举下载完整仓库，并落到 `${XDG_DATA_HOME:-$HOME/.local/share}/bootstrap`。不要让 `shell` 模块链接到 `/tmp` 中的配置文件。

## 验证

修改 shell 脚本后运行：

```bash
bash -n install.sh lib/common.sh lib/apt.sh lib/brew.sh modules/*.sh scripts/install-openrgb.sh tests/*.sh
./tests/test-install-openrgb.sh
./tests/test-one-line-bootstrap.sh
./tests/test-bootstrap-dry-run.sh
./tests/test-macos-dry-run.sh
./install.sh --dry-run
BOOTSTRAP_OS=macos ./install.sh --dry-run
```

如果某个命令会执行真实安装，不要直接跑；改用 `--dry-run`，或补一个隔离测试。

## 编辑风格

- Bash 脚本使用 `set -Eeuo pipefail`。
- 中文说明可以保留；命令、路径、变量名保持英文。
- 注释要短，只解释不明显的行为。
- 能局部修改就不要大范围重写工作正常的模块。
- 用户可见行为、模块、路径或命令变化时，同步更新 `README.md`。
