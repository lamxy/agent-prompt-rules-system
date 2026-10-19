#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-dot-mcp.sh -f <FLAG> -t <target_dir> [-s <dot_mcp_jsons_root>] [-F]

选项：
  -f  与源目录中 dot-mcp-json-<FLAG>.json 匹配的标识符
  -t  目标项目目录（文件将以 .mcp.json 放置于此）
  -s  源 dot_mcp_jsons 根目录（默认：<repo>/dot_mcp_jsons）
  -F  目标文件已存在时强制覆盖（先备份为 .mcp.json.bak.<时间戳>）
  -h  显示此帮助信息

源文件为空（模板尚未填写）时跳过；源文件不是合法 JSON 时报错，不会写入。

示例：
  sh scripts/install-dot-mcp.sh -f frontend-dev -t ~/my-project
  sh scripts/install-dot-mcp.sh -f frontend-dev -t ~/my-project -F
  sh scripts/install-dot-mcp.sh -f frontend-dev -t ~/my-project -s /custom/dot_mcp_jsons
USAGE
}

# Picks a backup path that does not exist yet, so repeated runs keep every backup.
backup_file() {
  base_path="$1.bak.$(date +%Y%m%d-%H%M%S)"
  backup_path="$base_path"
  counter=1
  while [ -e "$backup_path" ]; do
    backup_path="${base_path}.${counter}"
    counter=$((counter + 1))
  done
  cp "$1" "$backup_path"
  printf '[BACKUP] %s\n' "$backup_path"
}

# Returns 2 when no Python is available, so the caller can warn instead of fail.
validate_json() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$1" >/dev/null 2>&1
  else
    return 2
  fi
}

FLAG=""
TARGET=""
SOURCE_ROOT=""
FORCE=0

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
  printf '错误：-f <FLAG> 和 -t <target_dir> 为必填项。\n' >&2
  usage
  exit 1
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/dot_mcp_jsons"
fi

SRC_FILE="$SOURCE_ROOT/dot-mcp-json-$FLAG.json"

if [ ! -f "$SRC_FILE" ]; then
  printf '错误：源文件不存在：%s\n' "$SRC_FILE" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf '错误：目标目录不存在：%s\n' "$TARGET" >&2
  exit 1
fi

if [ ! -s "$SRC_FILE" ]; then
  printf '[SKIP] 模板尚未填写（空文件）：%s\n' "$SRC_FILE"
  exit 0
fi

json_status=0
validate_json "$SRC_FILE" || json_status=$?
case "$json_status" in
  0) ;;
  2) printf '[WARN] 未找到 python3，跳过 JSON 校验：%s\n' "$SRC_FILE" >&2 ;;
  *)
    printf '错误：源文件不是合法 JSON：%s\n' "$SRC_FILE" >&2
    exit 1
    ;;
esac

DEST="$TARGET/.mcp.json"

if [ -f "$DEST" ]; then
  if [ "$FORCE" -eq 1 ]; then
    backup_file "$DEST"
    cp "$SRC_FILE" "$DEST"
    printf '[COPIED] %s -> .mcp.json\n' "$(basename "$SRC_FILE")"
  else
    printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$DEST"
    printf '使用 -F 可强制覆盖（会先备份）。\n'
    exit 0
  fi
else
  cp "$SRC_FILE" "$DEST"
  printf '[COPIED] %s -> .mcp.json\n' "$(basename "$SRC_FILE")"
fi
