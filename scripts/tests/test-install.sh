#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install.sh"
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

assert_dir() {
  [ -d "$1" ] || fail "expected directory: $1"
}

assert_not_exists() {
  [ ! -e "$1" ] && [ ! -L "$1" ] || fail "expected path to be absent: $1"
}

assert_same_file() {
  cmp -s "$1" "$2" || fail "files differ: $1 $2"
}

assert_contains() {
  grep -F -- "$2" "$1" >/dev/null 2>&1 || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -F -- "$2" "$1" >/dev/null 2>&1; then
    fail "expected $1 not to contain: $2"
  fi
}

# Creates a target .claude directory that looks like a pre-2026-10-19 install,
# plus one user-owned rule that must never be treated as legacy.
seed_legacy() {
  mkdir -p "$1/rules/task" "$1/rules/preferences" "$1/expandable/templates" "$1/hooks" "$1/commands"
  printf 'legacy\n' > "$1/rules/task/general-task-rule-min.md"
  printf 'legacy\n' > "$1/rules/preferences/source-verification-min.md"
  printf 'legacy\n' > "$1/expandable/templates/dispatch-template.md"
  printf 'legacy\n' > "$1/hooks/subagent_stop_gate.py"
  printf 'legacy\n' > "$1/commands/auditrules.md"
  printf 'mine\n' > "$1/rules/my-own-rule.md"
}

test_project_skips_settings_and_readme() {
  target="$TMP_DIR/skip/.claude"
  mkdir -p "$target"

  HOME="$TMP_DIR/home" sh "$INSTALLER" -l project -p "$target" -m overwrite > "$TMP_DIR/skip.log"

  assert_file "$target/CLAUDE.md"
  assert_file "$target/commands/analyze-github-repo.md"
  assert_not_exists "$target/settings.json"
  assert_not_exists "$target/README.md"
  assert_contains "$TMP_DIR/skip.log" "[SKIPPED-DEFAULT] settings.json"
  assert_contains "$TMP_DIR/skip.log" "[SKIPPED-DEFAULT] README.md"
  pass "project install skips settings.json and README.md by default"
}

test_project_include_settings_flag() {
  target="$TMP_DIR/include/.claude"
  mkdir -p "$target"

  HOME="$TMP_DIR/home" sh "$INSTALLER" -l project -p "$target" -m overwrite -S > "$TMP_DIR/include.log"

  assert_file "$target/settings.json"
  assert_not_exists "$target/README.md"
  pass "-S installs settings.json at project level"
}

test_user_installs_settings_and_keeps_rtk() {
  home="$TMP_DIR/user-home"
  mkdir -p "$home/.claude"
  printf 'rtk generated\n' > "$home/.claude/RTK.md"

  HOME="$home" sh "$INSTALLER" -l user -m overwrite > "$TMP_DIR/user.log"

  assert_file "$home/.claude/settings.json"
  assert_not_exists "$home/.claude/README.md"
  assert_file "$home/.claude/RTK.md"
  assert_not_contains "$TMP_DIR/user.log" "[LEGACY]"
  pass "user install includes settings.json and does not flag RTK.md as legacy"
}

test_legacy_warns_without_moving() {
  target="$TMP_DIR/warn/.claude"
  seed_legacy "$target"

  HOME="$TMP_DIR/home" sh "$INSTALLER" -l project -p "$target" -m overwrite > "$TMP_DIR/warn.log"

  assert_contains "$TMP_DIR/warn.log" "[LEGACY] $target/rules/task/general-task-rule-min.md"
  assert_contains "$TMP_DIR/warn.log" "[LEGACY] $target/expandable"
  assert_contains "$TMP_DIR/warn.log" "[LEGACY] $target/hooks/subagent_stop_gate.py"
  assert_not_contains "$TMP_DIR/warn.log" "my-own-rule.md"
  assert_contains "$TMP_DIR/warn.log" "同步完成（含警告）"
  assert_file "$target/rules/task/general-task-rule-min.md"
  assert_file "$target/expandable/templates/dispatch-template.md"
  pass "legacy files are reported but left in place without -C"
}

test_legacy_move_with_flag() {
  target="$TMP_DIR/move/.claude"
  seed_legacy "$target"

  HOME="$TMP_DIR/home" sh "$INSTALLER" -l project -p "$target" -m overwrite -C > "$TMP_DIR/move.log"

  backup="$(find "$target" -maxdepth 1 -type d -name 'legacy-backup-*')"
  [ -n "$backup" ] || fail "expected a legacy-backup-* directory under $target"
  assert_file "$backup/rules/task/general-task-rule-min.md"
  assert_file "$backup/rules/preferences/source-verification-min.md"
  assert_file "$backup/expandable/templates/dispatch-template.md"
  assert_file "$backup/hooks/subagent_stop_gate.py"
  assert_file "$backup/commands/auditrules.md"
  assert_not_exists "$target/rules/task"
  assert_not_exists "$target/rules/preferences"
  assert_not_exists "$target/expandable"
  assert_not_exists "$target/hooks"
  assert_not_exists "$target/commands/auditrules.md"
  assert_file "$target/rules/my-own-rule.md"
  assert_file "$target/commands/analyze-github-repo.md"
  assert_contains "$TMP_DIR/move.log" "[LEGACY-MOVED]"
  pass "-C moves legacy files to a backup and keeps user-owned files"
}

test_legacy_reference_warnings() {
  target="$TMP_DIR/refs/.claude"
  mkdir -p "$target"
  printf 'see rules/task/general-task-rule-min.md\n' > "$target/CLAUDE.md"
  printf '{"hooks":{"SubagentStop":"python3 ~/.claude/hooks/subagent_stop_gate.py"}}\n' > "$target/settings.json"

  HOME="$TMP_DIR/home" sh "$INSTALLER" -l project -p "$target" -m append > "$TMP_DIR/refs.log"

  assert_contains "$TMP_DIR/refs.log" "[LEGACY-WARN] $target/CLAUDE.md"
  assert_contains "$TMP_DIR/refs.log" "[LEGACY-WARN] $target/settings.json"
  assert_contains "$target/settings.json" "subagent_stop_gate"
  pass "legacy CLAUDE.md and hook registrations are warned about, not modified"
}

# Both installers must read from dot_claude/, never from a repo-root .claude/
# that a local Claude Code session may have created.
test_installers_resolve_dot_claude_source() {
  target="$TMP_DIR/source/.claude"
  mkdir -p "$target"
  HOME="$TMP_DIR/home" sh "$INSTALLER" -l project -p "$target" -m overwrite > /dev/null
  assert_same_file "$REPO_ROOT/dot_claude/CLAUDE.md" "$target/CLAUDE.md"

  codex_target="$TMP_DIR/codex-project"
  mkdir -p "$codex_target"
  HOME="$TMP_DIR/home" sh "$REPO_ROOT/scripts/multi_client_support/codex.sh" -l project -p "$codex_target" -v > /dev/null
  assert_same_file "$REPO_ROOT/dot_claude/CLAUDE.md" "$codex_target/.agent-rules/claude/CLAUDE.md"
  assert_dir "$codex_target/.agent-rules/claude/commands"
  assert_not_exists "$codex_target/.agent-rules/claude/rules"
  assert_not_exists "$codex_target/.claude"
  pass "install.sh and codex.sh resolve the dot_claude source"
}

test_installers_resolve_dot_claude_source
test_project_skips_settings_and_readme
test_project_include_settings_flag
test_user_installs_settings_and_keeps_rtk
test_legacy_warns_without_moving
test_legacy_move_with_flag
test_legacy_reference_warnings
