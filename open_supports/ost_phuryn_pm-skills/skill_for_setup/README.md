# PM Skills Marketplace Install Skill - Usage

## Triggers

| Trigger | Example |
|---------|---------|
| Natural language | "Install PM Skills for Codex" |
| Natural language | "Set up phuryn/pm-skills in Claude Code" |
| Explicit skill | `/ost-phuryn-pm-skills-install` |

## Supported Clients

| Client | Support |
|--------|---------|
| Claude Code | Primary path through `claude plugin` commands |
| Codex CLI | Primary path through `codex plugin` commands |
| Claude Cowork | GUI setup instructions only |
| Gemini CLI | Skills-only copy mode |
| OpenCode | Skills-only copy mode |
| Cursor | Skills-only copy mode |
| Kiro | Skills-only copy mode |

## Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `--client=codex` | `codex` | Use Codex CLI plugin commands. |
| `--client=claude-code` | | Use Claude Code plugin commands. |
| `--client=cowork` | | Print Claude Cowork GUI setup steps. |
| `--client=gemini` | | Copy skills to Gemini CLI skills directory. |
| `--client=opencode` | | Copy skills to OpenCode skills directory. |
| `--client=cursor` | | Copy skills to Cursor skills directory. |
| `--client=kiro` | | Copy skills to Kiro skills directory. |
| `--plugins=all` | `all` | Install or copy all nine PM plugins. |
| `--plugins=a,b,c` | | Install or copy selected PM plugin names. |
| `--location=local` | `local` | Project-level skills directory for skills-only clients. |
| `--location=global` | | User-level skills directory for skills-only clients. |
| `--repo-dir=PATH` | | Existing `phuryn/pm-skills` checkout for skills-only copy mode. |
| `--verify-only` | | Run verification without installing or copying. |

## Scope

- Includes: choosing the target client, confirming local config changes before running them, installing or updating PM Skills, copying skills for skills-only clients, and verifying installed plugins or copied `SKILL.md` files.
- Excludes: converting Claude slash commands into Codex skills, teaching PM workflows in detail, uninstalling plugins, or changing unrelated Claude/Codex/Gemini/OpenCode/Cursor/Kiro configuration.
