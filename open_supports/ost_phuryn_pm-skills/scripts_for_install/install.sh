#!/bin/sh
# =============================================================================
# install.sh - PM Skills Marketplace 安装助手
# 仓库：https://github.com/phuryn/pm-skills
#
# 用法：
#   ./install.sh [选项] [目标项目目录]
#
# 选项：
#   --client=codex        使用 Codex CLI 插件命令安装（默认）
#   --client=claude-code  使用 Claude Code 插件命令安装
#   --client=cowork       输出 Claude Cowork 图形界面安装步骤
#   --client=gemini       将 skills 复制到 Gemini CLI skills 目录
#   --client=opencode     将 skills 复制到 OpenCode skills 目录
#   --client=cursor       将 skills 复制到 Cursor skills 目录
#   --client=kiro         将 skills 复制到 Kiro skills 目录
#   --plugins=all         安装/复制全部 PM 插件（默认）
#   --plugins=a,b,c       安装/复制指定插件名
#   --location=local      复制客户端使用项目级 skills 目录（默认）
#   --location=global     复制客户端使用用户级 skills 目录
#   --project-dir=PATH    本地复制客户端的项目根目录（默认：.）
#   TARGET_DIR            --project-dir 的位置参数别名
#   --repo-dir=PATH       复制客户端使用的既有 phuryn/pm-skills 检出目录
#   --verify-only         不安装，只运行验证检查
#   --help                显示帮助
#
# 示例：
#   ./install.sh --client=codex
#   ./install.sh --client=claude-code --plugins=pm-toolkit,pm-execution
#   ./install.sh --client=opencode --location=local --repo-dir=/path/to/pm-skills
# =============================================================================
# 安装模式：双模。marketplace 命令为用户/全局级；本地复制客户端从 CWD 推导目标，并在 TARGET_DIR 内运行。

set -eu

REPO="phuryn/pm-skills"
MARKETPLACE="pm-skills"
REPO_URL="https://github.com/phuryn/pm-skills.git"
DEFAULT_PLUGINS="pm-toolkit pm-product-strategy pm-product-discovery pm-market-research pm-data-analytics pm-marketing-growth pm-go-to-market pm-execution pm-ai-shipping"

CLIENT="codex"
PLUGINS="all"
LOCATION="local"
REPO_DIR=""
VERIFY_ONLY="no"
TMP_DIR=""
PROJECT_DIR="."
PROJECT_DIR_SET="no"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --client=*) CLIENT="${1#--client=}" ;;
    --plugins=*) PLUGINS="${1#--plugins=}" ;;
    --location=local|--local) LOCATION="local" ;;
    --location=global|--global) LOCATION="global" ;;
    --project-dir=*) PROJECT_DIR="${1#--project-dir=}"; PROJECT_DIR_SET="yes" ;;
    --repo-dir=*) REPO_DIR="${1#--repo-dir=}" ;;
    --verify-only) VERIFY_ONLY="yes" ;;
    --help|-h) sed -n '/^# 用法：/,/^# ====/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    -*)
      printf '错误：未知选项“%s”\n运行“%s --help”查看用法。\n' "$1" "$0" >&2
      exit 1
      ;;
    *)
      if [ "$PROJECT_DIR_SET" = "yes" ]; then
        printf '错误：只能指定一个 TARGET_DIR 或 --project-dir\n' >&2
        exit 1
      fi
      PROJECT_DIR="$1"
      PROJECT_DIR_SET="yes"
      ;;
  esac
  shift
done

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT HUP INT TERM

detect_platform() {
  _uname="$(uname -s 2>/dev/null || echo unknown)"
  case "$_uname" in
    Darwin) PLATFORM="macos" ;;
    Linux)
      if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        PLATFORM="wsl"
      else
        PLATFORM="linux"
      fi
      ;;
    *)
      printf '错误：不支持的平台“%s”。本脚本支持 macOS、Linux 和 WSL。\n' "$_uname" >&2
      printf 'Windows users can use Claude Cowork from the GUI or run the relevant Claude/Codex plugin commands manually.\n' >&2
      exit 1
      ;;
  esac
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '错误：找不到必需命令：%s\n' "$1" >&2
    exit 1
  fi
}

normalize_project_dir() {
  [ -d "$PROJECT_DIR" ] || {
    printf '错误：目标项目目录不存在：%s\n' "$PROJECT_DIR" >&2
    exit 1
  }
  PROJECT_DIR="$(CDPATH= cd -- "$PROJECT_DIR" && pwd)"
}

plugin_names() {
  if [ "$PLUGINS" = "all" ]; then
    printf '%s\n' $DEFAULT_PLUGINS
  else
    printf '%s\n' "$PLUGINS" | tr ',' '\n' | sed '/^$/d'
  fi
}

validate_plugins() {
  for plugin in $(plugin_names); do
    case " $DEFAULT_PLUGINS " in
      *" $plugin "*) ;;
      *)
        printf 'Error: unknown plugin "%s". Use --plugins=all or one of:\n%s\n' "$plugin" "$DEFAULT_PLUGINS" >&2
        exit 1
        ;;
    esac
  done
}

target_dir_for_client() {
  case "$CLIENT:$LOCATION" in
    gemini:local) printf '%s\n' ".gemini/skills" ;;
    gemini:global) printf '%s\n' "$HOME/.gemini/skills" ;;
    opencode:local) printf '%s\n' ".opencode/skills" ;;
    opencode:global) printf '%s\n' "$HOME/.opencode/skills" ;;
    cursor:local) printf '%s\n' ".cursor/skills" ;;
    cursor:global) printf '%s\n' "$HOME/.cursor/skills" ;;
    kiro:local) printf '%s\n' ".kiro/skills" ;;
    kiro:global) printf '%s\n' "$HOME/.kiro/skills" ;;
    *)
      printf 'Error: --location is only used for gemini, opencode, cursor, and kiro clients.\n' >&2
      exit 1
      ;;
  esac
}

prepare_repo_dir() {
  if [ -n "$REPO_DIR" ]; then
    if [ ! -d "$REPO_DIR" ]; then
      printf 'Error: --repo-dir does not exist: %s\n' "$REPO_DIR" >&2
      exit 1
    fi
    return 0
  fi

  require_cmd git
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pm-skills.XXXXXX")"
  printf 'Cloning official repository: %s\n' "$REPO_URL"
  git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo"
  REPO_DIR="$TMP_DIR/repo"
}

copy_skills_for_client() {
  prepare_repo_dir
  target_dir="$(target_dir_for_client)"
  mkdir -p "$target_dir"

  copied=0
  for plugin in $(plugin_names); do
    source_dir="$REPO_DIR/$plugin/skills"
    if [ ! -d "$source_dir" ]; then
      printf 'Warning: no skills directory found for %s at %s\n' "$plugin" "$source_dir" >&2
      continue
    fi

    for skill_dir in "$source_dir"/*; do
      if [ -d "$skill_dir" ]; then
        skill_name="$(basename "$skill_dir")"
        mkdir -p "$target_dir/$skill_name"
        cp -R "$skill_dir/." "$target_dir/$skill_name/"
        copied=$((copied + 1))
      fi
    done
  done

  printf 'Copied %s skill folder(s) to %s\n' "$copied" "$target_dir"
}

verify_skills_client() {
  target_dir="$(target_dir_for_client)"
  if [ ! -d "$target_dir" ]; then
    printf 'Verification failed: skills directory not found: %s\n' "$target_dir" >&2
    return 1
  fi

  count="$(find "$target_dir" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | sed 's/[ ]//g')"
  if [ "$count" -gt 0 ]; then
    printf 'Verification passed: found %s SKILL.md file(s) under %s\n' "$count" "$target_dir"
    return 0
  fi

  printf 'Verification failed: no SKILL.md files found under %s\n' "$target_dir" >&2
  return 1
}

install_claude_code() {
  require_cmd claude

  printf 'Adding Claude marketplace %s...\n' "$REPO"
  if claude plugin marketplace add "$REPO"; then
    printf 'Marketplace add completed.\n'
  else
    printf 'Marketplace add returned non-zero; continuing because it may already exist.\n'
  fi

  if claude plugin marketplace update "$MARKETPLACE"; then
    printf 'Marketplace snapshot refreshed.\n'
  else
    printf 'Marketplace refresh skipped or unavailable.\n'
  fi

  for plugin in $(plugin_names); do
    if claude plugin list 2>/dev/null | grep -F "$plugin" >/dev/null 2>&1; then
      printf 'Updating existing Claude plugin: %s\n' "$plugin"
      claude plugin update "$plugin" || true
    else
      printf 'Installing Claude plugin: %s\n' "$plugin"
      if ! claude plugin install "$plugin@$MARKETPLACE"; then
        if claude plugin list 2>/dev/null | grep -F "$plugin" >/dev/null 2>&1; then
          printf 'Plugin appears installed after non-zero install result: %s\n' "$plugin"
        else
          printf 'Error: failed to install Claude plugin: %s\n' "$plugin" >&2
          exit 1
        fi
      fi
    fi
  done
}

verify_claude_code() {
  require_cmd claude
  failed=0
  for plugin in $(plugin_names); do
    if claude plugin list 2>/dev/null | grep -F "$plugin" >/dev/null 2>&1; then
      printf 'Verified Claude plugin: %s\n' "$plugin"
    else
      printf 'Verification failed: Claude plugin not listed: %s\n' "$plugin" >&2
      failed=1
    fi
  done
  return "$failed"
}

install_codex() {
  require_cmd codex

  printf 'Adding Codex marketplace %s...\n' "$REPO"
  if codex plugin marketplace add "$REPO"; then
    printf 'Marketplace add completed.\n'
  else
    printf 'Marketplace add returned non-zero; continuing because it may already exist.\n'
  fi

  if codex plugin marketplace upgrade "$MARKETPLACE"; then
    printf 'Marketplace snapshot refreshed.\n'
  else
    printf 'Marketplace refresh skipped or unavailable.\n'
  fi

  for plugin in $(plugin_names); do
    if codex plugin list 2>/dev/null | grep -F "$plugin" >/dev/null 2>&1; then
      printf 'Codex plugin already listed: %s\n' "$plugin"
    else
      printf 'Installing Codex plugin: %s\n' "$plugin"
      if ! codex plugin add "$plugin@$MARKETPLACE"; then
        if codex plugin list 2>/dev/null | grep -F "$plugin" >/dev/null 2>&1; then
          printf 'Plugin appears installed after non-zero install result: %s\n' "$plugin"
        else
          printf 'Error: failed to install Codex plugin: %s\n' "$plugin" >&2
          exit 1
        fi
      fi
    fi
  done
}

verify_codex() {
  require_cmd codex
  failed=0
  if codex plugin list --marketplace "$MARKETPLACE" >/dev/null 2>&1; then
    printf 'Verified Codex marketplace is visible: %s\n' "$MARKETPLACE"
  else
    printf 'Warning: Codex marketplace listing check failed for %s\n' "$MARKETPLACE" >&2
  fi

  for plugin in $(plugin_names); do
    if codex plugin list 2>/dev/null | grep -F "$plugin" >/dev/null 2>&1; then
      printf 'Verified Codex plugin: %s\n' "$plugin"
    else
      printf 'Verification failed: Codex plugin not listed: %s\n' "$plugin" >&2
      failed=1
    fi
  done
  return "$failed"
}

print_cowork_steps() {
  cat <<'EOF'
Claude Cowork is installed through the GUI:
1. Open Customize from the bottom-left.
2. Go to Browse plugins, then Personal, then +.
3. Select Add marketplace from GitHub.
4. Enter: phuryn/pm-skills

Expected result: all 9 PM Skills plugins install automatically.
Verification: confirm the PM Skills plugins and commands are visible in Browse plugins.
EOF
}

print_summary() {
  printf '\nOperation summary\n'
  printf '  repository: %s\n' "$REPO"
  printf '  client: %s\n' "$CLIENT"
  printf '  plugins: %s\n' "$PLUGINS"
  case "$CLIENT" in
    gemini|opencode|cursor|kiro) printf '  location: %s\n' "$(target_dir_for_client)" ;;
    *) ;;
  esac
}

main() {
  detect_platform
  validate_plugins

  case "$CLIENT:$LOCATION" in
    gemini:local|opencode:local|cursor:local|kiro:local)
      normalize_project_dir
      ;;
  esac

  printf 'Platform: %s\n' "$PLATFORM"
  print_summary
  printf '\n'

  case "$CLIENT" in
    claude-code)
      if [ "$VERIFY_ONLY" = "no" ]; then
        install_claude_code
      fi
      verify_claude_code
      ;;
    codex)
      if [ "$VERIFY_ONLY" = "no" ]; then
        install_codex
      fi
      verify_codex
      ;;
    cowork)
      print_cowork_steps
      ;;
    gemini|opencode|cursor|kiro)
      if [ "$LOCATION" = "local" ]; then
        (
          cd "$PROJECT_DIR" || exit 1
          if [ "$VERIFY_ONLY" = "no" ]; then
            copy_skills_for_client
          fi
          verify_skills_client
        )
      else
        if [ "$VERIFY_ONLY" = "no" ]; then
          copy_skills_for_client
        fi
        verify_skills_client
      fi
      ;;
    *)
      printf 'Error: unsupported client "%s". Run "%s --help" for supported clients.\n' "$CLIENT" "$0" >&2
      exit 1
      ;;
  esac

  printf '\nDone.\n'
}

main
