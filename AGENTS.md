# Repository Guidelines

## Project Structure & Module Organization

This repository maintains Claude Code prompt, rule, agent, skill, MCP, and settings templates. Reusable shared configuration lives in `.claude/`, including rules, hooks, commands, settings, and base guidance.

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

Before changing shell scripts, run:

```sh
sh -n scripts/*.sh
```

For installer behavior, use temporary directories for smoke tests. Do not test against real user configuration unless explicitly requested.

## Coding Style & Naming Conventions

Shell scripts should use POSIX `sh`, `set -eu`, two-space indentation, small helper functions, and `printf` for output. Avoid Bash-only syntax.

Markdown should be concise, task-oriented, and easy to scan. Preserve existing naming patterns: `agents-<FLAG>`, `skills-<FLAG>`, `CLAUDE-<FLAG>.md`, `dot-mcp-json-<FLAG>.json`, and `*-min.md` for minimal rule files.

## Testing Guidelines

Testing relies on shell syntax checks, installer smoke tests, and manual review of generated prompt/config files. Installer changes should cover successful install paths, missing package errors, existing target conflict handling, and `-F` overwrite behavior.

## Commit & Pull Request Guidelines

Git history uses concise conventional-style prefixes such as `feat:`, `docs:`, `test:`, `templates:`, and `refactor:`. Commit messages should describe intent, not only changed files.

Pull requests should state the goal, affected directories, verification performed, and any maintenance or context-size impact. For template or rule changes, explain why the change belongs at that layer rather than in a package-specific `CLAUDE.md`.

## Security & Configuration Tips

Never commit API keys, access tokens, `.env` contents, or private cloud credentials. Shared settings should avoid sensitive paths and should not automatically overwrite JSON that requires human review.
