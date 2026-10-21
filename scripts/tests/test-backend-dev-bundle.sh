#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
BUNDLE="$REPO_ROOT/dot_claude_projects/.claude-backend-dev"
HOOK="$BUNDLE/.claude/hooks/go-fmt.sh"
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

# Every rule must be path-scoped: an unscoped rule loads in every session.
test_rules_have_paths() {
  count=0
  for rule in $(find "$BUNDLE/.claude/rules" -type f -name '*.md'); do
    count=$((count + 1))
    [ "$(sed -n 1p "$rule")" = "---" ] || fail "rule has no frontmatter: $rule"
    sed -n '2,/^---$/p' "$rule" | grep -q '^paths:' || fail "rule has no paths: $rule"
  done
  [ "$count" -gt 0 ] || fail "expected rules under $BUNDLE/.claude/rules"
  pass "all $count backend rules declare paths"
}

test_settings_are_backend_only() {
  for file in "$REPO_ROOT/settings/settings.project-backend-dev.json" "$BUNDLE/.claude/settings.json"; do
    python3 -m json.tool "$file" > /dev/null || fail "invalid JSON: $file"
    if grep -q 'typescript' "$file"; then
      fail "backend settings should not enable TypeScript tooling: $file"
    fi
    grep -q '.claude/hooks/go-fmt.sh' "$file" || fail "expected go-fmt hook in $file"
  done
  [ -x "$HOOK" ] || fail "expected executable hook: $HOOK"
  pass "backend settings drop frontend tooling and register the go-fmt hook"
}

run_hook() {
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1" | sh "$HOOK"
}

test_hook_formats_go_files() {
  command -v gofmt > /dev/null 2>&1 || { printf 'SKIP: gofmt not installed\n'; return 0; }

  printf 'package main\nfunc  main( ) {}\n' > "$TMP_DIR/ok.go"
  run_hook "$TMP_DIR/ok.go" || fail "hook should succeed on valid Go"
  grep -q '^func main() {}$' "$TMP_DIR/ok.go" || fail "hook did not format $TMP_DIR/ok.go"

  printf 'package main\nfunc main( {\n' > "$TMP_DIR/bad.go"
  set +e
  run_hook "$TMP_DIR/bad.go" 2> "$TMP_DIR/bad.err"
  rc=$?
  set -e
  [ "$rc" -eq 2 ] || fail "hook should exit 2 on syntax errors, got $rc"
  grep -q 'bad.go' "$TMP_DIR/bad.err" || fail "hook should report the failing file"

  printf 'not go\n' > "$TMP_DIR/notes.md"
  run_hook "$TMP_DIR/notes.md" || fail "hook should ignore non-Go files"
  run_hook "$TMP_DIR/missing.go" || fail "hook should ignore missing files"
  pass "go-fmt hook formats Go, reports syntax errors, and ignores other files"
}

test_bundle_install_keeps_hook_executable() {
  project="$TMP_DIR/project"
  mkdir -p "$project"
  sh "$REPO_ROOT/scripts/install-claude-project.sh" -f backend-dev -t "$project" -N > "$TMP_DIR/install.log"

  [ -x "$project/.claude/hooks/go-fmt.sh" ] || fail "installed hook is not executable"
  for rule in go/layering.md go/concurrency.md database/mysql.md database/mongodb.md redis.md mq/kafka.md mq/rabbitmq.md rpc/proto.md rpc/grpc-go.md; do
    [ -f "$project/.claude/rules/$rule" ] || fail "rule was not installed: $rule"
  done
  for skill in go-new-module db-schema-design cache-design mq-design rpc-design system-design-doc go-perf-diagnose; do
    [ -f "$project/.claude/skills/$skill/SKILL.md" ] || fail "skill was not installed: $skill"
  done
  [ -f "$project/.claude/skills/db-schema-design/references/mysql.md" ] || fail "skill references were not installed"
  pass "installing the bundle copies rules, skills, and an executable hook"
}

test_rules_have_paths
test_settings_are_backend_only
test_hook_formats_go_files
test_bundle_install_keeps_hook_executable
