#!/bin/sh
# =============================================================================
# install.sh - Agency Agents install/update helper
# Repository: https://github.com/msitarzewski/agency-agents
#
# Purpose:
#   1. Detect supported shell platforms: macOS, Linux, WSL, and Git Bash/MSYS.
#   2. Clone or fast-forward an official agency-agents checkout.
#   3. Run the official Bash installer in non-interactive mode.
#   4. Keep selection flags delegated to upstream instead of reimplementing them.
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --tool=NAME             Tool to install for: claude-code, copilot,
#                           antigravity, gemini-cli, opencode, openclaw,
#                           cursor, aider, windsurf, qwen, kimi, codex,
#                           osaurus, hermes, or all. Default: all detected.
#   --division=LIST         Comma-separated divisions/teams to install.
#   --agent=LIST            Comma-separated agent slugs/names to install.
#   --agents-file=PATH      File of agent slugs/names, one per line.
#   --project-dir=PATH      Project directory for project-scoped tools.
#                           Default: current directory.
#   --repo-dir=PATH         Official checkout cache.
#                           Default: ~/.cache/agency-agents/agency-agents.
#   --path=PATH             Override upstream install directory for one tool.
#   --link                  Ask upstream to symlink instead of copy.
#   --no-convert            Do not let upstream auto-run convert.sh.
#   --parallel              Ask upstream to install selected tools in parallel.
#   --jobs=N                Upstream parallel job count.
#   --dry-run               Print upstream installation plan without writing.
#   --verify-only           Verify checkout and upstream installer availability.
#   --list=WHAT             List upstream tools, teams/divisions, agents, or all.
#   --help|-h               Show this help.
#
# Examples:
#   ./install.sh --tool=codex
#   ./install.sh --tool=opencode --division=engineering --project-dir=/path/to/project
#   ./install.sh --tool=cursor --agent=frontend-developer,ui-designer --dry-run
#   ./install.sh --list=teams
#
# Notes:
#   - This script does not uninstall agents or delete configuration.
#   - The official installer is Bash-based; this wrapper is POSIX sh.
#   - The native Agency Agents desktop app is available from:
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

usage() {
  sed -n '/^# Usage:/,/^# ====/p' "$0" | sed '/^# ====/d; s/^# \?//'
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  printf 'Run "%s --help" for usage.\n' "$0" >&2
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
    --project-dir=*) PROJECT_DIR="${1#--project-dir=}" ;;
    --project-dir)
      [ "$#" -ge 2 ] || fail_usage '--project-dir requires a value'
      PROJECT_DIR="$2"
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
    *)
      fail_usage "unknown option \"$1\""
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
    printf 'Error: directory does not exist: %s\n' "$_dir" >&2
    exit 1
  fi

  _old_pwd="$(pwd)"
  cd "$_dir"
  pwd
  cd "$_old_pwd"
}

ensure_checkout() {
  if [ -d "$REPO_DIR/.git" ]; then
    printf '-> Updating official agency-agents checkout: %s\n' "$REPO_DIR"
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

  printf '-> Cloning official agency-agents repository: %s\n' "$REPO_DIR"
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
  _project_dir="$(abs_dir "$PROJECT_DIR")"
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

  cd "$_project_dir"
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
