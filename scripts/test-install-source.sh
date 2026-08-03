#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
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

assert_file "$REPO_ROOT/dot_claude/CLAUDE.md"
assert_not_exists "$REPO_ROOT/.claude"

target="$TMP_DIR/project"
mkdir -p "$target/.claude"
HOME="$TMP_DIR/home" sh "$REPO_ROOT/scripts/install.sh" -l project -p "$target/.claude" -m overwrite
assert_same_file "$REPO_ROOT/dot_claude/CLAUDE.md" "$target/.claude/CLAUDE.md"

codex_target="$TMP_DIR/codex-project"
mkdir -p "$codex_target"
HOME="$TMP_DIR/home" sh "$REPO_ROOT/scripts/multi_client_support/codex.sh" -l project -p "$codex_target" -v
assert_same_file "$REPO_ROOT/dot_claude/CLAUDE.md" "$codex_target/.agent-rules/claude/CLAUDE.md"
assert_dir "$codex_target/.agent-rules/claude/rules"
assert_not_exists "$codex_target/.claude"

printf 'PASS: installers resolve dot_claude source and retain target contracts\n'
