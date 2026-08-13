# Taskmaster MCP Project Directory Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure Taskmaster's Claude project-scoped MCP configuration is written under `--project-dir`, never the installer's invocation directory.

**Architecture:** Keep the installer POSIX `sh` and fix the path at the process boundary: normalize the target whenever project-scoped MCP needs it, then invoke `claude mcp add` from that directory. Extend the existing Docker-only shell harness with a Claude stub that records its working directory and emulates the `.mcp.json` side effect.

**Tech Stack:** POSIX `sh`, Docker-isolated shell regression harness, stubbed Node/npm/npx/Claude CLIs.

## Global Constraints

- Do not read or write `/home/tesla/workspace/agent_workflow_learn/gstack_try`.
- Do not read or write real WSL, Windows, Claude, Codex, or user configuration; every behavioral test must run with a temporary `HOME` inside Docker.
- Preserve POSIX `sh` compatibility, `set -eu`, two-space indentation, and existing installer option names.
- With `--mcp-scope=project`, `claude mcp add` must execute from the normalized `--project-dir` so Claude writes `<project-dir>/.mcp.json`.
- Every Claude MCP registration branch must pass the requested `--scope` and use the canonical server name `task-master-ai`.
- A project-scoped MCP request must validate `--project-dir` even when `--location=global` and `--init-project` is absent.
- Other `open_supports/ost_*` installers must remain unchanged unless they independently write project-scoped MCP configuration; the audit found no such installer.

---

### Task 1: Route project-scoped Claude MCP registration through the target project

**Files:**
- Modify: `open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh`
- Modify: `scripts/test-open-supports-shell.sh`

**Interfaces:**
- Consumes: `PROJECT_DIR`, `LOCATION`, `CLAUDE_MCP`, `MCP_SCOPE`, and `TOOLS_MODE` parsed by the existing installer.
- Produces: Claude MCP registration whose working directory, scope, and server name match the caller's requested project configuration.

- [ ] **Step 1: Add a failing behavioral regression test**

Add a `claude` stub to `scripts/test-open-supports-shell.sh`. It must log `PWD` plus arguments, parse the `--scope` value, and create `$PWD/.mcp.json` only for `project` scope. Run the Taskmaster installer from a separate temporary invocation directory with:

```sh
--local --claude-mcp --tools=standard --mcp-scope=project --project-dir="$taskmaster_project"
```

Assert all of these observable outcomes:

```text
<invocation-dir>/.mcp.json does not exist
<taskmaster-project>/.mcp.json exists
the Claude log contains cwd=<taskmaster-project>
the Claude arguments contain: mcp add task-master-ai --scope project --env TASK_MASTER_TOOLS=standard -- npx -y task-master-ai@latest
```

Add a second invocation without `--tools` and assert it still uses `task-master-ai --scope project`, creates only the target project's `.mcp.json`, and never writes in the invocation directory. Use a distinct target directory so the second assertion cannot pass because of the first invocation.

- [ ] **Step 2: Run the focused Docker harness and verify RED**

Run from the isolated worktree root:

```sh
docker run --rm -v "$PWD:/work:ro" -w /work alpine:3.22 sh -c 'apk add --no-cache dash jq >/dev/null && dash scripts/test-open-supports-shell.sh'
```

Expected: FAIL because the Claude stub records the invocation directory and/or the no-tools branch omits `--scope project`.

- [ ] **Step 3: Implement the minimal path and scope fix**

Change project-directory normalization so it runs when any of these are true: local npm install, project initialization, or Claude MCP registration with `MCP_SCOPE=project`. In `configure_claude_mcp`, run both Claude registration branches in a subshell whose CWD is the normalized `PROJECT_DIR` when scope is `project`; preserve the existing invocation CWD for user/local scopes. Make both branches pass `--scope "$MCP_SCOPE"`, use server name `task-master-ai`, and retain the existing package/tool-mode semantics.

- [ ] **Step 4: Run focused and repository shell verification**

Run:

```sh
docker run --rm -v "$PWD:/work:ro" -w /work alpine:3.22 sh -c 'apk add --no-cache dash jq >/dev/null && dash scripts/test-open-supports-shell.sh'
sh -n scripts/*.sh open_supports/ost_*/scripts_for_install/install.sh
```

Expected: the Docker harness prints `PASS: open_supports shell regressions`; syntax validation exits 0.

- [ ] **Step 5: Confirm the change is scoped and commit**

Verify only the Taskmaster installer, its shell regression harness, and this plan changed. Commit with:

```sh
git add scripts/test-open-supports-shell.sh open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh
git add -f docs/superpowers/plans/2026-08-13-taskmaster-mcp-project-dir.md
git commit -m "fix: honor taskmaster MCP project directory"
```
