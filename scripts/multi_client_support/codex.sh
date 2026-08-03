#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
SOURCE_DOT_CLAUDE_DIR="$REPO_ROOT/dot_claude"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]

选项：
  -l  目标层级：
      user     写入 ${CODEX_HOME:-$HOME/.codex}
      project  写入目标项目目录
  -p  目标项目目录。-l project 时必填；-l user 时不可使用。
  -n  输出文件名（默认：AGENTS.codex.md）
  -F  强制覆盖已有输出文件。与 -v 一同使用时，更新匹配的内嵌文件，同时保留无关的额外文件。
  -v  将本仓库的 dot_claude/ 内嵌到 <target>/.agent-rules/claude/。仅 -l project 时有效。
  -h  显示此帮助信息

示例：
  sh scripts/multi_client_support/codex.sh -l user
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
USAGE
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

expand_path() {
  case "$1" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

preflight_output() {
  dest="$1"
  force="$2"

  if [ -e "$dest" ] && [ ! -f "$dest" ]; then
      printf '[MANUAL] 输出路径已存在但不是普通文件：%s\n' "$dest" >&2
    printf '请手动处理该路径后再使用 -F。\n' >&2
    exit 1
  fi

  if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
    printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$dest" >&2
    printf '使用 -F 可强制覆盖。\n' >&2
    exit 1
  fi
}

preflight_vendor() {
  target_project="$1"
  force="$2"
  parent="$target_project/.agent-rules"
  dest="$target_project/.agent-rules/claude"

  if [ ! -d "$SOURCE_DOT_CLAUDE_DIR" ]; then
    printf '错误：源 dot_claude 目录不存在：%s\n' "$SOURCE_DOT_CLAUDE_DIR" >&2
    exit 1
  fi

  if [ -e "$parent" ] && [ ! -d "$parent" ]; then
    printf '[MANUAL] 内嵌父路径已存在但不是目录：%s\n' "$parent" >&2
    printf '请手动处理该路径后再使用 -F。\n' >&2
    exit 1
  fi

  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    printf '[MANUAL] 内嵌路径已存在但不是目录：%s\n' "$dest" >&2
    printf '请手动处理该路径后再使用 -F。\n' >&2
    exit 1
  fi

  if [ -d "$dest" ] && [ "$force" -ne 1 ]; then
    printf '[MANUAL] 内嵌目录已存在，请手动处理：%s\n' "$dest" >&2
    printf '使用 -F 可将源文件复制到匹配的目标路径，同时保留无关的额外文件。\n' >&2
    exit 1
  fi

  (
    cd "$SOURCE_DOT_CLAUDE_DIR"
    find . -type d -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        if [ "$rel" = "." ]; then
          dest_path="$dest"
        else
          dest_path="$dest/$rel"
        fi

        if [ -e "$dest_path" ] && [ ! -d "$dest_path" ]; then
          printf "[MANUAL] 内嵌路径已存在但不是目录：%s\n" "$dest_path" >&2
          exit 1
        fi
      done
    ' sh "$dest" {} +
    find . -type f -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        dest_path="$dest/$rel"

        if [ -e "$dest_path" ] && [ ! -f "$dest_path" ]; then
          printf "[MANUAL] 内嵌路径已存在但不是普通文件：%s\n" "$dest_path" >&2
          exit 1
        fi
      done
    ' sh "$dest" {} +
  )
}

copy_template() {
  src="$1"
  dest="$2"
  force="$3"

  if [ ! -f "$src" ]; then
    printf '错误：模板文件不存在：%s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && [ "$force" -eq 1 ]; then
    printf '[FORCE] Overwriting: %s\n' "$dest"
  fi

  cp "$src" "$dest"
  printf '[CREATED] %s\n' "$dest"
}

vendor_claude_source() {
  target_project="$1"
  force="$2"
  dest="$target_project/.agent-rules/claude"

  mkdir -p "$dest"

  if [ "$force" -eq 1 ] && [ -d "$dest" ]; then
    printf '[FORCE] 更新内嵌的 Claude 规则来源：%s\n' "$dest"
  fi

  (
    cd "$SOURCE_DOT_CLAUDE_DIR"
    find . -type d -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        if [ "$rel" = "." ]; then
          dest_path="$dest"
        else
          dest_path="$dest/$rel"
        fi

        mkdir -p "$dest_path" || exit 1
      done
    ' sh "$dest" {} +
    find . -type f -exec sh -c '
      dest="$1"
      shift
      for src do
        rel="${src#./}"
        cp "$src" "$dest/$rel" || exit 1
      done
    ' sh "$dest" {} +
  )

  printf '[VENDORED] %s -> %s\n' "$SOURCE_DOT_CLAUDE_DIR" "$dest"
}

LEVEL=""
TARGET=""
OUTNAME="AGENTS.codex.md"
FORCE=0
VENDOR=0

while getopts "l:p:n:Fvh" opt; do
  case "$opt" in
    l) LEVEL="$OPTARG" ;;
    p) TARGET="$OPTARG" ;;
    n) OUTNAME="$OPTARG" ;;
    F) FORCE=1 ;;
    v) VENDOR=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[ -n "$LEVEL" ] || fail_usage '-l <user|project> 为必填项'

case "$LEVEL" in
  user|project)
    ;;
  *)
    fail_usage "无效的层级：$LEVEL"
    ;;
esac

case "$OUTNAME" in
  ""|*/*)
    fail_usage '-n 必须是文件名，不能是路径'
    ;;
esac

case "$LEVEL" in
  user)
    [ -z "$TARGET" ] || fail_usage '-p 仅在 -l project 时有效'
    [ "$VENDOR" -eq 0 ] || fail_usage '-v 仅在 -l project 时有效'
    TARGET_DIR="${CODEX_HOME:-$HOME/.codex}"
    TARGET_DIR="$(expand_path "$TARGET_DIR")"
    TEMPLATE="$TEMPLATE_DIR/AGENTS.codex-user.md"
    ;;
  project)
    [ -n "$TARGET" ] || fail_usage '-l project 时 -p <target_dir> 为必填项'
    TARGET_DIR="$(expand_path "$TARGET")"
    if [ ! -d "$TARGET_DIR" ]; then
      printf '错误：目标目录不存在：%s\n' "$TARGET_DIR" >&2
      exit 1
    fi
    TEMPLATE="$TEMPLATE_DIR/AGENTS.codex-project.md"
    ;;
esac

DEST="$TARGET_DIR/$OUTNAME"
preflight_output "$DEST" "$FORCE"
if [ "$VENDOR" -eq 1 ]; then
  preflight_vendor "$TARGET_DIR" "$FORCE"
fi

copy_template "$TEMPLATE" "$DEST" "$FORCE"

if [ "$VENDOR" -eq 1 ]; then
  vendor_claude_source "$TARGET_DIR" "$FORCE"
fi
