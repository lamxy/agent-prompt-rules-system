#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-open-supports.sh"

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
  if ! grep -F "$pattern" "$file" >/dev/null 2>&1; then
    printf '--- %s ---\n' "$file" >&2
    sed -n '1,160p' "$file" >&2
    fail "expected $file to contain: $pattern"
  fi
}

make_support_root() {
  root="$1"
  mkdir -p "$root/ost_acme_widget/scripts_for_install"
  mkdir -p "$root/ost_acme_widget/skill_for_setup/ost_acme_widget_install"
  mkdir -p "$root/ost_acme_widget/.ost-refs"

  printf '# Widget Summary\n' > "$root/ost_acme_widget/repo_readme_summary.md"
  printf '# Widget Skill README\n' > "$root/ost_acme_widget/skill_for_setup/README.md"
  cat > "$root/ost_acme_widget/skill_for_setup/ost_acme_widget_install/SKILL.md" <<'EOF_SKILL'
---
name: ost-acme-widget-install
description: Internal support package skill.
---

# Internal Widget Install Skill
EOF_SKILL
  printf 'ref\n' > "$root/ost_acme_widget/.ost-refs/local.md"
  cat > "$root/ost_acme_widget/scripts_for_install/install.sh" <<'EOF_INSTALL'
#!/bin/sh
set -eu
printf '%s\n' "$*" > install-args.log
printf 'ran\n' > install-ran.log
EOF_INSTALL
  chmod +x "$root/ost_acme_widget/scripts_for_install/install.sh"

  mkdir -p "$root/ost_acme_no_script/skill_for_setup/ost_acme_no_script_install"
  printf '# No Script Summary\n' > "$root/ost_acme_no_script/repo_readme_summary.md"
  printf '# No Script Skill README\n' > "$root/ost_acme_no_script/skill_for_setup/README.md"
  printf '# No Script Skill\n' > "$root/ost_acme_no_script/skill_for_setup/ost_acme_no_script_install/SKILL.md"

  mkdir -p "$root/ost_acme_failing/scripts_for_install"
  mkdir -p "$root/ost_acme_failing/skill_for_setup/ost_acme_failing_install"
  printf '# Failing Summary\n' > "$root/ost_acme_failing/repo_readme_summary.md"
  printf '# Failing Skill README\n' > "$root/ost_acme_failing/skill_for_setup/README.md"
  printf '# Failing Skill\n' > "$root/ost_acme_failing/skill_for_setup/ost_acme_failing_install/SKILL.md"
  cat > "$root/ost_acme_failing/scripts_for_install/install.sh" <<'EOF_FAIL'
#!/bin/sh
exit 7
EOF_FAIL
  chmod +x "$root/ost_acme_failing/scripts_for_install/install.sh"
}

new_target() {
  target="$1"
  mkdir -p "$target/.claude"
}

test_skills_only_vendors_and_generates_wrapper() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'acme/widget --alpha beta\n' > "$target/.claude/open_supports_name_list.txt"

  sh "$INSTALLER" -t "$target" -s "$source_root" --skills-only

  assert_dir "$target/.claude/open_supports/ost_acme_widget"
  assert_file "$target/.claude/open_supports/ost_acme_widget/repo_readme_summary.md"
  assert_file "$target/.claude/skills/ost_acme_widget_install/SKILL.md"
  assert_contains "$target/.claude/skills/ost_acme_widget_install/SKILL.md" "name: ost-acme-widget-install"
  assert_contains "$target/.claude/skills/ost_acme_widget_install/SKILL.md" ".claude/open_supports/ost_acme_widget/repo_readme_summary.md"
  assert_not_exists "$target/.claude/open_supports/ost_acme_widget/install-ran.log"
  pass "skills-only vendors support package and generates wrapper"
}

test_no_skills_runs_vendored_script_without_wrapper() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'ost_acme_widget --one two\n' > "$target/.claude/open_supports_name_list.txt"

  sh "$INSTALLER" -t "$target" -s "$source_root" --no-skills

  assert_dir "$target/.claude/open_supports/ost_acme_widget"
  assert_file "$target/.claude/open_supports/ost_acme_widget/install-ran.log"
  assert_contains "$target/.claude/open_supports/ost_acme_widget/install-args.log" "--one two"
  assert_not_exists "$target/.claude/skills/ost_acme_widget_install/SKILL.md"
  pass "no-skills runs vendored script without wrapper"
}

test_default_mode_generates_wrapper_and_runs_script() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  {
    printf '# comment\n'
    printf '\n'
    printf 'acme/widget --default yes\n'
  } > "$target/.claude/open_supports_name_list.txt"

  sh "$INSTALLER" -t "$target" -s "$source_root"

  assert_file "$target/.claude/skills/ost_acme_widget_install/SKILL.md"
  assert_file "$target/.claude/open_supports/ost_acme_widget/install-ran.log"
  assert_contains "$target/.claude/open_supports/ost_acme_widget/install-args.log" "--default yes"
  pass "default mode generates wrapper and runs script"
}

test_reuse_existing_vendor_without_force() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'acme/widget\n' > "$target/.claude/open_supports_name_list.txt"

  mkdir -p "$target/.claude/open_supports/ost_acme_widget/scripts_for_install"
  printf 'kept\n' > "$target/.claude/open_supports/ost_acme_widget/marker.txt"
  cat > "$target/.claude/open_supports/ost_acme_widget/scripts_for_install/install.sh" <<'EOF_EXISTING'
#!/bin/sh
printf 'existing\n' > install-ran.log
EOF_EXISTING
  chmod +x "$target/.claude/open_supports/ost_acme_widget/scripts_for_install/install.sh"

  sh "$INSTALLER" -t "$target" -s "$source_root" --no-skills

  assert_contains "$target/.claude/open_supports/ost_acme_widget/marker.txt" "kept"
  assert_contains "$target/.claude/open_supports/ost_acme_widget/install-ran.log" "existing"
  pass "existing vendored package is reused without force"
}

test_force_replaces_existing_vendor() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'acme/widget\n' > "$target/.claude/open_supports_name_list.txt"

  mkdir -p "$target/.claude/open_supports/ost_acme_widget"
  printf 'remove me\n' > "$target/.claude/open_supports/ost_acme_widget/stale.txt"

  sh "$INSTALLER" -t "$target" -s "$source_root" --skills-only -F

  assert_not_exists "$target/.claude/open_supports/ost_acme_widget/stale.txt"
  assert_file "$target/.claude/open_supports/ost_acme_widget/repo_readme_summary.md"
  pass "force replaces existing vendored package"
}

test_dry_run_writes_nothing() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'acme/widget\n' > "$target/.claude/open_supports_name_list.txt"

  sh "$INSTALLER" -t "$target" -s "$source_root" --dry-run

  assert_not_exists "$target/.claude/open_supports"
  assert_not_exists "$target/.claude/skills"
  pass "dry-run writes nothing"
}

test_missing_package_returns_nonzero_after_summary() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  {
    printf 'acme/widget\n'
    printf 'acme/missing\n'
  } > "$target/.claude/open_supports_name_list.txt"

  if sh "$INSTALLER" -t "$target" -s "$source_root" --skills-only > "$tmp/out.log" 2>&1; then
    fail "missing package should return non-zero"
  fi

  assert_file "$target/.claude/open_supports/ost_acme_widget/repo_readme_summary.md"
  assert_contains "$tmp/out.log" "missing=1"
  pass "missing package returns non-zero after processing later entries"
}

test_no_script_fails_when_scripts_enabled() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'acme/no_script\n' > "$target/.claude/open_supports_name_list.txt"

  if sh "$INSTALLER" -t "$target" -s "$source_root" > "$tmp/out.log" 2>&1; then
    fail "missing install script should return non-zero"
  fi

  assert_contains "$tmp/out.log" "no_script=1"
  pass "missing install script fails when scripts are enabled"
}

test_failing_script_continues_and_returns_nonzero() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  {
    printf 'acme/failing\n'
    printf 'acme/widget\n'
  } > "$target/.claude/open_supports_name_list.txt"

  if sh "$INSTALLER" -t "$target" -s "$source_root" --no-skills > "$tmp/out.log" 2>&1; then
    fail "failing install script should return non-zero"
  fi

  assert_contains "$tmp/out.log" "failed=1"
  assert_file "$target/.claude/open_supports/ost_acme_widget/install-ran.log"
  pass "failing script is summarized and later entries continue"
}

test_missing_manifest_fails_immediately() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"

  if sh "$INSTALLER" -t "$target" -s "$source_root" > "$tmp/out.log" 2>&1; then
    fail "missing manifest should fail"
  fi

  assert_contains "$tmp/out.log" "list file not found"
  pass "missing manifest fails immediately"
}

test_mutually_exclusive_modes_fail() {
  tmp="$(mktemp -d)"
  source_root="$tmp/open_supports"
  target="$tmp/project"
  make_support_root "$source_root"
  new_target "$target"
  printf 'acme/widget\n' > "$target/.claude/open_supports_name_list.txt"

  if sh "$INSTALLER" -t "$target" -s "$source_root" --skills-only --no-skills > "$tmp/out.log" 2>&1; then
    fail "mutually exclusive modes should fail"
  fi

  assert_contains "$tmp/out.log" "mutually exclusive"
  pass "mutually exclusive modes fail"
}

test_skills_only_vendors_and_generates_wrapper
test_no_skills_runs_vendored_script_without_wrapper
test_default_mode_generates_wrapper_and_runs_script
test_reuse_existing_vendor_without_force
test_force_replaces_existing_vendor
test_dry_run_writes_nothing
test_missing_package_returns_nonzero_after_summary
test_no_script_fails_when_scripts_enabled
test_failing_script_continues_and_returns_nonzero
test_missing_manifest_fails_immediately
test_mutually_exclusive_modes_fail

printf '\nAll install-open-supports tests passed.\n'
