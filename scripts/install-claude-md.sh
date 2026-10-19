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
  -F  目标文件已存在时强制覆盖（先备份为 <文件>.bak.<时间戳>）
  -h  显示此帮助信息

源文件为空（模板尚未填写）时跳过，不会写入空文件。

示例：
  sh scripts/install-claude-md.sh -f frontend-dev -t ~/my-project
  sh scripts/install-claude-md.sh -f prd-design -t ~/my-project -n AGENTS.md
  sh scripts/install-claude-md.sh -f backend-dev -t ~/my-project -F
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

FLAG=""
TARGET=""
OUTNAME="CLAUDE.md"
SOURCE_ROOT=""
FORCE=0

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

case "$OUTNAME" in
  */*|.|..|'')
    printf '错误：-n 只能是文件名，不能包含路径：%s\n' "$OUTNAME" >&2
    exit 1
    ;;
esac

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

if [ ! -s "$SRC_FILE" ]; then
  printf '[SKIP] 模板尚未填写（空文件）：%s\n' "$SRC_FILE"
  exit 0
fi

DEST="$TARGET/$OUTNAME"

if [ -f "$DEST" ]; then
  if [ "$FORCE" -eq 1 ]; then
    backup_file "$DEST"
    cp "$SRC_FILE" "$DEST"
    printf '[COPIED] %s -> %s\n' "$(basename "$SRC_FILE")" "$OUTNAME"
  else
    printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$DEST"
    printf '使用 -F 可强制覆盖（会先备份）。\n'
    exit 0
  fi
else
  cp "$SRC_FILE" "$DEST"
  printf '[COPIED] %s -> %s\n' "$(basename "$SRC_FILE")" "$OUTNAME"
fi
