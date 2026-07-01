# Codex Project Instructions

This project can use Claude-oriented rule sources as shared agent rule material. This file is the Codex-native instruction entrypoint.

## Rule Source

Use the first existing rule source:

1. `.agent-rules/claude/`
2. `.claude/`

The Claude rule source is reference material. Do not blindly load or follow the whole `CLAUDE.md` file. Use this `AGENTS` file first, then read only the rule files needed for the current task.

Claude-specific `settings.json`, `hooks/`, plugins, and `SendMessage` instructions are not active Codex runtime configuration unless separate Codex-native configuration has been installed.

## Core Behavior

- Answer the current request directly.
- Start with the conclusion, then include only necessary detail.
- Keep context small. Do not load unrelated rules, templates, logs, or docs.
- If uncertain, state the uncertainty and what evidence is missing.
- Ask one key clarification question only when the answer materially changes the work.
- Prefer existing project patterns over new abstractions.
- Do not perform destructive or externally visible actions without approval.

## Rule Loading

Use the smallest sufficient instruction layer.

1. Apply this `AGENTS` document first.
2. For general tasks, use the core behavior above unless more detail is needed.
3. When a task matches a scenario listed in Scenario Hints, read only that listed path under the active rule source. The listed path is authoritative and may be under `rules/` or `expandable/`.
4. When no Scenario Hint applies, read only the most relevant local rule file for the current task.
5. Use templates under `expandable/templates/` only when output structure must be stable.
6. Do not load unrelated rules merely because they exist.

## Scenario Hints

- General work: `rules/task/general-task-rule-min.md`
- Tool use: `rules/task/tool-call-rule-min.md`
- Subagent work: `rules/task/sub-agent-rule-min.md`
- Design, planning, architecture, or brainstorming: `expandable/task/design-first-rule-min.md`
- Loop, cron, or repeated monitoring: `expandable/task/loop-cron-rule-min.md`
- Agent team workflows: `expandable/task/agent-team-rule-min.md`
- Output formats: `expandable/templates/`

When a referenced file does not exist, continue with the best available local instructions instead of blocking.
