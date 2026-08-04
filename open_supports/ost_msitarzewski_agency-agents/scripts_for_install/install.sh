#!/bin/sh
# =============================================================================
# install.sh - Agency Agents 安装/更新助手
# 仓库：https://github.com/msitarzewski/agency-agents
#
# 功能：
#   1. 检测支持的 Shell 平台：macOS、Linux、WSL 和 Git Bash/MSYS。
#   2. 克隆或快进更新官方 agency-agents 检出目录。
#   3. 以非交互模式运行官方 Bash 安装器。
#   4. 将选择参数交给上游处理，避免重复实现。
#
# 用法：
#   ./install.sh [选项] [目标项目目录]
#
# 选项：
#   --tool=NAME             要安装的工具：claude-code、copilot、antigravity、gemini-cli、opencode、openclaw、cursor、aider、windsurf、qwen、kimi、codex、osaurus、hermes 或 all；默认检测全部。
#   --division=LIST         要安装的 division/team，逗号分隔。
#   --agent=LIST            要安装的 agent slug/名称，逗号分隔。
#   --agents-file=PATH      agent slug/名称文件，每行一个。
#   --project-dir=PATH      项目级工具的项目目录（默认：当前目录）。
#   TARGET_DIR              --project-dir 的位置参数别名。
#   --repo-dir=PATH         官方检出缓存目录（默认：~/.cache/agency-agents/agency-agents）。
#   --path=PATH             覆盖一个工具的上游安装目录。
#   --link                  要求上游创建符号链接而非复制。
#   --no-convert            不允许上游自动运行 convert.sh。
#   --parallel              要求上游并行安装所选工具。
#   --jobs=N                上游并行任务数。
#   --dry-run               只输出上游安装计划，不写入。
#   --verify-only           验证检出目录与上游安装器可用性。
#   --list=WHAT             列出上游工具、team/division、agent 或全部。
#   --help|-h               显示帮助。
#
# 示例：
#   ./install.sh --tool=codex
#   ./install.sh --tool=opencode --division=engineering --project-dir=/path/to/project
#   ./install.sh --tool=cursor --agent=frontend-developer,ui-designer --dry-run
#   ./install.sh --list=teams
#
# 说明：
#   - 安装模式：双模。部分上游工具为全局安装，项目级工具则从 CWD 推导目标位置。
#   - 本脚本不会卸载 agent 或删除配置。
#   - 官方安装器基于 Bash；本封装使用 POSIX sh。
#   - Agency Agents 原生桌面应用可从以下地址获取：
#     https://github.com/msitarzewski/agency-agents-app/releases/latest
# =============================================================================

set -eu

REPO_URL="https://github.com/msitarzewski/agency-agents.git"
REPO_DIR="${HOME}/.cache/agency-agents/agency-agents"
PROJECT_DIR="."
TOOL=""
DIVISIONS=""
AGENTS=""
AGENTS_FILE=""
OVERRIDE_PATH=""
LINK="no"
NO_CONVERT="no"
PARALLEL="no"
JOBS=""
DRY_RUN="no"
VERIFY_ONLY="no"
LIST_WHAT=""
PROJECT_DIR_SET="no"

usage() {
  sed -n '/^# 用法：/,/^# ====/p' "$0" | sed '/^# ====/d; s/^# \?//'
}

fail_usage() {
  printf '错误：%s\n' "$1" >&2
  printf '运行“%s --help”查看用法。\n' "$0" >&2
  exit 1
}

append_csv() {
  _current="$1"
  _value="$2"
  if [ -z "$_current" ]; then
    printf '%s\n' "$_value"
  else
    printf '%s,%s\n' "$_current" "$_value"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --tool=*) TOOL="${1#--tool=}" ;;
    --tool)
      [ "$#" -ge 2 ] || fail_usage '--tool requires a value'
      TOOL="$2"
      shift
      ;;
    --division=*) DIVISIONS="$(append_csv "$DIVISIONS" "${1#--division=}")" ;;
    --division)
      [ "$#" -ge 2 ] || fail_usage '--division requires a value'
      DIVISIONS="$(append_csv "$DIVISIONS" "$2")"
      shift
      ;;
    --agent=*) AGENTS="$(append_csv "$AGENTS" "${1#--agent=}")" ;;
    --agent)
      [ "$#" -ge 2 ] || fail_usage '--agent requires a value'
      AGENTS="$(append_csv "$AGENTS" "$2")"
      shift
      ;;
    --agents-file=*) AGENTS_FILE="${1#--agents-file=}" ;;
    --agents-file)
      [ "$#" -ge 2 ] || fail_usage '--agents-file requires a value'
      AGENTS_FILE="$2"
      shift
      ;;
    --project-dir=*) PROJECT_DIR="${1#--project-dir=}"; PROJECT_DIR_SET="yes" ;;
    --project-dir)
      [ "$#" -ge 2 ] || fail_usage '--project-dir requires a value'
      PROJECT_DIR="$2"
      PROJECT_DIR_SET="yes"
      shift
      ;;
    --repo-dir=*) REPO_DIR="${1#--repo-dir=}" ;;
    --repo-dir)
      [ "$#" -ge 2 ] || fail_usage '--repo-dir requires a value'
      REPO_DIR="$2"
      shift
      ;;
    --path=*) OVERRIDE_PATH="${1#--path=}" ;;
    --path)
      [ "$#" -ge 2 ] || fail_usage '--path requires a value'
      OVERRIDE_PATH="$2"
      shift
      ;;
    --jobs=*) JOBS="${1#--jobs=}" ;;
    --jobs)
      [ "$#" -ge 2 ] || fail_usage '--jobs requires a value'
      JOBS="$2"
      shift
      ;;
    --list=*) LIST_WHAT="${1#--list=}" ;;
    --list)
      if [ "$#" -ge 2 ]; then
        LIST_WHAT="$2"
        shift
      else
        LIST_WHAT="all"
      fi
      ;;
    --link) LINK="yes" ;;
    --no-convert) NO_CONVERT="yes" ;;
    --parallel) PARALLEL="yes" ;;
    --dry-run) DRY_RUN="yes" ;;
    --verify-only) VERIFY_ONLY="yes" ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      fail_usage "未知选项 \"$1\""
      ;;
    *)
      if [ "$PROJECT_DIR_SET" = "yes" ]; then
        fail_usage 'specify only one TARGET_DIR or --project-dir'
      fi
      PROJECT_DIR="$1"
      PROJECT_DIR_SET="yes"
      ;;
  esac
  shift
done

case "$TOOL" in
  ""|all|claude-code|copilot|antigravity|gemini-cli|opencode|openclaw|cursor|aider|windsurf|qwen|kimi|codex|osaurus|hermes) ;;
  *) fail_usage '--tool must be all, claude-code, copilot, antigravity, gemini-cli, opencode, openclaw, cursor, aider, windsurf, qwen, kimi, codex, osaurus, or hermes' ;;
esac

case "$REPO_DIR" in
  ""|"/") fail_usage '--repo-dir must not be empty or /' ;;
esac

case "$PROJECT_DIR" in
  "") fail_usage '--project-dir must not be empty' ;;
esac

case "$JOBS" in
  ""|*[!0-9]*) [ -z "$JOBS" ] || fail_usage '--jobs must be a positive integer' ;;
  *) [ "$JOBS" -gt 0 ] || fail_usage '--jobs must be a positive integer' ;;
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
      printf 'Error: unsupported platform "%s".\n' "$_uname" >&2
      printf 'This script supports macOS, Linux, WSL, and Git Bash/MSYS on Windows.\n' >&2
      printf 'Windows users can also install the desktop app from:\n' >&2
      printf '  https://github.com/msitarzewski/agency-agents-app/releases/latest\n' >&2
      exit 1
      ;;
  esac
}

require_command() {
  _cmd="$1"
  _hint="$2"
  if ! command -v "$_cmd" >/dev/null 2>&1; then
    printf 'Error: missing required command: %s\n' "$_cmd" >&2
    printf '%s\n' "$_hint" >&2
    exit 1
  fi
}

abs_dir() {
  _dir="$1"
  if [ ! -d "$_dir" ]; then
    printf 'Target project directory does not exist: %s\n' "$_dir" >&2
    exit 1
  fi

  CDPATH= cd -- "$_dir" && pwd
}

ensure_checkout() {
  if [ -d "$REPO_DIR/.git" ]; then
    printf '%s\n' "-> Updating official agency-agents checkout: $REPO_DIR"
    if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
      printf 'Error: checkout has local changes: %s\n' "$REPO_DIR" >&2
      printf 'Commit/stash them or choose another cache path with --repo-dir=PATH.\n' >&2
      exit 1
    fi
    git -C "$REPO_DIR" pull --ff-only
    return 0
  fi

  if [ -e "$REPO_DIR" ]; then
    printf 'Error: repo dir exists but is not a git checkout: %s\n' "$REPO_DIR" >&2
    printf 'Move it aside or choose another path with --repo-dir=PATH.\n' >&2
    exit 1
  fi

  printf '%s\n' "-> Cloning official agency-agents repository: $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
}

verify_checkout() {
  if [ ! -f "$REPO_DIR/scripts/install.sh" ]; then
    printf 'Error: official installer not found: %s/scripts/install.sh\n' "$REPO_DIR" >&2
    exit 1
  fi
  if [ ! -f "$REPO_DIR/scripts/convert.sh" ]; then
    printf 'Error: official converter not found: %s/scripts/convert.sh\n' "$REPO_DIR" >&2
    exit 1
  fi

  printf 'Verified official checkout: %s\n' "$REPO_DIR"
  bash "$REPO_DIR/scripts/install.sh" --list tools >/dev/null
  printf 'Verified official installer responds to --list tools.\n'
}

run_official_installer() {
  _project_dir="$PROJECT_DIR"
  _installer="$REPO_DIR/scripts/install.sh"

  printf 'Platform: %s\n' "$PLATFORM"
  printf 'Official checkout: %s\n' "$REPO_DIR"
  printf 'Project dir: %s\n' "$_project_dir"
  if [ -n "$TOOL" ]; then
    printf 'Tool: %s\n' "$TOOL"
  else
    printf 'Tool: all detected\n'
  fi
  [ -n "$DIVISIONS" ] && printf 'Divisions: %s\n' "$DIVISIONS"
  [ -n "$AGENTS" ] && printf 'Agents: %s\n' "$AGENTS"
  [ -n "$OVERRIDE_PATH" ] && printf 'Path override: %s\n' "$OVERRIDE_PATH"
  printf '\n'

  (
    cd "$_project_dir" || exit 1
    set -- "$_installer" --no-interactive
    if [ -n "$TOOL" ] && [ "$TOOL" != "all" ]; then
      set -- "$@" --tool "$TOOL"
    fi
    [ -z "$DIVISIONS" ] || set -- "$@" --division "$DIVISIONS"
    [ -z "$AGENTS" ] || set -- "$@" --agent "$AGENTS"
    [ -z "$AGENTS_FILE" ] || set -- "$@" --agents-file "$AGENTS_FILE"
    [ -z "$OVERRIDE_PATH" ] || set -- "$@" --path "$OVERRIDE_PATH"
    [ "$LINK" = "no" ] || set -- "$@" --link
    [ "$NO_CONVERT" = "no" ] || set -- "$@" --no-convert
    [ "$PARALLEL" = "no" ] || set -- "$@" --parallel
    [ -z "$JOBS" ] || set -- "$@" --jobs "$JOBS"
    [ "$DRY_RUN" = "no" ] || set -- "$@" --dry-run
    [ -z "$LIST_WHAT" ] || set -- "$@" --list "$LIST_WHAT"
    bash "$@"
  )
}

print_next_steps() {
  printf '\n'
  printf 'Agency Agents install/update completed.\n'
  printf '\n'
  printf 'Next steps:\n'
  printf '  1. Restart the target AI tool so it reloads agent files.\n'
  printf '  2. Reference an installed agent by name, for example Frontend Developer.\n'
  printf '  3. Re-run this script later to fast-forward the official checkout and update files.\n'
  printf '\n'
  printf 'For the desktop app instead, use the official release page:\n'
  printf '  https://github.com/msitarzewski/agency-agents-app/releases/latest\n'
}

main() {
  PROJECT_DIR="$(abs_dir "$PROJECT_DIR")"
  detect_platform
  require_command "git" "Install Git, then rerun this script."
  require_command "bash" "Install Bash 3.2 or newer, then rerun this script."

  ensure_checkout
  verify_checkout

  if [ "$VERIFY_ONLY" = "yes" ]; then
    exit 0
  fi

  run_official_installer
  [ -n "$LIST_WHAT" ] || [ "$DRY_RUN" = "yes" ] || print_next_steps
}

main
