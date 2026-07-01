#!/bin/sh
# =============================================================================
# install.sh - gstack install/update script
# Repository: https://github.com/garrytan/gstack
#
# Purpose:
#   1. Detect supported shell platforms: macOS, Linux, WSL, and Git Bash/MSYS.
#   2. Install or update the official gstack checkout.
#   3. Run the official ./setup flow for Claude Code or a selected host.
#   4. Optionally initialize team mode when explicitly requested.
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --host=HOST          Run ./setup --host HOST for non-Claude hosts.
#                        Supported values from upstream docs include:
#                        codex, opencode, cursor, factory, slate, kiro,
#                        hermes, gbrain.
#                        Default: claude, which runs ./setup without --host.
#   --team=MODE         Also run gstack-team-init MODE after setup.
#                        MODE must be required or optional. Default: none.
#   --install-dir=DIR   Checkout directory.
#                        Default: ~/.claude/skills/gstack.
#   --help|-h           Show this help.
#
# Examples:
#   ./install.sh
#   ./install.sh --host=codex
#   ./install.sh --team=optional
#   ./install.sh --team=required
#   ./install.sh --host=cursor --install-dir="$HOME/gstack"
#
# Notes:
#   - This script does not uninstall gstack or delete configuration.
#   - Team mode modifies the current project through gstack-team-init.
#   - If using Windows without Developer Mode, upstream setup may copy files
#     instead of symlinking; rerun this script after future git updates.
# =============================================================================

set -eu

REPO_URL="https://github.com/garrytan/gstack.git"
HOST="claude"
TEAM_MODE="none"
INSTALL_DIR="$HOME/.claude/skills/gstack"

usage() {
  sed -n '/^# Usage:/,/^# ====/p' "$0" | sed '/^# ====/d; s/^# \?//'
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  printf 'Run "%s --help" for usage.\n' "$0" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --host=*)
      HOST="${arg#--host=}"
      ;;
    --team=*)
      TEAM_MODE="${arg#--team=}"
      ;;
    --install-dir=*)
      INSTALL_DIR="${arg#--install-dir=}"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail_usage "unknown option \"$arg\""
      ;;
  esac
done

case "$HOST" in
  claude|codex|opencode|cursor|factory|slate|kiro|hermes|gbrain) ;;
  *) fail_usage '--host must be claude, codex, opencode, cursor, factory, slate, kiro, hermes, or gbrain' ;;
esac

case "$TEAM_MODE" in
  none|required|optional) ;;
  *) fail_usage '--team must be none, required, or optional' ;;
esac

case "$INSTALL_DIR" in
  ""|"/") fail_usage '--install-dir must not be empty or /' ;;
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
      printf 'This script supports macOS, Linux, WSL, and Git Bash/MSYS on Windows 11.\n' >&2
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

check_prerequisites() {
  require_command "git" "Install Git, then rerun this script."
  require_command "bun" "Install Bun v1.0 or newer, then rerun this script."

  if [ "$PLATFORM" = "windows-git-bash" ] || [ "$PLATFORM" = "wsl" ]; then
    require_command "node" "On Windows/WSL, upstream docs require Node.js on PATH for browser fallback support."
  fi
}

ensure_checkout() {
  if [ -d "$INSTALL_DIR/.git" ]; then
    printf '-> Updating existing gstack checkout: %s\n' "$INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
    return 0
  fi

  if [ -e "$INSTALL_DIR" ]; then
    printf 'Error: install directory exists but is not a git checkout: %s\n' "$INSTALL_DIR" >&2
    printf 'Move it aside or choose another path with --install-dir=DIR.\n' >&2
    exit 1
  fi

  printf '-> Cloning gstack into: %s\n' "$INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --single-branch --depth 1 "$REPO_URL" "$INSTALL_DIR"
}

run_setup() {
  printf '-> Running official setup for host: %s\n' "$HOST"
  if [ "$HOST" = "claude" ]; then
    (cd "$INSTALL_DIR" && ./setup)
  else
    (cd "$INSTALL_DIR" && ./setup --host "$HOST")
  fi
}

run_team_init() {
  [ "$TEAM_MODE" != "none" ] || return 0

  if [ ! -x "$INSTALL_DIR/bin/gstack-team-init" ]; then
    printf 'Error: expected team init helper not found: %s/bin/gstack-team-init\n' "$INSTALL_DIR" >&2
    exit 1
  fi

  printf '-> Initializing gstack team mode: %s\n' "$TEAM_MODE"
  "$INSTALL_DIR/bin/gstack-team-init" "$TEAM_MODE"
}

print_next_steps() {
  printf '\n'
  printf 'Installed or updated gstack.\n'
  printf '\n'
  if [ "$HOST" = "claude" ]; then
    printf 'Next steps:\n'
    printf '  1. Restart Claude Code or start a new session.\n'
    printf '  2. Try /office-hours, /review, or /qa https://example.com.\n'
    printf '  3. If Claude cannot see the skills, add the upstream gstack section and slash-command list to CLAUDE.md.\n'
  else
    printf 'Next steps:\n'
    printf '  1. Restart the %s agent.\n' "$HOST"
    printf '  2. Confirm gstack skills appear in that agent.\n'
  fi
  printf '\n'
  printf 'Updates can also be requested from gstack with /gstack-upgrade where supported.\n'
}

main() {
  detect_platform
  check_prerequisites

  printf 'Platform: %s\n' "$PLATFORM"
  printf 'Host: %s\n' "$HOST"
  printf 'Team mode: %s\n' "$TEAM_MODE"
  printf 'Install dir: %s\n' "$INSTALL_DIR"
  printf '\n'

  ensure_checkout
  run_setup
  run_team_init
  print_next_steps
}

main
