#!/bin/sh
# =============================================================================
# install.sh — GSD Core 安装脚本
# 仓库：https://github.com/open-gsd/gsd-core
#
# 功能：
#   1. 检测平台（macOS / Linux / WSL），Windows native 给出官方命令提示
#   2. 检查 Node.js >= 22.0.0、npm >= 10.0.0 和 npx 可用性
#   3. 通过官方安装器安装 / 更新指定 runtime 的 GSD Core 配置
#
# 用法：
#   ./install.sh [RUNTIME_FLAGS] [SCOPE]
#
# Runtime flags（至少选择一个，均透传给官方安装器）：
#   --claude          Claude Code
#   --codex           Codex
#   --gemini          Gemini CLI
#   --opencode        OpenCode
#   --kilo            Kilo
#   --kimi            Kimi CLI / Kimi Code
#   --copilot         GitHub Copilot
#   --cursor          Cursor
#   --windsurf        Windsurf / Devin Desktop
#   --devin-desktop   Windsurf / Devin Desktop 等价 flag
#   --cline           Cline
#   --codebuddy       CodeBuddy
#   --qwen            Qwen Code
#   --augment         Augment Code
#   --antigravity     Antigravity
#   --trae            Trae
#   --all             安装全部官方支持 runtime（官方示例要求配合 --global）
#
# Scope：
#   --local             项目级安装（默认）
#   --global            全局安装（需显式指定）
#   --location=local    --local 的别名
#   --location=global   --global 的别名
#
# 选项：
#   --help|-h           显示此帮助
#
# 示例：
#   ./install.sh --claude
#   ./install.sh --codex --local
#   ./install.sh --claude --codex --global
#   ./install.sh --all --global
#
# 说明：
#   - 本脚本不运行交互式安装；未指定 runtime 时会报错。
#   - 如需自定义官方支持的配置目录，可在执行前设置对应环境变量，
#     例如 CLAUDE_CONFIG_DIR、GEMINI_CONFIG_DIR、OPENCODE_CONFIG_DIR 等。
# =============================================================================

set -eu

GSD_INSTALLER="@opengsd/gsd-core@latest"
SCOPE="local"
SCOPE_EXPLICIT="no"
SCOPE_FLAG="--local"
RUNTIME_FLAGS=""
RUNTIME_LABELS=""
RUNTIME_COUNT=0
ALL_SELECTED="no"
NEED_CODEX="no"

usage() {
  sed -n '/^# 用法/,/^# ====/p' "$0" | sed 's/^# \?//'
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  printf '运行 "%s --help" 查看用法\n' "$0" >&2
  exit 1
}

add_runtime() {
  _flag="$1"
  _label="$2"

  case " $RUNTIME_FLAGS " in
    *" --$_flag "*) return 0 ;;
  esac

  if [ "$ALL_SELECTED" = "yes" ] && [ "$_flag" != "all" ]; then
    fail_usage '--all 不能与其他 runtime flag 混用'
  fi
  if [ "$_flag" = "all" ] && [ "$RUNTIME_COUNT" -gt 0 ]; then
    fail_usage '--all 不能与其他 runtime flag 混用'
  fi

  RUNTIME_FLAGS="${RUNTIME_FLAGS} --$_flag"
  if [ -z "$RUNTIME_LABELS" ]; then
    RUNTIME_LABELS="$_label"
  else
    RUNTIME_LABELS="$RUNTIME_LABELS,$_label"
  fi

  RUNTIME_COUNT=$((RUNTIME_COUNT + 1))
  if [ "$_flag" = "all" ]; then
    ALL_SELECTED="yes"
  fi
  if [ "$_flag" = "codex" ]; then
    NEED_CODEX="yes"
  fi
}

for arg in "$@"; do
  case "$arg" in
    --claude) add_runtime "claude" "claude" ;;
    --codex) add_runtime "codex" "codex" ;;
    --gemini) add_runtime "gemini" "gemini" ;;
    --opencode) add_runtime "opencode" "opencode" ;;
    --kilo) add_runtime "kilo" "kilo" ;;
    --kimi) add_runtime "kimi" "kimi" ;;
    --copilot) add_runtime "copilot" "copilot" ;;
    --cursor) add_runtime "cursor" "cursor" ;;
    --windsurf) add_runtime "windsurf" "windsurf" ;;
    --devin-desktop) add_runtime "devin-desktop" "devin-desktop" ;;
    --cline) add_runtime "cline" "cline" ;;
    --codebuddy) add_runtime "codebuddy" "codebuddy" ;;
    --qwen) add_runtime "qwen" "qwen" ;;
    --augment) add_runtime "augment" "augment" ;;
    --antigravity) add_runtime "antigravity" "antigravity" ;;
    --trae) add_runtime "trae" "trae" ;;
    --all) add_runtime "all" "all" ;;
    --local|--location=local)
      SCOPE="local"
      SCOPE_FLAG="--local"
      SCOPE_EXPLICIT="yes"
      ;;
    --global|--location=global)
      SCOPE="global"
      SCOPE_FLAG="--global"
      SCOPE_EXPLICIT="yes"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail_usage "未知选项 \"$arg\""
      ;;
  esac
done

if [ "$RUNTIME_COUNT" -eq 0 ]; then
  fail_usage '请至少指定一个 runtime flag，例如 --claude 或 --codex'
fi

if [ "$ALL_SELECTED" = "yes" ] && [ "$SCOPE" != "global" ]; then
  if [ "$SCOPE_EXPLICIT" = "yes" ]; then
    fail_usage '官方摘要只给出 --all --global；请改用 --global 或选择单个 runtime'
  fi
  fail_usage '官方摘要只给出 --all --global；请显式追加 --global'
fi

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
      printf 'Windows 用户可在已安装 Node.js/npm 的终端中直接运行官方安装器，例如：\n' >&2
      printf '  npx %s --claude --local\n' "$GSD_INSTALLER" >&2
      printf '或改用 WSL 运行本脚本。\n' >&2
      exit 1
      ;;
    *)
      printf 'Error: 不支持的平台 "%s"。\n' "$_uname" >&2
      printf '本脚本支持 macOS、Linux 和 WSL。\n' >&2
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
  require_command "node" "请先安装 Node.js >= 22.0.0。"
  require_command "npm" "请先安装 npm >= 10.0.0。"
  require_command "npx" "请先安装 npm/npx。"

  _node_version="$(clean_version "$(node --version 2>/dev/null || true)")"
  _npm_version="$(clean_version "$(npm --version 2>/dev/null || true)")"

  if [ -z "$_node_version" ] || ! version_ge "$_node_version" "22.0.0"; then
    printf 'Error: Node.js 版本不满足要求（当前：%s，要求：>= 22.0.0）。\n' "${_node_version:-unknown}" >&2
    exit 1
  fi

  if [ -z "$_npm_version" ] || ! version_ge "$_npm_version" "10.0.0"; then
    printf 'Error: npm 版本不满足要求（当前：%s，要求：>= 10.0.0）。\n' "${_npm_version:-unknown}" >&2
    exit 1
  fi

  NODE_VERSION="$_node_version"
  NPM_VERSION="$_npm_version"
}

check_codex_runtime() {
  if [ "$NEED_CODEX" != "yes" ]; then
    return 0
  fi

  require_command "codex" "安装 Codex runtime 前，请先安装 Codex CLI >= 0.130.0。"

  _codex_raw="$(codex --version 2>/dev/null || true)"
  _codex_version="$(clean_version "$_codex_raw")"

  if [ -n "$_codex_version" ]; then
    if ! version_ge "$_codex_version" "0.130.0"; then
      printf 'Error: Codex CLI 版本不满足要求（当前：%s，要求：>= 0.130.0）。\n' "$_codex_version" >&2
      exit 1
    fi
    CODEX_VERSION="$_codex_version"
  else
    CODEX_VERSION="unknown"
    printf 'Warning: 无法解析 Codex CLI 版本输出：%s\n' "$_codex_raw" >&2
    printf '将继续执行；如安装失败，请确认 Codex CLI >= 0.130.0。\n' >&2
  fi
}

print_summary() {
  printf '=== GSD Core 安装 / 更新摘要 ===\n'
  printf '平台：%s\n' "$PLATFORM"
  printf 'Runtime：%s\n' "$RUNTIME_LABELS"
  printf 'Scope：%s\n' "$SCOPE"
  printf 'Node.js：%s\n' "$NODE_VERSION"
  printf 'npm：%s\n' "$NPM_VERSION"
  if [ "$NEED_CODEX" = "yes" ]; then
    printf 'Codex CLI：%s\n' "$CODEX_VERSION"
  fi
  printf '官方命令：\n'
  printf '  npx %s%s %s\n' "$GSD_INSTALLER" "$RUNTIME_FLAGS" "$SCOPE_FLAG"
  printf '\n'
}

run_installer() {
  # RUNTIME_FLAGS 只由脚本内固定白名单拼接，允许按空格拆分为多个官方 flag。
  npx "$GSD_INSTALLER" $RUNTIME_FLAGS "$SCOPE_FLAG"
}

print_next_steps() {
  printf '\n'
  printf '✓ GSD Core 安装器已执行完成。\n'
  printf '\n'
  printf '验证方式：重启目标 runtime 后运行对应命令，命令被识别并开始询问项目问题即代表安装成功。\n'
  printf '  Claude Code / Copilot / OpenCode / Kilo / Cline 等：/gsd-new-project\n'
  printf '  Gemini CLI：/gsd:new-project\n'
  printf '  Codex：$gsd-new-project\n'
  printf '\n'
  printf '更新方式：重新运行本脚本或官方 npx 安装命令；安装器会按官方逻辑处理已有文件。\n'
}

main() {
  detect_platform
  check_node_runtime
  check_codex_runtime
  print_summary
  run_installer
  print_next_steps
}

main
