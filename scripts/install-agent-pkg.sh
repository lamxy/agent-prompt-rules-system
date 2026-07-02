#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-agent-pkg.sh -f <FLAG> -t <target_agents_dir> [-s <agents_root>] [-F]

选项：
  -f  Agent 包标识符（如 frontend-dev → agents-frontend-dev/）
  -t  目标 agents 目录（如 /path/to/project/.claude/agents）
  -s  源 agents 根目录（默认：<repo>/agents）
  -F  强制覆盖：删除同名 .md 文件后重新复制
  -h  显示此帮助信息

示例：
  sh scripts/install-agent-pkg.sh -f frontend-dev -t ~/.claude/agents
  sh scripts/install-agent-pkg.sh -f frontend-dev -t /my/project/.claude/agents -F
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
      printf '[FORCE] 删除已有文件：%s\n' "$dest"
      rm -f "$dest"
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
  printf '标记为 [MANUAL] 的文件已跳过。请在目标目录中删除或重命名后重新运行；或使用 -F 强制覆盖。\n'
fi
