#!/bin/sh
# =============================================================================
# install.sh - PM Skills Marketplace install helper
# Repository: https://github.com/phuryn/pm-skills
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --client=codex        Install with Codex CLI plugin commands (default)
#   --client=claude-code  Install with Claude Code plugin commands
#   --client=cowork       Print Claude Cowork GUI install steps
#   --client=gemini       Copy skills to Gemini CLI skills directory
#   --client=opencode     Copy skills to OpenCode skills directory
#   --client=cursor       Copy skills to Cursor skills directory
#   --client=kiro         Copy skills to Kiro skills directory
#   --plugins=all         Install/copy all PM plugins (default)
#   --plugins=a,b,c       Install/copy selected plugin names
#   --location=local      Project-level skills directory for copy clients (default)
#   --location=global     User-level skills directory for copy clients
#   --repo-dir=PATH       Existing phuryn/pm-skills checkout for copy clients
#   --verify-only         Do not install; run verification checks only
#   --help                Show this help
#
# Examples:
#   ./install.sh --client=codex
#   ./install.sh --client=claude-code --plugins=pm-toolkit,pm-execution
#   ./install.sh --client=opencode --location=local --repo-dir=/path/to/pm-skills
# =============================================================================

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

for arg in "$@"; do
  case "$arg" in
    --client=*) CLIENT="${arg#--client=}" ;;
    --plugins=*) PLUGINS="${arg#--plugins=}" ;;
    --location=local) LOCATION="local" ;;
    --location=global) LOCATION="global" ;;
    --repo-dir=*) REPO_DIR="${arg#--repo-dir=}" ;;
    --verify-only) VERIFY_ONLY="yes" ;;
    --help|-h) sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *)
      printf 'Error: unknown option "%s"\nRun "%s --help" for usage.\n' "$arg" "$0" >&2
      exit 1
      ;;
  esac
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
      printf 'Error: unsupported platform "%s". This script supports macOS, Linux, and WSL.\n' "$_uname" >&2
      printf 'Windows users can use Claude Cowork from the GUI or run the relevant Claude/Codex plugin commands manually.\n' >&2
      exit 1
      ;;
  esac
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$1" >&2
    exit 1
  fi
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
      if [ "$VERIFY_ONLY" = "no" ]; then
        copy_skills_for_client
      fi
      verify_skills_client
      ;;
    *)
      printf 'Error: unsupported client "%s". Run "%s --help" for supported clients.\n' "$CLIENT" "$0" >&2
      exit 1
      ;;
  esac

  printf '\nDone.\n'
}

main
