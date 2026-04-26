#!/bin/sh
set -eu

usage() {
  printf '%s\n' \
    'Usage:' \
    '  sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]' \
    '' \
    'Options:' \
    '  -l  Settings level:' \
    '      user     Operate on user-level settings' \
    '      project  Operate on shared project settings' \
    '      local    Operate on local project settings' \
    '' \
    '  --src  Optional explicit source settings file path.' \
    '         When provided, -s is ignored.' \
    '' \
    '  -s  Scenario name used to resolve the default source template under ./settings/.' \
    '      Resolution rules:' \
    '      user without -s    -> settings/settings.user.json' \
    '      user with -s foo   -> settings/settings.user-foo.json' \
    '      project with -s foo-> settings/settings.project-foo.json' \
    '      local with -s foo  -> settings/settings.local-foo.json' \
    '' \
    '  -m  Operation mode when target settings already exists:' \
    '      overwrite  Replace the target file after creating a backup' \
    '      merge      Merge enabledPlugins and extraKnownMarketplaces into target' \
    '      ask        Ask whether to overwrite, merge, or skip' \
    '' \
    '  -p, --dst  Exact target directory.' \
    '             Defaults to ~/.claude for user level.' \
    '             Required for project and local levels.' \
    '' \
    '  -h, --help  Show this help message' \
    '' \
    'Notes:' \
    '  - merge only affects enabledPlugins and extraKnownMarketplaces.' \
    '  - Source file names must match the selected level.' \
    '  - Existing target files are backed up before overwrite or merge writes.'
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

  fail "Python 3 is required for JSON validation and merge operations."
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
    raise SystemExit("Source settings JSON must be an object")

if not isinstance(target, dict):
    raise SystemExit("Target settings JSON must be an object")

result = dict(target)

target_plugins = target.get("enabledPlugins") or {}
source_plugins = source.get("enabledPlugins") or {}
if not isinstance(target_plugins, dict):
    raise SystemExit("Target enabledPlugins must be an object")
if not isinstance(source_plugins, dict):
    raise SystemExit("Source enabledPlugins must be an object")

target_marketplaces = target.get("extraKnownMarketplaces") or {}
source_marketplaces = source.get("extraKnownMarketplaces") or {}
if not isinstance(target_marketplaces, dict):
    raise SystemExit("Target extraKnownMarketplaces must be an object")
if not isinstance(source_marketplaces, dict):
    raise SystemExit("Source extraKnownMarketplaces must be an object")

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
    printf 'Target file exists: %s\n' "$target_file" >&2
    if [ "$allow_merge" = "yes" ]; then
      printf 'Choose action: [o]verwrite, [m]erge, [s]kip: ' >&2
    else
      printf 'Choose action: [o]verwrite, [s]kip: ' >&2
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
        printf 'Merge is unavailable because the target settings file is not valid JSON.\n' >&2
        ;;
      s|S|skip|SKIP)
        printf 'skip\n'
        return 0
        ;;
      *)
        if [ "$allow_merge" = "yes" ]; then
          printf 'Invalid choice. Please enter o, m, or s.\n' >&2
        else
          printf 'Invalid choice. Please enter o or s.\n' >&2
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
      [ "$#" -ge 2 ] || fail "-l requires a value."
      LEVEL="$2"
      shift 2
      ;;
    -s)
      [ "$#" -ge 2 ] || fail "-s requires a value."
      SCENARIO="$2"
      shift 2
      ;;
    -m)
      [ "$#" -ge 2 ] || fail "-m requires a value."
      MODE="$2"
      shift 2
      ;;
    -p|--dst)
      [ "$#" -ge 2 ] || fail "$1 requires a value."
      TARGET_DIR="$2"
      shift 2
      ;;
    --src)
      [ "$#" -ge 2 ] || fail "--src requires a value."
      SOURCE_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unsupported argument: $1"
      ;;
  esac
done

[ -n "$LEVEL" ] || fail "-l is required."
[ -n "$MODE" ] || fail "-m is required."

case "$LEVEL" in
  user|project|local)
    ;;
  *)
    fail "invalid level: $LEVEL. Use user, project, or local."
    ;;
esac

case "$MODE" in
  overwrite|merge|ask)
    ;;
  *)
    fail "invalid mode: $MODE. Use overwrite, merge, or ask."
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
      [ -n "$SCENARIO" ] || fail "-s is required for project level when --src is not provided."
      RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.project-$SCENARIO.json"
      ;;
    local)
      [ -n "$SCENARIO" ] || fail "-s is required for local level when --src is not provided."
      RESOLVED_SOURCE_PATH="$DEFAULT_SETTINGS_DIR/settings.local-$SCENARIO.json"
      ;;
  esac
fi

[ -f "$RESOLVED_SOURCE_PATH" ] || fail "source settings file not found: $RESOLVED_SOURCE_PATH"

SOURCE_BASENAME="$(basename "$RESOLVED_SOURCE_PATH")"
validate_source_name_matches_level "$SOURCE_BASENAME" "$LEVEL" || fail "source settings file does not match level $LEVEL: $SOURCE_BASENAME"

if [ -n "$TARGET_DIR" ]; then
  RESOLVED_TARGET_DIR="$(expand_path "$TARGET_DIR")"
else
  case "$LEVEL" in
    user)
      RESOLVED_TARGET_DIR="$HOME/.claude"
      ;;
    project|local)
      fail "-p/--dst is required for project and local levels."
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
validate_json_file "$RESOLVED_SOURCE_PATH" || fail "source settings file is not valid JSON: $RESOLVED_SOURCE_PATH"

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
    printf 'Target settings file is not valid JSON, merge is unavailable: %s\n' "$TARGET_FILE" >&2
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
    [ "$TARGET_JSON_VALID" = "yes" ] || fail "target settings file is not valid JSON, cannot merge: $TARGET_FILE"
    TMP_MERGED_FILE="$(create_temp_file "$RESOLVED_TARGET_DIR")"
    trap 'rm -f "$TMP_MERGED_FILE"' EXIT HUP INT TERM
    merge_json_files "$RESOLVED_SOURCE_PATH" "$TARGET_FILE" "$TMP_MERGED_FILE" || fail "failed to merge settings JSON"
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
    fail "unsupported action: $CURRENT_MODE"
    ;;
esac

printf 'Settings install complete.\n'