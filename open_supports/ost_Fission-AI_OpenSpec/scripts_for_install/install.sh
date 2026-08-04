#!/bin/sh
# =============================================================================
# install.sh — OpenSpec 安装脚本
# 仓库：https://github.com/Fission-AI/OpenSpec
#
# 功能：
#   1. 检测支持的 Shell 平台：macOS、Linux 和 WSL。
#   2. 检查官方运行时前置条件：Node.js >= 20.19.0。
#   3. 安装或更新官方 OpenSpec CLI 包。
#   4. 可选地初始化或更新目标项目中的 OpenSpec 文件。
#
# 用法：
#   ./install.sh [选项] [目标项目目录]
#
# 选项：
#   --package-manager=PM   包管理器：npm、pnpm、yarn 或 bun（默认：npm）。
#   --project-dir=DIR      --init-project 或 --update-project 的目标项目目录（默认：当前目录）。
#   TARGET_DIR             初始化或更新项目时，--project-dir 的位置参数别名。
#   --init-project         在目标项目中运行 openspec init。
#   --tools=TOOLS          非交互式初始化的工具选择，例如 none、all、claude,cursor；默认：none。
#   --profile=PROFILE      传给 openspec init 的可选 profile。
#   --update-project       在目标项目中运行 openspec update。
#   --help|-h              显示帮助。
#
# 示例：
#   ./install.sh
#   ./install.sh --package-manager=pnpm
#   ./install.sh --init-project --tools=claude,codex --project-dir=/path/to/project
#   ./install.sh --update-project --project-dir=.
#
# 说明：
#   - 安装模式：仅全局安装 CLI；项目初始化/更新是独立且依赖 CWD 的操作。
#   - 本脚本不会卸载 OpenSpec，也不会删除项目或工具文件。
#   - 项目初始化和更新必须显式指定，因为它们会向目标项目写入 OpenSpec
#     specs/changes 及 AI 工具命令文件。
#   - 官方文档也说明了 Nix 用法；本脚本采用有文档依据的跨平台包管理器安装路径。
# =============================================================================

set -eu

PACKAGE_NAME="@fission-ai/openspec"
BINARY_NAME="openspec"
MIN_NODE_VERSION="20.19.0"

PACKAGE_MANAGER="npm"
PROJECT_DIR="."
INIT_PROJECT="no"
TOOLS="none"
PROFILE=""
UPDATE_PROJECT="no"
PROJECT_DIR_SET="no"

usage() {
  sed -n '/^# 用法：/,/^# ====/p' "$0" | sed '/^# ====/d; s/^# \?//'
}

fail_usage() {
  printf '错误：%s\n' "$1" >&2
  printf '运行“%s --help”查看用法。\n' "$0" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --package-manager=*)
      PACKAGE_MANAGER="${1#--package-manager=}"
      ;;
    --project-dir=*)
      PROJECT_DIR="${1#--project-dir=}"
      PROJECT_DIR_SET="yes"
      ;;
    --init-project)
      INIT_PROJECT="yes"
      ;;
    --tools=*)
      TOOLS="${1#--tools=}"
      ;;
    --profile=*)
      PROFILE="${1#--profile=}"
      ;;
    --update-project)
      UPDATE_PROJECT="yes"
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

case "$PACKAGE_MANAGER" in
  npm|pnpm|yarn|bun) ;;
  *) fail_usage '--package-manager 必须是 npm、pnpm、yarn 或 bun' ;;
esac

case "$PROJECT_DIR" in
  "") fail_usage '--project-dir 不能为空' ;;
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
      printf '错误：检测到 Windows 原生 Shell（%s）。\n' "$_uname" >&2
      printf '本脚本支持 macOS、Linux 和 WSL。\n' >&2
      printf 'Windows 用户可在具备 Node.js 的终端中运行官方包管理器命令：\n' >&2
      printf '  npm install -g %s@latest\n' "$PACKAGE_NAME" >&2
      exit 1
      ;;
    *)
      printf '错误：不支持的平台“%s”。\n' "$_uname" >&2
      printf '本脚本支持 macOS、Linux 和 WSL。\n' >&2
      exit 1
      ;;
  esac
}

require_command() {
  _cmd="$1"
  _hint="$2"
  if ! command -v "$_cmd" >/dev/null 2>&1; then
    printf '错误：缺少必需命令：%s\n' "$_cmd" >&2
    printf '%s\n' "$_hint" >&2
    exit 1
  fi
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

check_node_runtime() {
  require_command "node" "请安装 Node.js >= 20.19.0 后重新运行本脚本。"

  _node_version="$(clean_version "$(node --version 2>/dev/null || true)")"
  if [ -z "$_node_version" ] || ! version_ge "$_node_version" "$MIN_NODE_VERSION"; then
    printf '错误：Node.js 版本不满足 OpenSpec 要求。\n' >&2
    printf '当前版本：%s\n' "${_node_version:-未知}" >&2
    printf '要求：>= %s\n' "$MIN_NODE_VERSION" >&2
    exit 1
  fi

  NODE_VERSION="$_node_version"
}

check_package_manager() {
  case "$PACKAGE_MANAGER" in
    npm)
      require_command "npm" "请安装 npm 后重新运行本脚本。"
      PM_VERSION="$(npm --version 2>/dev/null || printf unknown)"
      ;;
    pnpm)
      require_command "pnpm" "请安装 pnpm 后重新运行本脚本。"
      PM_VERSION="$(pnpm --version 2>/dev/null || printf unknown)"
      ;;
    yarn)
      require_command "yarn" "请安装 Yarn 后重新运行本脚本。"
      PM_VERSION="$(yarn --version 2>/dev/null || printf unknown)"
      ;;
    bun)
      require_command "bun" "请安装 Bun 后重新运行本脚本。"
      PM_VERSION="$(bun --version 2>/dev/null || printf unknown)"
      ;;
  esac
}

add_path_dir() {
  _dir="$1"
  if [ -n "$_dir" ] && [ -d "$_dir" ]; then
    case ":$PATH:" in
      *:"$_dir":*) ;;
      *) PATH="$_dir:$PATH"; export PATH ;;
    esac
  fi
}

refresh_path() {
  add_path_dir "$HOME/.local/bin"
  add_path_dir "$HOME/bin"
  add_path_dir "/usr/local/bin"
  add_path_dir "/opt/homebrew/bin"
  add_path_dir "$HOME/.bun/bin"

  if command -v npm >/dev/null 2>&1; then
    _npm_prefix="$(npm prefix -g 2>/dev/null || true)"
    [ -z "$_npm_prefix" ] || add_path_dir "$_npm_prefix/bin"
  fi

  if command -v pnpm >/dev/null 2>&1; then
    _pnpm_bin="$(pnpm bin -g 2>/dev/null || true)"
    [ -z "$_pnpm_bin" ] || add_path_dir "$_pnpm_bin"
  fi

  if command -v yarn >/dev/null 2>&1; then
    _yarn_bin="$(yarn global bin 2>/dev/null || true)"
    [ -z "$_yarn_bin" ] || add_path_dir "$_yarn_bin"
  fi
}

normalize_project_dir() {
  if [ "$INIT_PROJECT" = "yes" ] || [ "$UPDATE_PROJECT" = "yes" ]; then
    if [ ! -d "$PROJECT_DIR" ]; then
      printf '错误：目标项目目录不存在：%s\n' "$PROJECT_DIR" >&2
      exit 1
    fi
    PROJECT_DIR="$(CDPATH= cd -- "$PROJECT_DIR" && pwd)"
  fi
}

install_or_update_cli() {
  printf '%s\n' "-> 正在使用 $PACKAGE_MANAGER 安装或更新 OpenSpec CLI..."
  case "$PACKAGE_MANAGER" in
    npm)
      npm install -g "$PACKAGE_NAME@latest"
      ;;
    pnpm)
      pnpm add -g "$PACKAGE_NAME@latest"
      ;;
    yarn)
      yarn global add "$PACKAGE_NAME@latest"
      ;;
    bun)
      bun add -g "$PACKAGE_NAME@latest"
      ;;
  esac
  refresh_path
}

verify_cli() {
  printf '%s\n' '-> 正在验证 OpenSpec CLI...'
  if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
    printf '错误：安装后仍无法在 PATH 中找到 %s。\n' "$BINARY_NAME" >&2
    printf '请打开新终端，或检查包管理器的全局 bin 目录。\n' >&2
    exit 1
  fi
  OPENSPEC_VERSION="$("$BINARY_NAME" --version 2>/dev/null || printf unknown)"
}

init_project() {
  [ "$INIT_PROJECT" = "yes" ] || return 0

  printf '%s\n' "-> 正在初始化 OpenSpec 项目：$PROJECT_DIR"
  if [ -n "$PROFILE" ]; then
    (cd "$PROJECT_DIR" && "$BINARY_NAME" init --tools "$TOOLS" --profile "$PROFILE")
  else
    (cd "$PROJECT_DIR" && "$BINARY_NAME" init --tools "$TOOLS")
  fi
}

update_project() {
  [ "$UPDATE_PROJECT" = "yes" ] || return 0

  printf '%s\n' "-> 正在更新 OpenSpec 项目文件：$PROJECT_DIR"
  (cd "$PROJECT_DIR" && "$BINARY_NAME" update)
}

print_summary() {
  printf '平台：%s\n' "$PLATFORM"
  printf 'Node.js：%s\n' "$NODE_VERSION"
  printf '包管理器：%s（%s）\n' "$PACKAGE_MANAGER" "$PM_VERSION"
  printf '初始化项目：%s\n' "$INIT_PROJECT"
  printf '更新项目：%s\n' "$UPDATE_PROJECT"
  if [ "$INIT_PROJECT" = "yes" ] || [ "$UPDATE_PROJECT" = "yes" ]; then
    printf '项目目录：%s\n' "$PROJECT_DIR"
    printf '初始化工具：%s\n' "$TOOLS"
    printf '初始化 profile：%s\n' "${PROFILE:-默认}"
  fi
  printf '\n'
}

print_next_steps() {
  printf '\n'
  printf '已安装或更新 OpenSpec CLI（%s）。\n' "$OPENSPEC_VERSION"
  printf '\n'
  printf '常用命令：\n'
  printf '  openspec --version\n'
  printf '  openspec init --tools claude,codex\n'
  printf '  openspec list\n'
  printf '  openspec validate <change-id>\n'
  printf '\n'
  printf '初始化项目后，可在 AI 助手对话中使用 /opsx:* 命令。\n'
}

main() {
  normalize_project_dir
  detect_platform
  check_node_runtime
  check_package_manager
  print_summary
  install_or_update_cli
  verify_cli
  init_project
  update_project
  print_next_steps
}

main
