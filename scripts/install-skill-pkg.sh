#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-skill-pkg.sh -f <FLAG> -t <target_skills_dir> [-s <skills_root>] [-F]

选项：
  -f  Skill 包标识符（如 frontend-dev → skills-frontend-dev/）
  -t  目标 skills 目录（如 /path/to/project/.claude/skills）
  -s  源 skills 根目录（默认：<repo>/skills）
  -F  强制覆盖：删除同名 skill 目录后重新复制
  -h  显示此帮助信息

示例：
  sh scripts/install-skill-pkg.sh -f frontend-dev -t ~/.claude/skills
  sh scripts/install-skill-pkg.sh -f frontend-dev -t /my/project/.claude/skills -F
USAGE
}

FLAG=""
TARGET=""
SKILLS_ROOT=""
FORCE=0

while getopts "f:t:s:Fh" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    s) SKILLS_ROOT="$OPTARG" ;;
    F) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [ -z "$FLAG" ] || [ -z "$TARGET" ]; then
  printf '错误：-f <FLAG> 和 -t <target_skills_dir> 为必填项。\n' >&2
  usage
  exit 1
fi

if [ -z "$SKILLS_ROOT" ]; then
  SKILLS_ROOT="$REPO_ROOT/skills"
fi

PKG_DIR="$SKILLS_ROOT/skills-$FLAG"

if [ ! -d "$PKG_DIR" ]; then
  printf '错误：Skill 包不存在：%s\n' "$PKG_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf '错误：目标目录不存在：%s\n' "$TARGET" >&2
  exit 1
fi

COPIED=0
SKIPPED=0
FORCED=0

for skill_dir in "$PKG_DIR"/*/; do
  # Skip if no subdirs exist
  [ -d "$skill_dir" ] || continue

  skill_name="$(basename "$skill_dir")"
  dest="$TARGET/$skill_name"

  if [ -d "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] 删除已有目录：%s\n' "$dest"
      rm -rf "$dest"
      cp -r "$skill_dir" "$dest"
      printf '[COPIED] %s\n' "$skill_name"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] Skill 已存在，请手动处理：%s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp -r "$skill_dir" "$dest"
    printf '[COPIED] %s\n' "$skill_name"
    COPIED=$((COPIED + 1))
  fi
done

printf '\nDone. copied=%d  forced=%d  manual=%d\n' "$COPIED" "$FORCED" "$SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  printf '标记为 [MANUAL] 的 Skill 已跳过。请在目标目录中删除或重命名后重新运行；或使用 -F 强制覆盖。\n'
fi
