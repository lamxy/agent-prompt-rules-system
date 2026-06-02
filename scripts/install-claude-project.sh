#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/install-claude-project.sh -f <FLAG> -t <target_dir> [-s <dot_claude_projects_root>] [-F]

Options:
  -f  Flag/identifier matching .claude-<FLAG>/ in the source directory
  -t  Target project root directory (files are placed directly here)
  -s  Source dot_claude_projects root (default: <repo>/dot_claude_projects)
  -F  Force overwrite if target files/dirs already exist
  -h  Show this help message

Copies .claude/, .mcp.json, and CLAUDE.md from .claude-<FLAG>/ into <target_dir>.

Examples:
  sh scripts/install-claude-project.sh -f frontend-dev -t ~/my-project
  sh scripts/install-claude-project.sh -f frontend-dev -t ~/my-project -F
  sh scripts/install-claude-project.sh -f frontend-dev -t ~/my-project -s /custom/dot_claude_projects
USAGE
}

FLAG=""
TARGET=""
SOURCE_ROOT=""
FORCE=0

# Long-option shim
ARGS=""
for arg in "$@"; do
  case "$arg" in
    --flag)   ARGS="$ARGS -f" ;;
    --target) ARGS="$ARGS -t" ;;
    --source) ARGS="$ARGS -s" ;;
    --force)  ARGS="$ARGS -F" ;;
    --help)   ARGS="$ARGS -h" ;;
    *)        ARGS="$ARGS $arg" ;;
  esac
done
eval "set -- $ARGS"

while getopts "f:t:s:Fh" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    s) SOURCE_ROOT="$OPTARG" ;;
    F) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [ -z "$FLAG" ] || [ -z "$TARGET" ]; then
  printf 'Error: -f <FLAG> and -t <target_dir> are required.\n' >&2
  usage
  exit 1
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/dot_claude_projects"
fi

PKG_DIR="$SOURCE_ROOT/.claude-$FLAG"

if [ ! -d "$PKG_DIR" ]; then
  printf 'Error: source package not found: %s\n' "$PKG_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: target directory does not exist: %s\n' "$TARGET" >&2
  exit 1
fi

COPIED=0
SKIPPED=0
FORCED=0

# Helper: copy a single file
copy_file() {
  src="$1"; dest="$2"; label="$3"
  if [ -f "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] Overwriting: %s\n' "$dest"
      cp "$src" "$dest"
      printf '[COPIED] %s\n' "$label"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] File already exists, please handle manually: %s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp "$src" "$dest"
    printf '[COPIED] %s\n' "$label"
    COPIED=$((COPIED + 1))
  fi
}

# Helper: copy a directory
copy_dir() {
  src="$1"; dest="$2"; label="$3"
  if [ -d "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] Removing and recopying: %s\n' "$dest"
      rm -rf "$dest"
      cp -r "$src" "$dest"
      printf '[COPIED] %s\n' "$label"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] Directory already exists, please handle manually: %s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp -r "$src" "$dest"
    printf '[COPIED] %s\n' "$label"
    COPIED=$((COPIED + 1))
  fi
}

# Copy .claude/
if [ -d "$PKG_DIR/.claude" ]; then
  copy_dir "$PKG_DIR/.claude" "$TARGET/.claude" ".claude/"
fi

# Copy .mcp.json
if [ -f "$PKG_DIR/.mcp.json" ]; then
  copy_file "$PKG_DIR/.mcp.json" "$TARGET/.mcp.json" ".mcp.json"
fi

# Copy CLAUDE.md
if [ -f "$PKG_DIR/CLAUDE.md" ]; then
  copy_file "$PKG_DIR/CLAUDE.md" "$TARGET/CLAUDE.md" "CLAUDE.md"
fi

printf '\nDone. copied=%d  forced=%d  manual=%d\n' "$COPIED" "$FORCED" "$SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  printf 'Items marked [MANUAL] were skipped. Remove or rename them, then rerun; or use -F to force overwrite.\n'
fi
