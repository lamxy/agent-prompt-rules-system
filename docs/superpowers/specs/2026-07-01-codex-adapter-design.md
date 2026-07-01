# Codex Adapter Design

## Purpose

Provide a first-phase Codex adapter for this repository's Claude-oriented rule system.

The adapter lets Codex quickly understand and use the existing `.claude/` rules without trying to fully reproduce Claude Code runtime behavior. It creates Codex-native instruction documents and can optionally vendor the current `.claude/` directory into a target project as a portable rule source.

## Phase Boundary

This design covers phase 1 only.

Phase 1 delivers:

- A lightweight `scripts/multi_client_support/codex.sh` installer.
- Codex instruction templates for user-level and project-level targets.
- Optional vendoring of the repository's `.claude/` directory into a target project.
- Documentation for how Codex should progressively consult vendored Claude rule sources.

Phase 1 does not deliver:

- `.codex/config.toml` generation.
- Codex hook conversion.
- Codex `.rules` command policy conversion.
- Codex skill generation from `.claude/rules/` or `.claude/expandable/`.
- Codex custom agent generation from Claude agent packages.
- A generic multi-client manifest or adapter framework.

Those areas remain future evolution directions and should not be implemented as part of this phase.

## Current Context

The repository's primary rule system is under `.claude/`:

- `.claude/CLAUDE.md` is the Claude Code primary memory file.
- `.claude/rules/` contains lightweight task and preference rules.
- `.claude/expandable/` contains lower-frequency rules, detailed references, and templates.
- `.claude/settings.json` and `.claude/hooks/` are Claude Code runtime configuration and enforcement surfaces.

Codex has different native surfaces:

- `AGENTS.md` for durable user and project instructions loaded at session start.
- Skills for true progressive disclosure, where only skill metadata is initially visible and full instructions are loaded when selected.
- `.codex/config.toml`, hooks, and command rules for runtime configuration and enforcement.

Phase 1 uses only the `AGENTS.md` instruction surface, plus optional vendored rule-source files. It intentionally avoids deeper Codex runtime integration.

## Design Summary

The adapter generates Codex-native instruction documents from templates.

It supports two target levels:

- `user`: write a global Codex instruction document under `${CODEX_HOME:-$HOME/.codex}`.
- `project`: write a project instruction document into a target project directory.

It supports two project source modes:

- reference mode: the generated project instruction document refers to an existing `.claude/` directory in the target project.
- vendor mode: the adapter copies this repository's `.claude/` directory to the target project's `.agent-rules/claude/` directory, and the generated instruction document refers to that vendored source.

The generated Codex document is the active instruction entrypoint. The vendored Claude files are reference material, not Codex-native runtime configuration.

## Command Interface

The script follows the repository's existing POSIX `sh` installer style:

```sh
sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]
```

Options:

- `-l user|project`: required target level.
- `-p <target_dir>`: required for `project`; invalid for `user`.
- `-n <filename>`: output filename. Default: `AGENTS.codex.md`.
- `-F`: force overwrite if the output file already exists.
- `-v`: vendor this repository's `.claude/` directory into the project target as `.agent-rules/claude/`. Valid only with `-l project`.
- `-h`: show usage.

Recommended examples:

```sh
sh scripts/multi_client_support/codex.sh -l user
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
```

The default output filename is `AGENTS.codex.md` to avoid overwriting an existing project `AGENTS.md`. Users can pass `-n AGENTS.md` when they want the file to be an active Codex instruction entrypoint immediately.

## Template Layout

Add two templates:

```text
scripts/multi_client_support/templates/
  AGENTS.codex-user.md
  AGENTS.codex-project.md
```

The script copies the matching template to the target output path. Phase 1 should avoid complex template expansion. If a small amount of substitution is needed, keep it limited to values such as the rule source path.

## User-Level Template

The user-level template should be generic and not tied to this repository's `.claude/` path.

It should include:

- concise Codex working preferences: answer directly, avoid context bloat, verify uncertainty, minimize tool use.
- safe execution expectations: ask before destructive or irreversible operations, respect sandbox and approval boundaries.
- a conditional project rule-source protocol: if the current project has `.agent-rules/claude/` or `.claude/`, treat it as a project-local rule source and follow the project-level loading protocol.

It should not include:

- references to this repository's absolute path.
- assumptions that every project contains `.claude/`.
- Claude Code hook, settings, plugin, or `SendMessage` semantics as active Codex behavior.

## Project-Level Template

The project-level template should be Codex-native and concise.

It should state:

- This project may use Claude-oriented rule sources as shared agent rule material.
- Follow the generated `AGENTS` document first.
- If `.agent-rules/claude/` exists, use it as the preferred Claude rule source.
- Otherwise, if `.claude/` exists, use it as the project-local Claude rule source.
- Treat `settings.json`, `hooks/`, and plugin-specific files as reference material unless Codex-native config has separately been installed.

It should include a rule-loading protocol:

1. Use the smallest sufficient instruction layer.
2. Apply the current `AGENTS` document first.
3. When a task matches a specific scenario, read only the most relevant file under the active rule source's `rules/`.
4. If the lightweight rule is insufficient, read only the matching file under the active rule source's `expandable/`.
5. Use templates under `expandable/templates/` only when output structure must be stable.
6. Do not load unrelated rules merely because they exist.

The project template should avoid instructing Codex to blindly follow the entire vendored `CLAUDE.md`. `CLAUDE.md` is a source reference, while the generated `AGENTS` file is the Codex entrypoint.

## Vendored Rule Source

When `-v` is used with `-l project`, the adapter copies:

```text
.claude/ -> <target_project>/.agent-rules/claude/
```

The copy should preserve the directory structure:

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
```

Copy behavior:

- Create missing parent directories.
- If `.agent-rules/claude/` already exists and `-F` is not set, exit with a manual-merge message.
- If `.agent-rules/claude/` already exists and `-F` is set, copy source files over matching destination paths and preserve unrelated extra files. Do not delete and recreate the directory.
- Do not mutate the source `.claude/` directory.

## Error Handling

The script should fail clearly when:

- `-l` is missing or invalid.
- `-l user` is used with `-p`.
- `-l project` is used without `-p`.
- the project target directory does not exist.
- `-v` is used without `-l project`.
- the source `.claude/` directory does not exist.
- the output file exists and `-F` is not set.
- the vendor destination exists and `-F` is not set.

The script should print concise status lines following existing installer style, such as:

- `[COPIED]`
- `[CREATED]`
- `[VENDORED]`
- `[MANUAL]`
- `[FORCE]`

## Verification

Phase 1 verification should include:

- `sh -n scripts/multi_client_support/codex.sh`.
- A user-level smoke test against a temporary `CODEX_HOME`.
- A project-level smoke test against a temporary project directory.
- A project-level vendor smoke test that confirms `.agent-rules/claude/CLAUDE.md`, `rules/`, and `expandable/` exist.
- Conflict-path tests for existing output files and existing vendor directories without `-F`.
- Force-overwrite smoke tests with `-F`.

These tests can be manual shell smoke tests in phase 1. A dedicated automated test script is optional, not required.

## Future Evolution

Future phases may add deeper Codex integration after phase 1 proves the instruction-entrypoint approach.

Possible future work:

- Generate `.codex/config.toml` from selected Claude settings intent.
- Convert selected Claude hooks into Codex hooks.
- Convert command permission intent into Codex `.rules` files.
- Convert selected `.claude/rules/` and `.claude/expandable/` documents into Codex skills for true progressive disclosure.
- Convert Claude agent packages into Codex custom agents.
- Introduce a cross-client manifest after at least one Codex adapter version has been validated in real projects.

These are intentionally out of scope for phase 1.
