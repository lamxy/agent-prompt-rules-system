#!/bin/sh
# install-dot-mcp.sh - 安装 dot_mcp_jsons/ 下的场景 .mcp.json
#
# 功能：
#   把 dot_mcp_jsons/dot-mcp-json-<FLAG>.json 复制为目标目录的 .mcp.json。
#   - 模板为空文件（场景没有专属 MCP）时跳过
#   - 模板不是合法 JSON 时报错，不写入；没有 python3 时跳过校验并警告
#   - 目标已存在时默认跳过（[MANUAL]）；-F 时先备份为 .mcp.json.bak.<时间戳> 再覆盖
#   模板中的凭据以 ${VAR} 引用环境变量，本脚本不展开也不写入任何凭据。
#
# 只安装 .mcp.json 这一个维度；整个场景的完整配置见 install-claude-project.sh。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-dot-mcp.sh -f <FLAG> -t <target_dir> [-s <dot_mcp_jsons_root>] [-F]

必选：
  -f <FLAG>   场景标识，对应 <dot_mcp_jsons_root>/dot-mcp-json-<FLAG>.json，
              例如 backend-dev（MySQL、PostgreSQL）；
              prd-design、frontend-dev、dev-ops 目前为空模板，会被跳过
  -t <目录>   目标目录（通常是项目根目录），必须已存在；输出文件固定为 .mcp.json

可选：
  -s <目录>   源 dot_mcp_jsons 根目录（默认：<repo>/dot_mcp_jsons）
  -F          目标 .mcp.json 已存在时先备份为 .mcp.json.bak.<时间戳> 再覆盖
  -h          显示此帮助信息

示例：
  # 为项目安装后端场景的数据库 MCP（连接请使用只读账号）
  sh scripts/install-dot-mcp.sh -f backend-dev -t ~/my-project

  # 用仓库版本覆盖已有的 .mcp.json（先备份）
  sh scripts/install-dot-mcp.sh -f backend-dev -t ~/my-project -F

  # 从其他模板目录安装
  sh scripts/install-dot-mcp.sh -f my-team -t ~/my-project -s ~/shared/dot_mcp_jsons
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
