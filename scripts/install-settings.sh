#!/bin/sh
# install-settings.sh - 安装 settings/ 下的 Claude Code 设定模板
#
# 功能：
#   按作用域把一份设定模板写入目标目录：
#   - user     settings/settings.user.json         -> ~/.claude/settings.json
#   - project  settings/settings.project-<场景>.json -> <dir>/settings.json
#   - local    settings/settings.local-<场景>.json   -> <dir>/settings.local.json
#   目标不存在时直接创建；已存在时按 -m 覆盖（先备份）、合并插件字段或从终端询问。
#   源文件与已存在的目标都会做 JSON 校验，需要 Python 3（python3、python 或 py）。
#
# 只安装 settings 这一个维度；整个场景的完整配置见 install-claude-project.sh。
set -eu

usage() {
  cat <<'USAGE'
用法：
  sh ./scripts/install-settings.sh -l <user|project|local> -m <overwrite|merge|ask> [-s <场景>] [--src <文件>] [-p <target_dir>]

必选：
  -l <作用域>       user | project | local，决定默认模板与目标文件名：
                      user     -> <target_dir>/settings.json（默认 ~/.claude）
                      project  -> <target_dir>/settings.json
                      local    -> <target_dir>/settings.local.json
  -m <模式>         目标文件已存在时的处理方式（不存在时总是直接创建）：
                      overwrite  备份为 <文件>.bak.<时间戳> 后整体替换
                      merge      只把 enabledPlugins、extraKnownMarketplaces 合并进目标
                                 （先备份）；源文件其他字段不写入，以 [WARN] 列出
                      ask        从终端询问覆盖、合并或跳过；非交互环境报错退出

条件必选：
  -s <场景>         场景名，用来解析 settings/ 下的默认模板：
                      project -s foo -> settings/settings.project-foo.json
                      local   -s foo -> settings/settings.local-foo.json
                      user 不带 -s   -> settings/settings.user.json
                    project / local 未给 --src 时必填；找不到模板时列出可用场景
  -p, --dst <目录>  目标目录（不存在时自动创建，可用 ~ 开头）。
                    project / local 必填；user 默认 ~/.claude

可选：
  --src <文件>      显式指定源模板，提供时忽略 -s。文件名仍须与作用域匹配
                    （settings.user*.json / settings.project-*.json / settings.local-*.json）
  -h, --help        显示此帮助信息

当前可用场景：
  project：prd-design、frontend-dev、backend-dev、dev-ops、fullstack-dev
  local：  prd-design、frontend-dev、backend-dev、dev-ops

注意：
  - 安装完整的用户级设定（含 permissions、hooks、sandbox）请用 overwrite
  - 含 permissions 的项目模板（backend-dev、dev-ops、fullstack-dev）也应使用 overwrite
  - 每次覆盖或合并前都会备份，同一秒内多次执行也不会覆盖之前的备份

示例：
  # 安装推荐的全局基础设定到 ~/.claude（先备份已有设定）
  sh ./scripts/install-settings.sh -l user -m overwrite

  # 只把全局插件与市场合并进已有的 ~/.claude/settings.json
  sh ./scripts/install-settings.sh -l user -m merge

  # 为项目安装后端场景设定（含数据库破坏性命令的 deny 规则）
  sh ./scripts/install-settings.sh -l project -s backend-dev -m overwrite -p ~/my-project/.claude

  # 已有项目设定时，只追加前端场景的插件
  sh ./scripts/install-settings.sh -l project -s frontend-dev -m merge -p ~/my-project/.claude

  # 安装本地级可选插件（写入 settings.local.json），已存在时询问
  sh ./scripts/install-settings.sh -l local -s dev-ops -m ask -p ~/my-project/.claude

  # 使用自定义模板
  sh ./scripts/install-settings.sh -l project --src ~/templates/settings.project-mine.json -m overwrite -p ~/my-project/.claude

  # 场景名写错时会列出可用场景
  sh ./scripts/install-settings.sh -l project -s backend -m overwrite -p ~/my-project/.claude
USAGE
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
    json.dump(result, output_handle, ensure_ascii=False, indent=4)
    output_handle.write("\n")

# Report source keys that merge does not carry over, so the caller can warn.
merged_keys = {"$schema", "enabledPlugins", "extraKnownMarketplaces"}
print(", ".join(key for key in source if key not in merged_keys))
' "$source_file" "$target_file" "$output_file"
}

list_scenarios() {
  level="$1"

  for scenario_file in "$DEFAULT_SETTINGS_DIR"/settings."$level"-*.json; do
    [ -f "$scenario_file" ] || continue
    scenario_name="${scenario_file##*/settings.$level-}"
    printf '  %s\n' "${scenario_name%.json}"
  done
}

fail_with_scenarios() {
  printf 'Error: %s\n' "$1" >&2
  printf '%s 级可用的 -s 场景：\n' "$LEVEL" >&2
  list_scenarios "$LEVEL" >&2
  exit 1
}

unique_path() {
  base_path="$1"
  candidate_path="$base_path"
  counter=1

  while [ -e "$candidate_path" ]; do
    candidate_path="${base_path}.${counter}"
    counter=$((counter + 1))
  done

  printf '%s\n' "$candidate_path"
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

  # Read answers from the terminal, not stdin, so a redirected or closed stdin
  # fails loudly instead of exiting silently. Tests point this at a file.
  prompt_input="${INSTALL_SETTINGS_TTY:-/dev/tty}"
  if ! { : < "$prompt_input"; } 2>/dev/null; then
    printf '无法从终端读取输入（%s）。非交互环境请改用 -m overwrite 或 -m merge。\n' "$prompt_input" >&2
    return 1
  fi

  while true; do
    printf '目标文件已存在：%s\n' "$target_file" >&2
    if [ "$allow_merge" = "yes" ]; then
      printf '选择操作：[o] 覆盖  [m] 合并  [s] 跳过：' >&2
    else
      printf '选择操作：[o] 覆盖  [s] 跳过：' >&2
    fi

    if ! IFS= read -r answer; then
      printf '\n未读取到输入，已取消。\n' >&2
      return 1
    fi
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
  done < "$prompt_input"
}

backup_target_file() {
  target_file="$1"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  # Two runs within the same second must not overwrite the earlier backup.
  backup_path="$(unique_path "${target_file}.bak.${timestamp}")"
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
    fail "无效的作用域：${LEVEL}。请使用 user、project 或 local。"
    ;;
esac

case "$MODE" in
  overwrite|merge|ask)
    ;;
  *)
    fail "无效的模式：${MODE}。请使用 overwrite、merge 或 ask。"
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
      [ -n "$SCENARIO" ] || fail_with_scenarios "未提供 --src 时，project 级必须指定 -s。"
      RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.project-$SCENARIO.json"
      ;;
    local)
      [ -n "$SCENARIO" ] || fail_with_scenarios "未提供 --src 时，local 级必须指定 -s。"
      RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.local-$SCENARIO.json"
      ;;
  esac
fi

if [ ! -f "$RESOLVED_SOURCE_PATH" ]; then
  if [ -n "$SOURCE_PATH" ] || [ -z "$SCENARIO" ]; then
    fail "源配置文件不存在：$RESOLVED_SOURCE_PATH"
  fi
  fail_with_scenarios "源配置文件不存在：$RESOLVED_SOURCE_PATH"
fi

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
    CURRENT_MODE="$(prompt_existing_file_action "$TARGET_FILE" "yes")" || exit 1
  else
    printf '目标配置文件不是合法 JSON，合并不可用：%s\n' "$TARGET_FILE" >&2
    CURRENT_MODE="$(prompt_existing_file_action "$TARGET_FILE" "no")" || exit 1
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
    IGNORED_KEYS="$(merge_json_files "$RESOLVED_SOURCE_PATH" "$TARGET_FILE" "$TMP_MERGED_FILE")" || fail "settings JSON 合并失败"
    backup_target_file "$TARGET_FILE"
    cp "$TMP_MERGED_FILE" "$TARGET_FILE"
    rm -f "$TMP_MERGED_FILE"
    trap - EXIT HUP INT TERM
    printf '[MERGE] %s\n' "$TARGET_FILE"
    if [ -n "$IGNORED_KEYS" ]; then
      printf '[WARN] merge 只合并 enabledPlugins 和 extraKnownMarketplaces，以下源字段未写入：%s\n' "$IGNORED_KEYS" >&2
      printf '[WARN] 需要这些字段时请改用 -m overwrite（会先备份），或手动合并。\n' >&2
    fi
    ;;
  skip)
    printf '[SKIP] %s\n' "$TARGET_FILE"
    ;;
  *)
    fail "不支持的操作：$CURRENT_MODE"
    ;;
esac

printf '配置安装完成。\n'