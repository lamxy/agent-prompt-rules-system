# Open Supports Installer Design

## Context

This repository provides reusable Claude Code prompt and configuration packages.
Project-level packages under `dot_claude_projects/` can declare a list of open
source support packages required by that project type.

`open_supports/` stores localized support packages for Agent programming
libraries. Each support package is named after its GitHub repository, using the
form `ost_GithubName_RepoName`, and normally contains:

- `repo_readme_summary.md`
- `scripts_for_install/install.*`
- `skill_for_setup/README.md`
- `skill_for_setup/ost_GithubName_RepoName_install/SKILL.md`
- optional `.ost-refs/`

The new installer must connect these two systems without changing the current
meaning of `scripts/install-claude-project.sh`, which should continue to copy
project templates only.

## Goal

Add an independent open supports installer that reads a target project's
`.claude/open_supports_name_list.txt`, vendors the requested support packages
into that project, optionally generates project-local wrapper Skills, and
optionally runs the vendored install scripts.

## Non-Goals

- Do not make `install-claude-project.sh` automatically install open supports.
- Do not require JSON, YAML, TOML, `jq`, Python, or Node just to parse the list.
- Do not copy support package `skill_for_setup/*/SKILL.md` directly into
  `.claude/skills/`, because those Skills depend on files relative to the full
  support package.
- Do not implement uninstall behavior in the first version.

## Architecture

Use a script-first architecture with a natural-language Skill wrapper:

1. `scripts/install-open-supports.sh` is the core execution entrypoint.
2. `open_supports/ost_*` packages remain the source of package-specific install
   behavior and documentation.
3. A generic Skill package, for example
   `skills/skills-open-supports/open-supports-install/SKILL.md`, wraps the core
   script for natural-language use.
4. `dot_claude_projects/*/.claude/open_supports_name_list.txt` declares desired
   support packages but does not trigger installation by itself.

Installed project shape:

```text
target_project/
  .claude/
    open_supports/
      ost_colbymchenry_codegraph/
        repo_readme_summary.md
        scripts_for_install/install.sh
        skill_for_setup/
    skills/
      ost_colbymchenry_codegraph_install/
        SKILL.md
```

## CLI

Add:

```sh
sh scripts/install-open-supports.sh -t <target_project_dir> [options]
```

Options:

```text
-t <target_project_dir>  Target project root directory.
-l <list_file>           List file. Defaults to
                         <target_project_dir>/.claude/open_supports_name_list.txt.
-s <open_supports_root>  Source support root. Defaults to this repository's
                         open_supports/.
-F                       Force overwrite existing vendored support packages and
                         generated wrapper Skills.
--no-skills              Vendor support packages and run install scripts, but do
                         not generate wrapper Skills.
--skills-only            Vendor support packages and generate wrapper Skills, but
                         do not run install scripts.
--dry-run                Print planned actions without copying or running
                         scripts.
-h, --help               Show usage.
```

`--no-skills` and `--skills-only` are mutually exclusive.

Default behavior is:

1. vendor the support package;
2. generate a wrapper Skill;
3. run the vendored support package install script.

## Manifest Format

`open_supports_name_list.txt` stays a line-oriented text manifest:

```text
# Each non-comment line:
#   <support-name> [install args...]

colbymchenry/codegraph --target=claude --location=local
open-gsd/gsd-core --claude --local
ost_garrytan_gstack
```

Rules:

- Ignore blank lines.
- Ignore lines whose first non-space character is `#`.
- The first field is the support package name.
- Support names may be either `GithubName/RepoName` or
  `ost_GithubName_RepoName`.
- Map `GithubName/RepoName` to `ost_GithubName_RepoName`.
- Pass all remaining fields through to the support package install script.
- Version 1 does not support inline comments.
- Version 1 does not support argument values containing spaces.

## Execution Flow

For each valid manifest line:

1. Parse the support name and install arguments.
2. Resolve the source support package directory.
3. If the source package is missing, record `missing` and continue.
4. Vendor the package into
   `<target_project_dir>/.claude/open_supports/<ost_name>/`.
5. If the vendored package already exists and `-F` is not set, reuse it without
   overwriting.
6. Unless `--no-skills` is set, generate a wrapper Skill in
   `<target_project_dir>/.claude/skills/<ost_name>_install/SKILL.md`.
7. Unless `--skills-only` is set, run the vendored package install script from
   the vendored package directory and pass through the line arguments.
8. Continue processing later packages even if one package fails.

Install scripts should run from the vendored package directory so their relative
paths remain valid.

## Wrapper Skill

Do not copy the original package Skill directly. Generate a small project-local
wrapper Skill that points to the vendored support package.

The wrapper Skill should:

- use a discoverable name such as `ost-colbymchenry-codegraph-install`;
- explain that it operates on the project-local vendored support package;
- require reading:
  - `.claude/open_supports/<ost_name>/repo_readme_summary.md`;
  - `.claude/open_supports/<ost_name>/skill_for_setup/README.md`;
  - `.claude/open_supports/<ost_name>/skill_for_setup/<ost_name>_install/SKILL.md`;
  - `.claude/open_supports/<ost_name>/.ost-refs/` if present;
- instruct the agent to run the vendored install script from:
  - `.claude/open_supports/<ost_name>/scripts_for_install/install.*`.

This keeps each target project self-contained and avoids broken relative paths.

## Overwrite And Reuse

Use conservative overwrite behavior:

- If a vendored package exists and `-F` is not set, reuse it.
- If a generated wrapper Skill exists and `-F` is not set, keep it and continue.
- If `-F` is set, replace both the vendored support package and generated
  wrapper Skill.
- `-F` does not override or control behavior inside each package's install
  script. Package-specific update behavior remains the responsibility of that
  script.

## Error Handling

The installer should process all manifest entries and summarize at the end.

Recommended statuses:

- `vendored`
- `reused`
- `skill_generated`
- `skill_reused`
- `script_ok`
- `missing`
- `no_script`
- `failed`

Exit behavior:

- Missing manifest file: fail immediately with non-zero exit.
- Invalid CLI options: fail immediately with non-zero exit.
- Missing source support package: record and continue.
- Missing install script while scripts are enabled: record `no_script` and mark
  that package failed.
- Install script exits non-zero: record `failed` and continue.
- Final exit is non-zero if any package is `missing`, `no_script`, or `failed`.
- Final exit is zero if all packages succeeded, were reused, or were skipped only
  by the selected mode.

## Documentation Updates

Update documentation in:

- `README.md`: mention the new installer in the script list and usage section.
- `dot_claude_projects/README.md`: explain that project templates can include
  `.claude/open_supports_name_list.txt` and that installation is a separate
  command.
- `dot_claude_projects/.claude-FLAG-NAME_template/README-open_supports_name-list.md`:
  document the line-oriented manifest format and examples.
- `dot_claude_projects/.claude-FLAG-NAME_template/.claude/open_supports_name_list.txt`:
  include commented examples.

## Verification

Syntax check:

```sh
sh -n scripts/install-open-supports.sh
```

Smoke test:

```sh
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/.claude"
printf 'colbymchenry/codegraph --help\n' > "$tmpdir/.claude/open_supports_name_list.txt"
sh scripts/install-open-supports.sh -t "$tmpdir" --skills-only
```

Test cases:

- `GithubName/RepoName` maps to `ost_GithubName_RepoName`.
- `ost_*` package names are accepted.
- Blank lines and full-line comments are ignored.
- `--dry-run` does not write files or run scripts.
- `--skills-only` vendors packages and generates wrappers without running
  scripts.
- `--no-skills` vendors packages and runs scripts without generating wrappers.
- Existing vendored packages are reused without `-F`.
- `-F` replaces vendored packages and wrappers.
- Missing support packages are summarized as `missing`.
- Missing manifest file fails immediately.
