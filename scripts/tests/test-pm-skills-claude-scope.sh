#!/bin/sh
# Checks ost_phuryn_pm-skills --client=claude-code scope handling with a stub
# `claude` on PATH, so the real Claude Code configuration is never touched.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/open_supports/ost_phuryn_pm-skills/scripts_for_install/install.sh"
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

# Stub: logs "cwd | args" and, for a project-scope install, enables the plugin
# in ./.claude/settings.json like the real command does.
mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/claude" <<'EOF'
#!/bin/sh
printf '%s | %s\n' "$(pwd -P)" "$*" >> "$CLAUDE_STUB_LOG"
if [ "$1 $2" = "plugin install" ]; then
  case " $* " in
    *" --scope project "*)
      mkdir -p .claude
      printf '{"enabledPlugins": {"%s": true}}\n' "$3" > .claude/settings.json
      ;;
  esac
fi
exit 0
EOF
chmod +x "$TMP_DIR/bin/claude"
PATH="$TMP_DIR/bin:$PATH"
export PATH

test_local_installs_to_project_scope() {
  project="$TMP_DIR/my project"
  mkdir -p "$project"
  CLAUDE_STUB_LOG="$TMP_DIR/local.log"
  export CLAUDE_STUB_LOG
  caller_dir="$(pwd -P)"

  sh "$INSTALLER" --client=claude-code --location=local --plugins=pm-execution "$project" > "$TMP_DIR/local.out"

  abs_project="$(cd "$project" && pwd -P)"
  assert_contains "$TMP_DIR/local.log" "$abs_project | plugin marketplace add phuryn/pm-skills --scope project"
  assert_contains "$TMP_DIR/local.log" "$abs_project | plugin install pm-execution@pm-skills --scope project"
  assert_contains "$TMP_DIR/local.out" "Verified project plugin: pm-execution"
  assert_contains "$TMP_DIR/local.out" "scope: project"
  [ "$(pwd -P)" = "$caller_dir" ] || fail "installer changed the caller's working directory"

  pass "--location=local installs with --scope project inside the project directory"
}

test_default_stays_user_scope() {
  CLAUDE_STUB_LOG="$TMP_DIR/user.log"
  export CLAUDE_STUB_LOG

  sh "$INSTALLER" --client=claude-code --plugins=pm-execution > "$TMP_DIR/user.out" 2>&1 || true

  assert_contains "$TMP_DIR/user.log" "plugin install pm-execution@pm-skills"
  assert_not_contains "$TMP_DIR/user.log" "--scope project"
  assert_contains "$TMP_DIR/user.out" "scope: user"

  pass "claude-code defaults to user scope like the official command"
}

test_project_dir_requires_local() {
  CLAUDE_STUB_LOG="$TMP_DIR/reject.log"
  export CLAUDE_STUB_LOG
  mkdir -p "$TMP_DIR/app"

  for scope_arg in "" "--location=global"; do
    # shellcheck disable=SC2086
    if sh "$INSTALLER" --client=claude-code $scope_arg "$TMP_DIR/app" > /dev/null 2> "$TMP_DIR/reject.err"; then
      fail "a project directory without --location=local should fail ($scope_arg)"
    fi
    assert_contains "$TMP_DIR/reject.err" "--location=local"
  done
  [ ! -s "$TMP_DIR/reject.log" ] || fail "claude must not run when the arguments are rejected"

  pass "a project directory without --location=local is rejected before running claude"
}

test_local_installs_to_project_scope
test_default_stays_user_scope
test_project_dir_requires_local
