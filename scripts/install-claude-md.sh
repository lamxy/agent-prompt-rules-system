#!/bin/sh
# install-claude-md.sh - 安装 claude_mds/ 下的场景 CLAUDE.md
#
# 功能：
#   把 claude_mds/CLAUDE-<FLAG>.md 复制到目标目录，默认命名为 CLAUDE.md，
#   也可用 -n 输出为 AGENTS.md、GEMINI.md 等其他客户端的指令文件名。
#   - 模板为空文件（尚未填写）时跳过，不写入空文件
#   - 目标已存在时默认跳过（[MANUAL]）；-F 时先备份为 <文件>.bak.<时间戳> 再覆盖
#
# 只安装 CLAUDE.md 这一个维度；整个场景的完整配置见 install-claude-project.sh。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-claude-md.sh -f <FLAG> -t <target_dir> [-n <filename>] [-s <claude_mds_root>] [-F]

必选：
  -f <FLAG>     场景标识，对应 <claude_mds_root>/CLAUDE-<FLAG>.md，
                例如 prd-design、frontend-dev、backend-dev、dev-ops
  -t <目录>     目标目录（通常是项目根目录），必须已存在

可选：
  -n <文件名>   输出文件名（默认：CLAUDE.md），只能是文件名，不能含路径，
                例如 AGENTS.md、GEMINI.md
  -s <目录>     源 claude_mds 根目录（默认：<repo>/claude_mds）
  -F            目标文件已存在时先备份为 <文件>.bak.<时间戳> 再覆盖
  -h            显示此帮助信息

示例：
  # 为项目安装后端场景的 CLAUDE.md
  sh scripts/install-claude-md.sh -f backend-dev -t ~/my-project

  # 用仓库版本覆盖已有的 CLAUDE.md（先备份）
  sh scripts/install-claude-md.sh -f backend-dev -t ~/my-project -F

  # 同一份场景约定输出为 Codex 使用的 AGENTS.md
  sh scripts/install-claude-md.sh -f backend-dev -t ~/my-project -n AGENTS.md

  # 输出为 Gemini CLI 使用的 GEMINI.md
  sh scripts/install-claude-md.sh -f frontend-dev -t ~/my-project -n GEMINI.md

  # 从其他模板目录安装
  sh scripts/install-claude-md.sh -f my-team -t ~/my-project -s ~/shared/claude_mds
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
