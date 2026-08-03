#!/bin/sh
# =============================================================================
# install.sh — OpenSpec installation script
# Repository: https://github.com/Fission-AI/OpenSpec
#
# Purpose:
#   1. Detect supported shell platforms: macOS, Linux, and WSL.
#   2. Check the official runtime prerequisite: Node.js >= 20.19.0.
#   3. Install or update the official OpenSpec CLI package.
#   4. Optionally initialize or update OpenSpec files in a target project.
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --package-manager=PM   Package manager: npm, pnpm, yarn, or bun.
#                          Default: npm.
#   --project-dir=DIR      Target project for --init-project or --update-project.
#                          Default: current directory.
#   --init-project         Run openspec init in the target project.
#   --tools=TOOLS          Non-interactive init tool selection, e.g. none, all,
#                          claude,cursor. Default for --init-project: none.
#   --profile=PROFILE      Optional profile passed to openspec init.
#   --update-project       Run openspec update in the target project.
#   --help|-h              Show this help.
#
# Examples:
#   ./install.sh
#   ./install.sh --package-manager=pnpm
#   ./install.sh --init-project --tools=claude,codex --project-dir=/path/to/project
#   ./install.sh --update-project --project-dir=.
#
# Notes:
#   - This script does not uninstall OpenSpec or delete project/tool files.
#   - Project initialization and project updates are explicit because they write
#     OpenSpec specs/changes and AI tool command files into the target project.
#   - Official docs also describe Nix usage; this script uses package-manager
#     install commands because they are the documented cross-platform path.
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
    --package-manager=*)
      PACKAGE_MANAGER="${arg#--package-manager=}"
      ;;
    --project-dir=*)
      PROJECT_DIR="${arg#--project-dir=}"
      ;;
    --init-project)
      INIT_PROJECT="yes"
      ;;
    --tools=*)
      TOOLS="${arg#--tools=}"
      ;;
    --profile=*)
      PROFILE="${arg#--profile=}"
      ;;
    --update-project)
      UPDATE_PROJECT="yes"
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

case "$PACKAGE_MANAGER" in
  npm|pnpm|yarn|bun) ;;
  *) fail_usage '--package-manager must be npm, pnpm, yarn, or bun' ;;
esac

case "$PROJECT_DIR" in
  "") fail_usage '--project-dir must not be empty' ;;
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
      printf 'Error: detected Windows native shell (%s).\n' "$_uname" >&2
      printf 'This script supports macOS, Linux, and WSL.\n' >&2
      printf 'Windows users can run the official package-manager command in a Node.js terminal:\n' >&2
      printf '  npm install -g %s@latest\n' "$PACKAGE_NAME" >&2
      exit 1
      ;;
    *)
      printf 'Error: unsupported platform "%s".\n' "$_uname" >&2
      printf 'This script supports macOS, Linux, and WSL.\n' >&2
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
  require_command "node" "Install Node.js >= 20.19.0, then rerun this script."

  _node_version="$(clean_version "$(node --version 2>/dev/null || true)")"
  if [ -z "$_node_version" ] || ! version_ge "$_node_version" "$MIN_NODE_VERSION"; then
    printf 'Error: Node.js version does not meet OpenSpec requirements.\n' >&2
    printf 'Current: %s\n' "${_node_version:-unknown}" >&2
    printf 'Required: >= %s\n' "$MIN_NODE_VERSION" >&2
    exit 1
  fi

  NODE_VERSION="$_node_version"
}

check_package_manager() {
  case "$PACKAGE_MANAGER" in
    npm)
      require_command "npm" "Install npm, then rerun this script."
      PM_VERSION="$(npm --version 2>/dev/null || printf unknown)"
      ;;
    pnpm)
      require_command "pnpm" "Install pnpm, then rerun this script."
      PM_VERSION="$(pnpm --version 2>/dev/null || printf unknown)"
      ;;
    yarn)
      require_command "yarn" "Install Yarn, then rerun this script."
      PM_VERSION="$(yarn --version 2>/dev/null || printf unknown)"
      ;;
    bun)
      require_command "bun" "Install Bun, then rerun this script."
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
      printf 'Error: project directory does not exist: %s\n' "$PROJECT_DIR" >&2
      exit 1
    fi
    PROJECT_DIR="$(CDPATH= cd -- "$PROJECT_DIR" && pwd)"
  fi
}

install_or_update_cli() {
  printf '%s\n' "-> Installing or updating OpenSpec CLI with $PACKAGE_MANAGER..."
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
  printf '%s\n' '-> Verifying OpenSpec CLI...'
  if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
    printf 'Error: %s is still not on PATH after installation.\n' "$BINARY_NAME" >&2
    printf 'Open a new terminal or check your global package-manager bin directory.\n' >&2
    exit 1
  fi
  OPENSPEC_VERSION="$("$BINARY_NAME" --version 2>/dev/null || printf unknown)"
}

init_project() {
  [ "$INIT_PROJECT" = "yes" ] || return 0

  printf '%s\n' "-> Initializing OpenSpec project: $PROJECT_DIR"
  if [ -n "$PROFILE" ]; then
    (cd "$PROJECT_DIR" && "$BINARY_NAME" init --tools "$TOOLS" --profile "$PROFILE")
  else
    (cd "$PROJECT_DIR" && "$BINARY_NAME" init --tools "$TOOLS")
  fi
}

update_project() {
  [ "$UPDATE_PROJECT" = "yes" ] || return 0

  printf '%s\n' "-> Updating OpenSpec project files: $PROJECT_DIR"
  (cd "$PROJECT_DIR" && "$BINARY_NAME" update)
}

print_summary() {
  printf 'Platform: %s\n' "$PLATFORM"
  printf 'Node.js: %s\n' "$NODE_VERSION"
  printf 'Package manager: %s (%s)\n' "$PACKAGE_MANAGER" "$PM_VERSION"
  printf 'Initialize project: %s\n' "$INIT_PROJECT"
  printf 'Update project: %s\n' "$UPDATE_PROJECT"
  if [ "$INIT_PROJECT" = "yes" ] || [ "$UPDATE_PROJECT" = "yes" ]; then
    printf 'Project dir: %s\n' "$PROJECT_DIR"
    printf 'Init tools: %s\n' "$TOOLS"
    printf 'Init profile: %s\n' "${PROFILE:-default}"
  fi
  printf '\n'
}

print_next_steps() {
  printf '\n'
  printf 'Installed or updated OpenSpec CLI (%s).\n' "$OPENSPEC_VERSION"
  printf '\n'
  printf 'Useful commands:\n'
  printf '  openspec --version\n'
  printf '  openspec init --tools claude,codex\n'
  printf '  openspec list\n'
  printf '  openspec validate <change-id>\n'
  printf '\n'
  printf 'Use /opsx:* commands inside your AI assistant chat after initializing a project.\n'
}

main() {
  detect_platform
  check_node_runtime
  check_package_manager
  normalize_project_dir
  print_summary
  install_or_update_cli
  verify_cli
  init_project
  update_project
  print_next_steps
}

main
