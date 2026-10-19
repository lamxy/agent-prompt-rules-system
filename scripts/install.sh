#!/bin/sh
# install.sh - 把本仓库的 dot_claude/ 同步到 Claude Code 配置目录
#
# 功能：
#   逐个文件复制 dot_claude/（个人用户级配置：CLAUDE.md、commands/、settings.json）
#   到 ~/.claude（-l user）或指定的 .claude 目录（-l project / local）。
#   - 目标文件不存在时直接创建；已存在时按 -m 覆盖、追加或逐个询问
#   - 已存在的 .json 文件在 overwrite/append 时一律跳过（[MANUAL-JSON]），需手动合并
#   - 默认不安装 README.md；project/local 默认不安装 settings.json（-S 启用）
#   - 检测目标中的旧版（dot_claude_legacy）规则文件：默认只警告，-C 移到备份目录
#
# 场景化的项目配置（settings、CLAUDE.md、agents 等）不由本脚本安装，
# 见 install-claude-project.sh 与各维度的 install-*.sh。
set -eu

usage() {
  cat <<'USAGE'
用法：
  sh ./scripts/install.sh -l <user|project|local> -m <overwrite|append|ask> [-p <target_path>] [选项]

必选：
  -l <层级>    目标层级：
                 user     同步到 ~/.claude（忽略 -p；目录不存在时自动创建）
                 project  同步到 -p 指定的项目 .claude 目录
                 local    同步到 -p 指定的目录（行为与 project 相同）
  -m <模式>    目标文件已存在时的处理方式（不存在的文件总是直接创建）：
                 overwrite  用源文件覆盖目标文件
                 append     把源文件内容追加到目标文件末尾
                 ask        逐个文件从终端询问：[o] 覆盖  [a] 追加  [s] 跳过
               已存在的 .json 文件在 overwrite/append 时一律跳过（[MANUAL-JSON]），
               需手动合并以保持合法 JSON 结构。

条件必选：
  -p <路径>    目标 .claude 目录。-l project / local 时必填，目录必须已存在；
               可用 ~ 开头。-l user 时忽略。

可选：
  -e <模式>    排除文件名等于该名称或匹配该 glob 的文件，可重复（glob 请加引号）
  -E <目录>    排除相对 dot_claude/ 根目录的目录，可重复
  -S           project/local 层级也安装 settings.json（默认跳过：它是个人用户级设定，
               项目设定建议用 install-settings.sh）
  -C           把目标中检测到的旧版（dot_claude_legacy）文件移到
               <target>/legacy-backup-<时间戳>/；不加时只列出并警告
  -h           显示此帮助信息

默认行为：
  - README.md 不安装（仓库说明文件）
  - 目标中的旧版 CLAUDE.md、旧版 SubagentStop hook 只警告，不自动修改

示例：
  # 首次同步到 ~/.claude，已有文件逐个询问
  sh ./scripts/install.sh -l user -m ask

  # 用仓库版本覆盖 ~/.claude 中的同名文件（已有 .json 仍跳过），并把旧版规则移到备份
  sh ./scripts/install.sh -l user -m overwrite -C

  # 只更新 commands/，不碰 CLAUDE.md 与 settings.json
  sh ./scripts/install.sh -l user -m overwrite -e CLAUDE.md -e settings.json

  # 把 CLAUDE.md 追加到已有的用户级 CLAUDE.md 之后，不同步 commands/
  sh ./scripts/install.sh -l user -m append -E commands

  # 同步到项目的 .claude（默认不装 settings.json）
  sh ./scripts/install.sh -l project -p ~/my-project/.claude -m ask

  # 项目也安装个人 settings.json
  sh ./scripts/install.sh -l project -p ~/my-project/.claude -m overwrite -S

  # 排除所有 Markdown 文件（glob 加引号，避免被 shell 展开）
  sh ./scripts/install.sh -l local -p ~/my-project/.claude -m ask -e '*.md'
USAGE
}

# Paths (relative to the target .claude directory) installed by the
# pre-2026-10-19 layered rule system. RTK.md is intentionally absent: rtk itself
# generates ~/.claude/RTK.md, so its presence is not evidence of a legacy install.
LEGACY_PATHS="expandable audi_reports audit-reports
commands/auditrules.md
hooks/subagent_stop_gate.py hooks/artifact_read_gate.py
rules/task/general-task-rule-min.md rules/task/sub-agent-rule-min.md
rules/task/tool-call-rule-min.md rules/task/design-first-rule-min.md
rules/preferences/instruction-writing-style-min.md
rules/preferences/network-degraded-preference-min.md
rules/preferences/skill-trigger-constraint-min.md
rules/preferences/source-verification-min.md"

# Prints legacy paths that exist under the target, one per line.
find_legacy_paths() {
  for _path in $LEGACY_PATHS; do
    if [ -e "$TARGET_DIR/$_path" ]; then
      printf '%s\n' "$_path"
    fi
  done
}

# Moves legacy paths into a timestamped backup directory, then removes
# directories the move left empty. rmdir only succeeds on empty directories.
move_legacy_paths() {
  _backup_dir="$TARGET_DIR/legacy-backup-$(date +%Y%m%d-%H%M%S)"
  for _path in $1; do
    mkdir -p "$(dirname "$_backup_dir/$_path")"
    mv "$TARGET_DIR/$_path" "$_backup_dir/$_path"
    printf '[LEGACY-MOVED] %s -> %s\n' "$_path" "$_backup_dir/$_path"
  done
  for _dir in rules/task rules/preferences rules hooks commands; do
    rmdir "$TARGET_DIR/$_dir" 2>/dev/null || true
  done
}

# Warns about legacy content that is never moved automatically.
warn_legacy_references() {
  if [ -f "$TARGET_DIR/CLAUDE.md" ] && grep -q 'general-task-rule-min.md' "$TARGET_DIR/CLAUDE.md"; then
    LEGACY_WARN_COUNT=$((LEGACY_WARN_COUNT + 1))
    printf '[LEGACY-WARN] %s 是旧版内容；overwrite 会替换它，append 会与新内容并存，请确认。\n' "$TARGET_DIR/CLAUDE.md"
  fi
  if [ -f "$TARGET_DIR/settings.json" ] && grep -q 'subagent_stop_gate' "$TARGET_DIR/settings.json"; then
    LEGACY_WARN_COUNT=$((LEGACY_WARN_COUNT + 1))
    printf '[LEGACY-WARN] %s 仍注册旧版 SubagentStop hook（subagent_stop_gate.py），请手动移除该 hook。\n' "$TARGET_DIR/settings.json"
  fi
}

# Returns 0 for source files that are skipped unless explicitly requested.
is_default_skipped() {
  case "$1" in
    README.md)
      SKIP_REASON='仓库说明文件'
      return 0
      ;;
    settings.json)
      if [ "$LEVEL" != "user" ] && [ "$INCLUDE_SETTINGS" -eq 0 ]; then
        SKIP_REASON='个人用户级设定，project/local 默认跳过；需要时加 -S，项目设定建议用 install-settings.sh'
        return 0
      fi
      ;;
  esac
  return 1
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

is_json_file() {
  case "$1" in
    *.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

print_json_manual_message() {
  dest_file="$1"
  MANUAL_JSON_COUNT=$((MANUAL_JSON_COUNT + 1))
  printf '[MANUAL-JSON] %s\n' "$dest_file"
  printf '  已有 .json 文件在 overwrite/append 时被跳过。\n'
  printf '  请手动合并，遵循官方要求并保持合法 JSON 结构。\n'
}

prompt_existing_file_action() {
  target_file="$1"
  while true; do
    printf '文件已存在：%s\n' "$target_file" >&2
    printf '选择操作：[o] 覆盖  [a] 追加  [s] 跳过：' >&2
    # Read from the terminal: stdin is the file list being iterated.
    IFS= read -r answer < /dev/tty
    case "$answer" in
      o|O|overwrite|OVERWRITE)
        printf 'overwrite\n'
        return 0
        ;;
      a|A|append|APPEND)
        printf 'append\n'
        return 0
        ;;
      s|S|skip|SKIP)
        printf 'skip\n'
        return 0
        ;;
      *)
        printf '输入无效，请输入 o、a 或 s。\n' >&2
        ;;
    esac
  done
}

LEVEL=""
TARGET_PATH=""
MODE=""
EXCLUDE_FILES=""
EXCLUDE_DIRS=""
MANUAL_JSON_COUNT=0
INCLUDE_SETTINGS=0
MOVE_LEGACY=0
LEGACY_WARN_COUNT=0
SKIP_REASON=""

while getopts "l:p:m:e:E:SCh" opt; do
  case "$opt" in
    l) LEVEL="$OPTARG" ;;
    p) TARGET_PATH="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    e) EXCLUDE_FILES="${EXCLUDE_FILES:+$EXCLUDE_FILES }$OPTARG" ;;
    E) EXCLUDE_DIRS="${EXCLUDE_DIRS:+$EXCLUDE_DIRS }$OPTARG" ;;
    S) INCLUDE_SETTINGS=1 ;;
    C) MOVE_LEGACY=1 ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [ -z "$LEVEL" ] || [ -z "$MODE" ]; then
  printf '错误：-l 和 -m 为必填项。\n' >&2
  usage
  exit 1
fi

case "$LEVEL" in
  user)
    TARGET_DIR="$HOME/.claude"
    ;;
  project|local)
    if [ -z "$TARGET_PATH" ]; then
      printf '错误：层级为 project 或 local 时，-p <target_path> 为必填项。\n' >&2
      exit 1
    fi
    TARGET_DIR="$(expand_path "$TARGET_PATH")"
    if [ ! -d "$TARGET_DIR" ]; then
      printf '错误：目标目录不存在：%s\n' "$TARGET_DIR" >&2
      exit 1
    fi
    ;;
  *)
    printf '错误：无效的层级：%s。请使用 user、project 或 local。\n' "$LEVEL" >&2
    exit 1
    ;;
esac

case "$MODE" in
  overwrite|append|ask)
    ;;
  *)
    printf '错误：无效的模式：%s。请使用 overwrite、append 或 ask。\n' "$MODE" >&2
    exit 1
    ;;
esac

# Returns 0 if the given file path should be excluded based on -e patterns.
is_excluded_file() {
  _fname="$(basename "$1")"
  # Split the patterns without expanding them against the current directory.
  set -f
  for _pattern in $EXCLUDE_FILES; do
    case "$_fname" in
      $_pattern) set +f; return 0 ;;
    esac
  done
  set +f
  return 1
}

# Returns 0 if the given relative path falls under an excluded directory (-E).
is_excluded_dir() {
  _relpath="$1"
  for _dir in $EXCLUDE_DIRS; do
    case "$_relpath" in
      "$_dir"|"$_dir"/*) return 0 ;;
    esac
  done
  return 1
}

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)/dot_claude"

if [ ! -d "$SOURCE_DIR" ]; then
  printf '错误：源目录不存在：%s\n' "$SOURCE_DIR" >&2
  exit 1
fi

if [ "$LEVEL" = "user" ] && [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

LEGACY_FOUND="$(find_legacy_paths)"
LEGACY_LEFT=0
if [ -n "$LEGACY_FOUND" ]; then
  if [ "$MOVE_LEGACY" -eq 1 ]; then
    move_legacy_paths "$LEGACY_FOUND"
  else
    for _path in $LEGACY_FOUND; do
      LEGACY_LEFT=$((LEGACY_LEFT + 1))
      printf '[LEGACY] %s\n' "$TARGET_DIR/$_path"
    done
    printf '  以上为旧版（dot_claude_legacy）文件，rules/ 下的规则会在每次启动时载入并与新版冲突。\n'
    printf '  请手动处理，或加 -C 移至备份目录。\n'
  fi
fi
warn_legacy_references

TMP_FILE_LIST="$(mktemp)"
trap 'rm -f "$TMP_FILE_LIST"' EXIT HUP INT TERM
find "$SOURCE_DIR" -type f > "$TMP_FILE_LIST"

while IFS= read -r src_file; do
  relative_path="${src_file#"$SOURCE_DIR"/}"

  if is_excluded_dir "$relative_path"; then
    printf '[EXCLUDED-DIR] %s\n' "$relative_path"
    continue
  fi

  if is_excluded_file "$src_file"; then
    printf '[EXCLUDED-FILE] %s\n' "$relative_path"
    continue
  fi

  if is_default_skipped "$relative_path"; then
    printf '[SKIPPED-DEFAULT] %s（%s）\n' "$relative_path" "$SKIP_REASON"
    continue
  fi

  dest_file="$TARGET_DIR/$relative_path"
  dest_dir="$(dirname "$dest_file")"

  mkdir -p "$dest_dir"

  if [ ! -f "$dest_file" ]; then
    cp "$src_file" "$dest_file"
    printf '[CREATED] %s\n' "$dest_file"
    continue
  fi

  current_mode="$MODE"
  if [ "$MODE" = "ask" ]; then
    current_mode="$(prompt_existing_file_action "$dest_file")"
  fi

  case "$current_mode" in
    overwrite)
      if is_json_file "$dest_file"; then
        print_json_manual_message "$dest_file"
        continue
      fi
      cp "$src_file" "$dest_file"
      printf '[OVERWRITE] %s\n' "$dest_file"
      ;;
    append)
      if is_json_file "$dest_file"; then
        print_json_manual_message "$dest_file"
        continue
      fi
      if [ -s "$dest_file" ] && [ "$(tail -c 1 "$dest_file" | wc -l)" -eq 0 ]; then
        printf '\n' >> "$dest_file"
      fi
      cat "$src_file" >> "$dest_file"
      printf '[APPEND] %s\n' "$dest_file"
      ;;
    skip)
      printf '[SKIP] %s\n' "$dest_file"
      ;;
    *)
      printf '错误：不支持的操作：%s\n' "$current_mode" >&2
      exit 1
      ;;
  esac
done < "$TMP_FILE_LIST"

if [ "$MANUAL_JSON_COUNT" -gt 0 ] || [ "$LEGACY_LEFT" -gt 0 ] || [ "$LEGACY_WARN_COUNT" -gt 0 ]; then
  printf '同步完成（含警告）：%s 个已有 .json 文件需要手动合并；%s 个旧版路径未处理；%s 项旧版内容需确认。\n' \
    "$MANUAL_JSON_COUNT" "$LEGACY_LEFT" "$LEGACY_WARN_COUNT"
else
  printf '同步完成。\n'
fi
