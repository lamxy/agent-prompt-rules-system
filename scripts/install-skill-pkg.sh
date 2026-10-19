#!/bin/sh
# install-skill-pkg.sh - 安装 skills/ 下的场景 skill 包
#
# 功能：
#   把 skills/skills-<FLAG>/ 中每个含 SKILL.md 的子目录整体复制到目标 skills 目录。
#   - 包内的 README.md、.gitkeep 等文件不安装；缺少 SKILL.md 的子目录跳过并警告
#   - 目标目录不存在时自动创建
#   - 同名 skill 已存在时默认跳过（[MANUAL]）；-F 时先把旧目录移到
#     <target>.backup-<时间戳>/ 再复制，备份不会被当成 skill 载入
#
# 只安装 skills 这一个维度；整个场景的完整配置见 install-claude-project.sh。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  sh scripts/install-skill-pkg.sh -f <FLAG> -t <target_skills_dir> [-s <skills_root>] [-F]

必选：
  -f <FLAG>   skill 包标识，对应 <skills_root>/skills-<FLAG>/，
              例如 prd-design、frontend-dev、backend-dev、dev-ops、open-supports
  -t <目录>   目标 skills 目录，不存在时自动创建，
              例如 <project>/.claude/skills（项目级）或 ~/.claude/skills（用户级）

可选：
  -s <目录>   源 skills 根目录（默认：<repo>/skills）
  -F          同名 skill 已存在时先备份到 <target>.backup-<时间戳>/ 再覆盖
  -h          显示此帮助信息

说明：
  场景包目前可能只有 README.md 占位，此时脚本提示「此包尚无 skill」并正常结束。

示例：
  # 为项目安装前端场景的 skill
  sh scripts/install-skill-pkg.sh -f frontend-dev -t ~/my-project/.claude/skills

  # 用仓库版本更新已安装的同名 skill（旧目录先备份）
  sh scripts/install-skill-pkg.sh -f frontend-dev -t ~/my-project/.claude/skills -F

  # 把 open_supports 安装 Skill 装到用户级，所有项目可用
  sh scripts/install-skill-pkg.sh -f open-supports -t ~/.claude/skills

  # 从其他 skills 根目录安装
  sh scripts/install-skill-pkg.sh -f my-team -t ~/my-project/.claude/skills -s ~/shared/skills
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

if [ -e "$TARGET" ] && [ ! -d "$TARGET" ]; then
  printf '错误：目标路径不是目录：%s\n' "$TARGET" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  mkdir -p "$TARGET"
  printf '[MKDIR] %s\n' "$TARGET"
fi

TARGET="${TARGET%/}"
BACKUP_DIR=""

# Backups live next to the target, not inside it, so Claude Code does not load
# the old copies as skills.
ensure_backup_dir() {
  [ -z "$BACKUP_DIR" ] || return 0

  base_path="${TARGET}.backup-$(date +%Y%m%d-%H%M%S)"
  BACKUP_DIR="$base_path"
  counter=1
  while [ -e "$BACKUP_DIR" ]; do
    BACKUP_DIR="${base_path}.${counter}"
    counter=$((counter + 1))
  done
  mkdir -p "$BACKUP_DIR"
}

COPIED=0
SKIPPED=0
FORCED=0
INVALID=0

for skill_dir in "$PKG_DIR"/*/; do
  # Skip if no subdirs exist
  [ -d "$skill_dir" ] || continue

  skill_dir="${skill_dir%/}"
  skill_name="$(basename "$skill_dir")"
  dest="$TARGET/$skill_name"

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    printf '[WARN] 缺少 SKILL.md，已跳过：%s\n' "$skill_dir"
    INVALID=$((INVALID + 1))
    continue
  fi

  if [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      ensure_backup_dir
      mv "$dest" "$BACKUP_DIR/$skill_name"
      printf '[BACKUP] %s -> %s\n' "$dest" "$BACKUP_DIR/$skill_name"
      cp -R "$skill_dir" "$dest"
      printf '[COPIED] %s\n' "$skill_name"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] Skill 已存在，请手动处理：%s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp -R "$skill_dir" "$dest"
    printf '[COPIED] %s\n' "$skill_name"
    COPIED=$((COPIED + 1))
  fi
done

printf '\nDone. copied=%d  forced=%d  manual=%d  invalid=%d\n' "$COPIED" "$FORCED" "$SKIPPED" "$INVALID"
if [ $((COPIED + FORCED + SKIPPED + INVALID)) -eq 0 ]; then
  printf '此包尚无 skill（只有占位文件）：%s\n' "$PKG_DIR"
fi
if [ "$SKIPPED" -gt 0 ]; then
  printf '标记为 [MANUAL] 的 Skill 已跳过。请在目标目录中删除或重命名后重新运行；或使用 -F 强制覆盖（旧目录会先备份）。\n'
fi
if [ -n "$BACKUP_DIR" ]; then
  printf '被覆盖的 Skill 已备份到：%s\n' "$BACKUP_DIR"
fi
