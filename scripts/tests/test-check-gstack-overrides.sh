#!/bin/sh
# Checks scripts/check-gstack-overrides.sh against fake skills directories.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
CHECKER="$REPO_ROOT/scripts/check-gstack-overrides.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

assert_contains() {
  grep -F -- "$2" "$1" >/dev/null 2>&1 || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -F -- "$2" "$1" >/dev/null 2>&1; then
    fail "expected $1 not to contain: $2"
  fi
}

make_skills() {
  skills="$TMP_DIR/$1/skills"
  shift
  mkdir -p "$skills"
  for name in "$@"; do
    mkdir -p "$skills/$name"
    printf -- '---\nname: %s\n---\n' "$name" > "$skills/$name/SKILL.md"
  done
}

test_reports_uncovered_and_stale() {
  make_skills drift gstack _gstack-command gstack-review gstack-new myhandoff
  printf '{"skillOverrides": {"gstack": "user-invocable-only", "_gstack-command": "user-invocable-only", "gstack-review": "user-invocable-only", "gstack-gone": "off"}}\n' > "$TMP_DIR/drift.json"

  if sh "$CHECKER" -s "$skills" -f "$TMP_DIR/drift.json" > "$TMP_DIR/drift.out" 2>&1; then
    fail "expected exit 1 when overrides drift"
  fi
  assert_contains "$TMP_DIR/drift.out" '"gstack-new": "user-invocable-only"'
  assert_contains "$TMP_DIR/drift.out" "gstack-gone"
  assert_not_contains "$TMP_DIR/drift.out" "myhandoff"
  assert_not_contains "$TMP_DIR/drift.out" '"gstack-review": "user-invocable-only"'

  pass "lists uncovered gstack skills as a JSON snippet and stale keys"
}

test_consistent_overrides_pass() {
  make_skills ok gstack gstack-ship
  printf '{"skillOverrides": {"gstack": "user-invocable-only", "gstack-ship": "on", "claude-api": "user-invocable-only"}}\n' > "$TMP_DIR/ok.json"

  sh "$CHECKER" -s "$skills" -f "$TMP_DIR/ok.json" > "$TMP_DIR/ok.out" 2>&1 || fail "expected exit 0: $(cat "$TMP_DIR/ok.out")"

  pass "consistent overrides exit 0"
}

test_no_gstack_installed() {
  make_skills none myhandoff
  printf '{}\n' > "$TMP_DIR/none.json"

  sh "$CHECKER" -s "$skills" -f "$TMP_DIR/none.json" > "$TMP_DIR/none.out" 2>&1 || fail "expected exit 0 without gstack"
  assert_contains "$TMP_DIR/none.out" "未发现"

  pass "no installed gstack skills is not an error"
}

test_files_are_not_modified() {
  make_skills ro gstack-new
  printf '{"skillOverrides": {}}\n' > "$TMP_DIR/ro.json"
  cp "$TMP_DIR/ro.json" "$TMP_DIR/ro.before"

  sh "$CHECKER" -s "$skills" -f "$TMP_DIR/ro.json" > /dev/null 2>&1 || true
  cmp -s "$TMP_DIR/ro.json" "$TMP_DIR/ro.before" || fail "settings file was modified"

  pass "the checker never writes the settings file"
}

test_reports_uncovered_and_stale
test_consistent_overrides_pass
test_no_gstack_installed
test_files_are_not_modified
