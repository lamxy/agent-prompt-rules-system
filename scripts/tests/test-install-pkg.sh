#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
SKILL_INSTALLER="$REPO_ROOT/scripts/install-skill-pkg.sh"
AGENT_INSTALLER="$REPO_ROOT/scripts/install-agent-pkg.sh"
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

assert_not_contains() {
  if grep -F -- "$2" "$1" >/dev/null 2>&1; then
    fail "expected $1 not to contain: $2"
  fi
}

# A package with one valid skill, one directory without SKILL.md, and a README.
SKILLS_ROOT="$TMP_DIR/skills-src"
mkdir -p "$SKILLS_ROOT/skills-demo/good/references" "$SKILLS_ROOT/skills-demo/nodoc"
printf -- '---\nname: good\ndescription: demo\n---\nv2\n' > "$SKILLS_ROOT/skills-demo/good/SKILL.md"
printf 'ref\n' > "$SKILLS_ROOT/skills-demo/good/references/ref.md"
printf 'notes\n' > "$SKILLS_ROOT/skills-demo/nodoc/notes.txt"
printf 'readme\n' > "$SKILLS_ROOT/skills-demo/README.md"

test_skill_install_creates_target_and_filters() {
  target="$TMP_DIR/skill-new/.claude/skills"

  sh "$SKILL_INSTALLER" -f demo -t "$target" -s "$SKILLS_ROOT" > "$TMP_DIR/skill-new.log"

  assert_file "$target/good/SKILL.md"
  assert_file "$target/good/references/ref.md"
  assert_not_exists "$target/nodoc"
  assert_not_exists "$target/README.md"
  assert_not_exists "$target/good/good"
  assert_contains "$TMP_DIR/skill-new.log" "[MKDIR]"
  assert_contains "$TMP_DIR/skill-new.log" "缺少 SKILL.md"
  assert_contains "$TMP_DIR/skill-new.log" "invalid=1"

  pass "skill install creates the target and skips directories without SKILL.md"
}

test_skill_placeholder_package() {
  target="$TMP_DIR/skill-placeholder"

  for flag in prd-design frontend-dev; do
    sh "$SKILL_INSTALLER" -f "$flag" -t "$target" > "$TMP_DIR/skill-placeholder.log"
    assert_contains "$TMP_DIR/skill-placeholder.log" "此包尚无 skill"
  done
  [ -z "$(ls -A "$target")" ] || fail "placeholder packages should install nothing"

  pass "scenario placeholder packages install nothing and say so"
}

test_skill_backend_dev_package() {
  target="$TMP_DIR/skill-backend"

  sh "$SKILL_INSTALLER" -f backend-dev -t "$target" > "$TMP_DIR/skill-backend.log"

  [ -f "$target/go-new-module/SKILL.md" ] || fail "expected backend-dev to install go-new-module"
  pass "backend-dev package installs its skills"
}

test_skill_conflict_without_force() {
  target="$TMP_DIR/skill-manual"
  mkdir -p "$target/good"
  printf 'mine\n' > "$target/good/SKILL.md"

  sh "$SKILL_INSTALLER" -f demo -t "$target" -s "$SKILLS_ROOT" > "$TMP_DIR/skill-manual.log"

  assert_contains "$TMP_DIR/skill-manual.log" "[MANUAL]"
  assert_contains "$target/good/SKILL.md" "mine"

  pass "existing skill is left alone without -F"
}

test_skill_force_backs_up() {
  target="$TMP_DIR/skill-force/skills"
  mkdir -p "$target/good/mine"
  printf 'my edit\n' > "$target/good/SKILL.md"
  printf 'mine\n' > "$target/good/mine/extra.md"

  sh "$SKILL_INSTALLER" -f demo -t "$target" -s "$SKILLS_ROOT" -F > "$TMP_DIR/skill-force.log"

  assert_contains "$target/good/SKILL.md" "v2"
  assert_not_exists "$target/good/mine"
  backup="$(find "$TMP_DIR/skill-force" -maxdepth 1 -name 'skills.backup-*')"
  [ -n "$backup" ] || fail "expected a backup directory next to $target"
  assert_contains "$backup/good/SKILL.md" "my edit"
  assert_file "$backup/good/mine/extra.md"
  assert_contains "$TMP_DIR/skill-force.log" "[BACKUP]"

  pass "skill -F moves the old copy to a sibling backup directory"
}

test_skill_target_is_file() {
  printf 'x\n' > "$TMP_DIR/not-a-dir"

  if sh "$SKILL_INSTALLER" -f demo -t "$TMP_DIR/not-a-dir" -s "$SKILLS_ROOT" > /dev/null 2> "$TMP_DIR/not-a-dir.err"; then
    fail "file target should fail"
  fi
  assert_contains "$TMP_DIR/not-a-dir.err" "不是目录"

  pass "skill install refuses a target that is a file"
}

test_skill_real_package() {
  target="$TMP_DIR/skill-real"

  sh "$SKILL_INSTALLER" -f open-supports -t "$target" > /dev/null
  assert_file "$target/open-supports-install/SKILL.md"
  assert_not_exists "$target/README.md"

  pass "repository skill package installs"
}

test_agent_force_backs_up() {
  agents_root="$TMP_DIR/agents-src"
  target="$TMP_DIR/agent-force/agents"
  mkdir -p "$agents_root/agents-demo" "$target"
  printf 'v2\n' > "$agents_root/agents-demo/reviewer.md"
  printf 'my edit\n' > "$target/reviewer.md"

  sh "$AGENT_INSTALLER" -f demo -t "$target" -s "$agents_root" > "$TMP_DIR/agent-manual.log"
  assert_contains "$TMP_DIR/agent-manual.log" "[MANUAL]"
  assert_contains "$target/reviewer.md" "my edit"

  sh "$AGENT_INSTALLER" -f demo -t "$target" -s "$agents_root" -F > "$TMP_DIR/agent-force.log"
  assert_contains "$target/reviewer.md" "v2"
  backup="$(find "$TMP_DIR/agent-force" -maxdepth 1 -name 'agents.backup-*')"
  [ -n "$backup" ] || fail "expected a backup directory next to $target"
  assert_contains "$backup/reviewer.md" "my edit"
  assert_not_contains "$TMP_DIR/agent-force.log" "删除"

  pass "agent -F moves the old file to a sibling backup directory"
}

test_skill_install_creates_target_and_filters
test_skill_placeholder_package
test_skill_backend_dev_package
test_skill_conflict_without_force
test_skill_force_backs_up
test_skill_target_is_file
test_skill_real_package
test_agent_force_backs_up
