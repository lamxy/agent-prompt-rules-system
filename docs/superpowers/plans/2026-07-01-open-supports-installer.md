# Open Supports Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an independent installer that reads `.claude/open_supports_name_list.txt`, vendors requested `open_supports/ost_*` packages into a target project, generates project-local wrapper Skills, and runs vendored install scripts when requested.

**Architecture:** Add one POSIX `sh` core script, one POSIX `sh` smoke/regression test script, one generic Skill package that wraps the script, and documentation updates. The core script owns parsing, vendoring, wrapper generation, script dispatch, dry-run behavior, and final status reporting; support packages keep package-specific install details.

**Tech Stack:** POSIX `sh`, `cp`, `rm`, `mkdir`, `mktemp`, Markdown, existing repository installer conventions.

---

## File Structure

- Create `scripts/install-open-supports.sh`
  - Core installer entrypoint.
  - Parses CLI options and line-oriented manifest.
  - Vendors support packages into `<target>/.claude/open_supports/`.
  - Generates wrapper Skills into `<target>/.claude/skills/`.
  - Runs vendored `scripts_for_install/install.*` scripts.

- Create `scripts/test-install-open-supports.sh`
  - Self-contained POSIX shell regression tests.
  - Builds fake support packages in a temp source root.
  - Verifies mapping, vendoring, wrapper generation, mode flags, reuse, force, dry-run, and missing package behavior.

- Create `skills/skills-open-supports/README.md`
  - Explains the reusable skill package.

- Create `skills/skills-open-supports/open-supports-install/SKILL.md`
  - Generic natural-language wrapper that tells an agent how to run `scripts/install-open-supports.sh`.

- Modify `README.md`
  - Add `install-open-supports.sh` to script list and usage section.

- Modify `dot_claude_projects/README.md`
  - Explain that project templates may include `.claude/open_supports_name_list.txt`.
  - Explain that installation is a separate command.

- Modify `dot_claude_projects/.claude-FLAG-NAME_template/README-open_supports_name-list.md`
  - Document the text manifest format.

- Modify `dot_claude_projects/.claude-FLAG-NAME_template/.claude/open_supports_name_list.txt`
  - Add commented examples.

---

### Task 1: Add Failing Regression Tests

**Files:**
- Create: `scripts/test-install-open-supports.sh`
- Depends on: `docs/superpowers/specs/2026-07-01-open-supports-installer-design.md`

- [ ] **Step 1: Create the shell regression test script**

Create `scripts/test-install-open-supports.sh` with this content:

```sh
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
```

- [ ] **Step 2: Run the test and verify it fails before implementation**

Run:

```sh
sh scripts/test-install-open-supports.sh
```

Expected: non-zero exit because `scripts/install-open-supports.sh` does not exist yet. The first failure should be from `sh` trying to open the missing installer.

- [ ] **Step 3: Commit the failing tests**

```sh
git add scripts/test-install-open-supports.sh
git commit -m "test: add open supports installer coverage"
```

---

### Task 2: Implement The Installer Script

**Files:**
- Create: `scripts/install-open-supports.sh`
- Test: `scripts/test-install-open-supports.sh`

- [ ] **Step 1: Create the installer script**

Create `scripts/install-open-supports.sh` with this complete implementation:

```sh
#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/install-open-supports.sh -t <target_project_dir> [options]

Options:
  -t <target_project_dir>    Target project root directory
  -l <list_file>             List file (default: <target>/.claude/open_supports_name_list.txt)
  -s <open_supports_root>    Source open_supports root (default: <repo>/open_supports)
  -F                         Force overwrite vendored support packages and wrapper Skills
  --no-skills                Vendor packages and run install scripts, but do not generate wrapper Skills
  --skills-only              Vendor packages and generate wrapper Skills, but do not run install scripts
  --dry-run                  Print planned actions without copying or running scripts
  -h, --help                 Show this help message

Manifest format:
  <support-name> [install args...]

Support names:
  GithubName/RepoName        Example: colbymchenry/codegraph
  ost_GithubName_RepoName    Example: ost_colbymchenry_codegraph
USAGE
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

TARGET=""
LIST_FILE=""
SOURCE_ROOT=""
FORCE=0
NO_SKILLS=0
SKILLS_ONLY=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -t|--target)
      [ "$#" -ge 2 ] || fail_usage '-t requires a value'
      TARGET="$2"
      shift 2
      ;;
    -t=*)
      TARGET="${1#-t=}"
      shift
      ;;
    --target=*)
      TARGET="${1#--target=}"
      shift
      ;;
    -l|--list)
      [ "$#" -ge 2 ] || fail_usage '-l requires a value'
      LIST_FILE="$2"
      shift 2
      ;;
    -l=*)
      LIST_FILE="${1#-l=}"
      shift
      ;;
    --list=*)
      LIST_FILE="${1#--list=}"
      shift
      ;;
    -s|--source)
      [ "$#" -ge 2 ] || fail_usage '-s requires a value'
      SOURCE_ROOT="$2"
      shift 2
      ;;
    -s=*)
      SOURCE_ROOT="${1#-s=}"
      shift
      ;;
    --source=*)
      SOURCE_ROOT="${1#--source=}"
      shift
      ;;
    -F|--force)
      FORCE=1
      shift
      ;;
    --no-skills)
      NO_SKILLS=1
      shift
      ;;
    --skills-only)
      SKILLS_ONLY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail_usage "unknown option: $1"
      ;;
  esac
done

[ -n "$TARGET" ] || fail_usage '-t <target_project_dir> is required'

if [ "$NO_SKILLS" -eq 1 ] && [ "$SKILLS_ONLY" -eq 1 ]; then
  fail_usage '--no-skills and --skills-only are mutually exclusive'
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/open_supports"
fi

if [ -z "$LIST_FILE" ]; then
  LIST_FILE="$TARGET/.claude/open_supports_name_list.txt"
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: target directory does not exist: %s\n' "$TARGET" >&2
  exit 1
fi

if [ ! -d "$SOURCE_ROOT" ]; then
  printf 'Error: open_supports root not found: %s\n' "$SOURCE_ROOT" >&2
  exit 1
fi

if [ ! -f "$LIST_FILE" ]; then
  printf 'Error: list file not found: %s\n' "$LIST_FILE" >&2
  exit 1
fi

TOTAL=0
VENDORED=0
REUSED=0
SKILL_GENERATED=0
SKILL_REUSED=0
SCRIPT_OK=0
MISSING=0
NO_SCRIPT=0
FAILED=0

trim_line() {
  printf '%s\n' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

support_to_ost() {
  name="$1"
  case "$name" in
    ost_*)
      printf '%s\n' "$name"
      ;;
    */*)
      printf 'ost_%s\n' "$(printf '%s\n' "$name" | sed 's,/,_,g')"
      ;;
    *)
      return 1
      ;;
  esac
}

skill_slug() {
  printf '%s\n' "$1" | sed 's/_/-/g'
}

run_copy_dir() {
  src="$1"
  dest="$2"
  label="$3"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] vendor %s -> %s\n' "$src" "$dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -d "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] Replacing %s: %s\n' "$label" "$dest"
      rm -rf "$dest"
      cp -r "$src" "$dest"
      VENDORED=$((VENDORED + 1))
      return 0
    fi
    printf '[REUSED] %s: %s\n' "$label" "$dest"
    REUSED=$((REUSED + 1))
    return 0
  fi

  cp -r "$src" "$dest"
  printf '[VENDORED] %s\n' "$dest"
  VENDORED=$((VENDORED + 1))
}

generate_wrapper_skill() {
  ost_name="$1"
  target_dir="$2"
  dest_dir="$target_dir/.claude/skills/${ost_name}_install"
  dest_file="$dest_dir/SKILL.md"
  slug="$(skill_slug "${ost_name}_install")"

  if [ "$NO_SKILLS" -eq 1 ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] generate wrapper Skill: %s\n' "$dest_file"
    return 0
  fi

  if [ -e "$dest_dir" ] && [ "$FORCE" -eq 0 ]; then
    printf '[REUSED] wrapper Skill: %s\n' "$dest_dir"
    SKILL_REUSED=$((SKILL_REUSED + 1))
    return 0
  fi

  if [ -e "$dest_dir" ] && [ "$FORCE" -eq 1 ]; then
    printf '[FORCE] Replacing wrapper Skill: %s\n' "$dest_dir"
    rm -rf "$dest_dir"
  fi

  mkdir -p "$dest_dir"
  cat > "$dest_file" <<EOF_SKILL
---
name: $slug
description: Install or update ${ost_name} using this project's vendored open_supports package.
---

# ${ost_name} Open Supports Wrapper

Use this project-local vendored support package before taking action:

1. Read \`.claude/open_supports/${ost_name}/repo_readme_summary.md\`.
2. Read \`.claude/open_supports/${ost_name}/skill_for_setup/README.md\` if it exists.
3. Read \`.claude/open_supports/${ost_name}/skill_for_setup/${ost_name}_install/SKILL.md\` if it exists.
4. Read every file under \`.claude/open_supports/${ost_name}/.ost-refs/\` if that directory exists and has files.

Run the vendored install script from the target project root:

\`\`\`sh
cd /path/to/project/.claude/open_supports/${ost_name}
sh scripts_for_install/install.sh
\`\`\`

If the support package uses a non-sh installer, inspect \`.claude/open_supports/${ost_name}/scripts_for_install/\` and use the matching runtime described by the package documentation.
EOF_SKILL

  printf '[SKILL] %s\n' "$dest_file"
  SKILL_GENERATED=$((SKILL_GENERATED + 1))
}

find_install_script() {
  pkg_dir="$1"
  for rel in \
    scripts_for_install/install.sh \
    scripts_for_install/install.py \
    scripts_for_install/install.js
  do
    if [ -f "$pkg_dir/$rel" ]; then
      printf '%s\n' "$rel"
      return 0
    fi
  done

  for abs in "$pkg_dir"/scripts_for_install/install.*; do
    [ -f "$abs" ] || continue
    basename_file="$(basename "$abs")"
    printf 'scripts_for_install/%s\n' "$basename_file"
    return 0
  done

  return 1
}

run_install_script() {
  pkg_dir="$1"
  rel_script="$2"
  args="$3"

  if [ "$SKILLS_ONLY" -eq 1 ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] run %s/%s %s\n' "$pkg_dir" "$rel_script" "$args"
    return 0
  fi

  set -- $args
  case "$rel_script" in
    *.sh)
      (cd "$pkg_dir" && sh "$rel_script" "$@")
      ;;
    *.py)
      (cd "$pkg_dir" && python3 "$rel_script" "$@")
      ;;
    *.js)
      (cd "$pkg_dir" && node "$rel_script" "$@")
      ;;
    *)
      if [ -x "$pkg_dir/$rel_script" ]; then
        (cd "$pkg_dir" && "./$rel_script" "$@")
      else
        return 1
      fi
      ;;
  esac
}

process_entry() {
  support_name="$1"
  args="$2"

  TOTAL=$((TOTAL + 1))

  if ! ost_name="$(support_to_ost "$support_name")"; then
    printf '[MISSING] invalid support name: %s\n' "$support_name" >&2
    MISSING=$((MISSING + 1))
    return 0
  fi

  src_dir="$SOURCE_ROOT/$ost_name"
  vendored_dir="$TARGET/.claude/open_supports/$ost_name"

  printf '\n==> %s\n' "$ost_name"

  if [ ! -d "$src_dir" ]; then
    printf '[MISSING] source package not found: %s\n' "$src_dir" >&2
    MISSING=$((MISSING + 1))
    return 0
  fi

  run_copy_dir "$src_dir" "$vendored_dir" "support package"
  generate_wrapper_skill "$ost_name" "$TARGET"

  if [ "$SKILLS_ONLY" -eq 1 ]; then
    return 0
  fi

  if ! rel_script="$(find_install_script "$vendored_dir")"; then
    printf '[NO_SCRIPT] %s/scripts_for_install/install.*\n' "$vendored_dir" >&2
    NO_SCRIPT=$((NO_SCRIPT + 1))
    return 0
  fi

  if run_install_script "$vendored_dir" "$rel_script" "$args"; then
    printf '[SCRIPT_OK] %s\n' "$ost_name"
    SCRIPT_OK=$((SCRIPT_OK + 1))
  else
    printf '[FAILED] install script failed: %s\n' "$ost_name" >&2
    FAILED=$((FAILED + 1))
  fi
}

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  line="$(trim_line "$raw_line")"
  case "$line" in
    ''|\#*)
      continue
      ;;
  esac

  set -- $line
  support_name="$1"
  shift || true
  args="$*"

  process_entry "$support_name" "$args"
done < "$LIST_FILE"

printf '\nDone. total=%d vendored=%d reused=%d skill_generated=%d skill_reused=%d script_ok=%d missing=%d no_script=%d failed=%d\n' \
  "$TOTAL" "$VENDORED" "$REUSED" "$SKILL_GENERATED" "$SKILL_REUSED" "$SCRIPT_OK" "$MISSING" "$NO_SCRIPT" "$FAILED"

if [ "$MISSING" -gt 0 ] || [ "$NO_SCRIPT" -gt 0 ] || [ "$FAILED" -gt 0 ]; then
  exit 1
fi
```

- [ ] **Step 2: Run syntax checks**

Run:

```sh
sh -n scripts/install-open-supports.sh
sh -n scripts/test-install-open-supports.sh
```

Expected: both commands exit 0 with no output.

- [ ] **Step 3: Run the regression tests**

Run:

```sh
sh scripts/test-install-open-supports.sh
```

Expected: all individual tests print `PASS`, followed by `All install-open-supports tests passed.`

- [ ] **Step 4: Commit the installer implementation**

```sh
git add scripts/install-open-supports.sh scripts/test-install-open-supports.sh
git commit -m "feat: add open supports installer"
```

---

### Task 3: Add The Generic Open Supports Skill Package

**Files:**
- Create: `skills/skills-open-supports/README.md`
- Create: `skills/skills-open-supports/open-supports-install/SKILL.md`
- Test: `scripts/install-skill-pkg.sh`

- [ ] **Step 1: Create the skill package README**

Create `skills/skills-open-supports/README.md`:

```md
# Open Supports Skills

This package provides project-level Skills for installing and maintaining
`open_supports/` localized support packages.

Install into a project with:

```sh
sh scripts/install-skill-pkg.sh -f open-supports -t /path/to/project/.claude/skills
```

The package expects the rule source repository to contain
`scripts/install-open-supports.sh` and `open_supports/`.
```

- [ ] **Step 2: Create the generic Skill**

Create `skills/skills-open-supports/open-supports-install/SKILL.md`:

```md
---
name: open-supports-install
description: Install or update project-local open_supports packages from .claude/open_supports_name_list.txt by using scripts/install-open-supports.sh.
argument-hint: '-t <project> [--skills-only|--no-skills|--dry-run|-F]'
---

# Open Supports Install

Use this Skill when the user asks to install, update, vendor, or inspect
`open_supports/` packages for a project.

## Pre-read

Before running commands:

1. Read the target project's `.claude/open_supports_name_list.txt`.
2. Read this repository's `open_supports/README.md`.
3. Read `docs/superpowers/specs/2026-07-01-open-supports-installer-design.md` if present.

## Procedure

Default to the current working directory as the target project when the user does
not specify a target.

Run from the rule source repository:

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

Useful modes:

```sh
sh scripts/install-open-supports.sh -t /path/to/project --dry-run
sh scripts/install-open-supports.sh -t /path/to/project --skills-only
sh scripts/install-open-supports.sh -t /path/to/project --no-skills
sh scripts/install-open-supports.sh -t /path/to/project -F
```

If a custom list file is requested:

```sh
sh scripts/install-open-supports.sh -t /path/to/project -l /path/to/open_supports_name_list.txt
```

If a custom `open_supports/` source root is requested:

```sh
sh scripts/install-open-supports.sh -t /path/to/project -s /path/to/open_supports
```

## Reporting

After the command finishes, report:

- which packages were vendored or reused;
- which wrapper Skills were generated or reused;
- which install scripts ran successfully;
- any `missing`, `no_script`, or `failed` counts;
- the next command the user should run if the script reported manual follow-up.
```

- [ ] **Step 3: Smoke test skill package installation**

Run:

```sh
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/.claude/skills"
sh scripts/install-skill-pkg.sh -f open-supports -t "$tmpdir/.claude/skills"
test -f "$tmpdir/.claude/skills/open-supports-install/SKILL.md"
```

Expected: the install script prints `[COPIED] open-supports-install`, and `test -f` exits 0.

- [ ] **Step 4: Commit the Skill package**

```sh
git add skills/skills-open-supports
git commit -m "skills: add open supports installer skill"
```

---

### Task 4: Update Project Template Documentation

**Files:**
- Modify: `dot_claude_projects/README.md`
- Modify: `dot_claude_projects/.claude-FLAG-NAME_template/README-open_supports_name-list.md`
- Modify: `dot_claude_projects/.claude-FLAG-NAME_template/.claude/open_supports_name_list.txt`

- [ ] **Step 1: Update `dot_claude_projects/README.md`**

Add this section after the usage examples:

```md
## Open Supports List

Project templates may include:

```text
.claude/open_supports_name_list.txt
```

This file declares localized `open_supports/` packages that should be vendored
into a target project after the project template is installed. Installing a
`.claude-<FLAG>/` template does not automatically install these support
packages.

Run the separate installer from this repository root:

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

The list format is line-oriented:

```text
# <support-name> [install args...]
colbymchenry/codegraph --target=claude --location=local
open-gsd/gsd-core --claude --local
ost_garrytan_gstack
```

Both `GithubName/RepoName` and `ost_GithubName_RepoName` names are accepted.
```

- [ ] **Step 2: Fill the template list README**

Replace `dot_claude_projects/.claude-FLAG-NAME_template/README-open_supports_name-list.md` with:

```md
# open_supports_name_list.txt

`open_supports_name_list.txt` declares which localized open source support
packages should be vendored into projects created from this template.

The file is installed at:

```text
.claude/open_supports_name_list.txt
```

Install the listed packages separately from the rule source repository:

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

## Format

Each non-empty, non-comment line has this form:

```text
<support-name> [install args...]
```

Accepted support names:

- `GithubName/RepoName`, for example `colbymchenry/codegraph`
- `ost_GithubName_RepoName`, for example `ost_colbymchenry_codegraph`

Arguments after the support name are passed to that package's vendored
`scripts_for_install/install.*` script.

Version 1 does not support inline comments or argument values containing spaces.
Use full-line comments instead.

## Examples

```text
# Install CodeGraph for Claude Code at project scope.
colbymchenry/codegraph --target=claude --location=local

# Install GSD Core for Claude Code at project scope.
open-gsd/gsd-core --claude --local

# Internal ost_* names are also valid.
ost_garrytan_gstack
```
```

- [ ] **Step 3: Fill the template manifest with commented examples**

Replace `dot_claude_projects/.claude-FLAG-NAME_template/.claude/open_supports_name_list.txt` with:

```text
# open_supports_name_list.txt
#
# Each non-empty, non-comment line:
#   <support-name> [install args...]
#
# Accepted support names:
#   GithubName/RepoName
#   ost_GithubName_RepoName
#
# Examples:
# colbymchenry/codegraph --target=claude --location=local
# open-gsd/gsd-core --claude --local
# ost_garrytan_gstack
```

- [ ] **Step 4: Commit project template documentation**

```sh
git add dot_claude_projects/README.md dot_claude_projects/.claude-FLAG-NAME_template/README-open_supports_name-list.md dot_claude_projects/.claude-FLAG-NAME_template/.claude/open_supports_name_list.txt
git commit -m "docs: document open supports project lists"
```

---

### Task 5: Update Root README

**Files:**
- Modify: `README.md`
- Test: `sh -n scripts/install-open-supports.sh`

- [ ] **Step 1: Add the script to the scenario package table**

In the table under "场景包目录", update the `dot_claude_projects/` row text so it mentions the separate open supports installer:

```md
| `dot_claude_projects/` | 按项目场景分类的项目级指令模板目录（`.claude-<FLAG>/`，含 `.claude/`、`.mcp.json`、`CLAUDE.md`，可声明 `open_supports_name_list.txt`） | `install-claude-project.sh`；支持包安装用 `install-open-supports.sh` |
```

- [ ] **Step 2: Add usage section after the existing 3.7 section**

Add:

```md
#### 3.8 安装项目声明的 open_supports 支持包

项目级完整配置包可以在 `.claude/open_supports_name_list.txt` 中声明需要接入的本地化开源支持包。该列表不会在安装项目模板时自动执行；需要单独运行：

```sh
sh ./scripts/install-open-supports.sh -t /path/to/project
```

列表格式为一行一个支持包：

```text
# <support-name> [install args...]
colbymchenry/codegraph --target=claude --location=local
open-gsd/gsd-core --claude --local
ost_garrytan_gstack
```

默认行为：

- 将支持包复制到目标项目的 `.claude/open_supports/`
- 在目标项目的 `.claude/skills/` 下生成 wrapper Skill
- 执行 vendored 支持包内的 `scripts_for_install/install.*`

常用选项：

```sh
sh ./scripts/install-open-supports.sh -t /path/to/project --dry-run
sh ./scripts/install-open-supports.sh -t /path/to/project --skills-only
sh ./scripts/install-open-supports.sh -t /path/to/project --no-skills
sh ./scripts/install-open-supports.sh -t /path/to/project -F
```
```

- [ ] **Step 3: Add script to complete directory structure**

In the `scripts/` tree section, add:

```text
│   ├── install-open-supports.sh # 安装项目声明的 open_supports 支持包
```

- [ ] **Step 4: Run final verification**

Run:

```sh
sh -n scripts/install-open-supports.sh
sh -n scripts/test-install-open-supports.sh
sh scripts/test-install-open-supports.sh
```

Expected: syntax checks exit 0; tests print all `PASS` lines.

- [ ] **Step 5: Commit README updates**

```sh
git add README.md
git commit -m "docs: add open supports installer usage"
```

---

### Task 6: Final Integration Check

**Files:**
- Verify: `scripts/install-open-supports.sh`
- Verify: `scripts/test-install-open-supports.sh`
- Verify: `skills/skills-open-supports/open-supports-install/SKILL.md`
- Verify: `dot_claude_projects/README.md`
- Verify: `README.md`

- [ ] **Step 1: Run syntax checks for all repository scripts**

Run:

```sh
sh -n scripts/*.sh
```

Expected: exits 0 with no output.

- [ ] **Step 2: Run installer tests**

Run:

```sh
sh scripts/test-install-open-supports.sh
```

Expected: all tests pass.

- [ ] **Step 3: Run a real-package skills-only smoke test**

Run:

```sh
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/.claude"
printf 'colbymchenry/codegraph --target=claude --location=local\n' > "$tmpdir/.claude/open_supports_name_list.txt"
sh scripts/install-open-supports.sh -t "$tmpdir" --skills-only
test -f "$tmpdir/.claude/open_supports/ost_colbymchenry_codegraph/repo_readme_summary.md"
test -f "$tmpdir/.claude/skills/ost_colbymchenry_codegraph_install/SKILL.md"
```

Expected: command exits 0; both `test -f` checks pass.

- [ ] **Step 4: Inspect final git state**

Run:

```sh
git status --short
```

Expected: no changes from this implementation remain unstaged or uncommitted. Pre-existing unrelated worktree changes may still appear; do not stage or revert them.

- [ ] **Step 5: Report completion**

Summarize:

- files added and modified;
- verification commands run;
- whether any unrelated pre-existing worktree changes remain;
- commit hashes created during implementation.

---

## Self-Review

- Spec coverage: the plan covers the independent script, txt manifest parsing, support package vendoring, generated wrapper Skills, reuse and force behavior, dry-run, mode flags, error summaries, documentation, and verification.
- Red-flag scan: no task uses vague filler language or unspecified error handling.
- Type and naming consistency: the plan consistently uses `scripts/install-open-supports.sh`, `scripts/test-install-open-supports.sh`, `open_supports_name_list.txt`, `.claude/open_supports/`, `.claude/skills/`, `ost_GithubName_RepoName`, and `<ost_name>_install`.
