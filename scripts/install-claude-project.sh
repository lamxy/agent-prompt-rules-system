#!/bin/sh
# install-claude-project.sh - 分发 dot_claude_projects/ 下的配置包
#
# 功能：
#   - 项目级（-f <FLAG> -t <project_dir>）：把场景包 .claude-<FLAG>/ 中的
#     .claude/、.mcp.json、CLAUDE.md 逐个文件复制到项目根目录，再调用
#     install-open-supports.sh -t 安装项目清单中的支持包。
#   - 全局（-g）：只把 dot_claude_projects/.claude/open_supports_name_list.txt
#     复制到 ~/.claude/，再调用 install-open-supports.sh -g 安装其中的全局支持包。
#
# 已存在的文件默认不覆盖（标记 [MANUAL]），-F 时先备份再覆盖。目标上已有清单时，
# 支持包按目标上的清单安装，保留使用者对清单的修改。场景包是各维度配置
# （settings/、claude_mds/、dot_mcp_jsons/、agents/、skills/）的完整聚合，与这些
# 目录分开维护；只安装单一维度时请用对应的 install-*.sh。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OPEN_SUPPORTS_INSTALLER="$SCRIPT_DIR/install-open-supports.sh"
LIST_REL=".claude/open_supports_name_list.txt"

usage() {
  cat <<'USAGE'
用法：
  项目级：sh scripts/install-claude-project.sh -f <FLAG> -t <project_dir> [选项]
  全局：  sh scripts/install-claude-project.sh -g [选项]

作用域（必选，二选一）：
  -f <FLAG>         项目级：场景标识，对应源目录中的 .claude-<FLAG>/；须与 -t 一起使用
  -t <project_dir>  项目级：目标项目根目录（目录必须已存在）
  -g                全局：只复制 .claude/open_supports_name_list.txt 到 ~/.claude/，
                    再安装其中的全局支持包；不能与 -f、-t 同用

其他选项（均可选）：
  -F                目标文件已存在时先备份再覆盖。项目级备份到
                    <project_dir>/.claude-project-backup-<时间戳>/；全局备份为
                    ~/.claude/open_supports_name_list.txt.backup-<时间戳>
  -N                只复制配置，不调用 install-open-supports.sh 安装支持包
  -d                预演：只打印要复制的文件和支持包安装计划，不写入任何文件
  -s <root>         源 dot_claude_projects 根目录（默认：<repo>/dot_claude_projects）
  -o <root>         源 open_supports 根目录，传给 install-open-supports.sh -s
                    （默认：<repo>/open_supports）
  -h                显示此帮助信息

复制规则：
  - 目标中配置包没有的文件（如 settings.local.json、自己加的 skills）一律保留
  - 空文件（模板尚未填写）和 .gitkeep 跳过；不是合法 JSON 的 .json 文件跳过
  - 目标文件已存在且未加 -F 时标记 [MANUAL] 跳过，支持包仍按目标上的清单安装

示例：
  sh scripts/install-claude-project.sh -f backend-dev -t ~/my-project -d
  sh scripts/install-claude-project.sh -f backend-dev -t ~/my-project
  sh scripts/install-claude-project.sh -f backend-dev -t ~/my-project -F -N
  sh scripts/install-claude-project.sh -g -d
  sh scripts/install-claude-project.sh -g
USAGE
}

fail_usage() {
  printf '错误：%s\n' "$1" >&2
  usage >&2
  exit 1
}

FLAG=""
TARGET=""
GLOBAL=0
FORCE=0
NO_INSTALL=0
DRY_RUN=0
SOURCE_ROOT=""
OPEN_SUPPORTS_ROOT=""

while getopts "f:t:gFNds:o:h" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    g) GLOBAL=1 ;;
    F) FORCE=1 ;;
    N) NO_INSTALL=1 ;;
    d) DRY_RUN=1 ;;
    s) SOURCE_ROOT="$OPTARG" ;;
    o) OPEN_SUPPORTS_ROOT="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
[ "$#" -eq 0 ] || fail_usage "多余的参数：$*"

if [ "$GLOBAL" -eq 1 ]; then
  if [ -n "$FLAG" ] || [ -n "$TARGET" ]; then
    fail_usage '-g 不能与 -f、-t 同用'
  fi
elif [ -z "$FLAG" ] || [ -z "$TARGET" ]; then
  fail_usage '项目级需要 -f <FLAG> 和 -t <project_dir>；全局请用 -g'
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/dot_claude_projects"
fi

if [ "$GLOBAL" -eq 1 ]; then
  PKG_DIR="$SOURCE_ROOT/.claude"
  TARGET="$HOME"
  if [ ! -f "$SOURCE_ROOT/$LIST_REL" ]; then
    printf '错误：全局清单不存在：%s\n' "$SOURCE_ROOT/$LIST_REL" >&2
    exit 1
  fi
else
  case "$FLAG" in
    *[!A-Za-z0-9._-]*|*..*)
      fail_usage "FLAG 只能包含字母、数字、点、下划线和连字符：$FLAG"
      ;;
  esac
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
fi

BACKUP_DIR=""
STAMP="$(date +%Y%m%d-%H%M%S)"

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

unique_path() {
  candidate="$1"
  counter=1
  while [ -e "$candidate" ]; do
    candidate="$1.$counter"
    counter=$((counter + 1))
  done
  printf '%s\n' "$candidate"
}

# Copies an existing target file aside before it is overwritten. Project backups
# keep the relative path in one directory; the global list is backed up beside
# itself so nothing new is created directly under ~.
backup_file() {
  rel="$1"

  if [ "$GLOBAL" -eq 1 ]; then
    backup="$(unique_path "$TARGET/$rel.backup-$STAMP")"
    cp "$TARGET/$rel" "$backup"
    printf '[BACKUP] %s\n' "$backup"
    BACKUP_DIR="$backup"
    return 0
  fi

  if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$(unique_path "$TARGET/.claude-project-backup-$STAMP")"
  fi

  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  cp "$TARGET/$rel" "$BACKUP_DIR/$rel"
  printf '[BACKUP] %s\n' "$BACKUP_DIR/$rel"
}

install_file() {
  rel="$1"
  src="$SOURCE_ROOT/$rel"
  [ "$GLOBAL" -eq 1 ] || src="$PKG_DIR/$rel"
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

  if [ -f "$dest" ] && [ "$FORCE" -ne 1 ]; then
    printf '[MANUAL] 文件已存在，请手动处理：%s\n' "$dest"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] copy %s -> %s\n' "$rel" "$dest"
    return 0
  fi

  if [ -f "$dest" ]; then
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

if [ "$GLOBAL" -eq 1 ]; then
  printf '[GLOBAL] 只复制 %s 到 %s/.claude/\n' "$LIST_REL" "$HOME"
  # The global bundle contributes this one file and nothing else.
  BUNDLE_FILES="$LIST_REL"
else
  # Relative paths of every file the scenario bundle provides.
  BUNDLE_FILES="$(
    cd "$PKG_DIR"
    for entry in .claude .mcp.json CLAUDE.md; do
      if [ -e "$entry" ]; then
        find "$entry" -type f
      fi
    done
  )"
fi

if [ -n "$BUNDLE_FILES" ]; then
  while IFS= read -r rel; do
    install_file "$rel"
  done <<EOF
$BUNDLE_FILES
EOF
fi

printf '\n复制完成。copied=%d  forced=%d  manual=%d  empty=%d  invalid=%d\n' "$COPIED" "$FORCED" "$SKIPPED" "$EMPTY" "$INVALID"
if [ "$SKIPPED" -gt 0 ]; then
  printf '标记为 [MANUAL] 的文件已跳过。请删除或重命名后重新运行；或使用 -F 强制覆盖（会先备份）。\n'
fi
if [ -n "$BACKUP_DIR" ]; then
  printf '被覆盖的文件已备份到：%s\n' "$BACKUP_DIR"
fi

if [ "$NO_INSTALL" -eq 1 ]; then
  printf '已指定 -N，跳过支持包安装。\n'
  exit 0
fi

# Support packages follow the list on the target, which keeps local edits. A
# dry run has not copied anything yet, so it previews with the bundle's list.
list_file="$TARGET/$LIST_REL"
if [ ! -f "$list_file" ] && [ "$DRY_RUN" -eq 1 ]; then
  if [ "$GLOBAL" -eq 1 ]; then
    list_file="$SOURCE_ROOT/$LIST_REL"
  else
    list_file="$PKG_DIR/$LIST_REL"
  fi
fi

if [ ! -s "$list_file" ]; then
  printf '没有支持包清单，跳过支持包安装：%s\n' "$TARGET/$LIST_REL"
  exit 0
fi

set -- -l "$list_file"
if [ "$GLOBAL" -eq 1 ]; then
  set -- -g "$@"
else
  set -- -t "$TARGET" "$@"
fi
[ -z "$OPEN_SUPPORTS_ROOT" ] || set -- "$@" -s "$OPEN_SUPPORTS_ROOT"
[ "$DRY_RUN" -eq 0 ] || set -- "$@" --dry-run

printf '\n==> 安装支持包：%s\n' "$list_file"
sh "$OPEN_SUPPORTS_INSTALLER" "$@"
