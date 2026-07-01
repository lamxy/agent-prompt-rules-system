#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/multi_client_support/codex.sh"

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
  [ ! -e "$1" ] || fail "expected path to be absent: $1"
}

assert_contains() {
  file="$1"
  pattern="$2"
  if ! grep -F -- "$pattern" "$file" >/dev/null 2>&1; then
    printf '%s\n' "--- $file ---" >&2
    sed -n '1,180p' "$file" >&2
    fail "expected $file to contain: $pattern"
  fi
}

assert_not_contains() {
  file="$1"
  pattern="$2"
  if grep -F -- "$pattern" "$file" >/dev/null 2>&1; then
    printf '%s\n' "--- $file ---" >&2
    sed -n '1,180p' "$file" >&2
    fail "expected $file not to contain: $pattern"
  fi
}

test_user_default_writes_to_codex_home() {
  tmp="$(mktemp -d)"
  CODEX_HOME="$tmp/codex-home" sh "$INSTALLER" -l user > "$tmp/out.log"

  assert_file "$tmp/codex-home/AGENTS.codex.md"
  assert_contains "$tmp/codex-home/AGENTS.codex.md" "Codex Global Instructions"
  assert_contains "$tmp/codex-home/AGENTS.codex.md" ".agent-rules/claude/"
  assert_contains "$tmp/out.log" "[CREATED]"
  pass "user default writes AGENTS.codex.md under CODEX_HOME"
}

test_user_rejects_project_path() {
  tmp="$(mktemp -d)"
  if CODEX_HOME="$tmp/codex-home" sh "$INSTALLER" -l user -p "$tmp/project" > "$tmp/out.log" 2>&1; then
    fail "user target with -p should fail"
  fi

  assert_contains "$tmp/out.log" "-p is only valid with -l project"
  assert_not_exists "$tmp/codex-home/AGENTS.codex.md"
  pass "user target rejects -p"
}

test_project_default_writes_codex_filename() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target"

  sh "$INSTALLER" -l project -p "$target" > "$tmp/out.log"

  assert_file "$target/AGENTS.codex.md"
  assert_contains "$target/AGENTS.codex.md" "Codex Project Instructions"
  assert_contains "$target/AGENTS.codex.md" "Use the smallest sufficient instruction layer."
  assert_not_exists "$target/.agent-rules/claude"
  assert_contains "$tmp/out.log" "[CREATED]"
  pass "project default writes AGENTS.codex.md without vendoring"
}

test_project_custom_name() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target"

  sh "$INSTALLER" -l project -p "$target" -n AGENTS.md > "$tmp/out.log"

  assert_file "$target/AGENTS.md"
  assert_contains "$target/AGENTS.md" "Codex Project Instructions"
  assert_contains "$tmp/out.log" "[CREATED]"
  pass "project custom filename is honored"
}

test_project_vendor_copies_claude_source() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target"

  sh "$INSTALLER" -l project -p "$target" -v > "$tmp/out.log"

  assert_file "$target/AGENTS.codex.md"
  assert_dir "$target/.agent-rules/claude"
  assert_file "$target/.agent-rules/claude/CLAUDE.md"
  assert_dir "$target/.agent-rules/claude/rules"
  assert_dir "$target/.agent-rules/claude/expandable"
  assert_contains "$tmp/out.log" "[VENDORED]"
  pass "project vendor copies .claude source"
}

test_existing_output_without_force_is_manual() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target"
  printf 'existing\n' > "$target/AGENTS.codex.md"

  if sh "$INSTALLER" -l project -p "$target" > "$tmp/out.log" 2>&1; then
    fail "existing output without -F should fail"
  fi

  assert_contains "$target/AGENTS.codex.md" "existing"
  assert_contains "$tmp/out.log" "[MANUAL]"
  pass "existing output without force is not overwritten"
}

test_force_overwrites_output() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target"
  printf 'existing\n' > "$target/AGENTS.codex.md"

  sh "$INSTALLER" -l project -p "$target" -F > "$tmp/out.log"

  assert_contains "$target/AGENTS.codex.md" "Codex Project Instructions"
  assert_not_contains "$target/AGENTS.codex.md" "existing"
  assert_contains "$tmp/out.log" "[FORCE]"
  pass "force overwrites output file"
}

test_existing_vendor_without_force_is_manual() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target/.agent-rules/claude"
  printf 'keep\n' > "$target/.agent-rules/claude/marker.txt"

  if sh "$INSTALLER" -l project -p "$target" -v > "$tmp/out.log" 2>&1; then
    fail "existing vendor without -F should fail"
  fi

  assert_contains "$target/.agent-rules/claude/marker.txt" "keep"
  assert_not_exists "$target/AGENTS.codex.md"
  assert_contains "$tmp/out.log" "[MANUAL]"
  pass "existing vendor without force is not overwritten"
}

test_force_vendor_preserves_extra_files() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target/.agent-rules/claude"
  printf 'keep\n' > "$target/.agent-rules/claude/marker.txt"

  sh "$INSTALLER" -l project -p "$target" -v -F > "$tmp/out.log"

  assert_contains "$target/.agent-rules/claude/marker.txt" "keep"
  assert_file "$target/.agent-rules/claude/CLAUDE.md"
  assert_dir "$target/.agent-rules/claude/rules"
  assert_contains "$tmp/out.log" "[FORCE]"
  assert_contains "$tmp/out.log" "[VENDORED]"
  pass "force vendor copies source and preserves extra files"
}

test_invalid_option_combinations() {
  tmp="$(mktemp -d)"
  target="$tmp/project"
  mkdir -p "$target"

  if sh "$INSTALLER" -l user -v > "$tmp/user-v.log" 2>&1; then
    fail "-v with user should fail"
  fi
  assert_contains "$tmp/user-v.log" "-v is only valid with -l project"

  if sh "$INSTALLER" -l project > "$tmp/project-missing-p.log" 2>&1; then
    fail "project without -p should fail"
  fi
  assert_contains "$tmp/project-missing-p.log" "-p <target_dir> is required when -l project"

  if sh "$INSTALLER" -l project -p "$tmp/missing" > "$tmp/missing-target.log" 2>&1; then
    fail "missing project target should fail"
  fi
  assert_contains "$tmp/missing-target.log" "target directory does not exist"

  pass "invalid option combinations fail clearly"
}

test_user_default_writes_to_codex_home
test_user_rejects_project_path
test_project_default_writes_codex_filename
test_project_custom_name
test_project_vendor_copies_claude_source
test_existing_output_without_force_is_manual
test_force_overwrites_output
test_existing_vendor_without_force_is_manual
test_force_vendor_preserves_extra_files
test_invalid_option_combinations
