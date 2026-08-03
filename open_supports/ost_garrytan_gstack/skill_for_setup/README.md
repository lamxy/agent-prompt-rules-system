# gstack Install Skill - Usage

## Triggers

| Trigger | Example |
|---|---|
| Natural language | "Install gstack for Claude Code" |
| Natural language | "Set up gstack skills for Codex CLI" |
| Natural language | "Enable gstack team mode for this project" |
| Explicit skill | `/ost-garrytan-gstack-install` |

## Supported Clients

| Client | Support status |
|---|---|
| Claude Code | Primary |
| Codex CLI | Primary via `--host=codex` |
| OpenCode | Supported via `--host=opencode` |
| Factory Droid | Supported via `--host=factory` |
| Kiro | Supported via `--host=kiro` |
| Auto-detected installed host | Supported via `--host=auto` |
| Cursor / Slate | Rejected: upstream `setup` does not install these hosts |
| OpenClaw / Hermes / GBrain | Use their separate artifact-generation or session workflow |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `--host=HOST` | `claude` | Runs upstream `./setup` for Claude Code or `./setup --host HOST` for a supported non-Claude agent. |
| `--team=MODE` | `none` | Also runs `gstack-team-init`; valid values are `required` and `optional`. |
| `--install-dir=DIR` | `~/.claude/skills/gstack` | Checkout directory for the official gstack repository. |
| `--help` / `-h` | | Shows script usage. |

`GSTACK_GIT_TIMEOUT_SECONDS` is an environment variable, not a CLI flag. It
defaults to `120` and accepts only positive decimal integers. Git runs with
`GIT_TERMINAL_PROMPT=0`; exported proxy variables are inherited by Git and
upstream `setup`. Docker callers must inject those proxy environment variables
explicitly into the container.

## Scope

- Includes: prerequisite checks, cloning or updating gstack, running upstream setup for a selected host, optional team initialization, and basic post-install verification guidance.
- Excludes: uninstalling gstack, deleting user or project configuration, writing workflow state JSON, and generating detailed usage tutorials.
