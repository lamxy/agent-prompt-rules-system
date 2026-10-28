#!/bin/sh
# Checks dot_claude/skills/myconfig/scripts/catalog: always exits 0 (a failing
# `!` injection aborts the whole skill), prints REPO= first, stays within 30
# lines, hides template FLAGs, and the skill contains no machine-specific paths.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)"
SKILL_DIR="$REPO_ROOT/dot_claude/skills/myconfig"
CATALOG="$SKILL_DIR/scripts/catalog"
TMP_DIR="$(CDPATH= cd -- "$(mktemp -d)" && pwd -P)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT HUP INT TERM

FAILED=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAILED=$((FAILED + 1))
}

# run_catalog <cwd> [env assignments...]; output goes to $TMP_DIR/out, exit code to $TMP_DIR/rc
run_catalog() {
  run_cwd="$1"
  shift
  set +e
  (cd "$run_cwd" && env -u AGENT_RULES_REPO "$@" sh "$CATALOG") > "$TMP_DIR/out" 2>&1
  printf '%s' "$?" > "$TMP_DIR/rc"
  set -e
}

check_ok() {
  label="$1"
  expected_repo="$2"
  rc="$(cat "$TMP_DIR/rc")"
  first="$(head -n 1 "$TMP_DIR/out")"
  lines="$(wc -l < "$TMP_DIR/out" | tr -d ' ')"

  [ "$rc" = 0 ] && pass "$label: exit 0" || fail "$label: exit $rc"
  [ "$first" = "REPO=$expected_repo" ] && pass "$label: first line" || fail "$label: first line is '$first'"
  [ "$lines" -le 30 ] && pass "$label: $lines lines" || fail "$label: $lines lines (> 30)"
}

[ -f "$CATALOG" ] || { printf 'FAIL: missing %s\n' "$CATALOG" >&2; exit 1; }

# 1. cwd outside any repo: located through the script's own path only.
run_catalog "$TMP_DIR"
check_ok "self path" "$REPO_ROOT"
for flag in prd-design frontend-dev backend-dev dev-ops fullstack-dev; do
  grep -q "$flag" "$TMP_DIR/out" && pass "lists $flag" || fail "missing $flag"
done
if grep -q 'FLAG-NAME\|NAME-FLAG' "$TMP_DIR/out"; then
  fail "template FLAG listed"
else
  pass "template FLAGs hidden"
fi

# 1b. Symlinked install under a path with a space: resolves back to the repo.
LINK_HOME="$TMP_DIR/link home"
mkdir -p "$LINK_HOME/.claude/skills"
ln -s "$SKILL_DIR" "$LINK_HOME/.claude/skills/myconfig"
CATALOG="$LINK_HOME/.claude/skills/myconfig/scripts/catalog"
run_catalog "$TMP_DIR"
check_ok "symlink" "$REPO_ROOT"

# 1c. Same under dash when available (Debian /bin/sh); macOS sh is bash in POSIX mode.
if command -v dash > /dev/null 2>&1; then
  set +e
  (cd "$TMP_DIR" && env -u AGENT_RULES_REPO dash "$SKILL_DIR/scripts/catalog") > "$TMP_DIR/out" 2>&1
  printf '%s' "$?" > "$TMP_DIR/rc"
  set -e
  check_ok "dash" "$REPO_ROOT"
fi

# 2. Copied install (no repo above the script), found through AGENT_RULES_REPO.
COPY_HOME="$TMP_DIR/home"
mkdir -p "$COPY_HOME/.claude/skills"
cp -R "$SKILL_DIR" "$COPY_HOME/.claude/skills/myconfig"
CATALOG="$COPY_HOME/.claude/skills/myconfig/scripts/catalog"
run_catalog "$TMP_DIR" AGENT_RULES_REPO="$REPO_ROOT"
check_ok "env var" "$REPO_ROOT"

# 3. Copied install, cwd is the repo: found through the cwd git root.
if git -C "$REPO_ROOT" rev-parse --show-toplevel > /dev/null 2>&1; then
  run_catalog "$REPO_ROOT/scripts"
  check_ok "cwd git root" "$REPO_ROOT"
fi

# 4. Nothing matches: REPO=NOT_FOUND, still exit 0.
run_catalog "$TMP_DIR"
check_ok "not found" "NOT_FOUND"
grep -q 'AGENT_RULES_REPO' "$TMP_DIR/out" && pass "not found: explains env var" || fail "not found: no hint"

# 5. Env var points at a non-repo: falls through to NOT_FOUND, exit 0.
run_catalog "$TMP_DIR" AGENT_RULES_REPO="$TMP_DIR/nope"
check_ok "bad env var" "NOT_FOUND"
grep -q '注意：AGENT_RULES_REPO' "$TMP_DIR/out" && pass "bad env var: note" || fail "bad env var: note missing"

# 6. Repo missing dimension directories: still exit 0.
BROKEN="$TMP_DIR/broken"
mkdir -p "$BROKEN/scripts" "$BROKEN/dot_claude_projects"
: > "$BROKEN/scripts/install-claude-project.sh"
run_catalog "$TMP_DIR" AGENT_RULES_REPO="$BROKEN"
check_ok "broken repo" "$BROKEN"

# 7. The injection must survive an unreadable script (sandbox denyRead aborts the
#    skill on non-zero exit) and match the allowed-tools rule verbatim.
SKILL_MD="$SKILL_DIR/SKILL.md"
allowed="$(sed -n 's/^allowed-tools: Bash(\(.*\))$/\1/p' "$SKILL_MD")"
injected="$(sed -n 's/^!`\(.*\)`$/\1/p' "$SKILL_MD")"
[ -n "$injected" ] && [ "$allowed" = "$injected" ] && pass "allowed-tools matches injection" \
  || fail "allowed-tools '$allowed' != injection '$injected'"
case "$injected" in
  *"|| printf 'REPO=UNREADABLE"*) pass "injection has fallback" ;;
  *) fail "injection lacks || fallback" ;;
esac

# 8. No machine-specific absolute paths inside the skill.
if grep -rn '/Users/\|~/workspace' "$SKILL_DIR"; then
  fail "skill contains machine-specific paths"
else
  pass "no machine-specific paths"
fi

[ "$FAILED" -eq 0 ] || exit 1
