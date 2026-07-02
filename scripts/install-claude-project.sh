#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-claude-project.sh -f <FLAG> -t <target_dir> [-s <dot_claude_projects_root>] [-F]

选项：
  -f  与源目录中 .claude-<FLAG>/ 匹配的标识符
  -t  目标项目根目录（文件直接放置于此）
  -s  源 dot_claude_projects 根目录（默认：<repo>/dot_claude_projects）
  -F  目标文件/目录已存在时强制覆盖
  -h  显示此帮助信息

将 .claude/、.mcp.json 和 CLAUDE.md 从 .claude-<FLAG>/ 复制到 <target_dir>。

示例：
  sh scripts/install-claude-project.sh -f frontend-dev -t ~/my-project
  sh scripts/install-claude-project.sh -f frontend-dev -t ~/my-project -F
  sh scripts/install-claude-project.sh -f frontend-dev -t ~/my-project -s /custom/dot_claude_projects
USAGE
}

FLAG=""
TARGET=""
SOURCE_ROOT=""
FORCE=0

# Long-option shim
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
  SOURCE_ROOT="$REPO_ROOT/dot_claude_projects"
fi

PKG_DIR="$SOURCE_ROOT/.claude-$FLAG"

if [ ! -d "$PKG_DIR" ]; then
  printf '错误：源配置包不存在：%s\n' "$PKG_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf '错误：目标目录不存在：%s\n' "$TARGET" >&2
  exit 1
fi

COPIED=0
SKIPPED=0
FORCED=0

# Helper: copy a single file
copy_file() {
  src="$1"; dest="$2"; label="$3"
  if [ -f "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] 覆盖写入：%s\n' "$dest"
      cp "$src" "$dest"
      printf '[COPIED] %s\n' "$label"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp "$src" "$dest"
    printf '[COPIED] %s\n' "$label"
    COPIED=$((COPIED + 1))
  fi
}

# Helper: copy a directory
copy_dir() {
  src="$1"; dest="$2"; label="$3"
  if [ -d "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] 删除并重新复制：%s\n' "$dest"
      rm -rf "$dest"
      cp -r "$src" "$dest"
      printf '[COPIED] %s\n' "$label"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] 目录已存在，请手动处理：%s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp -r "$src" "$dest"
    printf '[COPIED] %s\n' "$label"
    COPIED=$((COPIED + 1))
  fi
}

# Copy .claude/
if [ -d "$PKG_DIR/.claude" ]; then
  copy_dir "$PKG_DIR/.claude" "$TARGET/.claude" ".claude/"
fi

# Copy .mcp.json
if [ -f "$PKG_DIR/.mcp.json" ]; then
  copy_file "$PKG_DIR/.mcp.json" "$TARGET/.mcp.json" ".mcp.json"
fi

# Copy CLAUDE.md
if [ -f "$PKG_DIR/CLAUDE.md" ]; then
  copy_file "$PKG_DIR/CLAUDE.md" "$TARGET/CLAUDE.md" "CLAUDE.md"
fi

printf '\nDone. copied=%d  forced=%d  manual=%d\n' "$COPIED" "$FORCED" "$SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  printf '标记为 [MANUAL] 的项目已跳过。请删除或重命名后重新运行；或使用 -F 强制覆盖。\n'
fi
