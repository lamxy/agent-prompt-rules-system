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
| Cursor | Supported via `--host=cursor` |
| Factory Droid | Supported via `--host=factory` |
| Slate | Supported via `--host=slate` |
| Kiro | Supported via `--host=kiro` |
| Hermes | Supported via `--host=hermes` |
| GBrain | Supported via `--host=gbrain` |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `--host=HOST` | `claude` | Runs upstream `./setup` for Claude Code or `./setup --host HOST` for a supported non-Claude agent. |
| `--team=MODE` | `none` | Also runs `gstack-team-init`; valid values are `required` and `optional`. |
| `--install-dir=DIR` | `~/.claude/skills/gstack` | Checkout directory for the official gstack repository. |
| `--help` / `-h` | | Shows script usage. |

## Scope

- Includes: prerequisite checks, cloning or updating gstack, running upstream setup for a selected host, optional team initialization, and basic post-install verification guidance.
- Excludes: uninstalling gstack, deleting user or project configuration, writing workflow state JSON, and generating detailed usage tutorials.
