#!/bin/sh
# codex.sh - 把本仓库的个人差异规则同步到 Codex 的用户级 AGENTS.md
#
# 功能：
#   把 templates/AGENTS.codex-user.md 写入 ${CODEX_HOME:-~/.codex}/AGENTS.md 的标记区块：
#     <!-- agent-prompt-rules -->
#     ...模板内容...
#     <!-- /agent-prompt-rules -->
#   - AGENTS.md 不存在时创建；存在时只更新标记区块，区块外的内容原样保留
#   - 没有区块时追加到文件末尾；内容没有变化时不写入
#   - 每次修改已有文件前先备份为 AGENTS.md.bak.<时间戳>
#   - 标记缺失或重复（区块损坏）时报错退出；-F 时先删除所有标记区块再追加新区块
#
# 模板对应 dot_claude/CLAUDE.md 的差异规则，按 Codex 调整：加回复语言（Claude 由
# settings.json 的 language 设定）、去掉 LSP、工具名改为通用说法。修改 CLAUDE.md 时
# 需同步模板。
#
# 项目级不由本脚本处理：场景约定用 install-claude-project.sh 安装的 CLAUDE.md
# （配合 Codex 的 project_doc_fallback_filenames）或 install-claude-md.sh -n AGENTS.md；
# skill 用 install-skill-pkg.sh 安装到 .agents/skills。详见本目录 README.md。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/templates/AGENTS.codex-user.md"
BEGIN_MARK='<!-- agent-prompt-rules -->'
END_MARK='<!-- /agent-prompt-rules -->'

usage() {
  cat <<'USAGE'
用法：
  sh scripts/multi_client_support/codex.sh [-d] [-F]

目标：
  ${CODEX_HOME:-$HOME/.codex}/AGENTS.md（Codex 用户级指令文件，目录不存在时自动创建）

选项（均可选）：
  -d   预演：只打印将执行的操作和区块内容，不写入、不备份
  -F   区块损坏（标记缺失、重复或顺序颠倒）时强制重建：先备份，再删除所有标记区块，
       最后在文件末尾追加新区块。区块正常时 -F 不改变行为
  -h   显示此帮助信息

写入规则：
  - 文件不存在：创建，只含标记区块
  - 文件存在、没有区块：备份后在末尾追加区块
  - 文件存在、区块正常：内容相同则不写入（[UNCHANGED]）；不同则备份后替换区块
  - 区块外的内容（例如本机专属的 Homebrew、curl 规则）一律保留

已移除的选项：
  -l、-p、-n、-v（项目级与 dot_claude/ 内嵌）。项目级请改用：
    sh scripts/install-claude-project.sh -f <FLAG> -t <project>   # 安装场景 CLAUDE.md
    sh scripts/install-claude-md.sh -f <FLAG> -t <project> -n AGENTS.md
    sh scripts/install-skill-pkg.sh -f <FLAG> -t <project>/.agents/skills

示例：
  # 预演：查看将写入 ~/.codex/AGENTS.md 的区块
  sh scripts/multi_client_support/codex.sh -d

  # 写入或更新区块（修改前先备份）
  sh scripts/multi_client_support/codex.sh

  # 使用其他 Codex 目录
  CODEX_HOME=~/codex-alt sh scripts/multi_client_support/codex.sh

  # 区块标记被手动改坏时重建
  sh scripts/multi_client_support/codex.sh -F
USAGE
}

fail_usage() {
  printf '错误：%s\n' "$1" >&2
  usage >&2
  exit 1
}

DRY_RUN=0
FORCE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d) DRY_RUN=1 ;;
    -F) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    -l|-p|-n|-v)
      fail_usage "$1 已移除：本脚本只写入用户级 AGENTS.md，项目级见下方「已移除的选项」"
      ;;
    *) fail_usage "未知选项：$1" ;;
  esac
  shift
done

expand_path() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

TARGET_DIR="$(expand_path "${CODEX_HOME:-$HOME/.codex}")"
DEST="$TARGET_DIR/AGENTS.md"

[ -f "$TEMPLATE" ] || { printf '错误：模板不存在：%s\n' "$TEMPLATE" >&2; exit 1; }
if [ -e "$DEST" ] && [ ! -f "$DEST" ]; then
  printf '[MANUAL] 目标已存在但不是普通文件：%s\n' "$DEST" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-agents.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM
BLOCK="$WORK_DIR/block.md"
NEW="$WORK_DIR/AGENTS.md"

{
  printf '%s\n' "$BEGIN_MARK"
  cat "$TEMPLATE"
  printf '%s\n' "$END_MARK"
} > "$BLOCK"

backup_dest() {
  base_path="$DEST.bak.$(date +%Y%m%d-%H%M%S)"
  backup_path="$base_path"
  counter=1
  while [ -e "$backup_path" ]; do
    backup_path="$base_path.$counter"
    counter=$((counter + 1))
  done
  cp "$DEST" "$backup_path"
  printf '[BACKUP] %s\n' "$backup_path"
}

# Copies $1 to $NEW and appends the block after a blank line.
append_block() {
  cp "$1" "$NEW"
  if [ -s "$NEW" ]; then
    # Terminate a last line that lacks a newline, then leave one blank line.
    [ "$(tail -c 1 "$NEW" | wc -l)" -eq 1 ] || printf '\n' >> "$NEW"
    printf '\n' >> "$NEW"
  fi
  cat "$BLOCK" >> "$NEW"
}

# Writes $NEW to $DEST, backing up an existing file first.
commit() {
  action="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] %s %s，区块内容：\n' "$action" "$DEST"
    cat "$BLOCK"
    return 0
  fi
  mkdir -p "$TARGET_DIR"
  [ ! -f "$DEST" ] || backup_dest
  cp "$NEW" "$DEST"
  printf '[%s] %s\n' "$action" "$DEST"
}

if [ ! -f "$DEST" ]; then
  cp "$BLOCK" "$NEW"
  commit CREATED
  exit 0
fi

begin_count="$(grep -c -x -F -e "$BEGIN_MARK" "$DEST" || true)"
end_count="$(grep -c -x -F -e "$END_MARK" "$DEST" || true)"
begin_line="$(grep -n -x -F -e "$BEGIN_MARK" "$DEST" | head -n 1 | cut -d: -f1)"
end_line="$(grep -n -x -F -e "$END_MARK" "$DEST" | head -n 1 | cut -d: -f1)"

if [ "$begin_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
  append_block "$DEST"
  commit APPENDED
elif [ "$begin_count" -eq 1 ] && [ "$end_count" -eq 1 ] && [ "$begin_line" -lt "$end_line" ]; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v blk="$BLOCK" '
    $0 == b { while ((getline line < blk) > 0) print line; skip = 1; next }
    skip && $0 == e { skip = 0; next }
    !skip { print }
  ' "$DEST" > "$NEW"
  if cmp -s "$NEW" "$DEST"; then
    printf '[UNCHANGED] %s\n' "$DEST"
    exit 0
  fi
  commit UPDATED
elif [ "$FORCE" -eq 1 ]; then
  # Drop every marked region (an unclosed one runs to the end of the file)
  # and stray end markers, then append a fresh block.
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { print }
  ' "$DEST" > "$WORK_DIR/stripped.md"
  append_block "$WORK_DIR/stripped.md"
  commit REBUILT
else
  printf '[BROKEN] 标记区块损坏（开始标记 %s 个、结束标记 %s 个）：%s\n' "$begin_count" "$end_count" "$DEST" >&2
  printf '请手动修复标记，或加 -F 重建（会先备份；未闭合的区块会删到文件末尾）。\n' >&2
  exit 1
fi
