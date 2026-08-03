# Open Supports Shell Reliability Design

## Goal

Make every tracked `open_supports/**/*.sh` script syntactically valid and
regression-tested in an isolated Docker environment, while repairing the
confirmed gstack runtime failures without touching a host Agent configuration.

## Root Causes

Five package installers contain 22 calls shaped as `printf '-> ...'`.
dash and bash parse the leading hyphen as an option for their builtin `printf`,
so scripts invoked through `sh install.sh` stop before the intended command.

The affected installers are:

- `ost_Fission-AI_OpenSpec`
- `ost_eyaltoledano_claude-task-master`
- `ost_garrytan_gstack`
- `ost_msitarzewski_agency-agents`
- `ost_topoteretes_cognee`

The gstack wrapper separately runs Git network operations without disabling
interactive credential prompts, a configurable timeout, or operation-specific
failure context. Its advertised host list also does not match the current
upstream `setup` installation contract.

## Implementation

### Portable progress output

Replace every affected call with a fixed portable format string:

```sh
printf '%s\n' "-> Cloning gstack into: $INSTALL_DIR"
```

Do not use `printf --`, because that option is not portable POSIX `sh`.
No unrelated output, command, or package-manager behavior changes.

### gstack network behavior

Add a `run_git` helper to the gstack wrapper.

- Always set `GIT_TERMINAL_PROMPT=0` for wrapper-managed clone and pull
  commands so unavailable credentials fail instead of waiting for stdin.
- Read `GSTACK_GIT_TIMEOUT_SECONDS`, defaulting to `120`; it must be a positive
  integer.
- Prefer GNU `timeout`; use `gtimeout` on macOS when available.
- If neither command exists, run Git without a wall-clock wrapper and emit a
  warning that explains how to install coreutils or set up a compatible timeout
  command. This preserves support for default macOS installations instead of
  pretending a portable shell can reliably terminate a process tree itself.
- On Git failure, print whether the failed operation was `clone` or `pull`, the
  install directory, and the timeout setting before returning the original
  non-zero exit code.

The wrapper will not write or infer proxy settings. Exported `HTTP_PROXY`,
`HTTPS_PROXY`, `ALL_PROXY`, and `NO_PROXY` already pass through the wrapper's
subshell and to Git/upstream setup. Docker tests must inject them explicitly
when a proxy behavior is under test.

### gstack host contract

Accept exactly the current upstream setup hosts that actually run installation:

```text
claude, codex, kiro, factory, opencode, auto
```

Reject `cursor`, `slate`, `openclaw`, `hermes`, and `gbrain` before clone with
an actionable message: the first two are unsupported upstream hosts; the last
three use upstream artifact-generation or session-spawning flows rather than
a setup-based skill installation. Update the shell help, setup Skill,
README, usage examples, and summary documentation to make this distinction
clear.

## Tests

Create a POSIX shell test harness under `scripts/` that Docker executes with
the repository mounted read-only. It owns all fixtures under a container
temporary directory and supplies stub executables through `PATH`.

The harness must:

1. Run `sh -n` for every tracked `open_supports/**/*.sh` file.
2. Run the existing workflow-state test with a container-installed `jq`.
3. Exercise every package installer's `--help` and representative invalid
   argument path without external installation.
4. Exercise each package installer's first side-effect boundary with a stubbed
   runtime command, checking that calls receive the expected arguments and
   that no host configuration path is used.
5. Exercise gstack clone, pull, setup, team mode, timeout, and unsupported
   host branches with Git/Bun/setup stubs. The test must run the wrapper via
   dash or an equivalent shell that rejects the former `printf '-> ...'`
   pattern.
6. Perform one bounded real `git ls-remote` check against gstack's public
   repository, in a network-enabled disposable container with no repository or
   HOME mount. This probes GitHub reachability only; it does not clone, install,
   or run upstream setup.

No test invokes npm, pip, npx, curl, package-manager installation, an Agent
CLI, or a real upstream setup on the host.

## Success Criteria

- All 12 tracked shell scripts pass POSIX syntax validation.
- The Docker regression harness passes under dash-compatible `sh`.
- A gstack clone/pull failure returns an operation-specific non-zero error
  without prompting for credentials.
- The wrapper rejects non-installing/unsupported hosts before Git is invoked.
- Existing workflow state tests pass with isolated state storage.
- Only Docker containers access the network or create temporary installation
  fixtures; main and real user configuration remain untouched.
