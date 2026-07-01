---
name: open-supports-install
description: Install or update project-local open_supports packages from .claude/open_supports_name_list.txt by using scripts/install-open-supports.sh.
argument-hint: '-t <project> [--skills-only|--no-skills|--dry-run|-F]'
---

# Open Supports Install

Use this Skill when the user asks to install, update, vendor, or inspect
`open_supports/` packages for a project.

## Pre-read

Before running commands:

1. Read the target project's `.claude/open_supports_name_list.txt`.
2. Read this repository's `open_supports/README.md`.
3. Read `docs/superpowers/specs/2026-07-01-open-supports-installer-design.md` if present.

## Procedure

Default to the current working directory as the target project when the user does
not specify a target.

Run from the rule source repository:

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

Useful modes:

```sh
sh scripts/install-open-supports.sh -t /path/to/project --dry-run
sh scripts/install-open-supports.sh -t /path/to/project --skills-only
sh scripts/install-open-supports.sh -t /path/to/project --no-skills
sh scripts/install-open-supports.sh -t /path/to/project -F
```

If a custom list file is requested:

```sh
sh scripts/install-open-supports.sh -t /path/to/project -l /path/to/open_supports_name_list.txt
```

If a custom `open_supports/` source root is requested:

```sh
sh scripts/install-open-supports.sh -t /path/to/project -s /path/to/open_supports
```

## Reporting

After the command finishes, report:

- which packages were vendored or reused;
- which wrapper Skills were generated or reused;
- which install scripts ran successfully;
- any `missing`, `no_script`, `failed`, or `conflict` counts;
- the next command the user should run if the script reported manual follow-up.
