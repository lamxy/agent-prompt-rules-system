# open_supports_name_list.txt

`open_supports_name_list.txt` declares which localized open source support
packages should be vendored into projects created from this template.

The file is installed at:

```text
.claude/open_supports_name_list.txt
```

Install the listed packages separately from the rule source repository:

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

## Format

Each non-empty, non-comment line has this form:

```text
<support-name> [install args...]
```

Accepted support names:

- `GithubName/RepoName`, for example `colbymchenry/codegraph`
- `ost_GithubName_RepoName`, for example `ost_colbymchenry_codegraph`

Arguments after the support name are passed to that package's vendored
`scripts_for_install/install.*` script.

Version 1 does not support inline comments or argument values containing spaces.
Use full-line comments instead.

## Examples

```text
# Install CodeGraph for Claude Code at project scope.
colbymchenry/codegraph --target=claude --location=local

# Install GSD Core for Claude Code at project scope.
open-gsd/gsd-core --claude --local

# Internal ost_* names are also valid.
ost_garrytan_gstack
```
