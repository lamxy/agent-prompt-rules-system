# Repository Guidelines

## Project Structure & Module Organization

This repository maintains a Claude Code prompt and configuration system. Core reusable configuration lives in `.claude/`, including rules, hooks, commands, settings, and expandable templates. Scenario packages are grouped by type: `agents/agents-<FLAG>/` for agent definitions, `skills/skills-<FLAG>/` for skill directories, `claude_mds/` for `CLAUDE.md` variants, `dot_mcp_jsons/` for MCP templates, and `dot_claude_projects/` for full project starter bundles. Installer scripts live in `scripts/`. Documentation and external recommendations belong in `docs/`, while `examples/` and `open_supports/` hold sample and third-party support material.

## Build, Test, and Development Commands

There is no compiled build step. Use shell scripts directly from the repository root:

```sh
sh ./scripts/install.sh -l project -p /path/to/project/.claude -m ask
sh ./scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents
sh ./scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills
sh ./scripts/install-claude-project.sh -f frontend-dev -t /path/to/project
```

Before changing scripts, run syntax checks with `sh -n scripts/*.sh` and test risky copy behavior against a temporary directory.

## Coding Style & Naming Conventions

Shell scripts use POSIX `sh`, `set -eu`, two-space indentation, small helper functions, and `printf` for messages. Keep scripts portable and avoid Bash-only features. Markdown should be concise, task-oriented, and easy to scan. Preserve package naming patterns: `agents-<FLAG>`, `skills-<FLAG>`, `CLAUDE-<FLAG>.md`, and `dot-mcp-json-<FLAG>.json`. New minimal rule files should use `*-min.md`.

## Testing Guidelines

This project currently relies on script syntax checks, installer smoke tests, and manual review of generated prompt/config files. For installer changes, verify success and conflict paths, including non-existent package errors, existing target files, and `-F` overwrite behavior. Do not test installers against real user configuration unless explicitly intended.

## Commit & Pull Request Guidelines

Git history uses concise messages, often with conventional prefixes such as `feat:`, `refactor:`, `docs:`, `rules:`, and `templates:`. Make commits describe intent, not only files changed. PRs should state the goal, rationale, affected directories, whether context size or maintenance cost increases, and why the change belongs in its chosen layer instead of `CLAUDE.md` or another package.

## Security & Configuration Tips

Never commit API keys, access tokens, `.env` contents, or private cloud credentials. Shared settings should deny sensitive paths where possible and skip automatic JSON overwrites unless the merge is manually reviewed.
