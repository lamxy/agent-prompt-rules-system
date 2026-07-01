#!/bin/sh
# =============================================================================
# install.sh - Product Manager Skills install helper
# Repository: https://github.com/deanpeters/Product-Manager-Skills
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --client=codex-zip       Download latest pm-skills-codex.zip into a project (default)
#   --client=codex-cli       Install a named skill globally with the Skills CLI via npx
#   --client=claude-code     Print official Claude Code plugin commands
#   --client=claude-desktop  Print official Claude Desktop/Web ZIP upload steps
#   --project-dir=PATH       Project/repo root for --client=codex-zip (default: .)
#   --skill=NAME             Skill name for --client=codex-cli
#   --location=local         Project-level install where supported (default)
#   --location=global        Global install where supported; required for codex-cli
#   --verify-only            Do not install; run verification checks where feasible
#   --help                   Show this help
#
# Examples:
#   ./install.sh --client=codex-zip --project-dir=/path/to/project
#   ./install.sh --client=codex-cli --skill=prd-development --location=global
#   ./install.sh --client=claude-code
# =============================================================================

set -eu

REPO="deanpeters/Product-Manager-Skills"
REPO_URL="https://github.com/deanpeters/Product-Manager-Skills"
CODEX_ZIP_URL="https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-codex.zip"
STARTER_PACK_URL="https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-starter-pack.zip"

CLIENT="codex-zip"
PROJECT_DIR="."
SKILL=""
LOCATION="local"
VERIFY_ONLY="no"
TMP_DIR=""

usage() {
  sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --client=*) CLIENT="${arg#--client=}" ;;
    --project-dir=*) PROJECT_DIR="${arg#--project-dir=}" ;;
    --skill=*) SKILL="${arg#--skill=}" ;;
    --location=local) LOCATION="local" ;;
    --location=global) LOCATION="global" ;;
    --verify-only) VERIFY_ONLY="yes" ;;
    --help|-h) usage ;;
    *)
      printf 'Error: unknown option "%s"\n' "$arg" >&2
      printf 'Run "%s --help" for usage.\n' "$0" >&2
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
      printf 'Windows users can follow the official README/docs from:\n  %s\n' "$REPO_URL" >&2
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

abs_project_dir() {
  if [ ! -d "$PROJECT_DIR" ]; then
    printf 'Error: --project-dir does not exist: %s\n' "$PROJECT_DIR" >&2
    exit 1
  fi

  old_pwd="$(pwd)"
  cd "$PROJECT_DIR"
  pwd
  cd "$old_pwd"
}

find_extracted_skills_dir() {
  found="$(find "$TMP_DIR/extract" -type d -path '*/.agents/skills' -print 2>/dev/null | sed -n '1p')"
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi

  found="$(find "$TMP_DIR/extract" -type d -path '*/skills' -print 2>/dev/null | sed -n '1p')"
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi

  return 1
}

find_extracted_agents_md() {
  find "$TMP_DIR/extract" -type f -name AGENTS.md -print 2>/dev/null | sed -n '1p'
}

copy_codex_agents_md() {
  project_root="$1"
  agents_src="$2"
  agents_dst="$project_root/AGENTS.md"

  if [ ! -f "$agents_src" ]; then
    printf 'No AGENTS.md found in Codex ZIP; skipped AGENTS.md setup.\n'
    return 0
  fi

  if [ ! -f "$agents_dst" ]; then
    cp "$agents_src" "$agents_dst"
    printf 'Created AGENTS.md from the official Codex ZIP.\n'
    return 0
  fi

  if grep -F "Product Manager Skills" "$agents_dst" >/dev/null 2>&1; then
    printf 'AGENTS.md already references Product Manager Skills; left unchanged.\n'
    return 0
  fi

  cat >>"$agents_dst" <<'EOF'

## Product Manager Skills

Product Manager Skills are installed under `.agents/skills/`. Ask Codex to use a named skill, for example:

```text
Use the jobs-to-be-done skill to analyze this customer problem.
```
EOF
  printf 'Appended Product Manager Skills note to existing AGENTS.md.\n'
}

install_codex_zip() {
  require_cmd curl
  require_cmd unzip

  project_root="$(abs_project_dir)"
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pm-skills-codex.XXXXXX")"
  mkdir -p "$TMP_DIR/extract"

  printf 'Downloading latest Codex ZIP from %s\n' "$CODEX_ZIP_URL"
  curl -fsSL "$CODEX_ZIP_URL" -o "$TMP_DIR/pm-skills-codex.zip"
  unzip -q "$TMP_DIR/pm-skills-codex.zip" -d "$TMP_DIR/extract"

  skills_src="$(find_extracted_skills_dir || true)"
  if [ -z "$skills_src" ]; then
    printf 'Error: downloaded ZIP did not contain a recognizable skills directory.\n' >&2
    exit 1
  fi

  skills_dst="$project_root/.agents/skills"
  mkdir -p "$skills_dst"

  copied=0
  for skill_dir in "$skills_src"/*; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$skills_dst/$skill_name"
    cp -R "$skill_dir/." "$skills_dst/$skill_name/"
    copied=$((copied + 1))
  done

  agents_src="$(find_extracted_agents_md || true)"
  copy_codex_agents_md "$project_root" "$agents_src"

  printf 'Installed or updated %s Product Manager skill folder(s) under %s\n' "$copied" "$skills_dst"
}

verify_codex_zip() {
  project_root="$(abs_project_dir)"
  skills_dst="$project_root/.agents/skills"

  if [ ! -d "$skills_dst" ]; then
    printf 'Verification failed: skills directory not found: %s\n' "$skills_dst" >&2
    return 1
  fi

  count="$(find "$skills_dst" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | sed 's/[ ]//g')"
  if [ "$count" -gt 0 ]; then
    printf 'Verification passed: found %s SKILL.md file(s) under %s\n' "$count" "$skills_dst"
  else
    printf 'Verification failed: no SKILL.md files found under %s\n' "$skills_dst" >&2
    return 1
  fi

  if [ -f "$project_root/AGENTS.md" ]; then
    printf 'Verification passed: AGENTS.md exists at %s\n' "$project_root/AGENTS.md"
  else
    printf 'Verification warning: AGENTS.md not found at %s\n' "$project_root/AGENTS.md" >&2
  fi
}

install_codex_cli() {
  if [ "$LOCATION" != "global" ]; then
    printf 'Error: --client=codex-cli follows the official Skills CLI Codex command, which uses --location=global.\n' >&2
    printf 'Run again with:\n  %s --client=codex-cli --skill=<skill-name> --location=global\n' "$0" >&2
    exit 1
  fi

  require_cmd npx

  if [ -z "$SKILL" ]; then
    printf 'Error: --client=codex-cli requires --skill=<skill-name>.\n' >&2
    printf 'Discover skills with:\n  npx skills add %s --list\n' "$REPO" >&2
    exit 1
  fi

  printf 'Installing Product Manager skill with Skills CLI: %s\n' "$SKILL"
  npx skills add "$REPO" --skill "$SKILL" -a codex -g
}

verify_codex_cli() {
  if [ "$LOCATION" != "global" ]; then
    printf 'Error: --client=codex-cli verification follows the official global Skills CLI path.\n' >&2
    printf 'Run again with --location=global.\n' >&2
    return 1
  fi

  require_cmd npx

  printf 'Listing Codex skills with Skills CLI...\n'
  if [ -n "$SKILL" ]; then
    if npx skills list -a codex 2>/dev/null | grep -F "$SKILL" >/dev/null 2>&1; then
      printf 'Verification passed: %s is listed for Codex.\n' "$SKILL"
      return 0
    fi
    printf 'Verification failed: %s was not found in npx skills list -a codex.\n' "$SKILL" >&2
    return 1
  fi

  npx skills list -a codex
}

print_claude_code_steps() {
  printf 'Official Claude Code install path is run inside Claude Code:\n'
  printf '  /plugin marketplace add %s\n' "$REPO"
  printf '  /plugin install jobs-to-be-done@pm-skills\n'
  printf '  /reload-plugins\n'
  printf '\n'
  printf 'Other documented examples:\n'
  printf '  /plugin install user-story@pm-skills\n'
  printf '  /plugin install prd-development@pm-skills\n'
  printf '  /plugin install product-strategy-session@pm-skills\n'
}

print_claude_desktop_steps() {
  printf 'Official Claude Desktop/Web install path:\n'
  printf '  1. Download the starter pack: %s\n' "$STARTER_PACK_URL"
  printf '  2. Unzip the pack locally.\n'
  printf '  3. In Claude, open Settings -> Capabilities -> Skills.\n'
  printf '  4. Upload the individual skill ZIPs inside the pack, not the outer pack ZIP.\n'
}

print_next_steps() {
  printf '\nNext prompt to verify behavior:\n'
  printf '  Use the jobs-to-be-done skill to analyze this customer problem.\n'
}

main() {
  detect_platform
  printf 'Platform: %s\n' "$PLATFORM"
  printf 'Client: %s\n' "$CLIENT"
  printf '\n'

  case "$CLIENT" in
    codex-zip)
      if [ "$LOCATION" != "local" ]; then
        printf 'Error: --client=codex-zip supports only --location=local. Use --project-dir to choose the target repo.\n' >&2
        exit 1
      fi
      if [ "$VERIFY_ONLY" = "yes" ]; then
        verify_codex_zip
      else
        install_codex_zip
        verify_codex_zip
        print_next_steps
      fi
      ;;
    codex-cli)
      if [ "$VERIFY_ONLY" = "yes" ]; then
        verify_codex_cli
      else
        install_codex_cli
        verify_codex_cli
        print_next_steps
      fi
      ;;
    claude-code)
      print_claude_code_steps
      ;;
    claude-desktop|claude-web)
      print_claude_desktop_steps
      ;;
    *)
      printf 'Error: unknown --client value "%s".\n' "$CLIENT" >&2
      printf 'Supported clients: codex-zip, codex-cli, claude-code, claude-desktop.\n' >&2
      exit 1
      ;;
  esac
}

main
