#!/bin/sh
# install-agent-pkg.sh - 安装 agents/ 下的场景 agent 包
#
# 功能：
#   把 agents/agents-<FLAG>/ 中的 *.md agent 定义逐个复制到目标 agents 目录。
#   - 同名文件已存在时默认跳过（[MANUAL]）
#   - -F 时先把同名旧文件移到 <target>.backup-<时间戳>/ 再复制；备份放在目标目录
#     旁边而不是里面，Claude Code 不会把旧文件当成 agent 载入
#   - 目标中包里没有的 agent 文件一律保留
#
# 只安装 agents 这一个维度；整个场景的完整配置见 install-claude-project.sh。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-agent-pkg.sh -f <FLAG> -t <target_agents_dir> [-s <agents_root>] [-F]

必选：
  -f <FLAG>   agent 包标识，对应 <agents_root>/agents-<FLAG>/，
              例如 prd-design、frontend-dev、backend-dev、dev-ops
  -t <目录>   目标 agents 目录，必须已存在，
              例如 <project>/.claude/agents（项目级）或 ~/.claude/agents（用户级）

可选：
  -s <目录>   源 agents 根目录（默认：<repo>/agents）
  -F          同名文件已存在时先备份到 <target>.backup-<时间戳>/ 再覆盖
  -h          显示此帮助信息

示例：
  # 为项目安装后端场景的 agent
  sh scripts/install-agent-pkg.sh -f backend-dev -t ~/my-project/.claude/agents

  # 用仓库版本更新已安装的同名 agent（旧文件先备份）
  sh scripts/install-agent-pkg.sh -f backend-dev -t ~/my-project/.claude/agents -F

  # 安装到用户级，所有项目可用
  sh scripts/install-agent-pkg.sh -f prd-design -t ~/.claude/agents

  # 从其他 agents 根目录安装
  sh scripts/install-agent-pkg.sh -f my-team -t ~/my-project/.claude/agents -s ~/shared/agents
USAGE
}

FLAG=""
TARGET=""
AGENTS_ROOT=""
FORCE=0

while getopts "f:t:s:Fh" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    s) AGENTS_ROOT="$OPTARG" ;;
    F) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [ -z "$FLAG" ] || [ -z "$TARGET" ]; then
  printf '错误：-f <FLAG> 和 -t <target_agents_dir> 为必填项。\n' >&2
  usage
  exit 1
fi

if [ -z "$AGENTS_ROOT" ]; then
  AGENTS_ROOT="$REPO_ROOT/agents"
fi

PKG_DIR="$AGENTS_ROOT/agents-$FLAG"

if [ ! -d "$PKG_DIR" ]; then
  printf '错误：Agent 包不存在：%s\n' "$PKG_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf '错误：目标目录不存在：%s\n' "$TARGET" >&2
  exit 1
fi

TARGET="${TARGET%/}"
BACKUP_DIR=""

# Backups live next to the target, not inside it, so Claude Code does not load
# the old copies as agents.
ensure_backup_dir() {
  [ -z "$BACKUP_DIR" ] || return 0

  base_path="${TARGET}.backup-$(date +%Y%m%d-%H%M%S)"
  BACKUP_DIR="$base_path"
  counter=1
  while [ -e "$BACKUP_DIR" ]; do
    BACKUP_DIR="${base_path}.${counter}"
    counter=$((counter + 1))
  done
  mkdir -p "$BACKUP_DIR"
}

COPIED=0
SKIPPED=0
FORCED=0

for src_file in "$PKG_DIR"/*.md; do
  # Skip if no *.md files exist (glob unexpanded)
  [ -f "$src_file" ] || continue

  file_name="$(basename "$src_file")"
  dest="$TARGET/$file_name"

  if [ -f "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      ensure_backup_dir
      mv "$dest" "$BACKUP_DIR/$file_name"
      printf '[BACKUP] %s -> %s\n' "$dest" "$BACKUP_DIR/$file_name"
      cp "$src_file" "$dest"
      printf '[COPIED] %s\n' "$file_name"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] Agent 文件已存在，请手动处理：%s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp "$src_file" "$dest"
    printf '[COPIED] %s\n' "$file_name"
    COPIED=$((COPIED + 1))
  fi
done

printf '\nDone. copied=%d  forced=%d  manual=%d\n' "$COPIED" "$FORCED" "$SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  printf '标记为 [MANUAL] 的文件已跳过。请在目标目录中删除或重命名后重新运行；或使用 -F 强制覆盖（旧文件会先备份）。\n'
fi
if [ -n "$BACKUP_DIR" ]; then
  printf '被覆盖的 Agent 文件已备份到：%s\n' "$BACKUP_DIR"
fi
