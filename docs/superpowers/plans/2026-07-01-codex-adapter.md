# Codex Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the phase-1 Codex adapter that generates user/project Codex instruction files and optionally vendors `.claude/` as `.agent-rules/claude/`.

**Architecture:** Keep the adapter small and file-based. `scripts/multi_client_support/codex.sh` validates options, copies one of two markdown templates, and optionally copies `.claude/` into the target project without deleting unrelated existing vendored files. A focused smoke test script exercises user, project, vendor, conflict, and force paths.

**Tech Stack:** POSIX `sh`, markdown templates, existing repository installer conventions, `sh -n` syntax checks, temporary-directory smoke tests.

---

## File Structure

- Create `scripts/test-multi-client-codex.sh`: executable smoke test suite for the new adapter.
- Create `scripts/multi_client_support/templates/AGENTS.codex-user.md`: global/user-level Codex instruction template.
- Create `scripts/multi_client_support/templates/AGENTS.codex-project.md`: project-level Codex instruction template with progressive rule-source protocol.
- Modify `scripts/multi_client_support/codex.sh`: implement option parsing, template installation, and optional `.claude/` vendoring.
- Modify `scripts/multi_client_support/README.md`: document phase-1 scope, command usage, generated files, and out-of-scope future directions.

Do not add `.codex/config.toml`, hooks, Codex `.rules`, Codex skills, or Codex custom agents in this phase.

### Task 1: Add Codex Adapter Smoke Tests

**Files:**
- Create: `scripts/test-multi-client-codex.sh`

- [ ] **Step 1: Write the failing smoke test script**

Create `scripts/test-multi-client-codex.sh`:

```sh
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
```

- [ ] **Step 2: Make the smoke test executable**

Run:

```sh
chmod +x scripts/test-multi-client-codex.sh
```

- [ ] **Step 3: Run the smoke test and verify it fails for the missing implementation**

Run:

```sh
sh scripts/test-multi-client-codex.sh
```

Expected: FAIL because `scripts/multi_client_support/codex.sh` is currently empty and cannot create `AGENTS.codex.md`.

- [ ] **Step 4: Commit the failing smoke test**

Run:

```sh
git add scripts/test-multi-client-codex.sh
git commit -m "test: add codex adapter smoke tests"
```

### Task 2: Add Codex Instruction Templates

**Files:**
- Create: `scripts/multi_client_support/templates/AGENTS.codex-user.md`
- Create: `scripts/multi_client_support/templates/AGENTS.codex-project.md`

- [ ] **Step 1: Create the templates directory**

Run:

```sh
mkdir -p scripts/multi_client_support/templates
```

- [ ] **Step 2: Add the user-level Codex template**

Create `scripts/multi_client_support/templates/AGENTS.codex-user.md`:

```md
# Codex Global Instructions

These instructions define default Codex behavior for repositories that do not provide more specific local guidance.

## Core Behavior

- Answer the current request directly.
- Prefer concise conclusions before supporting detail.
- Do not invent facts. State uncertainty and the evidence boundary.
- Ask only the most important clarifying question when one is required.
- Use the smallest sufficient context and avoid loading unrelated files.
- Use tools only when they materially improve correctness, verification, or task completion.
- Summarize long tool output before using it in the main response.

## Safety

- Respect the active Codex sandbox, approval, and filesystem boundaries.
- Ask before destructive, irreversible, or externally visible operations.
- Do not expose secrets, credentials, private tokens, or `.env` contents.
- Prefer reversible edits and focused verification.

## Project Rule Sources

When a project contains `.agent-rules/claude/` or `.claude/`, treat that directory as project-local rule source material.

Use this loading protocol:

1. Follow active `AGENTS.md` instructions first.
2. Use the smallest sufficient instruction layer.
3. Read a project rule file only when the current task matches that rule's scenario.
4. Prefer `.agent-rules/claude/` over `.claude/` when both exist.
5. Treat Claude-specific `settings.json`, `hooks/`, plugin settings, and `SendMessage` references as source context, not active Codex runtime configuration.
```

- [ ] **Step 3: Add the project-level Codex template**

Create `scripts/multi_client_support/templates/AGENTS.codex-project.md`:

```md
# Codex Project Instructions

This project can use Claude-oriented rule sources as shared agent rule material. This file is the Codex-native instruction entrypoint.

## Rule Source

Use the first existing rule source:

1. `.agent-rules/claude/`
2. `.claude/`

The Claude rule source is reference material. Do not blindly load or follow the whole `CLAUDE.md` file. Use this `AGENTS` file first, then read only the rule files needed for the current task.

Claude-specific `settings.json`, `hooks/`, plugins, and `SendMessage` instructions are not active Codex runtime configuration unless separate Codex-native configuration has been installed.

## Core Behavior

- Answer the current request directly.
- Start with the conclusion, then include only necessary detail.
- Keep context small. Do not load unrelated rules, templates, logs, or docs.
- If uncertain, state the uncertainty and what evidence is missing.
- Ask one key clarification question only when the answer materially changes the work.
- Prefer existing project patterns over new abstractions.
- Do not perform destructive or externally visible actions without approval.

## Rule Loading

Use the smallest sufficient instruction layer.

1. Apply this `AGENTS` document first.
2. For general tasks, use the core behavior above unless more detail is needed.
3. When a task matches a specific scenario, read only the most relevant file under the active rule source's `rules/`.
4. If the lightweight rule is insufficient, read only the matching file under the active rule source's `expandable/`.
5. Use templates under `expandable/templates/` only when output structure must be stable.
6. Do not load unrelated rules merely because they exist.

## Scenario Hints

- General work: `rules/task/general-task-rule-min.md`
- Tool use: `rules/task/tool-call-rule-min.md`
- Subagent work: `rules/task/sub-agent-rule-min.md`
- Design, planning, architecture, or brainstorming: `expandable/task/design-first-rule-min.md`
- Loop, cron, or repeated monitoring: `expandable/task/loop-cron-rule-min.md`
- Agent team workflows: `expandable/task/agent-team-rule-min.md`
- Output formats: `expandable/templates/`

When a referenced file does not exist, continue with the best available local instructions instead of blocking.
```

- [ ] **Step 4: Verify templates include required protocol text**

Run:

```sh
grep -F "Codex Global Instructions" scripts/multi_client_support/templates/AGENTS.codex-user.md
grep -F "Codex Project Instructions" scripts/multi_client_support/templates/AGENTS.codex-project.md
grep -F "Use the smallest sufficient instruction layer." scripts/multi_client_support/templates/AGENTS.codex-project.md
grep -F ".agent-rules/claude/" scripts/multi_client_support/templates/AGENTS.codex-project.md
```

Expected: each command prints the matching line.

- [ ] **Step 5: Commit the templates**

Run:

```sh
git add scripts/multi_client_support/templates/AGENTS.codex-user.md scripts/multi_client_support/templates/AGENTS.codex-project.md
git commit -m "templates: add codex instruction templates"
```

### Task 3: Implement `codex.sh`

**Files:**
- Modify: `scripts/multi_client_support/codex.sh`

- [ ] **Step 1: Replace the empty adapter script with the implementation**

Replace `scripts/multi_client_support/codex.sh` with:

```sh
#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
SOURCE_CLAUDE_DIR="$REPO_ROOT/.claude"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]

Options:
  -l  Target level:
      user     Write to ${CODEX_HOME:-$HOME/.codex}
      project  Write to the target project directory
  -p  Target project directory. Required for -l project. Invalid for -l user.
  -n  Output filename (default: AGENTS.codex.md)
  -F  Force overwrite existing output file. With -v, copy over matching vendored files while preserving unrelated extra files.
  -v  Vendor this repository's .claude/ to <target>/.agent-rules/claude/. Valid only for -l project.
  -h  Show this help message

Examples:
  sh scripts/multi_client_support/codex.sh -l user
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v
  sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
USAGE
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

expand_path() {
  case "$1" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

preflight_output() {
  dest="$1"
  force="$2"

  if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
    printf '[MANUAL] File already exists, please handle manually: %s\n' "$dest" >&2
    printf 'Use -F to force overwrite.\n' >&2
    exit 1
  fi
}

preflight_vendor() {
  target_project="$1"
  force="$2"
  dest="$target_project/.agent-rules/claude"

  if [ ! -d "$SOURCE_CLAUDE_DIR" ]; then
    printf 'Error: source .claude directory not found: %s\n' "$SOURCE_CLAUDE_DIR" >&2
    exit 1
  fi

  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    printf '[MANUAL] Vendor path exists but is not a directory: %s\n' "$dest" >&2
    printf 'Use -F only after manually resolving this path.\n' >&2
    exit 1
  fi

  if [ -d "$dest" ] && [ "$force" -ne 1 ]; then
    printf '[MANUAL] Vendor directory already exists, please handle manually: %s\n' "$dest" >&2
    printf 'Use -F to copy source files over matching destination paths while preserving unrelated extra files.\n' >&2
    exit 1
  fi
}

copy_template() {
  src="$1"
  dest="$2"
  force="$3"

  if [ ! -f "$src" ]; then
    printf 'Error: template not found: %s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && [ "$force" -eq 1 ]; then
    printf '[FORCE] Overwriting: %s\n' "$dest"
  fi

  cp "$src" "$dest"
  printf '[CREATED] %s\n' "$dest"
}

vendor_claude_source() {
  target_project="$1"
  force="$2"
  dest="$target_project/.agent-rules/claude"

  mkdir -p "$dest"

  if [ "$force" -eq 1 ] && [ -d "$dest" ]; then
    printf '[FORCE] Updating vendored Claude rule source: %s\n' "$dest"
  fi

  (
    cd "$SOURCE_CLAUDE_DIR"
    find . -type d -exec mkdir -p "$dest/{}" \;
    find . -type f -exec cp "{}" "$dest/{}" \;
  )

  printf '[VENDORED] %s -> %s\n' "$SOURCE_CLAUDE_DIR" "$dest"
}

LEVEL=""
TARGET=""
OUTNAME="AGENTS.codex.md"
FORCE=0
VENDOR=0

while getopts "l:p:n:Fvh" opt; do
  case "$opt" in
    l) LEVEL="$OPTARG" ;;
    p) TARGET="$OPTARG" ;;
    n) OUTNAME="$OPTARG" ;;
    F) FORCE=1 ;;
    v) VENDOR=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[ -n "$LEVEL" ] || fail_usage '-l <user|project> is required'

case "$LEVEL" in
  user|project)
    ;;
  *)
    fail_usage "invalid level: $LEVEL"
    ;;
esac

case "$OUTNAME" in
  ""|*/*)
    fail_usage '-n must be a filename, not a path'
    ;;
esac

case "$LEVEL" in
  user)
    [ -z "$TARGET" ] || fail_usage '-p is only valid with -l project'
    [ "$VENDOR" -eq 0 ] || fail_usage '-v is only valid with -l project'
    TARGET_DIR="${CODEX_HOME:-$HOME/.codex}"
    TARGET_DIR="$(expand_path "$TARGET_DIR")"
    TEMPLATE="$TEMPLATE_DIR/AGENTS.codex-user.md"
    ;;
  project)
    [ -n "$TARGET" ] || fail_usage '-p <target_dir> is required when -l project'
    TARGET_DIR="$(expand_path "$TARGET")"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Error: target directory does not exist: %s\n' "$TARGET_DIR" >&2
      exit 1
    fi
    TEMPLATE="$TEMPLATE_DIR/AGENTS.codex-project.md"
    ;;
esac

DEST="$TARGET_DIR/$OUTNAME"
preflight_output "$DEST" "$FORCE"
if [ "$VENDOR" -eq 1 ]; then
  preflight_vendor "$TARGET_DIR" "$FORCE"
fi

copy_template "$TEMPLATE" "$DEST" "$FORCE"

if [ "$VENDOR" -eq 1 ]; then
  vendor_claude_source "$TARGET_DIR" "$FORCE"
fi
```

- [ ] **Step 2: Run shell syntax check**

Run:

```sh
sh -n scripts/multi_client_support/codex.sh
```

Expected: no output and exit status 0.

- [ ] **Step 3: Run the smoke tests**

Run:

```sh
sh scripts/test-multi-client-codex.sh
```

Expected: every test prints `PASS: ...`.

- [ ] **Step 4: Inspect generated vendored files in a temporary project**

Run:

```sh
tmp="$(mktemp -d)"
mkdir -p "$tmp/project"
sh scripts/multi_client_support/codex.sh -l project -p "$tmp/project" -v
find "$tmp/project" -maxdepth 4 -type d | sort
find "$tmp/project/.agent-rules/claude" -maxdepth 2 -type f | sort | sed -n '1,40p'
```

Expected: output includes `$tmp/project/.agent-rules/claude`, `$tmp/project/.agent-rules/claude/rules`, `$tmp/project/.agent-rules/claude/expandable`, and `$tmp/project/.agent-rules/claude/CLAUDE.md`.

- [ ] **Step 5: Commit the adapter implementation**

Run:

```sh
git add scripts/multi_client_support/codex.sh
git commit -m "feat: add codex instruction adapter"
```

### Task 4: Update Multi-Client README

**Files:**
- Modify: `scripts/multi_client_support/README.md`

- [ ] **Step 1: Replace the placeholder README with phase-1 documentation**

Replace `scripts/multi_client_support/README.md` with:

```md
# Multi-Client Support

This directory contains adapters for using this repository's agent rule sources with clients other than Claude Code.

## Current Status

Only the Codex phase-1 adapter is implemented.

The Codex adapter focuses on instruction documents and optional rule-source vendoring. It does not generate `.codex/config.toml`, Codex hooks, Codex `.rules`, Codex skills, or Codex custom agents.

## Codex Adapter

Use `codex.sh` to generate Codex-native instruction documents from templates.

```sh
sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]
```

Options:

- `-l user|project`: target level.
- `-p <target_dir>`: project target directory. Required for `project`, invalid for `user`.
- `-n <filename>`: output filename. Default: `AGENTS.codex.md`.
- `-F`: force overwrite an existing output file. With `-v`, update matching vendored files while preserving unrelated extra files.
- `-v`: for project targets, copy this repository's `.claude/` directory into `<target>/.agent-rules/claude/`.

Examples:

```sh
# Generate user-level Codex instructions under ${CODEX_HOME:-$HOME/.codex}
sh scripts/multi_client_support/codex.sh -l user

# Generate a project-level Codex instruction draft
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project

# Generate project instructions and vendor the Claude rule source
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v

# Write directly to AGENTS.md
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
```

## Generated Files

Default project output:

```text
target-project/
  AGENTS.codex.md
```

With `-v`:

```text
target-project/
  AGENTS.codex.md
  .agent-rules/
    claude/
      CLAUDE.md
      RTK.md
      rules/
      expandable/
      hooks/
      settings.json
```

`AGENTS.codex.md` is the Codex-native entrypoint. The vendored `.agent-rules/claude/` directory is reference material. Claude-specific settings, hooks, plugins, and `SendMessage` references are not active Codex runtime configuration unless separate Codex-native configuration is installed.

## Verification

Run:

```sh
sh -n scripts/multi_client_support/codex.sh
sh scripts/test-multi-client-codex.sh
```

## Future Directions

Future phases may convert selected Claude rule intent into Codex-native config, hooks, command rules, skills, or custom agents. Those areas are intentionally out of scope for phase 1.
```

- [ ] **Step 2: Verify README mentions the phase boundary**

Run:

```sh
grep -F "Only the Codex phase-1 adapter is implemented." scripts/multi_client_support/README.md
grep -F "does not generate" scripts/multi_client_support/README.md
grep -F ".agent-rules/claude/" scripts/multi_client_support/README.md
```

Expected: each command prints the matching line.

- [ ] **Step 3: Commit README update**

Run:

```sh
git add scripts/multi_client_support/README.md
git commit -m "docs: document codex multi-client adapter"
```

### Task 5: Final Verification

**Files:**
- Verify: `scripts/multi_client_support/codex.sh`
- Verify: `scripts/test-multi-client-codex.sh`
- Verify: `scripts/multi_client_support/templates/AGENTS.codex-user.md`
- Verify: `scripts/multi_client_support/templates/AGENTS.codex-project.md`
- Verify: `scripts/multi_client_support/README.md`

- [ ] **Step 1: Run shell syntax checks for all touched shell scripts**

Run:

```sh
sh -n scripts/multi_client_support/codex.sh scripts/test-multi-client-codex.sh
```

Expected: no output and exit status 0.

- [ ] **Step 2: Run the Codex adapter smoke tests**

Run:

```sh
sh scripts/test-multi-client-codex.sh
```

Expected: all tests print `PASS: ...` and the command exits 0.

- [ ] **Step 3: Run the repository script syntax baseline**

Run:

```sh
sh -n scripts/*.sh
```

Expected: no output and exit status 0.

- [ ] **Step 4: Inspect git status**

Run:

```sh
git status --short --untracked-files=all
```

Expected: clean working tree after the previous task commits.

- [ ] **Step 5: Record final commit state**

Run:

```sh
git log --oneline -n 5
```

Expected: includes the three implementation commits:

```text
docs: document codex multi-client adapter
feat: add codex instruction adapter
templates: add codex instruction templates
test: add codex adapter smoke tests
```

## Self-Review

Spec coverage:

- `codex.sh` installer: Task 3.
- user and project targets: Tasks 1 and 3.
- default `AGENTS.codex.md` and custom `-n`: Tasks 1 and 3.
- optional vendoring to `.agent-rules/claude/`: Tasks 1 and 3.
- no `.codex/config.toml`, hooks, rules, skills, custom agents, or manifest: File Structure, Task 4 README, and absence from implementation tasks.
- README documentation: Task 4.
- verification: Tasks 1, 3, and 5.

Placeholder scan:

- No implementation step uses placeholder language.
- All created files include concrete content.
- All verification steps include exact commands and expected outcomes.

Consistency check:

- The adapter option set is consistently `-l`, `-p`, `-n`, `-F`, `-v`, `-h`.
- The vendor destination is consistently `.agent-rules/claude/`.
- The default output filename is consistently `AGENTS.codex.md`.
