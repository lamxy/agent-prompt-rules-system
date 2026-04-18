#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
Usage:
  sh sync-claude-config.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask>

Options:
  -l  Target level:
      user    Sync to default user config path: ~/.claude (ignores -p)
      project Sync to specified target path with -p (must already exist)
      local   Sync to specified target path with -p (must already exist)
  -p  Target .claude directory path (required for project/local)
  -m  Sync mode when target file already exists:
      overwrite  Overwrite target file
      append     Append source content to target file
      ask        Ask interactively for each existing file
  -h  Show this help message
USAGE
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

prompt_existing_file_action() {
  target_file="$1"
  while true; do
    printf 'File exists: %s\n' "$target_file" >&2
    printf 'Choose action: [o]verwrite, [a]ppend, [s]kip: ' >&2
    IFS= read -r answer
    case "$answer" in
      o|O|overwrite|OVERWRITE)
        printf 'overwrite\n'
        return 0
        ;;
      a|A|append|APPEND)
        printf 'append\n'
        return 0
        ;;
      s|S|skip|SKIP)
        printf 'skip\n'
        return 0
        ;;
      *)
        printf 'Invalid choice. Please enter o, a, or s.\n' >&2
        ;;
    esac
  done
}

LEVEL=""
TARGET_PATH=""
MODE=""

while getopts "l:p:m:h" opt; do
  case "$opt" in
    l) LEVEL="$OPTARG" ;;
    p) TARGET_PATH="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [ -z "$LEVEL" ] || [ -z "$MODE" ]; then
  printf 'Error: -l and -m are required.\n' >&2
  usage
  exit 1
fi

case "$LEVEL" in
  user)
    TARGET_DIR="$HOME/.claude"
    ;;
  project|local)
    if [ -z "$TARGET_PATH" ]; then
      printf 'Error: -p <target_path> is required when level is project or local.\n' >&2
      exit 1
    fi
    TARGET_DIR="$(expand_path "$TARGET_PATH")"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Error: target directory does not exist: %s\n' "$TARGET_DIR" >&2
      exit 1
    fi
    ;;
  *)
    printf 'Error: invalid level: %s. Use user, project, or local.\n' "$LEVEL" >&2
    exit 1
    ;;
esac

case "$MODE" in
  overwrite|append|ask)
    ;;
  *)
    printf 'Error: invalid mode: %s. Use overwrite, append, or ask.\n' "$MODE" >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude"

if [ ! -d "$SOURCE_DIR" ]; then
  printf 'Error: source directory not found: %s\n' "$SOURCE_DIR" >&2
  exit 1
fi

if [ "$LEVEL" = "user" ] && [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

TMP_FILE_LIST="$(mktemp)"
trap 'rm -f "$TMP_FILE_LIST"' EXIT HUP INT TERM
find "$SOURCE_DIR" -type f > "$TMP_FILE_LIST"

while IFS= read -r src_file; do
  relative_path="${src_file#"$SOURCE_DIR"/}"
  dest_file="$TARGET_DIR/$relative_path"
  dest_dir="$(dirname "$dest_file")"

  mkdir -p "$dest_dir"

  if [ ! -f "$dest_file" ]; then
    cp "$src_file" "$dest_file"
    printf '[CREATED] %s\n' "$dest_file"
    continue
  fi

  current_mode="$MODE"
  if [ "$MODE" = "ask" ]; then
    current_mode="$(prompt_existing_file_action "$dest_file")"
  fi

  case "$current_mode" in
    overwrite)
      cp "$src_file" "$dest_file"
      printf '[OVERWRITE] %s\n' "$dest_file"
      ;;
    append)
      if [ -s "$dest_file" ] && [ "$(tail -c 1 "$dest_file" | wc -l)" -eq 0 ]; then
        printf '\n' >> "$dest_file"
      fi
      cat "$src_file" >> "$dest_file"
      printf '[APPEND] %s\n' "$dest_file"
      ;;
    skip)
      printf '[SKIP] %s\n' "$dest_file"
      ;;
    *)
      printf 'Error: unsupported action: %s\n' "$current_mode" >&2
      exit 1
      ;;
  esac
done < "$TMP_FILE_LIST"

printf 'Sync complete.\n'
