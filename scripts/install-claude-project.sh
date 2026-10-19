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
  -F  启动包中的文件在目标已存在时强制覆盖；被覆盖的文件先备份到
      <target_dir>/.claude-project-backup-<时间戳>/
  -h  显示此帮助信息

将 .claude-<FLAG>/ 中的 .claude/、.mcp.json 和 CLAUDE.md 逐个文件复制到 <target_dir>。
目标中启动包没有的文件（如 settings.local.json、已安装的 skills）一律保留。
空文件（模板尚未填写）和 .gitkeep 会被跳过；.mcp.json 不是合法 JSON 时也会跳过。

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

TARGET="${TARGET%/}"
BACKUP_DIR=""

COPIED=0
SKIPPED=0
FORCED=0
EMPTY=0
INVALID=0

# Returns 2 when no Python is available, so the caller can warn instead of fail.
validate_json() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$1" >/dev/null 2>&1
  else
    return 2
  fi
}

# Moves an existing target file into the backup tree, keeping its relative path.
backup_file() {
  rel="$1"

  if [ -z "$BACKUP_DIR" ]; then
    base_path="$TARGET/.claude-project-backup-$(date +%Y%m%d-%H%M%S)"
    BACKUP_DIR="$base_path"
    counter=1
    while [ -e "$BACKUP_DIR" ]; do
      BACKUP_DIR="${base_path}.${counter}"
      counter=$((counter + 1))
    done
  fi

  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  cp "$TARGET/$rel" "$BACKUP_DIR/$rel"
  printf '[BACKUP] %s\n' "$BACKUP_DIR/$rel"
}

install_file() {
  rel="$1"
  src="$PKG_DIR/$rel"
  dest="$TARGET/$rel"

  case "$(basename "$rel")" in
    .gitkeep) return 0 ;;
  esac

  if [ ! -s "$src" ]; then
    printf '[SKIP] 模板尚未填写（空文件）：%s\n' "$rel"
    EMPTY=$((EMPTY + 1))
    return 0
  fi

  case "$rel" in
    *.json)
      json_status=0
      validate_json "$src" || json_status=$?
      case "$json_status" in
        0) ;;
        2) printf '[WARN] 未找到 python3，跳过 JSON 校验：%s\n' "$rel" >&2 ;;
        *)
          printf '[INVALID] 模板不是合法 JSON，已跳过：%s\n' "$rel" >&2
          INVALID=$((INVALID + 1))
          return 0
          ;;
      esac
      ;;
  esac

  if [ -e "$dest" ] && [ ! -f "$dest" ]; then
    printf '[MANUAL] 目标路径已存在且不是文件，请手动处理：%s\n' "$dest"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  if [ -f "$dest" ]; then
    if [ "$FORCE" -ne 1 ]; then
      printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
      return 0
    fi
    backup_file "$rel"
    cp "$src" "$dest"
    printf '[COPIED] %s\n' "$rel"
    FORCED=$((FORCED + 1))
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  printf '[COPIED] %s\n' "$rel"
  COPIED=$((COPIED + 1))
}

# Relative paths of every file the bundle provides.
BUNDLE_FILES="$(
  cd "$PKG_DIR"
  for entry in .claude .mcp.json CLAUDE.md; do
    if [ -e "$entry" ]; then
      find "$entry" -type f
    fi
  done
)"

if [ -n "$BUNDLE_FILES" ]; then
  while IFS= read -r rel; do
    install_file "$rel"
  done <<EOF
$BUNDLE_FILES
EOF
fi

printf '\nDone. copied=%d  forced=%d  manual=%d  empty=%d  invalid=%d\n' "$COPIED" "$FORCED" "$SKIPPED" "$EMPTY" "$INVALID"
if [ "$SKIPPED" -gt 0 ]; then
  printf '标记为 [MANUAL] 的文件已跳过。请删除或重命名后重新运行；或使用 -F 强制覆盖（会先备份）。\n'
fi
if [ -n "$BACKUP_DIR" ]; then
  printf '被覆盖的文件已备份到：%s\n' "$BACKUP_DIR"
fi
if [ "$((COPIED + FORCED + SKIPPED))" -eq 0 ]; then
  printf '此启动包尚无可安装的内容：%s\n' "$PKG_DIR"
fi
