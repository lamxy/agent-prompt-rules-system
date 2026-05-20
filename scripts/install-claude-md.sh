#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/install-claude-md.sh -f <FLAG> -t <target_dir> [-n <filename>] [-s <claude_mds_root>] [-F]

Options:
  -f  Flag/identifier matching CLAUDE-<FLAG>.md in the source directory
  -t  Target project directory (file will be placed here)
  -n  Output filename (default: CLAUDE.md, e.g. AGENTS.md, GEMINI.md)
  -s  Source claude_mds root (default: <repo>/claude_mds)
  -F  Force overwrite if target file already exists
  -h  Show this help message

Examples:
  sh scripts/install-claude-md.sh -f project-frontend-dev -t ~/my-project
  sh scripts/install-claude-md.sh -f user-productivity -t ~/my-project -n AGENTS.md
  sh scripts/install-claude-md.sh -f project-backend-dev -t ~/my-project -F
USAGE
}

FLAG=""
TARGET=""
OUTNAME="CLAUDE.md"
SOURCE_ROOT=""
FORCE=0

# Manual --name / -n long-option shim before getopts
ARGS=""
i=1
for arg in "$@"; do
  case "$arg" in
    --name) ARGS="$ARGS -n" ;;
    --force) ARGS="$ARGS -F" ;;
    --flag) ARGS="$ARGS -f" ;;
    --target) ARGS="$ARGS -t" ;;
    --source) ARGS="$ARGS -s" ;;
    --help) ARGS="$ARGS -h" ;;
    *) ARGS="$ARGS $arg" ;;
  esac
done
# Re-set positional params using eval (POSIX-safe)
eval "set -- $ARGS"

while getopts "f:t:n:s:Fh" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    n) OUTNAME="$OPTARG" ;;
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
  SOURCE_ROOT="$REPO_ROOT/claude_mds"
fi

SRC_FILE="$SOURCE_ROOT/CLAUDE-$FLAG.md"

if [ ! -f "$SRC_FILE" ]; then
  printf 'Error: source file not found: %s\n' "$SRC_FILE" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: target directory does not exist: %s\n' "$TARGET" >&2
  exit 1
fi

DEST="$TARGET/$OUTNAME"

if [ -f "$DEST" ]; then
  if [ "$FORCE" -eq 1 ]; then
    printf '[FORCE] Overwriting: %s\n' "$DEST"
    cp "$SRC_FILE" "$DEST"
    printf '[COPIED] %s -> %s\n' "$(basename "$SRC_FILE")" "$OUTNAME"
  else
    printf '[MANUAL] File already exists, please handle manually: %s\n' "$DEST"
    printf 'Use -F to force overwrite.\n'
    exit 0
  fi
else
  cp "$SRC_FILE" "$DEST"
  printf '[COPIED] %s -> %s\n' "$(basename "$SRC_FILE")" "$OUTNAME"
fi
