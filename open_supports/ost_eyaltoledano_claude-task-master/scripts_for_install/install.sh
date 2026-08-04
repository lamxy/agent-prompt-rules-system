#!/bin/sh
# =============================================================================
# install.sh — Taskmaster 安装脚本
# 仓库：https://github.com/eyaltoledano/claude-task-master
#
# 功能：
#   1. 检测平台（macOS / Linux / WSL），Windows native 给出官方 npm 路径提示
#   2. 检查 Node.js >= 20.0.0、npm 和 npx
#   3. 按 location 安装 / 更新 task-master-ai CLI
#   4. 可选：显式传 --claude-mcp 时，注册 Claude Code MCP server
#   5. 可选：显式传 --init-project 时，在目标项目运行 task-master init
#
# 用法：
#   ./install.sh [OPTIONS] [TARGET_DIR]
#
# 选项：
#   --location=local      项目级 npm 安装（默认）
#   --location=global     全局 npm 安装
#   --global              --location=global 的别名
#   --local               --location=local 的别名
#   --project-dir=DIR     项目目录（默认：当前目录）
#   TARGET_DIR            --project-dir 的位置参数别名（仅本地安装或 --init-project 时使用）
#   --claude-mcp          同时配置 Claude Code MCP server（会修改 Claude 配置）
#   --mcp-scope=SCOPE     Claude MCP scope，默认 user；透传给 claude mcp add --scope
#   --tools=MODE          MCP 工具加载模式，如 core、standard、all、lean 或逗号列表
#   --init-project        安装后运行 task-master init（会修改项目目录）
#   --help|-h             显示此帮助
#
# 示例：
#   ./install.sh --location=local --project-dir=/path/to/project
#   ./install.sh --global
#   ./install.sh --global --claude-mcp --tools=core
#   ./install.sh --location=local --project-dir=. --init-project
#
# 说明：
#   - 安装模式：双模（全局 + 项目级）。项目级 npm 安装依赖 CWD；脚本会在子 Shell 中切换到目标目录。
#   - 本脚本不会写入 API keys。
#   - MCP 使用 API key 时，请在项目 .env 或 MCP 配置 env 区块中设置。
#   - 使用 Claude Code / Codex CLI provider 时，需要对应 CLI 已安装并完成认证。
# =============================================================================

set -eu

PACKAGE_NAME="task-master-ai"
BINARY_NAME="task-master"
PROJECT_DIR="."
LOCATION="local"
CLAUDE_MCP="no"
MCP_SCOPE="user"
TOOLS_MODE=""
INIT_PROJECT="no"
PROJECT_DIR_SET="no"

usage() {
  sed -n '/^# 用法/,/^# ====/p' "$0" | sed '/^# ====/d; s/^# \?//'
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  printf '运行 "%s --help" 查看用法\n' "$0" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --location=local|--local)
      LOCATION="local"
      ;;
    --location=global|--global)
      LOCATION="global"
      ;;
    --project-dir=*)
      PROJECT_DIR="${1#--project-dir=}"
      PROJECT_DIR_SET="yes"
      ;;
    --claude-mcp)
      CLAUDE_MCP="yes"
      ;;
    --mcp-scope=*)
      MCP_SCOPE="${1#--mcp-scope=}"
      ;;
    --tools=*)
      TOOLS_MODE="${1#--tools=}"
      ;;
    --init-project)
      INIT_PROJECT="yes"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      fail_usage "未知选项 \"$1\""
      ;;
    *)
      if [ "$PROJECT_DIR_SET" = "yes" ]; then
        fail_usage '只能指定一个 TARGET_DIR 或 --project-dir'
      fi
      PROJECT_DIR="$1"
      PROJECT_DIR_SET="yes"
      ;;
  esac
  shift
done

case "$MCP_SCOPE" in
  user|project|local) ;;
  *) fail_usage '--mcp-scope 只能是 user、project 或 local' ;;
esac

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
    MINGW*|MSYS*|CYGWIN*)
      printf 'Error: 检测到 Windows native shell（%s）。\n' "$_uname" >&2
      printf '本脚本仅支持 macOS、Linux 和 WSL。\n' >&2
      printf 'Windows 用户可在已安装 Node.js/npm 的终端中直接运行官方命令：\n' >&2
      printf '  npm install -g %s\n' "$PACKAGE_NAME" >&2
      printf '  npm install %s\n' "$PACKAGE_NAME" >&2
      exit 1
      ;;
    *)
      printf 'Error: 不支持的平台 "%s"。本脚本支持 macOS、Linux 和 WSL。\n' "$_uname" >&2
      exit 1
      ;;
  esac
}

clean_version() {
  printf '%s\n' "$1" | sed 's/^v//; s/^[^0-9]*//; s/[^0-9.].*$//'
}

version_ge() {
  _have="$1"
  _need="$2"
  _old_ifs="$IFS"

  IFS=.
  set -- $_have
  _h1="${1:-0}"
  _h2="${2:-0}"
  _h3="${3:-0}"

  set -- $_need
  _n1="${1:-0}"
  _n2="${2:-0}"
  _n3="${3:-0}"
  IFS="$_old_ifs"

  if [ "$_h1" -gt "$_n1" ]; then return 0; fi
  if [ "$_h1" -lt "$_n1" ]; then return 1; fi
  if [ "$_h2" -gt "$_n2" ]; then return 0; fi
  if [ "$_h2" -lt "$_n2" ]; then return 1; fi
  if [ "$_h3" -ge "$_n3" ]; then return 0; fi
  return 1
}

require_command() {
  _cmd="$1"
  _hint="$2"
  if ! command -v "$_cmd" >/dev/null 2>&1; then
    printf 'Error: 找不到 %s。\n' "$_cmd" >&2
    printf '%s\n' "$_hint" >&2
    exit 1
  fi
}

check_node_runtime() {
  require_command "node" "请先安装 Node.js >= 20.0.0。"
  require_command "npm" "请先安装 npm。"
  require_command "npx" "请先安装 npm/npx。"

  _node_version="$(clean_version "$(node --version 2>/dev/null || true)")"
  if [ -z "$_node_version" ] || ! version_ge "$_node_version" "20.0.0"; then
    printf 'Error: Node.js 版本不满足要求（当前：%s，要求：>= 20.0.0）。\n' "${_node_version:-unknown}" >&2
    exit 1
  fi

  NODE_VERSION="$_node_version"
  NPM_VERSION="$(npm --version 2>/dev/null || printf unknown)"
}

normalize_project_dir() {
  if [ "$LOCATION" = "local" ] || [ "$INIT_PROJECT" = "yes" ]; then
    [ -d "$PROJECT_DIR" ] || {
      printf 'Target project directory does not exist: %s\n' "$PROJECT_DIR" >&2
      exit 1
    }
    PROJECT_DIR="$(CDPATH= cd -- "$PROJECT_DIR" && pwd)"
  fi
}

install_cli() {
  if [ "$LOCATION" = "global" ]; then
    printf '%s\n' "-> 安装 / 更新全局 $PACKAGE_NAME..."
    npm install -g "$PACKAGE_NAME@latest"
  else
    printf '%s\n' "-> 在项目目录安装 / 更新 $PACKAGE_NAME：$PROJECT_DIR"
    (cd "$PROJECT_DIR" && npm install "$PACKAGE_NAME@latest")
  fi
}

verify_cli() {
  printf '%s\n' '-> 验证 CLI...'
  if [ "$LOCATION" = "global" ]; then
    require_command "$BINARY_NAME" "全局安装完成后仍找不到 task-master，请检查 npm global bin 是否在 PATH 中。"
    "$BINARY_NAME" --version >/dev/null 2>&1 || "$BINARY_NAME" --help >/dev/null 2>&1
  else
    (cd "$PROJECT_DIR" && npx "$BINARY_NAME" --version >/dev/null 2>&1) || \
      (cd "$PROJECT_DIR" && npx "$BINARY_NAME" --help >/dev/null 2>&1)
  fi
}

configure_claude_mcp() {
  [ "$CLAUDE_MCP" = "yes" ] || return 0
  require_command "claude" "配置 Claude Code MCP 前，请先安装并登录 Claude Code CLI。"

  printf '%s\n' "-> 配置 Claude Code MCP server（scope=$MCP_SCOPE）..."
  if [ -n "$TOOLS_MODE" ]; then
    claude mcp add task-master-ai --scope "$MCP_SCOPE" \
      --env TASK_MASTER_TOOLS="$TOOLS_MODE" \
      -- npx -y "$PACKAGE_NAME@latest"
  else
    claude mcp add taskmaster-ai -- npx -y "$PACKAGE_NAME"
  fi
}

init_project() {
  [ "$INIT_PROJECT" = "yes" ] || return 0
  printf '%s\n' "-> 初始化 Taskmaster 项目：$PROJECT_DIR"
  if [ "$LOCATION" = "global" ]; then
    (cd "$PROJECT_DIR" && "$BINARY_NAME" init)
  else
    (cd "$PROJECT_DIR" && npx "$BINARY_NAME" init)
  fi
}

print_summary() {
  printf '平台：%s\n' "$PLATFORM"
  printf 'Node.js：%s\n' "$NODE_VERSION"
  printf 'npm：%s\n' "$NPM_VERSION"
  printf '安装范围：%s\n' "$LOCATION"
  if [ "$LOCATION" = "local" ] || [ "$INIT_PROJECT" = "yes" ]; then
    printf '项目目录：%s\n' "$PROJECT_DIR"
  fi
  printf 'Claude MCP：%s\n' "$CLAUDE_MCP"
  if [ "$CLAUDE_MCP" = "yes" ]; then
    printf 'MCP scope：%s\n' "$MCP_SCOPE"
    printf 'TASK_MASTER_TOOLS：%s\n' "${TOOLS_MODE:-未设置}"
  fi
  printf '初始化项目：%s\n\n' "$INIT_PROJECT"
}

print_next_steps() {
  printf '\n✓ Taskmaster 安装流程完成。\n\n'
  if [ "$LOCATION" = "global" ]; then
    printf '验证命令：\n'
    printf '  task-master --version\n'
    printf '  task-master models\n'
  else
    printf '验证命令：\n'
    printf '  cd %s\n' "$PROJECT_DIR"
    printf '  npx task-master --version\n'
    printf '  npx task-master models\n'
  fi
  printf '\n下一步：\n'
  printf '  1. 在项目根目录 .env 或 MCP 配置 env 区块中设置所需 API keys。\n'
  printf '  2. 运行 task-master models --setup 配置模型。\n'
  printf '  3. 运行 task-master init 初始化项目，或通过 MCP 让 Agent 初始化。\n'
  printf '  4. 将 PRD 放到 .taskmaster/docs/prd.txt 后运行 task-master parse-prd .taskmaster/docs/prd.txt。\n'
}

main() {
  normalize_project_dir
  detect_platform
  check_node_runtime
  print_summary
  install_cli
  verify_cli
  configure_claude_mcp
  init_project
  print_next_steps
}

main
