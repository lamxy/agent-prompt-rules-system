# Open Supports Shell Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all tracked open_supports shell scripts syntactically valid and Docker-regression-tested, while repairing portable progress output and gstack's network/host contract.

**Architecture:** A single POSIX test harness runs only in Docker, mounts the repository read-only, and uses per-case temporary fixture directories plus stub executables. Production changes remain narrow: portable fixed-format progress messages in five installers, then a gstack-specific Git wrapper and host-validation contract.

**Tech Stack:** POSIX `sh`, dash, Docker, jq, Git

## Global Constraints

- All 12 tracked `open_supports/**/*.sh` files must pass `sh -n`.
- Tests execute only in Docker with the repository mounted read-only; all fixtures and HOME directories are under container `/tmp`.
- Tests must not invoke a real package-manager install, Agent CLI, upstream setup, or host configuration.
- Use stub commands through `PATH` to test first side-effect boundaries.
- Replace exactly the 22 confirmed `printf '-> ...'` calls with portable fixed-format output; do not use `printf --`.
- gstack accepts only `claude`, `codex`, `kiro`, `factory`, `opencode`, and `auto`.
- gstack must set `GIT_TERMINAL_PROMPT=0`, use `GSTACK_GIT_TIMEOUT_SECONDS` (default `120`), and preserve Git's exit status.
- A timeout utility is optional: prefer `timeout`, then `gtimeout`; warn and continue without a wall-clock wrapper if neither exists.
- No production code writes or infers proxy environment variables.

---

### Task 1: Add Isolated Shell Regression Harness

**Files:**
- Create: `scripts/test-open-supports-shell.sh`
- Test: every tracked `open_supports/**/*.sh`

**Interfaces:**
- Consumes: shell script paths relative to repository root
- Produces: one POSIX test command returning zero only when syntax, workflow state, help interfaces, and stubbed side-effect boundaries match the contract

- [ ] **Step 1: Write the failing regression harness**

Create `scripts/test-open-supports-shell.sh` with `set -eu`, a `mktemp -d`
workspace, an EXIT/HUP/INT/TERM cleanup trap, and assertion helpers. It must
fail when run against the current tree because dash reaches the existing
`printf '-> ...'` output in the gstack clone path.

The harness must implement these helpers:

```sh
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() { grep -F -- "$2" "$1" >/dev/null 2>&1 || fail "missing: $2"; }
assert_exit() { [ "$1" -eq "$2" ] || fail "exit=$1 want=$2"; }
```

For every file yielded by `find open_supports -type f -name '*.sh'`, run
`sh -n "$file"`; record its path before invoking it. Run the existing workflow
test with its state directory under the temporary workspace:

```sh
OST_WORKFLOW_STATE_DIR="$tmp/state" \
  sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh
```

Run `--help` for each of the ten package install scripts. The two workflow
scripts are exercised through `test-state.sh` instead because they are command
dispatchers rather than installers.

Build a fixture `bin/` directory and prepend it to PATH. The fixture commands
must log arguments to `$TEST_LOG`, never call host commands, and create only
the minimal files that the wrapper validates. Cover these side-effect paths:

| Installer | Stubbed boundary | Required assertion |
| --- | --- | --- |
| gstack | `git clone`; generated `setup` and `gstack-team-init` | wrapper reaches Git after progress output; setup receives `--host codex`; team helper sees setup sentinel |
| Taskmaster | `node`, `npm`, `npx` | local install invokes `npm install task-master-ai@latest` in temporary project |
| OpenSpec | `node`, `npm`, `openspec` | global install invokes `npm install -g @fission-ai/openspec@latest` then verifies CLI |
| Cognee | `python3` and its `-m pip` mode | dry-run emits no pip call; stubbed local path creates only temporary venv fixture |
| agency-agents | `git clone`, generated upstream `scripts/install.sh`, `bash` | verify-only runs upstream `--list tools` and does not call installation mode |

The other package installers must at minimum prove their `--help` parser does
not contact the network. The test ends with a single `PASS: open_supports shell
regressions` line.

- [ ] **Step 2: Run the harness in Docker and verify RED**

Run:

```sh
docker run --rm \
  -v "$PWD:/repo:ro" \
  -w /repo \
  alpine:3.22 \
  sh -c 'apk add --no-cache dash jq >/dev/null && dash scripts/test-open-supports-shell.sh'
```

Expected: FAIL in the gstack clone path with dash reporting the illegal `->`
printf option. No host directory is mounted except the read-only repository.

- [ ] **Step 3: Commit the red harness**

```sh
git add scripts/test-open-supports-shell.sh
git commit -m "test: cover open supports shell installers"
```

### Task 2: Make Progress Output Portable Across Shells

**Files:**
- Modify: `open_supports/ost_Fission-AI_OpenSpec/scripts_for_install/install.sh`
- Modify: `open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh`
- Modify: `open_supports/ost_garrytan_gstack/scripts_for_install/install.sh`
- Modify: `open_supports/ost_msitarzewski_agency-agents/scripts_for_install/install.sh`
- Modify: `open_supports/ost_topoteretes_cognee/scripts_for_install/install.sh`
- Test: `scripts/test-open-supports-shell.sh`

**Interfaces:**
- Consumes: existing progress message variables
- Produces: output with identical visible `->` text that works under dash, bash, and POSIX `sh`

- [ ] **Step 1: Confirm the target mutation is covered by the red harness**

The Task 1 gstack fixture must fail before its `git clone` stub receives any
arguments. Record this as the regression the production changes must fix.

- [ ] **Step 2: Replace all 22 calls with portable output**

Convert every match of this shape:

```sh
printf '-> Verifying OpenSpec CLI...\n'
printf '-> Installing Cognee into %s\n' "$VENV_DIR"
```

to this shape:

```sh
printf '%s\n' '-> Verifying OpenSpec CLI...'
printf '%s\n' "-> Installing Cognee into $VENV_DIR"
```

Keep the same variables and visible output. Do not alter any calls whose format
string does not begin with `-`.

- [ ] **Step 3: Run Docker regression and static checks**

Run the Task 1 Docker command, then:

```sh
docker run --rm -v "$PWD:/repo:ro" -w /repo alpine:3.22 \
  sh -c 'find open_supports -type f -name "*.sh" -exec sh -n {} \;'
```

Expected: both exit 0; the harness output contains the final PASS line.

- [ ] **Step 4: Commit**

```sh
git add open_supports/ost_Fission-AI_OpenSpec/scripts_for_install/install.sh \
  open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh \
  open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
  open_supports/ost_msitarzewski_agency-agents/scripts_for_install/install.sh \
  open_supports/ost_topoteretes_cognee/scripts_for_install/install.sh
git commit -m "fix: make open supports progress output portable"
```

### Task 3: Harden gstack Git and Host Handling

**Files:**
- Modify: `open_supports/ost_garrytan_gstack/scripts_for_install/install.sh`
- Modify: `open_supports/ost_garrytan_gstack/skill_for_setup/README.md`
- Modify: `open_supports/ost_garrytan_gstack/skill_for_setup/ost_garrytan_gstack_install/SKILL.md`
- Modify: `open_supports/ost_garrytan_gstack/usage_examples.md`
- Modify: `open_supports/ost_garrytan_gstack/repo_readme_summary.md`
- Modify: `scripts/test-open-supports-shell.sh`

**Interfaces:**
- Consumes: `--host`, `--install-dir`, `--team`, optional `GSTACK_GIT_TIMEOUT_SECONDS`
- Produces: non-interactive clone/pull execution with clear errors; only hosts that upstream setup installs

- [ ] **Step 1: Extend the failing tests for host and Git behavior**

Add harness cases that expect:

```sh
GSTACK_GIT_TIMEOUT_SECONDS=17 sh "$gstack" --host=cursor --install-dir="$tmp/cursor"
```

to exit 1 before the Git stub logs a call, and emit an unsupported-host
explanation. Repeat for `slate`, `openclaw`, `hermes`, and `gbrain`.

Add a supported `--host=auto` fixture case. Make the clone and existing-checkout
pull stubs log `GIT_TERMINAL_PROMPT`; assert it equals `0`. With a timeout stub
on PATH, assert the wrapper invokes it with `17` before Git. Have the Git stub
return 124 once for clone and once for pull; assert each wrapper invocation
returns 124 and names the failing operation in stderr.

- [ ] **Step 2: Run extended cases and verify RED**

Run the Task 1 Docker command. Expected: FAIL because current gstack accepts
`cursor`, rejects `auto`, and has no timeout wrapper or non-interactive Git
environment.

- [ ] **Step 3: Implement the narrow gstack contract**

Add:

```sh
GSTACK_GIT_TIMEOUT_SECONDS="${GSTACK_GIT_TIMEOUT_SECONDS:-120}"

run_git() {
  _operation=$1
  shift
  if command -v timeout >/dev/null 2>&1; then
    if GIT_TERMINAL_PROMPT=0 timeout "$GSTACK_GIT_TIMEOUT_SECONDS" git "$@"; then
      return 0
    else
      _status=$?
    fi
  elif command -v gtimeout >/dev/null 2>&1; then
    if GIT_TERMINAL_PROMPT=0 gtimeout "$GSTACK_GIT_TIMEOUT_SECONDS" git "$@"; then
      return 0
    else
      _status=$?
    fi
  else
    printf '%s\n' 'Warning: timeout/gtimeout unavailable; running Git without a wall-clock limit.' >&2
    if GIT_TERMINAL_PROMPT=0 git "$@"; then
      return 0
    else
      _status=$?
    fi
  fi
  printf 'Error: gstack Git %s failed for %s (timeout=%ss, exit=%s).\n' \
    "$_operation" "$INSTALL_DIR" "$GSTACK_GIT_TIMEOUT_SECONDS" "$_status" >&2
  return "$_status"
}
```

Validate it with a POSIX case expression that accepts only positive decimal
integers. Add `run_git OPERATION GIT_ARGS...`; it sets
`GIT_TERMINAL_PROMPT=0`, detects `timeout` then `gtimeout`, reports the failed
operation and install directory to stderr, and returns the original Git or
timeout exit code. If no timeout utility is available, print a warning once
and invoke non-interactive Git directly.

Make the `HOST` case accept exactly:

```sh
claude|codex|kiro|factory|opencode|auto
```

and reject the five non-installing values before `check_prerequisites` and
`ensure_checkout`, with messages that state whether the upstream host is
unsupported or requires a separate artifact-generation/session workflow.

Use `run_git clone clone --single-branch --depth 1 "$REPO_URL" "$INSTALL_DIR"`
and `run_git pull -C "$INSTALL_DIR" pull --ff-only`.

Add a no-timeout-utility fixture test: hide both timeout commands, make Git
succeed, and assert the warning is emitted while `GIT_TERMINAL_PROMPT=0` still
reaches Git.

- [ ] **Step 4: Align gstack documentation**

Update all five gstack package documents so their accepted host lists,
examples, fallback instructions, and completion wording match the wrapper.
Document the timeout environment variable and clarify that exported proxy
variables are inherited by Git and upstream setup, while Docker tests require
explicit environment injection.

- [ ] **Step 5: Run tests in Docker and commit**

Run the full Task 1 Docker harness and `sh -n` command from Task 2. Expected:
PASS and exit 0.

```sh
git add open_supports/ost_garrytan_gstack scripts/test-open-supports-shell.sh
git commit -m "fix: harden gstack installer network handling"
```

### Task 4: Perform Bounded Network Verification

**Files:**
- Verify only; no planned production changes

**Interfaces:**
- Consumes: public gstack GitHub repository
- Produces: fresh GitHub reachability evidence without cloning or installing

- [ ] **Step 1: Probe gstack remote from a disposable container**

Run:

```sh
docker run --rm alpine:3.22 sh -c '
  set -eu
  apk add --no-cache git >/dev/null
  GIT_TERMINAL_PROMPT=0 timeout 60 \
    git ls-remote --symref https://github.com/garrytan/gstack.git HEAD
'
```

Expected: exit 0 and a `ref: ... HEAD` response. The container has no repository
mount, no HOME mount, and no installation target.

- [ ] **Step 2: Record verification outcome**

Record the exact command, exit code, and response signature in the task report.
If unavailable, report the network failure as environmental; do not weaken the
local Docker regression suite or modify proxy settings.
