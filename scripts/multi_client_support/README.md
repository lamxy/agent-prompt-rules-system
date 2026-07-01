# Multi-Client Support

This directory contains adapters for using this repository's agent rule sources with clients other than Claude Code.

## Current Status

Only the Codex phase-1 adapter is implemented.

The Codex adapter focuses on instruction documents and optional rule-source vendoring. It does not generate `.codex/config.toml`, Codex hooks, Codex `.rules`, Codex skills, or Codex custom agents.

## Codex Adapter

Use `codex.sh` to generate Codex-native instruction documents from templates.

```sh
sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]
```

Options:

- `-l user|project`: target level.
- `-p <target_dir>`: existing project target directory. Required for `project`, invalid for `user`.
- `-n <filename>`: output filename. Default: `AGENTS.codex.md`.
- `-F`: force overwrite an existing output file. With `-v`, update matching vendored files while preserving unrelated extra files.
- `-v`: for project targets, copy this repository's `.claude/` directory into `<target>/.agent-rules/claude/`.

Examples:

```sh
# Generate user-level Codex instructions under ${CODEX_HOME:-$HOME/.codex}
sh scripts/multi_client_support/codex.sh -l user

# Generate a project-level Codex instruction draft
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project

# Generate project instructions and vendor the Claude rule source
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v

# Write directly to AGENTS.md
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
```

## Generated Files

Default project output:

```text
target-project/
  AGENTS.codex.md
```

With `-v`:

```text
target-project/
  AGENTS.codex.md
  .agent-rules/
    claude/
      CLAUDE.md
      RTK.md
      rules/
      expandable/
      hooks/
      settings.json
      ...
```

This vendored tree is abbreviated; `codex.sh` recursively copies all files and directories under this repository's `.claude/`.

`AGENTS.codex.md` is the Codex-native entrypoint. The vendored `.agent-rules/claude/` directory is reference material. Claude-specific settings, hooks, plugins, and `SendMessage` references are not active Codex runtime configuration unless separate Codex-native configuration is installed.

## Verification

Run:

```sh
sh -n scripts/multi_client_support/codex.sh
sh scripts/test-multi-client-codex.sh
```

## Future Directions

Future phases may convert selected Claude rule intent into Codex-native config, hooks, command rules, skills, or custom agents. Those areas are intentionally out of scope for phase 1.
