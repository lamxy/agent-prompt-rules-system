#!/bin/sh
# Covers scripts/multi_client_support/codex.sh: the marked block in the
# user-level Codex AGENTS.md. Every case uses a temporary CODEX_HOME.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/multi_client_support/codex.sh"
TEMPLATE="$REPO_ROOT/scripts/multi_client_support/templates/AGENTS.codex-user.md"
BEGIN_MARK='<!-- agent-prompt-rules -->'
END_MARK='<!-- /agent-prompt-rules -->'
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

assert_file() {
  [ -f "$1" ] || fail "expected file: $1"
}

assert_not_exists() {
  [ ! -e "$1" ] || fail "expected path to be absent: $1"
}

assert_contains() {
  if ! grep -F -- "$2" "$1" >/dev/null 2>&1; then
    sed -n '1,80p' "$1" >&2
    fail "expected $1 to contain: $2"
  fi
}

count_lines() {
  grep -c -x -F -e "$2" "$1" || true
}

backups() {
  find "$1" -name 'AGENTS.md.bak.*' | wc -l | tr -d ' '
}

run() {
  home="$1"
  shift
  CODEX_HOME="$home" sh "$INSTALLER" "$@"
}

test_creates_block_in_new_file() {
  home="$TMP_DIR/new"
  run "$home" > "$TMP_DIR/new.log"

  assert_file "$home/AGENTS.md"
  assert_contains "$TMP_DIR/new.log" "[CREATED]"
  [ "$(count_lines "$home/AGENTS.md" "$BEGIN_MARK")" -eq 1 ] || fail "expected one begin marker"
  assert_contains "$home/AGENTS.md" "以繁體中文回覆"
  assert_contains "$home/AGENTS.md" "rtk bypass"
  [ "$(backups "$home")" -eq 0 ] || fail "a new file needs no backup"
  pass "creates AGENTS.md with only the marked block"
}

test_appends_and_keeps_existing_content() {
  home="$TMP_DIR/append"
  mkdir -p "$home"
  printf '# mine\nkeep this line' > "$home/AGENTS.md"

  run "$home" > "$TMP_DIR/append.log"

  assert_contains "$TMP_DIR/append.log" "[APPENDED]"
  assert_contains "$home/AGENTS.md" "keep this line"
  [ "$(sed -n 1p "$home/AGENTS.md")" = "# mine" ] || fail "existing content should stay first"
  [ "$(sed -n 2p "$home/AGENTS.md")" = "keep this line" ] || fail "an unterminated last line should be kept intact"
  [ "$(backups "$home")" -eq 1 ] || fail "expected one backup before appending"
  pass "appends the block after existing content and backs up first"
}

test_update_is_idempotent_and_replaces_only_the_block() {
  home="$TMP_DIR/update"
  mkdir -p "$home"
  printf 'before\n\n%s\nold rules\n%s\n\nafter\n' "$BEGIN_MARK" "$END_MARK" > "$home/AGENTS.md"

  run "$home" > "$TMP_DIR/update.log"
  assert_contains "$TMP_DIR/update.log" "[UPDATED]"
  if grep -F 'old rules' "$home/AGENTS.md" > /dev/null; then
    fail "old block content should be replaced"
  fi
  [ "$(sed -n 1p "$home/AGENTS.md")" = "before" ] || fail "content before the block changed"
  [ "$(tail -n 1 "$home/AGENTS.md")" = "after" ] || fail "content after the block changed"

  run "$home" > "$TMP_DIR/update2.log"
  assert_contains "$TMP_DIR/update2.log" "[UNCHANGED]"
  [ "$(backups "$home")" -eq 1 ] || fail "an unchanged run must not create a backup"
  pass "replaces only the block, then reports [UNCHANGED] without a backup"
}

test_dry_run_writes_nothing() {
  home="$TMP_DIR/dry"
  run "$home" -d > "$TMP_DIR/dry.log"
  assert_contains "$TMP_DIR/dry.log" "[DRY-RUN] CREATED"
  assert_not_exists "$home"

  mkdir -p "$home"
  printf 'mine\n' > "$home/AGENTS.md"
  run "$home" -d > /dev/null
  [ "$(cat "$home/AGENTS.md")" = "mine" ] || fail "dry run changed the file"
  [ "$(backups "$home")" -eq 0 ] || fail "dry run created a backup"
  pass "-d prints the plan without writing or backing up"
}

test_broken_block_needs_force() {
  home="$TMP_DIR/broken"
  mkdir -p "$home"
  printf 'keep\n%s\nhalf\n%s\nstray\n%s\n' "$BEGIN_MARK" "$END_MARK" "$END_MARK" > "$home/AGENTS.md"
  cp "$home/AGENTS.md" "$TMP_DIR/broken.orig"

  if run "$home" > /dev/null 2> "$TMP_DIR/broken.err"; then
    fail "a broken block should fail without -F"
  fi
  assert_contains "$TMP_DIR/broken.err" "[BROKEN]"
  cmp -s "$home/AGENTS.md" "$TMP_DIR/broken.orig" || fail "a failed run changed the file"

  run "$home" -F > "$TMP_DIR/broken.log"
  assert_contains "$TMP_DIR/broken.log" "[REBUILT]"
  assert_contains "$home/AGENTS.md" "keep"
  assert_contains "$home/AGENTS.md" "stray"
  [ "$(count_lines "$home/AGENTS.md" "$BEGIN_MARK")" -eq 1 ] || fail "expected one begin marker after -F"
  [ "$(count_lines "$home/AGENTS.md" "$END_MARK")" -eq 1 ] || fail "expected one end marker after -F"
  [ "$(backups "$home")" -eq 1 ] || fail "-F should back up first"
  pass "a broken block fails without -F and is rebuilt with a backup on -F"
}

test_rejects_removed_options_and_non_file_target() {
  for opt in -l -p -n -v -x; do
    if run "$TMP_DIR/opts" "$opt" > /dev/null 2>&1; then
      fail "expected $opt to be rejected"
    fi
  done
  assert_not_exists "$TMP_DIR/opts"

  mkdir -p "$TMP_DIR/dir-target/AGENTS.md"
  if run "$TMP_DIR/dir-target" > /dev/null 2>&1; then
    fail "a directory named AGENTS.md should be rejected"
  fi
  pass "removed options and a non-file target are rejected"
}

test_template_has_no_claude_only_tools() {
  # Claude-only tool names would mislead Codex; LSP is not available there.
  for word in get_file_contents WebFetch LSP SendMessage .agent-rules; do
    if grep -F -- "$word" "$TEMPLATE" > /dev/null; then
      fail "template should not mention $word"
    fi
  done
  pass "the Codex template carries no Claude-only tool references"
}

test_creates_block_in_new_file
test_appends_and_keeps_existing_content
test_update_is_idempotent_and_replaces_only_the_block
test_dry_run_writes_nothing
test_broken_block_needs_force
test_rejects_removed_options_and_non_file_target
test_template_has_no_claude_only_tools
