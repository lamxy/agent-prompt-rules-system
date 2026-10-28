#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-settings.sh"
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

assert_contains() {
  grep -F -- "$2" "$1" >/dev/null 2>&1 || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -F -- "$2" "$1" >/dev/null 2>&1; then
    fail "expected $1 not to contain: $2"
  fi
}

count_backups() {
  find "$1" -name "$2.bak.*" | wc -l | tr -d ' '
}

test_all_scenarios_install() {
  for scenario in prd-design frontend-dev backend-dev dev-ops fullstack-dev; do
    target="$TMP_DIR/scenarios/project-$scenario"
    sh "$INSTALLER" -l project -s "$scenario" -m overwrite -p "$target" > /dev/null
    assert_file "$target/settings.json"
  done

  for scenario in prd-design frontend-dev backend-dev dev-ops; do
    target="$TMP_DIR/scenarios/local-$scenario"
    sh "$INSTALLER" -l local -s "$scenario" -m overwrite -p "$target" > /dev/null
    assert_file "$target/settings.local.json"
  done

  HOME="$TMP_DIR/home" sh "$INSTALLER" -l user -m overwrite > /dev/null
  assert_file "$TMP_DIR/home/.claude/settings.json"

  pass "project, local, and user templates install"
}

test_unknown_scenario_lists_available() {
  target="$TMP_DIR/unknown"

  if sh "$INSTALLER" -l project -s product-collab -m overwrite -p "$target" > /dev/null 2> "$TMP_DIR/unknown.err"; then
    fail "removed scenario name should fail"
  fi
  assert_contains "$TMP_DIR/unknown.err" "settings.project-product-collab.json"
  assert_contains "$TMP_DIR/unknown.err" "  prd-design"
  assert_contains "$TMP_DIR/unknown.err" "  fullstack-dev"

  if sh "$INSTALLER" -l local -m overwrite -p "$target" > /dev/null 2> "$TMP_DIR/missing-s.err"; then
    fail "local without -s should fail"
  fi
  assert_contains "$TMP_DIR/missing-s.err" "  dev-ops"
  assert_not_contains "$TMP_DIR/missing-s.err" "fullstack-dev"

  pass "unknown or missing scenario lists available scenarios"
}

test_source_name_must_match_level() {
  source_dir="$TMP_DIR/mismatch-src"
  mkdir -p "$source_dir"
  printf '{}\n' > "$source_dir/settings.local-custom.json"

  if sh "$INSTALLER" -l project --src "$source_dir/settings.local-custom.json" -m overwrite -p "$TMP_DIR/mismatch" > /dev/null 2> "$TMP_DIR/mismatch.err"; then
    fail "local source at project level should fail"
  fi
  assert_contains "$TMP_DIR/mismatch.err" "不匹配"

  pass "source file name must match the level"
}

test_same_second_backups_are_kept() {
  target="$TMP_DIR/backups"
  mkdir -p "$target"
  printf '{"original": true}\n' > "$target/settings.json"

  # The fullstack recipe: overwrite, then merge, usually within one second.
  sh "$INSTALLER" -l project -s frontend-dev -m overwrite -p "$target" > /dev/null
  sh "$INSTALLER" -l project -s backend-dev -m merge -p "$target" > /dev/null

  [ "$(count_backups "$target" settings.json)" -eq 2 ] || fail "expected two backups in $target"
  grep -l '"original"' "$target"/settings.json.bak.* > /dev/null || fail "original settings.json backup was lost"

  pass "consecutive runs keep every backup"
}

test_user_merge_warns_about_ignored_keys() {
  home="$TMP_DIR/merge-home"
  mkdir -p "$home/.claude"
  printf '{"theme": "dark"}\n' > "$home/.claude/settings.json"

  HOME="$home" sh "$INSTALLER" -l user -m merge > "$TMP_DIR/merge.out" 2> "$TMP_DIR/merge.err"

  assert_contains "$TMP_DIR/merge.err" "[WARN]"
  assert_contains "$TMP_DIR/merge.err" "permissions"
  assert_contains "$TMP_DIR/merge.err" "hooks"
  assert_not_contains "$TMP_DIR/merge.err" "enabledPlugins，"
  assert_contains "$home/.claude/settings.json" '"enabledPlugins"'
  assert_contains "$home/.claude/settings.json" '"theme": "dark"'
  assert_not_contains "$home/.claude/settings.json" '"permissions"'

  pass "user-level merge warns about keys it does not write"
}

test_plugin_only_merge_is_quiet() {
  target="$TMP_DIR/quiet"
  mkdir -p "$target"
  printf '{}\n' > "$target/settings.json"

  sh "$INSTALLER" -l project -s frontend-dev -m merge -p "$target" > /dev/null 2> "$TMP_DIR/quiet.err"
  assert_not_contains "$TMP_DIR/quiet.err" "[WARN]"

  pass "merging a plugin-only template prints no warning"
}

test_merge_keeps_format() {
  target="$TMP_DIR/format"
  mkdir -p "$target"
  printf '{"note": "中文说明"}\n' > "$target/settings.json"

  sh "$INSTALLER" -l project -s backend-dev -m merge -p "$target" > /dev/null
  assert_contains "$target/settings.json" '"note": "中文说明"'
  assert_contains "$target/settings.json" '    "enabledPlugins"'

  pass "merge keeps non-ASCII text and four-space indentation"
}

test_merge_carries_skill_overrides_per_key() {
  target="$TMP_DIR/overrides"
  mkdir -p "$target"
  printf '{"skillOverrides": {"gstack-ship": "off", "keep-me": "name-only"}}\n' > "$target/settings.json"

  sh "$INSTALLER" -l project -s dev-ops -m merge -p "$target" > /dev/null 2> "$TMP_DIR/overrides.err"
  assert_contains "$target/settings.json" '"gstack-ship": "on"'
  assert_contains "$target/settings.json" '"keep-me": "name-only"'
  sed -n 's/.*未写入：//p' "$TMP_DIR/overrides.err" > "$TMP_DIR/overrides.ignored"
  assert_not_contains "$TMP_DIR/overrides.ignored" "skillOverrides"

  pass "merge carries skillOverrides key by key"
}

test_ask_without_terminal_fails_loudly() {
  target="$TMP_DIR/ask-fail"
  mkdir -p "$target"
  printf '{}\n' > "$target/settings.json"

  if INSTALL_SETTINGS_TTY="$TMP_DIR/no-such-tty" sh "$INSTALLER" -l project -s frontend-dev -m ask -p "$target" > /dev/null 2> "$TMP_DIR/ask-notty.err"; then
    fail "ask without a terminal should fail"
  fi
  assert_contains "$TMP_DIR/ask-notty.err" "无法从终端读取输入"

  if INSTALL_SETTINGS_TTY=/dev/null sh "$INSTALLER" -l project -s frontend-dev -m ask -p "$target" > /dev/null 2> "$TMP_DIR/ask-eof.err"; then
    fail "ask with no answer should fail"
  fi
  assert_contains "$TMP_DIR/ask-eof.err" "未读取到输入"
  [ "$(count_backups "$target" settings.json)" -eq 0 ] || fail "failed ask should not touch the target"

  pass "ask fails with a message when no answer can be read"
}

test_ask_reads_answers() {
  target="$TMP_DIR/ask-ok"
  mkdir -p "$target"
  printf '{}\n' > "$target/settings.json"

  # An invalid answer is re-prompted; the next line is used.
  printf 'x\ns\n' > "$TMP_DIR/answers-skip"
  INSTALL_SETTINGS_TTY="$TMP_DIR/answers-skip" sh "$INSTALLER" -l project -s frontend-dev -m ask -p "$target" > "$TMP_DIR/ask-skip.out" 2> "$TMP_DIR/ask-skip.err"
  assert_contains "$TMP_DIR/ask-skip.out" "[SKIP]"
  assert_contains "$TMP_DIR/ask-skip.err" "输入无效"

  printf 'm\n' > "$TMP_DIR/answers-merge"
  INSTALL_SETTINGS_TTY="$TMP_DIR/answers-merge" sh "$INSTALLER" -l project -s frontend-dev -m ask -p "$target" > "$TMP_DIR/ask-merge.out" 2>/dev/null
  assert_contains "$TMP_DIR/ask-merge.out" "[MERGE]"
  assert_contains "$target/settings.json" '"enabledPlugins"'

  pass "ask reads answers and re-prompts on invalid input"
}

test_all_scenarios_install
test_unknown_scenario_lists_available
test_source_name_must_match_level
test_same_second_backups_are_kept
test_user_merge_warns_about_ignored_keys
test_plugin_only_merge_is_quiet
test_merge_keeps_format
test_merge_carries_skill_overrides_per_key
test_ask_without_terminal_fails_loudly
test_ask_reads_answers
