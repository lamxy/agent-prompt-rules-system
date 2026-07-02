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
  -F  目标文件已存在时强制覆盖
  -h  显示此帮助信息

示例：
  sh scripts/install-dot-mcp.sh -f frontend-dev -t ~/my-project
  sh scripts/install-dot-mcp.sh -f frontend-dev -t ~/my-project -F
  sh scripts/install-dot-mcp.sh -f frontend-dev -t ~/my-project -s /custom/dot_mcp_jsons
USAGE
}

FLAG=""
TARGET=""
SOURCE_ROOT=""
FORCE=0

# Long-option shim before getopts
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

DEST="$TARGET/.mcp.json"

if [ -f "$DEST" ]; then
  if [ "$FORCE" -eq 1 ]; then
    printf '[FORCE] 覆盖写入：%s\n' "$DEST"
    cp "$SRC_FILE" "$DEST"
    printf '[COPIED] %s -> .mcp.json\n' "$(basename "$SRC_FILE")"
  else
    printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$DEST"
    printf '使用 -F 可强制覆盖。\n'
    exit 0
  fi
else
  cp "$SRC_FILE" "$DEST"
  printf '[COPIED] %s -> .mcp.json\n' "$(basename "$SRC_FILE")"
fi
