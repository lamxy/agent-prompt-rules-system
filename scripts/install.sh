#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
用法：
  sh ./scripts/install.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask> [-e <file>] [-E <dir>]

选项：
  -l  目标层级：
      user    同步到用户级默认配置路径 ~/.claude（忽略 -p）
      project 同步到 -p 指定的目标路径（路径必须已存在）
      local   同步到 -p 指定的目标路径（路径必须已存在）
  -p  目标 .claude 目录路径（project/local 必填）
  -m  目标文件已存在时的同步模式：
      overwrite  覆盖目标文件
      append     将源文件内容追加到目标文件
      ask        逐文件交互询问
      注意：选择 overwrite/append 时，已有 .json 文件自动跳过，
            需手动合并以保持合法 JSON 结构。
  -e  排除匹配指定文件名或 glob 模式的文件（可重复）
      示例：-e CLAUDE.md -e "*.local.json"
  -E  排除相对于源 .claude/ 根目录的指定目录（可重复）
      示例：-E expandable -E "rules/preferences"
  -h  显示此帮助信息
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

is_json_file() {
  case "$1" in
    *.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

print_json_manual_message() {
  dest_file="$1"
  MANUAL_JSON_COUNT=$((MANUAL_JSON_COUNT + 1))
  printf '[MANUAL-JSON] %s\n' "$dest_file"
  printf '  已有 .json 文件在 overwrite/append 时被跳过。\n'
  printf '  请手动合并，遵循官方要求并保持合法 JSON 结构。\n'
}

prompt_existing_file_action() {
  target_file="$1"
  while true; do
    printf '文件已存在：%s\n' "$target_file" >&2
    printf '选择操作：[o] 覆盖  [a] 追加  [s] 跳过：' >&2
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
        printf '输入无效，请输入 o、a 或 s。\n' >&2
        ;;
    esac
  done
}

LEVEL=""
TARGET_PATH=""
MODE=""
EXCLUDE_FILES=""
EXCLUDE_DIRS=""
MANUAL_JSON_COUNT=0

while getopts "l:p:m:e:E:h" opt; do
  case "$opt" in
    l) LEVEL="$OPTARG" ;;
    p) TARGET_PATH="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    e) EXCLUDE_FILES="${EXCLUDE_FILES:+$EXCLUDE_FILES }$OPTARG" ;;
    E) EXCLUDE_DIRS="${EXCLUDE_DIRS:+$EXCLUDE_DIRS }$OPTARG" ;;
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
  printf '错误：-l 和 -m 为必填项。\n' >&2
  usage
  exit 1
fi

case "$LEVEL" in
  user)
    TARGET_DIR="$HOME/.claude"
    ;;
  project|local)
    if [ -z "$TARGET_PATH" ]; then
      printf '错误：层级为 project 或 local 时，-p <target_path> 为必填项。\n' >&2
      exit 1
    fi
    TARGET_DIR="$(expand_path "$TARGET_PATH")"
    if [ ! -d "$TARGET_DIR" ]; then
      printf '错误：目标目录不存在：%s\n' "$TARGET_DIR" >&2
      exit 1
    fi
    ;;
  *)
    printf '错误：无效的层级：%s。请使用 user、project 或 local。\n' "$LEVEL" >&2
    exit 1
    ;;
esac

case "$MODE" in
  overwrite|append|ask)
    ;;
  *)
    printf '错误：无效的模式：%s。请使用 overwrite、append 或 ask。\n' "$MODE" >&2
    exit 1
    ;;
esac

# Returns 0 if the given file path should be excluded based on -e patterns.
is_excluded_file() {
  _fname="$(basename "$1")"
  for _pattern in $EXCLUDE_FILES; do
    case "$_fname" in
      $_pattern) return 0 ;;
    esac
  done
  return 1
}

# Returns 0 if the given relative path falls under an excluded directory (-E).
is_excluded_dir() {
  _relpath="$1"
  for _dir in $EXCLUDE_DIRS; do
    case "$_relpath" in
      "$_dir"|"$_dir"/*) return 0 ;;
    esac
  done
  return 1
}

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)/.claude"

if [ ! -d "$SOURCE_DIR" ]; then
  printf '错误：源目录不存在：%s\n' "$SOURCE_DIR" >&2
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

  if is_excluded_dir "$relative_path"; then
    printf '[EXCLUDED-DIR] %s\n' "$relative_path"
    continue
  fi

  if is_excluded_file "$src_file"; then
    printf '[EXCLUDED-FILE] %s\n' "$relative_path"
    continue
  fi

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
      if is_json_file "$dest_file"; then
        print_json_manual_message "$dest_file"
        continue
      fi
      cp "$src_file" "$dest_file"
      printf '[OVERWRITE] %s\n' "$dest_file"
      ;;
    append)
      if is_json_file "$dest_file"; then
        print_json_manual_message "$dest_file"
        continue
      fi
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
      printf '错误：不支持的操作：%s\n' "$current_mode" >&2
      exit 1
      ;;
  esac
done < "$TMP_FILE_LIST"

if [ "$MANUAL_JSON_COUNT" -gt 0 ]; then
  printf '同步完成（含警告）：%s 个已有 .json 文件需要手动合并。\n' "$MANUAL_JSON_COUNT"
else
  printf '同步完成。\n'
fi
