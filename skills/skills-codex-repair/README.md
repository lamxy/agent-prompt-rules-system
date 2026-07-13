# Codex Repair Skills

This package contains reusable repair skills for Codex CLI installation and runtime issues.

Install into a project with:

```sh
sh scripts/install-skill-pkg.sh -f codex-repair -t /path/to/project/.claude/skills
```

Included skills:

- `npm-codex-enotempty-repair`: Fix global `npm install -g @openai/codex@latest` failures caused by `ENOTEMPTY` rename conflicts.
