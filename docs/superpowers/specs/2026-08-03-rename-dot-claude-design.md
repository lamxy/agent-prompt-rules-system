# Rename Repository Claude Source Directory

## Goal

Rename the repository-root `.claude/` source tree to `dot_claude/` so Claude
Code does not automatically treat this repository as a configured project,
while preserving every installed and runtime `.claude/` contract.

## Naming Boundary

`dot_claude/` means only the repository-side source/template directory.

The following paths retain their current names:

- User installation target: `~/.claude/`
- Project installation target: `<project>/.claude/`
- Project bundles: `dot_claude_projects/.claude-<FLAG>/.claude/`
- Codex vendored output: `<project>/.agent-rules/claude/`
- Runtime paths embedded in installed templates, rules, hooks, and third-party
  documentation

No compatibility symlink or empty root `.claude/` directory will remain,
because either would defeat the purpose of preventing automatic discovery.

## Implementation

Move the tracked root tree with `git mv .claude dot_claude`.

Update only repository-source references:

- `scripts/install.sh` reads from `dot_claude/` and continues writing to the
  selected `.claude/` target.
- `scripts/multi_client_support/codex.sh` vendors from `dot_claude/` and
  continues writing to `.agent-rules/claude/`.
- Repository documentation describes the source-to-target mapping explicitly.
- `.gitignore` rules that protect files inside the source tree follow the new
  `dot_claude/` name.

Do not mechanically replace `.claude` strings. Each occurrence must be
classified as repository source, installation target, runtime path, bundle
schema, or third-party documentation before it is changed.

## Safety

All work occurs on the `refactor/rename-dot-claude` branch in an isolated git
worktree.

Tests must not read from or write to the real user configuration:

- Never run an installer against the real `$HOME`, `~/.claude`, or a real
  project.
- Project-level smoke tests use a fresh `mktemp` target.
- User-level behavior, destructive paths, or any test whose side effects cannot
  be proven local to a temporary directory must run inside Docker with an
  isolated HOME and temporary filesystem.
- The repository may be mounted read-only into Docker; writable test outputs
  belong only to container or temporary volumes.

## Verification

1. Run POSIX shell syntax checks for scripts.
2. Run the multi-client regression test in Docker.
3. Run the open-supports installer regression test in Docker to detect
   unrelated regressions without touching the host.
4. Run a main installer smoke test against a temporary project target and
   compare representative output with `dot_claude/`.
5. Confirm `dot_claude/` exists and repository-root `.claude/` does not.
6. Scan scripts and tracked documentation for stale repository-source
   references.
7. Confirm required target/runtime `.claude/` references remain.

Two pre-existing baseline failures were identified during impact analysis:
the multi-client test expects different Simplified/Traditional Chinese wording
than its template, and an open-supports invalid-name assertion expects an
English message while the implementation emits Chinese. They are not part of
this rename and must not be silently fixed or attributed to it.
