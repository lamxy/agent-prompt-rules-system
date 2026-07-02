#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-claude-md.sh -f <FLAG> -t <target_dir> [-n <filename>] [-s <claude_mds_root>] [-F]

选项：
  -f  与源目录中 CLAUDE-<FLAG>.md 匹配的标识符
  -t  目标项目目录（文件将放置于此）
  -n  输出文件名（默认：CLAUDE.md，如 AGENTS.md、GEMINI.md）
  -s  源 claude_mds 根目录（默认：<repo>/claude_mds）
  -F  目标文件已存在时强制覆盖
  -h  显示此帮助信息

示例：
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
  printf '错误：-f <FLAG> 和 -t <target_dir> 为必填项。\n' >&2
  usage
  exit 1
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/claude_mds"
fi

SRC_FILE="$SOURCE_ROOT/CLAUDE-$FLAG.md"

if [ ! -f "$SRC_FILE" ]; then
  printf '错误：源文件不存在：%s\n' "$SRC_FILE" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf '错误：目标目录不存在：%s\n' "$TARGET" >&2
  exit 1
fi

DEST="$TARGET/$OUTNAME"

if [ -f "$DEST" ]; then
  if [ "$FORCE" -eq 1 ]; then
    printf '[FORCE] 覆盖写入：%s\n' "$DEST"
    cp "$SRC_FILE" "$DEST"
    printf '[COPIED] %s -> %s\n' "$(basename "$SRC_FILE")" "$OUTNAME"
  else
    printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$DEST"
    printf '使用 -F 可强制覆盖。\n'
    exit 0
  fi
else
  cp "$SRC_FILE" "$DEST"
  printf '[COPIED] %s -> %s\n' "$(basename "$SRC_FILE")" "$OUTNAME"
fi
