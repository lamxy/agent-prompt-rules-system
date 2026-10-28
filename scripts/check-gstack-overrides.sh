#!/bin/sh
# check-gstack-overrides.sh - 检查 gstack skill 是否都已写进 skillOverrides
#
# 功能：
#   比对 skills 目录中已安装的 gstack skill（gstack、_gstack-command、gstack-*）与
#   settings 文件的 skillOverrides，列出：
#   - 未覆盖：新安装或升级新增的 skill，默认为 on（模型可自动调用）；附可直接粘贴的 JSON
#   - 已失效：skillOverrides 中有、但已不存在的 gstack skill
#   只读，不修改任何文件。需要 Python 3。
#
# 处理方式：把未覆盖项补进 settings/settings.user.json，再执行
#   sh scripts/install-settings.sh -l user -m merge -K skillOverrides
set -eu

usage() {
  cat <<'USAGE'
用法：
  sh ./scripts/check-gstack-overrides.sh [-s <skills 目录>] [-f <settings 文件>]

可选：
  -s <目录>   已安装 skill 的目录（默认：~/.claude/skills）
  -f <文件>   要检查的 settings 文件（默认：~/.claude/settings.json，即本机实际生效的设定）
  -h, --help  显示此帮助信息

退出码：0 一致或未安装 gstack；1 有未覆盖或已失效的项；2 参数或文件错误。

示例：
  # gstack 安装或升级后，检查本机设定
  sh ./scripts/check-gstack-overrides.sh

  # 检查仓库的全局模板是否覆盖本机已安装的 gstack skill
  sh ./scripts/check-gstack-overrides.sh -f settings/settings.user.json
USAGE
}

fail() {
  printf '错误：%s\n' "$1" >&2
  exit 2
}

SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s)
      [ "$#" -ge 2 ] || fail "-s 需要一个值。"
      SKILLS_DIR="$2"
      shift 2
      ;;
    -f)
      [ "$#" -ge 2 ] || fail "-f 需要一个值。"
      SETTINGS_FILE="$2"
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

command -v python3 >/dev/null 2>&1 || fail "需要 python3。"
[ -f "$SETTINGS_FILE" ] || fail "settings 文件不存在：$SETTINGS_FILE"

python3 -I - "$SKILLS_DIR" "$SETTINGS_FILE" <<'PY'
import json
import os
import sys

skills_dir, settings_file = sys.argv[1:3]


def is_gstack(name):
    return name in ("gstack", "_gstack-command") or name.startswith("gstack-")


installed = set()
if os.path.isdir(skills_dir):
    for name in os.listdir(skills_dir):
        if is_gstack(name) and os.path.isfile(os.path.join(skills_dir, name, "SKILL.md")):
            installed.add(name)

try:
    with open(settings_file, "r", encoding="utf-8") as handle:
        overrides = json.load(handle).get("skillOverrides") or {}
except (OSError, ValueError) as error:
    print("错误：无法读取 %s：%s" % (settings_file, error), file=sys.stderr)
    sys.exit(2)

if not installed:
    print("未发现已安装的 gstack skill：%s" % skills_dir)
    sys.exit(0)

configured = {name for name in overrides if is_gstack(name)}
uncovered = sorted(installed - configured)
stale = sorted(configured - installed)

print("已安装 gstack skill %d 个，%s 中已设置 %d 个。" % (len(installed), settings_file, len(configured & installed)))
if uncovered:
    print("\n未覆盖（默认 on，模型可自动调用）%d 个，可粘贴进 skillOverrides：" % len(uncovered))
    for name in uncovered:
        print('    "%s": "user-invocable-only",' % name)
if stale:
    print("\n已失效（已不存在）%d 个，可从 skillOverrides 删除：" % len(stale))
    for name in stale:
        print("    %s" % name)
if uncovered or stale:
    print("\n处理：改 settings/settings.user.json 后执行 sh scripts/install-settings.sh -l user -m merge -K skillOverrides")
    sys.exit(1)
print("一致。")
PY
