#!/bin/sh
# =============================================================================
# install.sh — CodeGraph 安装脚本
# 仓库：https://github.com/colbymchenry/codegraph
#
# 功能：
#   1. 检测平台（macOS / Linux / WSL），不支持 Windows native（见下方提示）
#   2. 若已安装：显示版本并执行 codegraph upgrade
#   3. 若未安装：通过官方 curl 脚本安装 CLI，然后接入目标 Agent
#
# 注意：
#   - 本脚本只负责 CLI 安装 + Agent 接入，不执行 codegraph init
#   - 项目索引请在每个项目目录下单独执行：cd <project> && codegraph init
#
# 用法：
#   ./install.sh [OPTIONS]
#
# 选项：
#   --target=TARGETS     Agent 目标，逗号分隔：auto、claude、codex、cursor 等
#                        默认：auto（自动检测已安装的 Agent）
#   --location=local     仅为当前项目配置 Agent（默认，推荐）
#   --location=global    为所有项目全局配置 Agent（需显式指定）
#   --help               显示此帮助
#
# 示例：
#   ./install.sh                                   # 自动检测 Agent，项目级配置
#   ./install.sh --target=claude                   # 仅配置 Claude Code，项目级
#   ./install.sh --target=claude,codex             # 配置多个 Agent，项目级
#   ./install.sh --location=global                 # 全局配置，自动检测 Agent
# =============================================================================

set -eu

# --- [库特定] 官方安装源 ---
CODEGRAPH_INSTALL_URL="https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh"

# --- 默认值 ---
TARGET="auto"
LOCATION="local"

# =============================================================================
# 帮助信息
# =============================================================================
usage() {
  sed -n '/^# 用法/,/^# ====/p' "$0" | sed 's/^# \?//'
  exit 0
}

# =============================================================================
# 解析 flag
# =============================================================================
for arg in "$@"; do
  case "$arg" in
    --target=*)   TARGET="${arg#--target=}" ;;
    --location=local)  LOCATION="local" ;;
    --location=global) LOCATION="global" ;;
    --help|-h)    usage ;;
    *)
      printf 'Error: 未知选项 "%s"\n' "$arg" >&2
      printf '运行 "%s --help" 查看用法\n' "$0" >&2
      exit 1
      ;;
  esac
done

# =============================================================================
# 平台检测
# =============================================================================
detect_platform() {
  _uname="$(uname -s 2>/dev/null || echo unknown)"
  case "$_uname" in
    Darwin)
      PLATFORM="macos"
      ;;
    Linux)
      if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        PLATFORM="wsl"
      else
        PLATFORM="linux"
      fi
      ;;
    *)
      printf 'Error: 不支持的平台 "%s"。\n' "$_uname" >&2
      printf '本脚本支持 macOS、Linux 和 WSL。\n' >&2
      printf 'Windows 用户请在 PowerShell 中执行：\n' >&2
      printf '  irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex\n' >&2
      exit 1
      ;;
  esac
}

# =============================================================================
# 安装后 PATH 修复
# 通过 curl | sh 安装的二进制在当前 session 内 PATH 可能未生效，
# 主动在常见安装路径中查找并临时扩展 PATH。
# =============================================================================
refresh_path() {
  for _dir in \
    "$HOME/.local/bin" \
    "$HOME/bin" \
    "/usr/local/bin" \
    "/opt/homebrew/bin"
  do
    if [ -x "$_dir/codegraph" ]; then
      export PATH="$_dir:$PATH"
      return 0
    fi
  done
}

# =============================================================================
# CLI 安装（[库特定] 官方 curl 脚本）
# =============================================================================
install_cli() {
  printf '→ 正在安装 CodeGraph CLI...\n'
  curl -fsSL "$CODEGRAPH_INSTALL_URL" | sh
  refresh_path
}

# =============================================================================
# Agent 接入
# =============================================================================
wire_agents() {
  printf '→ 配置 Agent（target=%s，location=%s）...\n' "$TARGET" "$LOCATION"
  codegraph install --target="$TARGET" --location="$LOCATION" --yes
}

# =============================================================================
# 安装后提示
# =============================================================================
print_next_steps() {
  printf '\n'
  printf '✓ 安装完成。\n'
  printf '\n'
  printf '下一步：为每个项目单独初始化代码图谱：\n'
  printf '  cd /path/to/your/project\n'
  printf '  codegraph init\n'
  printf '\n'
  printf '验证 Agent 已接入：重启 Agent 后提问代码结构问题，\n'
  printf '确认 Agent 调用了 codegraph_explore 工具，而非逐文件 read/grep。\n'
}

# =============================================================================
# 主流程
# =============================================================================
main() {
  detect_platform

  printf '平台：%s\n' "$PLATFORM"
  printf 'Agent 目标：%s\n' "$TARGET"
  printf '配置范围：%s\n' "$LOCATION"
  printf '\n'

  # --- 已安装：升级检查 ---
  if command -v codegraph >/dev/null 2>&1; then
    _current="$(codegraph version 2>/dev/null || printf 'unknown')"
    printf 'ℹ CodeGraph 已安装（%s），检查更新...\n' "$_current"
    printf '\n'
    # codegraph upgrade 内置"已是最新"判断，无需额外处理退出码
    codegraph upgrade || true
    printf '\n'
    printf '提示：如需重新配置 Agent，运行：\n'
    printf '  %s --target=<agent>\n' "$0"
    exit 0
  fi

  # --- 首次安装 ---
  printf '=== CodeGraph 首次安装 ===\n'
  install_cli

  # 验证 CLI 可用
  if ! command -v codegraph >/dev/null 2>&1; then
    printf '\n'
    printf 'Error: 安装后仍找不到 codegraph 命令。\n' >&2
    printf '请重新打开终端后重试，或手动安装：\n' >&2
    printf '  npm i -g @colbymchenry/codegraph\n' >&2
    exit 1
  fi

  wire_agents
  print_next_steps
}

main
