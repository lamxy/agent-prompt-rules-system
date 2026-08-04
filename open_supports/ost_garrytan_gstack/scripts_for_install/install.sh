#!/bin/sh
# =============================================================================
# install.sh - gstack 安装/更新脚本
# 仓库：https://github.com/garrytan/gstack
#
# 功能：
#   1. 检测支持的 Shell 平台：macOS、Linux、WSL 和 Git Bash/MSYS。
#   2. 安装或更新官方 gstack 检出目录。
#   3. 为 Claude Code 或指定宿主运行官方 ./setup 流程。
#   4. 在明确请求时初始化团队模式。
#
# 用法：
#   ./install.sh [选项] [目标项目目录]
#
# 选项：
#   --host=HOST          为非 Claude 宿主运行 ./setup --host HOST。
#                        上游支持 codex、opencode、factory、kiro 或 auto；默认 claude（不传 --host）。
#   --team=MODE          setup 后也运行 gstack-team-init MODE；MODE 必须为 required 或 optional，默认 none。
#   --global             显式选择默认的用户级 setup；不能与 --team 同用。
#   TARGET_DIR           --team 的项目根目录（默认：.）；未传 --team 时忽略。
#   --install-dir=DIR    检出目录（默认：~/.claude/skills/gstack）。
#   --help|-h            显示帮助。
#
# 示例：
#   ./install.sh
#   ./install.sh --host=codex
#   ./install.sh --team=optional /path/to/project
#   ./install.sh --team=required /path/to/project
#   ./install.sh --host=auto --install-dir="$HOME/gstack"
#
# 说明：
#   - 安装模式：默认全局 setup；团队初始化是依赖 CWD 的项目级操作，在子 Shell 中于 TARGET_DIR 执行。
#   - 本脚本不会卸载 gstack 或删除配置。
#   - 团队模式通过 gstack-team-init 修改当前项目。
#   - GSTACK_GIT_TIMEOUT_SECONDS 默认为 120，必须是正十进制整数；Git 非交互运行，优先使用 timeout/gtimeout。
#   - 导出的代理变量会被 Git 和上游 setup 继承；Docker 调用方须显式注入代理环境变量。
#   - Windows 未开启开发者模式时，上游 setup 可能复制文件而非创建符号链接；后续 git 更新后请重跑本脚本。
# =============================================================================

set -eu

REPO_URL="https://github.com/garrytan/gstack.git"
HOST="claude"
TEAM_MODE="none"
INSTALL_DIR="$HOME/.claude/skills/gstack"
GSTACK_GIT_TIMEOUT_SECONDS="${GSTACK_GIT_TIMEOUT_SECONDS:-120}"
GIT_TIMEOUT_WARNING_PRINTED="no"
TARGET_DIR="."
TARGET_DIR_SET="no"
GLOBAL_REQUESTED="no"

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
    --host=*)
      HOST="${1#--host=}"
      ;;
    --team=*)
      TEAM_MODE="${1#--team=}"
      ;;
    --global)
      GLOBAL_REQUESTED="yes"
      ;;
    --install-dir=*)
      INSTALL_DIR="${1#--install-dir=}"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      fail_usage "未知选项 \"$1\""
      ;;
    *)
      if [ "$TARGET_DIR_SET" = "yes" ]; then
        fail_usage 'specify only one TARGET_DIR'
      fi
      TARGET_DIR="$1"
      TARGET_DIR_SET="yes"
      ;;
  esac
  shift
done

case "$HOST" in
  claude|codex|opencode|factory|kiro|auto) ;;
  cursor|slate)
    printf '错误：上游 setup 不支持 --host=%s。\n' "$HOST" >&2
    exit 1
    ;;
  openclaw|hermes|gbrain)
    printf '错误：--host=%s 需要独立的产物生成/会话工作流。\n' "$HOST" >&2
    exit 1
    ;;
  *) fail_usage '--host 必须是 claude、codex、opencode、factory、kiro 或 auto' ;;
esac

case "$TEAM_MODE" in
  none|required|optional) ;;
  *) fail_usage '--team 必须是 none、required 或 optional' ;;
esac

if [ "$GLOBAL_REQUESTED" = "yes" ] && [ "$TEAM_MODE" != "none" ]; then
  fail_usage '--global 不能与 --team 同用；团队初始化是项目级操作'
fi

if [ "$TEAM_MODE" != "none" ]; then
  [ -d "$TARGET_DIR" ] || {
    printf '错误：目标项目目录不存在：%s\n' "$TARGET_DIR" >&2
    exit 1
  }
  TARGET_DIR="$(CDPATH= cd -- "$TARGET_DIR" && pwd)"
fi

case "$INSTALL_DIR" in
  ""|"/") fail_usage '--install-dir 不能为空或 /' ;;
esac

case "$GSTACK_GIT_TIMEOUT_SECONDS" in
  ""|*[!0-9]*)
    printf '%s\n' '错误：GSTACK_GIT_TIMEOUT_SECONDS 必须是正十进制整数。' >&2
    exit 1
    ;;
esac

case "$GSTACK_GIT_TIMEOUT_SECONDS" in
  *[1-9]*) ;;
  *)
    printf '%s\n' '错误：GSTACK_GIT_TIMEOUT_SECONDS 必须是正十进制整数。' >&2
    exit 1
    ;;
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
      PLATFORM="windows-git-bash"
      ;;
    *)
      printf '错误：不支持的平台“%s”。\n' "$_uname" >&2
      printf '本脚本支持 macOS、Linux、WSL 以及 Windows 11 的 Git Bash/MSYS。\n' >&2
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

check_prerequisites() {
  require_command "git" "请安装 Git 后重新运行本脚本。"
  require_command "bun" "请安装 Bun v1.0 或更高版本后重新运行本脚本。"

  if [ "$PLATFORM" = "windows-git-bash" ] || [ "$PLATFORM" = "wsl" ]; then
    require_command "node" "在 Windows/WSL 上，上游文档要求 PATH 中有 Node.js 以支持浏览器兜底路径。"
  fi
}

run_git() {
  _operation=$1
  shift

  if command -v timeout >/dev/null 2>&1; then
    if GIT_TERMINAL_PROMPT=0 timeout "$GSTACK_GIT_TIMEOUT_SECONDS" git "$@"; then
      return 0
    else
      _status=$?
    fi
  elif command -v gtimeout >/dev/null 2>&1; then
    if GIT_TERMINAL_PROMPT=0 gtimeout "$GSTACK_GIT_TIMEOUT_SECONDS" git "$@"; then
      return 0
    else
      _status=$?
    fi
  else
    if [ "$GIT_TIMEOUT_WARNING_PRINTED" = "no" ]; then
      printf '%s\n' '警告：timeout/gtimeout 不可用；将不设墙钟时间限制地运行 Git。' >&2
      GIT_TIMEOUT_WARNING_PRINTED="yes"
    fi
    if GIT_TERMINAL_PROMPT=0 git "$@"; then
      return 0
    else
      _status=$?
    fi
  fi

  printf '错误：gstack Git %s 操作失败，目标为 %s（超时=%s 秒，退出码=%s）。\n' \
    "$_operation" "$INSTALL_DIR" "$GSTACK_GIT_TIMEOUT_SECONDS" "$_status" >&2
  return "$_status"
}

ensure_checkout() {
  if [ -d "$INSTALL_DIR/.git" ]; then
    printf '%s\n' "-> 正在更新既有 gstack 检出目录：$INSTALL_DIR"
    run_git pull -C "$INSTALL_DIR" pull --ff-only
    return 0
  fi

  if [ -e "$INSTALL_DIR" ]; then
    printf '错误：安装目录存在，但不是 Git 检出目录：%s\n' "$INSTALL_DIR" >&2
    printf '请移走该目录，或用 --install-dir=DIR 选择其他路径。\n' >&2
    exit 1
  fi

  printf '%s\n' "-> 正在将 gstack 克隆到：$INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  run_git clone clone --single-branch --depth 1 "$REPO_URL" "$INSTALL_DIR"
}

run_setup() {
  printf '%s\n' "-> 正在为宿主运行官方 setup：$HOST"
  if [ "$HOST" = "claude" ]; then
    (cd "$INSTALL_DIR" && ./setup)
  else
    (cd "$INSTALL_DIR" && ./setup --host "$HOST")
  fi
}

run_team_init() {
  [ "$TEAM_MODE" != "none" ] || return 0

  if [ ! -x "$INSTALL_DIR/bin/gstack-team-init" ]; then
    printf '错误：未找到预期的团队初始化工具：%s/bin/gstack-team-init\n' "$INSTALL_DIR" >&2
    exit 1
  fi

  printf '%s\n' "-> 正在初始化 gstack 团队模式：$TEAM_MODE"
  (cd "$TARGET_DIR" && "$INSTALL_DIR/bin/gstack-team-init" "$TEAM_MODE")
}

print_next_steps() {
  printf '\n'
  printf '已安装或更新 gstack。\n'
  printf '\n'
  if [ "$HOST" = "claude" ]; then
    printf '后续步骤：\n'
    printf '  1. Restart Claude Code or start a new session.\n'
    printf '  2. Try /office-hours, /review, or /qa https://example.com.\n'
    printf '  3. If Claude cannot see the skills, add the upstream gstack section and slash-command list to CLAUDE.md.\n'
  else
    printf '后续步骤：\n'
    printf '  1. Restart the %s agent.\n' "$HOST"
    printf '  2. Confirm gstack skills appear in that agent.\n'
  fi
  printf '\n'
  printf '在支持时，也可通过 gstack 的 /gstack-upgrade 请求更新。\n'
}

main() {
  detect_platform
  check_prerequisites

  printf '平台：%s\n' "$PLATFORM"
  printf '宿主：%s\n' "$HOST"
  printf '团队模式：%s\n' "$TEAM_MODE"
  [ "$TEAM_MODE" = "none" ] || printf '目标项目目录：%s\n' "$TARGET_DIR"
  printf '安装目录：%s\n' "$INSTALL_DIR"
  printf '\n'

  ensure_checkout
  run_setup
  run_team_init
  print_next_steps
}

main
