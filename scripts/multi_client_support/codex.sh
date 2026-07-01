#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
SOURCE_CLAUDE_DIR="$REPO_ROOT/.claude"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]

Options:
  -l  Target level:
      user     Write to ${CODEX_HOME:-$HOME/.codex}
      project  Write to the target project directory
  -p  Target project directory. Required for -l project. Invalid for -l user.
  -n  Output filename (default: AGENTS.codex.md)
  -F  Force overwrite existing output file. With -v, copy over matching vendored files while preserving unrelated extra files.
  -v  Vendor this repository's .claude/ to <target>/.agent-rules/claude/. Valid only for -l project.
  -h  Show this help message

Examples:
  sh scripts/multi_client_support/codex.sh -l user
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
USAGE
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

expand_path() {
  case "$1" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

preflight_output() {
  dest="$1"
  force="$2"

  if [ -e "$dest" ] && [ ! -f "$dest" ]; then
    printf '[MANUAL] Output path exists but is not a regular file: %s\n' "$dest" >&2
    printf 'Use -F only after manually resolving this path.\n' >&2
    exit 1
  fi

  if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
    printf '[MANUAL] File already exists, please handle manually: %s\n' "$dest" >&2
    printf 'Use -F to force overwrite.\n' >&2
    exit 1
  fi
}

preflight_vendor() {
  target_project="$1"
  force="$2"
  parent="$target_project/.agent-rules"
  dest="$target_project/.agent-rules/claude"

  if [ ! -d "$SOURCE_CLAUDE_DIR" ]; then
    printf 'Error: source .claude directory not found: %s\n' "$SOURCE_CLAUDE_DIR" >&2
    exit 1
  fi

  if [ -e "$parent" ] && [ ! -d "$parent" ]; then
    printf '[MANUAL] Vendor parent path exists but is not a directory: %s\n' "$parent" >&2
    printf 'Use -F only after manually resolving this path.\n' >&2
    exit 1
  fi

  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    printf '[MANUAL] Vendor path exists but is not a directory: %s\n' "$dest" >&2
    printf 'Use -F only after manually resolving this path.\n' >&2
    exit 1
  fi

  if [ -d "$dest" ] && [ "$force" -ne 1 ]; then
    printf '[MANUAL] Vendor directory already exists, please handle manually: %s\n' "$dest" >&2
    printf 'Use -F to copy source files over matching destination paths while preserving unrelated extra files.\n' >&2
    exit 1
  fi

  (
    cd "$SOURCE_CLAUDE_DIR"
    find . -type d -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        if [ "$rel" = "." ]; then
          dest_path="$dest"
        else
          dest_path="$dest/$rel"
        fi

        if [ -e "$dest_path" ] && [ ! -d "$dest_path" ]; then
          printf "[MANUAL] Vendor path exists but is not a directory: %s\n" "$dest_path" >&2
          exit 1
        fi
      done
    ' sh "$dest" {} +
    find . -type f -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        dest_path="$dest/$rel"

        if [ -e "$dest_path" ] && [ ! -f "$dest_path" ]; then
          printf "[MANUAL] Vendor path exists but is not a regular file: %s\n" "$dest_path" >&2
          exit 1
        fi
      done
    ' sh "$dest" {} +
  )
}

copy_template() {
  src="$1"
  dest="$2"
  force="$3"

  if [ ! -f "$src" ]; then
    printf 'Error: template not found: %s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && [ "$force" -eq 1 ]; then
    printf '[FORCE] Overwriting: %s\n' "$dest"
  fi

  cp "$src" "$dest"
  printf '[CREATED] %s\n' "$dest"
}

vendor_claude_source() {
  target_project="$1"
  force="$2"
  dest="$target_project/.agent-rules/claude"

  mkdir -p "$dest"

  if [ "$force" -eq 1 ] && [ -d "$dest" ]; then
    printf '[FORCE] Updating vendored Claude rule source: %s\n' "$dest"
  fi

  (
    cd "$SOURCE_CLAUDE_DIR"
    find . -type d -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        if [ "$rel" = "." ]; then
          dest_path="$dest"
        else
          dest_path="$dest/$rel"
        fi

        mkdir -p "$dest_path" || exit 1
      done
    ' sh "$dest" {} +
    find . -type f -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        cp "$src" "$dest/$rel" || exit 1
      done
    ' sh "$dest" {} +
  )

  printf '[VENDORED] %s -> %s\n' "$SOURCE_CLAUDE_DIR" "$dest"
}

LEVEL=""
TARGET=""
OUTNAME="AGENTS.codex.md"
FORCE=0
VENDOR=0

while getopts "l:p:n:Fvh" opt; do
  case "$opt" in
    l) LEVEL="$OPTARG" ;;
    p) TARGET="$OPTARG" ;;
    n) OUTNAME="$OPTARG" ;;
    F) FORCE=1 ;;
    v) VENDOR=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[ -n "$LEVEL" ] || fail_usage '-l <user|project> is required'

case "$LEVEL" in
  user|project)
    ;;
  *)
    fail_usage "invalid level: $LEVEL"
    ;;
esac

case "$OUTNAME" in
  ""|*/*)
    fail_usage '-n must be a filename, not a path'
    ;;
esac

case "$LEVEL" in
  user)
    [ -z "$TARGET" ] || fail_usage '-p is only valid with -l project'
    [ "$VENDOR" -eq 0 ] || fail_usage '-v is only valid with -l project'
    TARGET_DIR="${CODEX_HOME:-$HOME/.codex}"
    TARGET_DIR="$(expand_path "$TARGET_DIR")"
    TEMPLATE="$TEMPLATE_DIR/AGENTS.codex-user.md"
    ;;
  project)
    [ -n "$TARGET" ] || fail_usage '-p <target_dir> is required when -l project'
    TARGET_DIR="$(expand_path "$TARGET")"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Error: target directory does not exist: %s\n' "$TARGET_DIR" >&2
      exit 1
    fi
    TEMPLATE="$TEMPLATE_DIR/AGENTS.codex-project.md"
    ;;
esac

DEST="$TARGET_DIR/$OUTNAME"
preflight_output "$DEST" "$FORCE"
if [ "$VENDOR" -eq 1 ]; then
  preflight_vendor "$TARGET_DIR" "$FORCE"
fi

copy_template "$TEMPLATE" "$DEST" "$FORCE"

if [ "$VENDOR" -eq 1 ]; then
  vendor_claude_source "$TARGET_DIR" "$FORCE"
fi
