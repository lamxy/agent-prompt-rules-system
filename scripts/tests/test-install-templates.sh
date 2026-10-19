#!/bin/sh
# Covers install-claude-md.sh, install-dot-mcp.sh, and install-claude-project.sh.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
MD_INSTALLER="$REPO_ROOT/scripts/install-claude-md.sh"
MCP_INSTALLER="$REPO_ROOT/scripts/install-dot-mcp.sh"
PROJECT_INSTALLER="$REPO_ROOT/scripts/install-claude-project.sh"
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
  grep -F -- "$2" "$1" >/dev/null 2>&1 || fail "expected $1 to contain: $2"
}

# Source fixtures: a filled template, an empty one, and an invalid JSON one.
SRC="$TMP_DIR/src"
mkdir -p "$SRC/claude_mds" "$SRC/mcp" "$SRC/projects/.claude-demo/.claude/rules"
printf '# demo v2\n' > "$SRC/claude_mds/CLAUDE-demo.md"
: > "$SRC/claude_mds/CLAUDE-empty.md"
printf '{"mcpServers": {}}\n' > "$SRC/mcp/dot-mcp-json-demo.json"
: > "$SRC/mcp/dot-mcp-json-empty.json"
printf '{"mcpServers": \n' > "$SRC/mcp/dot-mcp-json-broken.json"
printf '# project v2\n' > "$SRC/projects/.claude-demo/CLAUDE.md"
printf '{"mcpServers": {}}\n' > "$SRC/projects/.claude-demo/.mcp.json"
printf 'rule v2\n' > "$SRC/projects/.claude-demo/.claude/rules/demo.md"
: > "$SRC/projects/.claude-demo/.claude/.gitkeep"
: > "$SRC/projects/.claude-demo/.claude/open_supports_name_list.txt"

test_arguments_are_not_evaluated() {
  target="$TMP_DIR/my project"
  mkdir -p "$target"

  sh "$MD_INSTALLER" -f demo -t "$target" -s "$SRC/claude_mds" > /dev/null
  assert_contains "$target/CLAUDE.md" "demo v2"

  sh "$MCP_INSTALLER" -f demo -t "$target" -s "$SRC/mcp" > /dev/null
  assert_file "$target/.mcp.json"

  for installer in "$MD_INSTALLER" "$MCP_INSTALLER" "$PROJECT_INSTALLER"; do
    sh "$installer" -f demo -t "$TMP_DIR/x;touch $TMP_DIR/PWNED" > /dev/null 2>&1 || true
    sh "$installer" -f 'demo$(touch '"$TMP_DIR"'/PWNED2)' -t "$target" > /dev/null 2>&1 || true
  done
  assert_not_exists "$TMP_DIR/PWNED"
  assert_not_exists "$TMP_DIR/PWNED2"

  pass "paths with spaces work and arguments are never evaluated"
}

test_claude_md_skips_empty_and_backs_up() {
  target="$TMP_DIR/md"
  mkdir -p "$target"
  printf 'mine\n' > "$target/CLAUDE.md"

  sh "$MD_INSTALLER" -f empty -t "$target" -s "$SRC/claude_mds" -F > "$TMP_DIR/md-empty.log"
  assert_contains "$TMP_DIR/md-empty.log" "模板尚未填写"
  assert_contains "$target/CLAUDE.md" "mine"

  sh "$MD_INSTALLER" -f demo -t "$target" -s "$SRC/claude_mds" > "$TMP_DIR/md-manual.log"
  assert_contains "$TMP_DIR/md-manual.log" "[MANUAL]"
  assert_contains "$target/CLAUDE.md" "mine"

  sh "$MD_INSTALLER" -f demo -t "$target" -s "$SRC/claude_mds" -F > /dev/null
  sh "$MD_INSTALLER" -f demo -t "$target" -s "$SRC/claude_mds" -F > /dev/null
  assert_contains "$target/CLAUDE.md" "demo v2"
  [ "$(find "$target" -name 'CLAUDE.md.bak.*' | wc -l | tr -d ' ')" -eq 2 ] || fail "expected two CLAUDE.md backups"
  grep -l mine "$target"/CLAUDE.md.bak.* > /dev/null || fail "original CLAUDE.md backup was lost"

  if sh "$MD_INSTALLER" -f demo -t "$target" -n ../escape.md -s "$SRC/claude_mds" > /dev/null 2>&1; then
    fail "-n with a path should fail"
  fi
  assert_not_exists "$TMP_DIR/escape.md"

  pass "CLAUDE.md skips empty templates, backs up on -F, and rejects -n paths"
}

test_dot_mcp_skips_empty_rejects_invalid_and_backs_up() {
  target="$TMP_DIR/mcp"
  mkdir -p "$target"

  sh "$MCP_INSTALLER" -f empty -t "$target" -s "$SRC/mcp" > "$TMP_DIR/mcp-empty.log"
  assert_contains "$TMP_DIR/mcp-empty.log" "模板尚未填写"
  assert_not_exists "$target/.mcp.json"

  if sh "$MCP_INSTALLER" -f broken -t "$target" -s "$SRC/mcp" > /dev/null 2> "$TMP_DIR/mcp-broken.err"; then
    fail "invalid JSON template should fail"
  fi
  assert_contains "$TMP_DIR/mcp-broken.err" "不是合法 JSON"
  assert_not_exists "$target/.mcp.json"

  printf '{"mine": true}\n' > "$target/.mcp.json"
  sh "$MCP_INSTALLER" -f demo -t "$target" -s "$SRC/mcp" -F > /dev/null
  assert_contains "$target/.mcp.json" "mcpServers"
  grep -l mine "$target"/.mcp.json.bak.* > /dev/null || fail "original .mcp.json backup missing"

  pass ".mcp.json skips empty templates, rejects invalid JSON, and backs up on -F"
}

test_project_force_keeps_unrelated_files() {
  target="$TMP_DIR/project"
  mkdir -p "$target/.claude/skills/mine" "$target/.claude/rules"
  printf 'keep\n' > "$target/.claude/settings.local.json"
  printf 'keep\n' > "$target/.claude/skills/mine/SKILL.md"
  printf 'my rule\n' > "$target/.claude/rules/demo.md"
  printf 'my claude\n' > "$target/CLAUDE.md"

  sh "$PROJECT_INSTALLER" -f demo -t "$target" -s "$SRC/projects" > "$TMP_DIR/project-manual.log"
  assert_contains "$TMP_DIR/project-manual.log" "[MANUAL]"
  assert_contains "$target/CLAUDE.md" "my claude"
  assert_file "$target/.mcp.json"

  sh "$PROJECT_INSTALLER" -f demo -t "$target" -s "$SRC/projects" -F > "$TMP_DIR/project-force.log"

  assert_contains "$target/.claude/settings.local.json" "keep"
  assert_contains "$target/.claude/skills/mine/SKILL.md" "keep"
  assert_contains "$target/.claude/rules/demo.md" "rule v2"
  assert_contains "$target/CLAUDE.md" "project v2"
  assert_not_exists "$target/.claude/.gitkeep"
  assert_not_exists "$target/.claude/open_supports_name_list.txt"

  backup="$(find "$target" -maxdepth 1 -name '.claude-project-backup-*')"
  [ -n "$backup" ] || fail "expected a backup directory in $target"
  assert_contains "$backup/.claude/rules/demo.md" "my rule"
  assert_contains "$backup/CLAUDE.md" "my claude"
  assert_contains "$TMP_DIR/project-force.log" "模板尚未填写"

  pass "project -F overwrites only bundle files, backs them up, and keeps the rest"
}

test_scenario_bundles() {
  for flag in prd-design frontend-dev backend-dev dev-ops; do
    target="$TMP_DIR/bundle-$flag"
    mkdir -p "$target"
    sh "$PROJECT_INSTALLER" -f "$flag" -t "$target" -N > /dev/null

    list="$target/.claude/open_supports_name_list.txt"
    assert_file "$list"
    assert_file "$target/.claude/settings.json"
    assert_file "$target/CLAUDE.md"
    [ -n "$(find "$target/.claude/agents" -name '*.md')" ] || fail "$flag bundle should install agents"

    # Scripts run inside the vendored package, so project-level lines must name the project.
    if grep -v '^[[:space:]]*#' "$list" | grep -E -e '--local|--location=local' | grep -v -F '{PROJECT_DIR}' > /dev/null; then
      fail "$flag: project-level entry without {PROJECT_DIR} in $list"
    fi
  done

  pass "scenario bundles install settings, CLAUDE.md, agents and an open_supports list with {PROJECT_DIR}"
}

# A fake support package whose install script records its arguments.
OST="$TMP_DIR/open_supports"
mkdir -p "$OST/ost_acme_widget/scripts_for_install"
cat > "$OST/ost_acme_widget/scripts_for_install/install.sh" <<'EOF_INSTALL'
#!/bin/sh
printf '%s|%s\n' "$PWD" "$*" >> "$PROJECT_TEST_LOG"
EOF_INSTALL
mkdir -p "$SRC/projects/.claude-ost/.claude" "$SRC/projects/.claude"
printf 'acme/widget --location=local {PROJECT_DIR}\n' > "$SRC/projects/.claude-ost/.claude/open_supports_name_list.txt"
printf 'acme/widget --global\n' > "$SRC/projects/.claude/open_supports_name_list.txt"
printf 'not copied\n' > "$SRC/projects/.claude/other.md"

test_project_installs_support_packages() {
  target="$TMP_DIR/ost-project"
  mkdir -p "$target"
  log="$TMP_DIR/ost-project.log"

  PROJECT_TEST_LOG="$log" sh "$PROJECT_INSTALLER" -f ost -t "$target" -s "$SRC/projects" -o "$OST" -N > /dev/null
  assert_file "$target/.claude/open_supports_name_list.txt"
  assert_not_exists "$log"

  # A list already on the target wins over the bundle's list.
  printf 'acme/widget --mine {PROJECT_DIR}\n' > "$target/.claude/open_supports_name_list.txt"
  PROJECT_TEST_LOG="$log" sh "$PROJECT_INSTALLER" -f ost -t "$target" -s "$SRC/projects" -o "$OST" > "$TMP_DIR/ost-project.out"
  assert_contains "$TMP_DIR/ost-project.out" "[MANUAL]"
  assert_contains "$log" "--mine $(cd "$target" && pwd -P)"
  assert_file "$target/.claude/open_supports/ost_acme_widget/scripts_for_install/install.sh"

  pass "project install copies the bundle, then installs the target's list; -N skips installing"
}

test_project_dry_run_writes_nothing() {
  target="$TMP_DIR/dry-project"
  mkdir -p "$target"
  log="$TMP_DIR/dry-project.log"

  PROJECT_TEST_LOG="$log" sh "$PROJECT_INSTALLER" -f ost -t "$target" -s "$SRC/projects" -o "$OST" -d > "$TMP_DIR/dry.out"
  assert_contains "$TMP_DIR/dry.out" "[DRY-RUN] copy"
  assert_contains "$TMP_DIR/dry.out" "[DRY-RUN] run"
  [ -z "$(find "$target" -mindepth 1)" ] || fail "dry run should not write into $target"
  assert_not_exists "$log"

  pass "-d previews copying and installing without writing"
}

test_global_copies_only_the_list() {
  home="$TMP_DIR/home"
  mkdir -p "$home"
  log="$TMP_DIR/global.log"

  for bad in "-g -f ost" "-g -t $TMP_DIR"; do
    # shellcheck disable=SC2086
    if HOME="$home" sh "$PROJECT_INSTALLER" $bad -s "$SRC/projects" -o "$OST" > /dev/null 2>&1; then
      fail "expected failure for: $bad"
    fi
  done

  HOME="$home" PROJECT_TEST_LOG="$log" sh "$PROJECT_INSTALLER" -g -s "$SRC/projects" -o "$OST" > "$TMP_DIR/global.out"
  assert_contains "$TMP_DIR/global.out" "[GLOBAL]"
  assert_contains "$home/.claude/open_supports_name_list.txt" "acme/widget --global"
  assert_not_exists "$home/.claude/other.md"
  assert_not_exists "$home/.claude/open_supports"
  assert_contains "$log" "$OST/ost_acme_widget|--global"

  printf 'acme/widget --mine\n' > "$home/.claude/open_supports_name_list.txt"
  HOME="$home" PROJECT_TEST_LOG="$log" sh "$PROJECT_INSTALLER" -g -s "$SRC/projects" -o "$OST" -F > /dev/null
  assert_contains "$home/.claude/open_supports_name_list.txt" "acme/widget --global"
  grep -l -e '--mine' "$home"/.claude/open_supports_name_list.txt.backup-* > /dev/null || fail "global -F should back up the old list"
  [ "$(find "$home" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" -eq 1 ] || fail "global install should only touch ~/.claude"

  pass "-g copies only the list to ~/.claude, backs it up on -F, and installs globally"
}

test_arguments_are_not_evaluated
test_claude_md_skips_empty_and_backs_up
test_dot_mcp_skips_empty_rejects_invalid_and_backs_up
test_project_force_keeps_unrelated_files
test_scenario_bundles
test_project_installs_support_packages
test_project_dry_run_writes_nothing
test_global_copies_only_the_list
