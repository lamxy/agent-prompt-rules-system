#!/bin/sh
# Tests dot_claude/skills/myopensupports/scripts/myopensupports against a fake repo in a temp dir:
# repo location via AGENT_RULES_REPO, INDEX parsing, list, sync/add, install plan, remove plan/apply.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
TOOL="$REPO_ROOT/dot_claude/skills/myopensupports/scripts/myopensupports"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'SKIP: python3 not found\n'
  exit 0
fi

TMP="$(mktemp -d)"; TMP="$(CDPATH= cd -- "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT INT TERM
FAILS=0

fail() { printf 'FAIL: %s\n' "$1"; FAILS=$((FAILS + 1)); }
pass() { printf 'ok   %s\n' "$1"; }
has() { printf '%s\n' "$1" | grep -F -q -- "$2"; }

R="$TMP/repo"; PROJ="$TMP/proj"; OS="$R/open_supports"
mkdir -p "$R/scripts" "$OS/ost_a_one/scripts_for_install" "$OS/ost_g_glob/scripts_for_install" \
  "$OS/ost_o_spec/scripts_for_install" "$OS/ost_x_ex/scripts_for_install" "$OS/ost_GithubName_RepoName_TEMPLATE" "$OS/ost_e_empty" \
  "$R/dot_claude_projects/.claude" "$R/dot_claude_projects/.claude-backend-dev/.claude" \
  "$R/dot_claude_projects/.claude-FLAG-NAME_template/.claude" "$PROJ"
: > "$R/scripts/install-open-supports.sh"
write_index() {
  {
    printf '# idx\n\n## 已收录支持包\n\n'
    printf '| 支持包 | 上游 | 用途 | 分类 | 建议场景 | usage_examples |\n'
    printf '|--------|------|------|------|----------|:-:|\n'
    printf '%s\n' "$@"
    printf '\n## 全局工具\n\n| 工具 | x |\n|---|---|\n| `ost_z_notpkg` | y |\n'
  } > "$OS/INDEX.md"
}
ROW_A='| `ost_a_one` | [a/one](https://github.com/a/one) | 工具一 | D（本地 B） | 主：后端 | ✅ |'
ROW_G='| `ost_g_glob` | [g/glob](https://github.com/g/glob) | 全域工具 | D（本地 B） | **全局** | ✅ |'
ROW_O='| `ost_o_spec` | [o/spec](https://github.com/o/spec) | 規格 | A（项目初始化 B） | 主：后端 | ✅ |'
ROW_E='| `ost_e_empty` | [e/empty](https://github.com/e/empty) | 空包 | D | 暂不启用（由全局插件承担） | — |'
ROW_X='| `ost_x_ex` | [x/ex](https://github.com/x/ex) | 示例包 | D（本地 B） | 不直接安装，已挑选到 `agents/` | ✅ |'
write_index "$ROW_A" "$ROW_G" "$ROW_O" "$ROW_E" "$ROW_X" '| 壞格式 |'
cat > "$OS/ost_a_one/scripts_for_install/install.sh" <<'EOF'
#!/bin/sh
# 用法：
#   ./install.sh [OPTIONS] [TARGET_DIR]
#
# 选项：
#   --target=X   目標
#
# 示例：
#   ./install.sh --location=global
#   ./install.sh --target=codex /work/app
#   ./install.sh --target=claude /work/app   # 項目級
#
# 说明：
#   - 不卸載
set -eu
EOF
cp "$OS/ost_a_one/scripts_for_install/install.sh" "$OS/ost_x_ex/scripts_for_install/install.sh"
cat > "$OS/ost_g_glob/scripts_for_install/install.sh" <<'EOF'
#!/bin/sh
# 用法：
#   ./install.sh [OPTIONS]
# 示例：
#   ./install.sh --team=optional /path/to/project
#   ./install.sh --host=codex
# =====
EOF
cat > "$OS/ost_o_spec/scripts_for_install/install.sh" <<'EOF'
#!/bin/sh
# 用法：
#   ./install.sh
EOF
printf '# s\n- 卸载：`one uninstall`\n' > "$OS/ost_a_one/repo_readme_summary.md"
printf '# s\n無\n' > "$OS/ost_o_spec/repo_readme_summary.md"
printf '# global\ng/glob --global\n' > "$R/dot_claude_projects/.claude/open_supports_name_list.txt"
printf '# backend\n# 次場景：\n# a/one --target=codex {PROJECT_DIR}\no/spec --init-project {PROJECT_DIR}\n' \
  > "$R/dot_claude_projects/.claude-backend-dev/.claude/open_supports_name_list.txt"
printf 'e/empty --x {PROJECT_DIR}\n' > "$R/dot_claude_projects/.claude-FLAG-NAME_template/.claude/open_supports_name_list.txt"

run() {
  AGENT_RULES_REPO="$R" MYOPENSUPPORTS_HOME="$TMP/home" MYOPENSUPPORTS_PROJECT_DIR="$PROJ" \
    CLAUDE_PROJECT_DIR= python3 "$TOOL" "$@"
}
run_rc() { set +e; OUT="$(run "$@" 2>&1)"; RC=$?; set -e; }

# --- repo location ---
set +e
OUT="$(AGENT_RULES_REPO= MYOPENSUPPORTS_HOME="$TMP/home" python3 "$TOOL" list 2>&1)"; RC=$?
set -e
[ "$RC" = 2 ] && has "$OUT" '未設定' && has "$OUT" 'export AGENT_RULES_REPO' \
  && pass "empty AGENT_RULES_REPO errors with setup hint" || fail "empty env: rc=$RC $OUT"
set +e
OUT="$(env -u AGENT_RULES_REPO MYOPENSUPPORTS_HOME="$TMP/home" python3 "$TOOL" list 2>&1)"; RC=$?
set -e
[ "$RC" = 2 ] && has "$OUT" '未設定' && pass "unset AGENT_RULES_REPO errors" || fail "unset env: $OUT"
set +e
OUT="$(AGENT_RULES_REPO="$TMP" MYOPENSUPPORTS_HOME="$TMP/home" python3 "$TOOL" list 2>&1)"; RC=$?
set -e
[ "$RC" = 2 ] && has "$OUT" '不是本倉庫' && pass "wrong repo path errors" || fail "wrong path: $OUT"
[ ! -e "$TMP/home/catalog.json" ] && pass "no catalog written on repo error" || fail "catalog written on error"

# --- list ---
mkdir -p "$PROJ/.claude/open_supports/ost_a_one"
OUT="$(AGENT_RULES_REPO="$R/" MYOPENSUPPORTS_HOME="$TMP/home" MYOPENSUPPORTS_PROJECT_DIR="$PROJ" python3 "$TOOL" list 2>&1)"
has "$OUT" ' 1. ost_a_one' && pass "trailing slash repo path works; list numbers packages" || fail "list: $OUT"
has "$OUT" 'TEMPLATE' && fail "template listed" || pass "template excluded"
has "$OUT" 'ost_z_notpkg' && fail "row from other table listed" || pass "only the packages table is parsed"
has "$OUT" '注意：INDEX' && pass "malformed row noted" || fail "no malformed note: $OUT"
[ -f "$TMP/home/catalog.json" ] && pass "catalog seeded" || fail "catalog not seeded"
printf '%s\n' "$OUT" | grep -q 'ost_a_one.*已安裝' && pass "installed project package marked" || fail "installed mark: $OUT"
printf '%s\n' "$OUT" | grep -q 'ost_g_glob.*全域（未偵測）' && pass "global-only package marked" || fail "global mark: $OUT"
printf '%s\n' "$OUT" | grep -q 'ost_o_spec.*未安裝' && pass "not installed marked" || fail "not installed: $OUT"
printf '%s\n' "$OUT" | grep -q 'ost_e_empty.*〔不啟用〕' && printf '%s\n' "$OUT" | grep -q 'ost_x_ex.*〔手動挑選〕' \
  && ! printf '%s\n' "$OUT" | grep -q 'ost_o_spec.*〔' && pass "list marks 不啟用 / 手動挑選" || fail "advisory marks: $OUT"

# --- install ---
run_rc install 1
[ "$RC" = 0 ] && has "$OUT" "-t $PROJ -n ost_a_one -- --target=codex '{PROJECT_DIR}'" && has "$OUT" 'backend-dev（註解行' \
  && pass "install: commented scene line used as default" || fail "install 1: $OUT"
has "$OUT" "-n ost_a_one --dry-run -- --target=codex" && pass "install: dry-run command shown" || fail "no dry-run: $OUT"
has "$OUT" '用法' && has "$OUT" './install.sh --location=global' && pass "install: usage/examples copied" || fail "usage: $OUT"
has "$OUT" '不卸載' && fail "install help leaked 说明 section" || pass "install help stops before 说明"
run_rc install x/ex
has "$OUT" '取自安裝腳本示例' && has "$OUT" "-t $PROJ -n ost_x_ex -- --target=claude '{PROJECT_DIR}'" \
  && has "$OUT" '注意：ost_x_ex 在 INDEX 標為手動挑選' && pass "install: default from script example with path replaced, 手動挑選 note" || fail "x/ex: $OUT"
run_rc install e/empty
has "$OUT" '注意：ost_e_empty 在 INDEX 標為不啟用' && pass "install: 不啟用 note" || fail "e/empty note: $OUT"
run_rc install ost_o_spec
has "$OUT" "-t $PROJ -n ost_o_spec -- --init-project '{PROJECT_DIR}'" && has "$OUT" 'backend-dev' \
  && pass "install: class A with project args uses -t from scene list" || fail "o/spec: $OUT"
run_rc install g/glob
has "$OUT" '-g -n ost_g_glob -- --global' && has "$OUT" '作用於所有專案' \
  && pass "install: global-only uses global list and -g" || fail "glob: $OUT"
run_rc install 1 -- --target=cursor '{PROJECT_DIR}'
has "$OUT" "-n ost_a_one -- --target=cursor '{PROJECT_DIR}'" && has "$OUT" '自訂參數' \
  && pass "install: custom args" || fail "custom: $OUT"
run_rc install 1 -- '--x=a b'
[ "$RC" = 2 ] && has "$OUT" '空格' && pass "install: args with spaces rejected" || fail "space: rc=$RC $OUT"
run_rc install g/glob -- --localhost=1
has "$OUT" '-g -n ost_g_glob -- --localhost=1' && pass "install: --localhost is not project-level" || fail "localhost: $OUT"
run_rc install 1 -- --target=claude
has "$OUT" '注意：參數沒有 {PROJECT_DIR}' && pass "install: warns when project arg missing" || fail "no PROJECT_DIR note: $OUT"
run_rc install 1 -- '--x=$(id)'
has "$OUT" "'--x=\$(id)'" && pass "install: custom args shell-quoted" || fail "quote: $OUT"
mkdir -p "$TMP/my proj"
OUT="$(AGENT_RULES_REPO="$R" MYOPENSUPPORTS_HOME="$TMP/home" python3 "$TOOL" install 1 --target "$TMP/my proj" 2>&1)"
has "$OUT" "-t '$TMP/my proj' -n" && pass "install: project path with space quoted" || fail "space path: $OUT"
run_rc install 99
[ "$RC" = 2 ] && has "$OUT" '錯誤：' && pass "install: bad number rejected" || fail "99: rc=$RC $OUT"
run_rc install e/empty
has "$OUT" '無預設參數' && has "$OUT" '找不到安裝腳本' && ! has "$OUT" '作用於所有專案' && ! has "$OUT" '完整命令' \
  && pass "install: no defaults, template list ignored, 全局 mid-text not global-only" || fail "empty: $OUT"

# --- remove ---
mkdir -p "$PROJ/.claude/skills/ost_a_one_install"
printf 'x\n' > "$PROJ/.claude/open_supports/ost_a_one/x"
printf '<!-- generated by scripts/install-open-supports.sh; delete this line to keep manual edits -->\n# s\n' \
  > "$PROJ/.claude/skills/ost_a_one_install/SKILL.md"
printf 'a/one --target=claude {PROJECT_DIR}\n' > "$PROJ/.claude/open_supports_name_list.txt"
run_rc remove 1
has "$OUT" '.claude/open_supports/ost_a_one' && has "$OUT" '.claude/skills/ost_a_one_install' \
  && has "$OUT" 'remove-apply ost_a_one' && has "$OUT" 'one uninstall' && has "$OUT" '注意：' \
  && pass "remove: plan lists paths, apply command, uninstall note, list note" || fail "remove plan: $OUT"
[ -f "$PROJ/.claude/open_supports/ost_a_one/x" ] && pass "remove: plan does not delete" || fail "plan deleted files"
run_rc remove 1 --apply
[ "$RC" = 2 ] && has "$OUT" 'remove-apply' && pass "remove --apply rejected (use remove-apply)" || fail "remove --apply: $OUT"
ln -s "$TMP/nowhere" "$PROJ/.claude/open_supports/ost_a_one/broken-link"
run_rc remove-apply 1
bk="$(ls -d "$PROJ"/.claude/open_supports.backup-* 2>/dev/null | head -1)"
[ "$RC" = 0 ] && [ -n "$bk" ] && [ -f "$bk/packages/ost_a_one/x" ] && [ -L "$bk/packages/ost_a_one/broken-link" ] \
  && [ -f "$bk/skills/ost_a_one_install/SKILL.md" ] \
  && [ ! -e "$PROJ/.claude/open_supports/ost_a_one" ] && [ ! -e "$PROJ/.claude/skills/ost_a_one_install" ] \
  && pass "remove-apply moves to backup (layout like -F, keeps broken symlink)" || fail "apply: rc=$RC $OUT"
rm -rf "$PROJ"/.claude/open_supports.backup-*
mkdir -p "$PROJ/.claude/open_supports/ost_a_one" "$PROJ/.claude/skills/ost_a_one_install"
printf '# manual\n' > "$PROJ/.claude/skills/ost_a_one_install/SKILL.md"
run_rc remove-apply 1
[ -f "$PROJ/.claude/skills/ost_a_one_install/SKILL.md" ] && [ ! -e "$PROJ/.claude/open_supports/ost_a_one" ] \
  && has "$OUT" '手動維護' && pass "remove: manual wrapper kept" || fail "manual wrapper: $OUT"
rm -rf "$PROJ"/.claude/open_supports.backup-*
run_rc remove 1
has "$OUT" '沒有可刪除的檔案' && ! has "$OUT" '將刪除' && pass "remove: only kept items, no delete header" || fail "kept only: $OUT"
rm -rf "$PROJ"/.claude/open_supports.backup-*
run_rc remove-apply ost_o_spec
has "$OUT" '目標專案未安裝' && has "$OUT" '支持包文件未記載卸載方式' \
  && [ -z "$(ls -d "$PROJ"/.claude/open_supports.backup-* 2>/dev/null)" ] \
  && pass "remove: not installed, no backup dir, no uninstall doc" || fail "not installed: $OUT"

# --- sync / add ---
rm -rf "$OS/ost_a_one"; mkdir -p "$OS/ost_n_new" "$OS/ost_u_unidx"
write_index "$ROW_G" "$ROW_O" "$ROW_E" '| `ost_n_new` | [n/new](https://github.com/n/new) | 新包 | D | 主：前端 | ✅ |'
run_rc list
has "$OUT" '注意：倉庫有 1 個新支持包' && printf '%s\n' "$OUT" | grep -q 'ost_a_one.*倉庫已無' \
  && pass "list notes new package and removed package" || fail "list after change: $OUT"
before="$(cat "$TMP/home/catalog.json")"
run_rc sync --dry-run
has "$OUT" '新增 1' && has "$OUT" '移除 1' && [ "$before" = "$(cat "$TMP/home/catalog.json")" ] \
  && pass "sync --dry-run reports without writing" || fail "sync dry: $OUT"
run_rc sync
grep -q ost_n_new "$TMP/home/catalog.json" && ! grep -q ost_a_one "$TMP/home/catalog.json" \
  && pass "sync adds new and removes gone" || fail "sync: $OUT"
run_rc add x/none
[ "$RC" = 2 ] && has "$OUT" '尚未建立該支持包' && pass "add: missing package" || fail "add none: $OUT"
run_rc add u/unidx
[ "$RC" = 0 ] && has "$OUT" '注意：' && grep -q ost_u_unidx "$TMP/home/catalog.json" \
  && pass "add: unindexed dir added with note" || fail "add unidx: $OUT"
run_rc add ost_n_new
has "$OUT" '已在清單' && [ "$(grep -c '"ost_n_new"' "$TMP/home/catalog.json")" = 1 ] \
  && pass "add: duplicate ignored" || fail "add dup: $OUT"
run_rc sync
grep -q ost_u_unidx "$TMP/home/catalog.json" && pass "sync keeps existing unindexed dir" || fail "sync dropped unidx"
write_index "$ROW_G" "$ROW_O" '| `ost_n_new` | [n/new](https://github.com/n/new) | 新包 | D | 主：前端 | ✅ |'
run_rc sync
has "$OUT" '更新 1：ost_e_empty' && python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); p=[x for x in d["packages"] if x["name"]=="ost_e_empty"][0]; sys.exit(0 if p["indexed"] is False else 1)' "$TMP/home/catalog.json" \
  && pass "sync marks package dropped from INDEX as unindexed" || fail "sync unindexed: $OUT"

if [ "$FAILS" -gt 0 ]; then
  printf '%d failure(s)\n' "$FAILS"
  exit 1
fi
printf 'all passed\n'
