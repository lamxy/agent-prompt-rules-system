# Repository Guidelines

## Project Structure & Module Organization

When picking up existing work, read `docs/handoff/HANDOFF.md` first: it records the current status and todo plan, confirmed decisions, user constraints (never modify the local machine's configuration unless asked), open items, and a change log to append to after each requirement.

This is a personal agent configuration, skill, and tool management repository (Claude Code first, with a Codex adapter). It was converted from a layered prompt-rule system in 2026-10; see the "转型说明" section of `README.md`. The minimal Claude Code configuration source lives in `dot_claude/` (a short `CLAUDE.md`, `commands/`, `skills/` such as `myhandoff`, and a personal user-level `settings.json`); see `dot_claude/README.md` for why it was slimmed down. `dot_claude_legacy/` is a read-only archive of the previous layered rule system and is not used by any installer.

Package-style assets are grouped by target:

- `agents/agents-<FLAG>/`: agent definitions.
- `skills/skills-<FLAG>/`: skill packages.
- `claude_mds/`: `CLAUDE.md` variants such as `CLAUDE-frontend-dev.md`.
- `dot_mcp_jsons/`: `.mcp.json` templates.
- `dot_claude_projects/`: full project starter bundles.
- `settings/`: user, project, and local settings templates.
- `scripts/`: POSIX shell installers and smoke tests.
- `docs/`, `examples/`, and `open_supports/`: documentation, examples, and external support materials.

## Build, Test, and Development Commands

There is no build step. Run scripts from the repository root:

```sh
sh ./scripts/install.sh -l project -p /path/to/project/.claude -m ask
sh ./scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents
sh ./scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills
sh ./scripts/install-claude-project.sh -f frontend-dev -t /path/to/project
```

Before and after changing shell scripts, run the syntax checks and every test in `scripts/tests/`:

```sh
sh scripts/tests/run-all.sh
```

Add new tests as `scripts/tests/test-<subject>.sh`; `run-all.sh` picks them up automatically.

For installer behavior, use temporary directories for smoke tests. Do not test against real user configuration unless explicitly requested.

## Coding Style & Naming Conventions

Shell scripts should use POSIX `sh`, `set -eu`, two-space indentation, small helper functions, and `printf` for output. Avoid Bash-only syntax.

Markdown should be concise, task-oriented, and easy to scan. Preserve existing naming patterns: `agents-<FLAG>`, `skills-<FLAG>`, `CLAUDE-<FLAG>.md`, and `dot-mcp-json-<FLAG>.json`. Content under `dot_claude/` is written in Traditional Chinese.

Only add a line to `dot_claude/CLAUDE.md` when it changes Claude's behavior compared with the Claude Code defaults. Enforce hard boundaries with `settings.json` permissions, sandbox, or hooks instead of prompt text, and put scenario-specific guidance in a skill or a path-scoped rule.

## Testing Guidelines

Testing relies on shell syntax checks, installer smoke tests, and manual review of generated prompt/config files. Installer changes should cover successful install paths, missing package errors, existing target conflict handling, and `-F` overwrite behavior.

## Commit & Pull Request Guidelines

Git history uses concise conventional-style prefixes such as `feat:`, `docs:`, `test:`, `templates:`, and `refactor:`. Commit messages should describe intent, not only changed files.

Pull requests should state the goal, affected directories, verification performed, and any maintenance or context-size impact. For template or rule changes, explain why the change belongs at that layer rather than in a package-specific `CLAUDE.md`.

## Security & Configuration Tips

Never commit API keys, access tokens, `.env` contents, or private cloud credentials. Shared settings should avoid sensitive paths and should not automatically overwrite JSON that requires human review.
