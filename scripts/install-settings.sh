#!/bin/sh
set -eu

usage() {
  printf '%s\n' \
    '用法：' \
    '  sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]' \
    '' \
    '选项：' \
    '  -l  配置作用域：' \
    '      user     操作用户级配置' \
    '      project  操作项目级共享配置' \
    '      local    操作本地项目配置' \
    '' \
    '  --src  可选，显式指定源配置文件路径。' \
    '         提供时忽略 -s。' \
    '' \
    '  -s  场景名，用于解析 ./settings/ 下的默认源模板。' \
    '      解析规则：' \
    '      user 不带 -s    -> settings/settings.user.json' \
    '      user 带 -s foo  -> settings/settings.user-foo.json' \
    '      project 带 -s foo-> settings/settings.project-foo.json' \
    '      local 带 -s foo  -> settings/settings.local-foo.json' \
    '' \
    '  -m  目标配置已存在时的操作模式：' \
    '      overwrite  备份后替换目标文件' \
    '      merge      将 enabledPlugins 和 extraKnownMarketplaces 合并到目标' \
    '      ask        询问是否覆盖、合并或跳过' \
    '' \
    '  -p, --dst  精确目标目录。' \
    '             用户级默认 ~/.claude。' \
    '             project 和 local 级必填。' \
    '' \
    '  -h, --help  显示此帮助信息' \
    '' \
    '注意：' \
    '  - merge 仅影响 enabledPlugins 和 extraKnownMarketplaces。' \
    '  - 源文件名必须与所选作用域匹配。' \
    '  - 覆盖或合并写入前，会自动备份已有目标文件。'
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

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

resolve_python() {
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
    PYTHON_ARG=""
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
    PYTHON_ARG=""
    return 0
  fi

  if command -v py >/dev/null 2>&1; then
    PYTHON_BIN="py"
    PYTHON_ARG="-3"
    return 0
  fi

  fail "JSON 校验和合并操作需要 Python 3。"
}

run_python_stdin() {
  script_input="$1"
  shift

  if [ -n "$PYTHON_ARG" ]; then
    printf '%s' "$script_input" | "$PYTHON_BIN" "$PYTHON_ARG" - "$@"
  else
    printf '%s' "$script_input" | "$PYTHON_BIN" - "$@"
  fi
}

validate_json_file() {
  json_file="$1"

  run_python_stdin '
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    json.load(handle)
' "$json_file" >/dev/null 2>&1
}

merge_json_files() {
  source_file="$1"
  target_file="$2"
  output_file="$3"

  run_python_stdin '
import json
import sys

source_path, target_path, output_path = sys.argv[1:4]

with open(source_path, "r", encoding="utf-8") as source_handle:
    source = json.load(source_handle)

with open(target_path, "r", encoding="utf-8") as target_handle:
    target = json.load(target_handle)

if not isinstance(source, dict):
    raise SystemExit("源 settings JSON 必须为对象")

if not isinstance(target, dict):
    raise SystemExit("目标 settings JSON 必须为对象")

result = dict(target)

target_plugins = target.get("enabledPlugins") or {}
source_plugins = source.get("enabledPlugins") or {}
if not isinstance(target_plugins, dict):
    raise SystemExit("目标 enabledPlugins 必须为对象")
if not isinstance(source_plugins, dict):
    raise SystemExit("源 enabledPlugins 必须为对象")

target_marketplaces = target.get("extraKnownMarketplaces") or {}
source_marketplaces = source.get("extraKnownMarketplaces") or {}
if not isinstance(target_marketplaces, dict):
    raise SystemExit("目标 extraKnownMarketplaces 必须为对象")
if not isinstance(source_marketplaces, dict):
    raise SystemExit("源 extraKnownMarketplaces 必须为对象")

result["enabledPlugins"] = dict(target_plugins)
result["enabledPlugins"].update(source_plugins)

result["extraKnownMarketplaces"] = dict(target_marketplaces)
result["extraKnownMarketplaces"].update(source_marketplaces)

with open(output_path, "w", encoding="utf-8") as output_handle:
    json.dump(result, output_handle, ensure_ascii=True, indent=2)
    output_handle.write("\n")
' "$source_file" "$target_file" "$output_file"
}

validate_source_name_matches_level() {
  file_name="$1"
  level="$2"

  case "$level:$file_name" in
    user:settings.user.json|user:settings.user-*.json)
      return 0
      ;;
    project:settings.project-*.json)
      return 0
      ;;
    local:settings.local-*.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

prompt_existing_file_action() {
  target_file="$1"
  allow_merge="$2"

  while true; do
    printf '目标文件已存在：%s\n' "$target_file" >&2
    if [ "$allow_merge" = "yes" ]; then
      printf '选择操作：[o] 覆盖  [m] 合并  [s] 跳过：' >&2
    else
      printf '选择操作：[o] 覆盖  [s] 跳过：' >&2
    fi

    IFS= read -r answer
    case "$answer" in
      o|O|overwrite|OVERWRITE)
        printf 'overwrite\n'
        return 0
        ;;
      m|M|merge|MERGE)
        if [ "$allow_merge" = "yes" ]; then
          printf 'merge\n'
          return 0
        fi
        printf '目标配置文件不是合法 JSON，无法执行合并。\n' >&2
        ;;
      s|S|skip|SKIP)
        printf 'skip\n'
        return 0
        ;;
      *)
        if [ "$allow_merge" = "yes" ]; then
          printf '输入无效，请输入 o、m 或 s。\n' >&2
        else
          printf '输入无效，请输入 o 或 s。\n' >&2
        fi
        ;;
    esac
  done
}

backup_target_file() {
  target_file="$1"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup_path="${target_file}.bak.${timestamp}"
  cp "$target_file" "$backup_path"
  printf '[BACKUP] %s\n' "$backup_path"
}

create_temp_file() {
  target_dir="$1"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  candidate="${target_dir}/.install-settings.${timestamp}.$$"
  counter=0

  while :; do
    if [ "$counter" -eq 0 ]; then
      temp_path="${candidate}.tmp"
    else
      temp_path="${candidate}.${counter}.tmp"
    fi

    if [ ! -e "$temp_path" ]; then
      : > "$temp_path"
      printf '%s\n' "$temp_path"
      return 0
    fi

    counter=$((counter + 1))
  done
}

LEVEL=""
SCENARIO=""
MODE=""
SOURCE_PATH=""
TARGET_DIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -l)
      [ "$#" -ge 2 ] || fail "-l 需要一个值。"
      LEVEL="$2"
      shift 2
      ;;
    -s)
      [ "$#" -ge 2 ] || fail "-s 需要一个值。"
      SCENARIO="$2"
      shift 2
      ;;
    -m)
      [ "$#" -ge 2 ] || fail "-m 需要一个值。"
      MODE="$2"
      shift 2
      ;;
    -p|--dst)
      [ "$#" -ge 2 ] || fail "$1 需要一个值。"
      TARGET_DIR="$2"
      shift 2
      ;;
    --src)
      [ "$#" -ge 2 ] || fail "--src 需要一个值。"
      SOURCE_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "不支持的参数：$1"
      ;;
  esac
done

[ -n "$LEVEL" ] || fail "-l 为必填项。"
[ -n "$MODE" ] || fail "-m 为必填项。"

case "$LEVEL" in
  user|project|local)
    ;;
  *)
    fail "无效的作用域：$LEVEL。请使用 user、project 或 local。"
    ;;
esac

case "$MODE" in
  overwrite|merge|ask)
    ;;
  *)
    fail "无效的模式：$MODE。请使用 overwrite、merge 或 ask。"
    ;;
esac

case "$0" in
  */*)
    SCRIPT_PATH_DIR="${0%/*}"
    ;;
  *)
    SCRIPT_PATH_DIR="."
    ;;
esac

SCRIPT_DIR="$(cd "$SCRIPT_PATH_DIR" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_SETTINGS_DIR="$REPO_ROOT/settings"

if [ -n "$SOURCE_PATH" ]; then
  RESOLVED_SOURCE_PATH="$(expand_path "$SOURCE_PATH")"
else
  case "$LEVEL" in
    user)
      if [ -n "$SCENARIO" ]; then
        RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.user-$SCENARIO.json"
      else
        RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.user.json"
      fi
      ;;
    project)
      [ -n "$SCENARIO" ] || fail "未提供 --src 时，project 级必须指定 -s。"
      RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.project-$SCENARIO.json"
      ;;
    local)
      [ -n "$SCENARIO" ] || fail "未提供 --src 时，local 级必须指定 -s。"
      RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.local-$SCENARIO.json"
      ;;
  esac
fi

[ -f "$RESOLVED_SOURCE_PATH" ] || fail "源配置文件不存在：$RESOLVED_SOURCE_PATH"

SOURCE_BASENAME="$(basename "$RESOLVED_SOURCE_PATH")"
validate_source_name_matches_level "$SOURCE_BASENAME" "$LEVEL" || fail "源配置文件与作用域 $LEVEL 不匹配：$SOURCE_BASENAME"

if [ -n "$TARGET_DIR" ]; then
  RESOLVED_TARGET_DIR="$(expand_path "$TARGET_DIR")"
else
  case "$LEVEL" in
    user)
      RESOLVED_TARGET_DIR="$HOME/.claude"
      ;;
    project|local)
      fail "-p/--dst 对于 project 和 local 级为必填项。"
      ;;
  esac
fi

case "$LEVEL" in
  user|project)
    TARGET_FILE_NAME="settings.json"
    ;;
  local)
    TARGET_FILE_NAME="settings.local.json"
    ;;
esac

TARGET_FILE="$RESOLVED_TARGET_DIR/$TARGET_FILE_NAME"

resolve_python
validate_json_file "$RESOLVED_SOURCE_PATH" || fail "源配置文件不是合法 JSON：$RESOLVED_SOURCE_PATH"

mkdir -p "$RESOLVED_TARGET_DIR"

if [ ! -f "$TARGET_FILE" ]; then
  cp "$RESOLVED_SOURCE_PATH" "$TARGET_FILE"
  printf '[CREATED] %s\n' "$TARGET_FILE"
  exit 0
fi

TARGET_JSON_VALID="no"
if validate_json_file "$TARGET_FILE"; then
  TARGET_JSON_VALID="yes"
fi

CURRENT_MODE="$MODE"
if [ "$MODE" = "ask" ]; then
  if [ "$TARGET_JSON_VALID" = "yes" ]; then
    CURRENT_MODE="$(prompt_existing_file_action "$TARGET_FILE" "yes")"
  else
    printf '目标配置文件不是合法 JSON，合并不可用：%s\n' "$TARGET_FILE" >&2
    CURRENT_MODE="$(prompt_existing_file_action "$TARGET_FILE" "no")"
  fi
fi

case "$CURRENT_MODE" in
  overwrite)
    backup_target_file "$TARGET_FILE"
    cp "$RESOLVED_SOURCE_PATH" "$TARGET_FILE"
    printf '[OVERWRITE] %s\n' "$TARGET_FILE"
    ;;
  merge)
    [ "$TARGET_JSON_VALID" = "yes" ] || fail "目标配置文件不是合法 JSON，无法合并：$TARGET_FILE"
    TMP_MERGED_FILE="$(create_temp_file "$RESOLVED_TARGET_DIR")"
    trap 'rm -f "$TMP_MERGED_FILE"' EXIT HUP INT TERM
    merge_json_files "$RESOLVED_SOURCE_PATH" "$TARGET_FILE" "$TMP_MERGED_FILE" || fail "settings JSON 合并失败"
    backup_target_file "$TARGET_FILE"
    cp "$TMP_MERGED_FILE" "$TARGET_FILE"
    rm -f "$TMP_MERGED_FILE"
    trap - EXIT HUP INT TERM
    printf '[MERGE] %s\n' "$TARGET_FILE"
    ;;
  skip)
    printf '[SKIP] %s\n' "$TARGET_FILE"
    ;;
  *)
    fail "不支持的操作：$CURRENT_MODE"
    ;;
esac

printf '配置安装完成。\n'