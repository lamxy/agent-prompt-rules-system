# Rename Repository Claude Source Directory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the repository-root Claude source tree from `.claude/` to `dot_claude/` without changing any installed or runtime `.claude/` contract.

**Architecture:** Treat `dot_claude/` as a repository-only source name. Installers resolve that source explicitly, while their user, project, bundle, and vendored destinations keep the names required by Claude Code and Codex.

**Tech Stack:** POSIX `sh`, Git, Docker, Markdown

## Global Constraints

- The repository source directory is exactly `dot_claude/`.
- The repository root must not contain `.claude/`, including as a symlink or empty compatibility directory.
- User targets remain `~/.claude/`.
- Project targets remain `<project>/.claude/`.
- Project bundles remain `dot_claude_projects/.claude-<FLAG>/.claude/`.
- Codex vendored output remains `<project>/.agent-rules/claude/`.
- Runtime `.claude/` paths embedded in installed content and third-party documentation remain unchanged.
- Never run an installer against the real `$HOME`, `~/.claude`, or a real project.
- Tests with installer side effects run in Docker with the repository mounted read-only and all writable output confined to the container or a temporary volume.
- Do not fix the two known baseline assertion-language failures in `scripts/test-multi-client-codex.sh` and `scripts/test-install-open-supports.sh`.

---

### Task 1: Move the Source Tree and Preserve Installer Behavior

**Files:**
- Rename: `.claude/` to `dot_claude/`
- Create: `scripts/test-install-source.sh`
- Modify: `scripts/install.sh`
- Modify: `scripts/multi_client_support/codex.sh`
- Modify: `scripts/test-multi-client-codex.sh`

**Interfaces:**
- Consumes: repository-root source template files
- Produces: `scripts/install.sh` source resolution from `dot_claude/`; Codex vendoring from `dot_claude/`; unchanged `.claude/` and `.agent-rules/claude/` destinations

- [ ] **Step 1: Write the failing integration test**

Create `scripts/test-install-source.sh` as a POSIX `sh` test. It must:

1. Fail unless `dot_claude/CLAUDE.md` exists and repository-root `.claude/` is absent.
2. Create a temporary project `.claude/` target, run:

   ```sh
   sh scripts/install.sh -l project -p "$target/.claude" -m overwrite
   ```

3. Compare the installed `CLAUDE.md` with `dot_claude/CLAUDE.md`.
4. Create a second temporary project, run:

   ```sh
   sh scripts/multi_client_support/codex.sh -l project -p "$codex_target" -v
   ```

5. Compare vendored `CLAUDE.md` with `dot_claude/CLAUDE.md`, assert
   `.agent-rules/claude/rules/` exists, and assert no `.claude/` destination
   was created in that Codex target.
6. Use `mktemp -d`, install an EXIT/HUP/INT/TERM cleanup trap, and never use
   the caller's HOME.

The production mutations this test catches are: restoring the old repository
source name, pointing either installer at the wrong source, changing either
destination contract, or leaving a discoverable root `.claude/`.

- [ ] **Step 2: Run the test in Docker and verify RED**

Run:

```sh
docker run --rm \
  -v "$PWD:/repo:ro" \
  -w /repo \
  alpine:3.22 \
  sh scripts/test-install-source.sh
```

Expected: FAIL because `dot_claude/CLAUDE.md` does not exist before the rename.
No host path other than the read-only repository mount is exposed.

- [ ] **Step 3: Rename the source and update source resolution**

Run:

```sh
git mv .claude dot_claude
```

In `scripts/install.sh`:

- Change `SOURCE_DIR` to the repository-root `dot_claude`.
- Change only help text that says an exclusion is relative to the source
  `.claude/` root; call it the source `dot_claude/` root.
- Keep `TARGET_DIR="$HOME/.claude"` and all project/local target wording.

In `scripts/multi_client_support/codex.sh`:

- Rename `SOURCE_CLAUDE_DIR` to `SOURCE_DOT_CLAUDE_DIR`.
- Point it at `$REPO_ROOT/dot_claude`.
- Update every reference to that variable.
- Describe `dot_claude/` as the repository source in help and error text.
- Keep the output destination `.agent-rules/claude/`.

In `scripts/test-multi-client-codex.sh`:

- Rename the source-copy test function and its PASS message from `.claude
  source` to `dot_claude source`.
- Do not alter language assertions or output-destination assertions.

- [ ] **Step 4: Run the focused test in Docker and verify GREEN**

Run the same Docker command from Step 2.

Expected: PASS with exit code 0. The installed project target contains
`.claude/CLAUDE.md`; the Codex target contains
`.agent-rules/claude/CLAUDE.md`; repository-root `.claude/` is absent.

- [ ] **Step 5: Run shell syntax checks**

Run:

```sh
sh -n scripts/*.sh scripts/multi_client_support/*.sh
```

Expected: exit code 0 with no diagnostics.

- [ ] **Step 6: Commit**

```sh
git add dot_claude scripts/install.sh scripts/multi_client_support/codex.sh \
  scripts/test-install-source.sh scripts/test-multi-client-codex.sh
git commit -m "refactor: rename Claude source directory"
```

### Task 2: Align Repository Documentation and Ignore Rules

**Files:**
- Modify: `.gitignore`
- Modify: `AGENTS.md`
- Modify: `CONTRIBUTING.md`
- Modify: `README.md`
- Modify: `scripts/README.md`
- Modify: `scripts/multi_client_support/README.md`

**Interfaces:**
- Consumes: the source/runtime naming boundary established in Task 1
- Produces: contributor and user documentation that distinguishes repository source `dot_claude/` from installed `.claude/`

- [ ] **Step 1: Update repository-source documentation**

Apply these semantic edits:

- `AGENTS.md`: shared reusable source configuration lives in `dot_claude/`;
  installation command targets remain `.claude/`.
- `CONTRIBUTING.md`: repository contribution paths become
  `dot_claude/CLAUDE.md`, `dot_claude/rules/task/`,
  `dot_claude/rules/templates/`, and `dot_claude/rules/preferences/`.
- `README.md`: rename the root source section and source tree to
  `dot_claude/`; describe `scripts/install.sh` as copying from
  `dot_claude/` to user/project `.claude/`; make `-E` relative to the
  source `dot_claude/` root; update the complete repository tree and script
  comments. Preserve quick-start target paths, project bundle paths,
  open-supports destinations, and third-party paths.
- `scripts/README.md`: describe `install.sh` as source `dot_claude/` to
  target `.claude/`; make `-E` relative to `dot_claude/`.
- `scripts/multi_client_support/README.md`: describe vendoring from the
  repository `dot_claude/` source to `.agent-rules/claude/`.

- [ ] **Step 2: Align source-tree ignore rules**

In `.gitignore`, move repository-source-specific rules from `.claude/...` to
`dot_claude/...`:

```gitignore
dot_claude/settings.local.json
dot_claude/CLAUDE-long.md
dot_claude/audit-reports/*
!dot_claude/audit-reports/.gitkeep
```

Do not rename the existing tracked `audi_reports/` directory or repair its
historical spelling mismatch in this task.

- [ ] **Step 3: Review remaining `.claude` references semantically**

Run:

```sh
rg -n --hidden --glob '!.git/**' --glob '!.worktrees/**' '\.claude/' \
  AGENTS.md CONTRIBUTING.md README.md scripts dot_claude .gitignore
```

Classify every result. Repository-source references must use `dot_claude/`.
Installation targets, runtime paths inside `dot_claude/`, project bundle
schema, and `.agent-rules/claude/` output remain unchanged.

Also run:

```sh
test -d dot_claude
test ! -e .claude
```

Expected: both commands exit 0.

- [ ] **Step 4: Commit**

```sh
git add .gitignore AGENTS.md CONTRIBUTING.md README.md \
  scripts/README.md scripts/multi_client_support/README.md
git commit -m "docs: align dot_claude source references"
```

### Task 3: Run Isolated Regression Verification

**Files:**
- Verify only; no planned production changes

**Interfaces:**
- Consumes: completed rename and documentation alignment
- Produces: fresh evidence that behavior matches the design without touching the host configuration

- [ ] **Step 1: Run the focused integration test in Docker**

```sh
docker run --rm \
  -v "$PWD:/repo:ro" \
  -w /repo \
  alpine:3.22 \
  sh scripts/test-install-source.sh
```

Expected: PASS.

- [ ] **Step 2: Run existing installer regressions in Docker**

Run each suite with the repository mounted read-only:

```sh
docker run --rm -v "$PWD:/repo:ro" -w /repo alpine:3.22 \
  sh scripts/test-multi-client-codex.sh

docker run --rm -v "$PWD:/repo:ro" -w /repo alpine:3.22 \
  sh scripts/test-install-open-supports.sh
```

Compare any failures with the recorded baseline. Only the two known
assertion-language mismatches are acceptable; any new failure blocks completion.

- [ ] **Step 3: Run final syntax and source-boundary checks**

```sh
sh -n scripts/*.sh scripts/multi_client_support/*.sh
test -d dot_claude
test ! -e .claude
git diff --check "$(git merge-base main HEAD)..HEAD"
```

Expected: all commands exit 0.

- [ ] **Step 4: Record verification**

Append the exact commands, exit codes, PASS counts, and the two baseline failure
signatures to the task report. Do not modify production files merely to make
baseline language assertions green.

