#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/install-agent-pkg.sh -f <FLAG> -t <target_agents_dir> [-s <agents_root>] [-F]

Options:
  -f  Agent package flag/identifier (e.g., frontend-dev → agents-frontend-dev/)
  -t  Target agents directory (e.g., /path/to/project/.claude/agents)
  -s  Source agents root (default: <repo>/agents)
  -F  Force overwrite: delete existing same-name .md files and recopy
  -h  Show this help message

Examples:
  sh scripts/install-agent-pkg.sh -f frontend-dev -t ~/.claude/agents
  sh scripts/install-agent-pkg.sh -f frontend-dev -t /my/project/.claude/agents -F
USAGE
}

FLAG=""
TARGET=""
AGENTS_ROOT=""
FORCE=0

while getopts "f:t:s:Fh" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    s) AGENTS_ROOT="$OPTARG" ;;
    F) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [ -z "$FLAG" ] || [ -z "$TARGET" ]; then
  printf 'Error: -f <FLAG> and -t <target_agents_dir> are required.\n' >&2
  usage
  exit 1
fi

if [ -z "$AGENTS_ROOT" ]; then
  AGENTS_ROOT="$REPO_ROOT/agents"
fi

PKG_DIR="$AGENTS_ROOT/agents-$FLAG"

if [ ! -d "$PKG_DIR" ]; then
  printf 'Error: agent package not found: %s\n' "$PKG_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: target directory does not exist: %s\n' "$TARGET" >&2
  exit 1
fi

COPIED=0
SKIPPED=0
FORCED=0

for src_file in "$PKG_DIR"/*.md; do
  # Skip if no *.md files exist (glob unexpanded)
  [ -f "$src_file" ] || continue

  file_name="$(basename "$src_file")"
  dest="$TARGET/$file_name"

  if [ -f "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] Removing existing: %s\n' "$dest"
      rm -f "$dest"
      cp "$src_file" "$dest"
      printf '[COPIED] %s\n' "$file_name"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] Agent file already exists, please handle manually: %s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp "$src_file" "$dest"
    printf '[COPIED] %s\n' "$file_name"
    COPIED=$((COPIED + 1))
  fi
done

printf '\nDone. copied=%d  forced=%d  manual=%d\n' "$COPIED" "$FORCED" "$SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  printf 'Files marked [MANUAL] were skipped. Remove or rename them in the target, then rerun; or use -F to force overwrite.\n'
fi
