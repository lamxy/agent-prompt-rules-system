# PM Skills Marketplace — 使用示例

## 安装作用域示例

```sh
# 项目级 skills-only 复制：脚本在目标项目中建立 .opencode/skills
sh scripts_for_install/install.sh --client=opencode --local /path/to/project

# 用户级 skills-only 复制
sh scripts_for_install/install.sh --client=opencode --global
```

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

### 安装后跑一次 discovery workflow

适用场景：PM Skills 已安装完成，需要确认 Claude/Codex 能实际调用 PM workflow。

Claude Code 或 Claude Cowork：

```text
/discover AI-powered meeting summarizer for remote teams
```

Codex CLI：

```text
Run product discovery on AI-powered meeting summarizer for remote teams: brainstorm options, map assumptions, prioritize the risky ones, then design experiments -- pause between each step.
```

预期结果：Claude 客户端启动 discovery cycle；Codex 通过已安装 skills 推进同类 discovery workflow，但不依赖 Claude slash command 运行时。

来源：`repo_readme_summary.md` 第 3 部分；官方 README 的 Codex CLI 说明。

## 常见场景

### 在 Claude Code 中使用 PM slash commands

适用场景：已通过 Claude Code 安装插件，想直接使用仓库提供的 Claude commands 和 skills。

```text
/discover AI-powered meeting summarizer for remote teams
```

预期结果：Claude Code 使用 PM Skills Marketplace 中安装的 command 和相关 skills，进入 discovery、assumption mapping、prioritization、experiment design 等步骤。

注意事项：slash commands 是 Claude-specific；命令是否可见取决于 Claude Code 插件安装与刷新状态。

来源：`repo_readme_summary.md` 第 2、3 部分。

### 在 Codex 中用自然语言调用等价 workflow

适用场景：已通过 Codex CLI 安装插件，想使用 PM skills，但不依赖 Claude slash commands。

```text
Run product discovery on AI-powered meeting summarizer for remote teams: brainstorm options, map assumptions, prioritize the risky ones, then design experiments -- pause between each step.
```

预期结果：Codex 读取已安装插件中的 skills，并按自然语言描述执行 PM discovery workflow。

注意事项：`/discover`、`/write-prd` 等 Claude slash command 文件可能已安装，但不会作为 Codex slash commands 运行。

来源：`repo_readme_summary.md` 的 Codex CLI 段落；`skill_for_setup/ost_phuryn_pm-skills_install/SKILL.md` 的 After Installation。

### 在 skills-only 客户端确认技能文件可用

适用场景：Gemini CLI、OpenCode、Cursor 或 Kiro 已通过 copy mode 获得 skill folders，需要确认客户端能发现 skill 文件。

```sh
find .opencode/skills -mindepth 2 -maxdepth 2 -name SKILL.md
```

预期结果：输出一个或多个 `SKILL.md` 路径。对其他客户端，把 `.opencode/skills` 换成对应目录：`.gemini/skills`、`.cursor/skills` 或 `.kiro/skills`。

注意事项：skills-only 客户端只应期待 copied skills 可用；Claude slash commands 不会在这些客户端中运行。

来源：`scripts_for_install/install.sh` 的 `verify_skills_client`；`repo_readme_summary.md` 的 Other AI assistants 说明。

### 只验证当前安装状态

适用场景：不想修改本地配置，只想检查 PM Skills 是否已安装或 copied。

```sh
sh scripts_for_install/install.sh --client=codex --verify-only
sh scripts_for_install/install.sh --client=claude-code --verify-only
sh scripts_for_install/install.sh --client=opencode --location=local --verify-only /path/to/project
```

预期结果：脚本打印 marketplace/plugin 或 `SKILL.md` 检查结果；失败时返回非零状态并指出缺失的命令、插件或目录。

注意事项：`--verify-only` 不安装插件、不复制 skills；skills-only 客户端仍需要传入正确的 `--client` 和 `--location`。

来源：`scripts_for_install/install.sh`；`skill_for_setup/ost_phuryn_pm-skills_install/SKILL.md` 的 Verification。

## 与 Agent 客户端配合

### Claude Code / Claude Cowork

适用场景：需要完整的 PM Marketplace 体验，包括 Claude slash commands 和 skills。

```text
/discover AI-powered meeting summarizer for remote teams
```

预期结果：已安装的 PM plugin command 触发对应 workflow；Cowork 可在 Browse plugins 中确认 PM Skills plugins 和 commands 可见。

来源：`repo_readme_summary.md` 第 2、3 部分；`scripts_for_install/install.sh` 的 Cowork verification 文案。

### Codex CLI

适用场景：需要在 Codex 中使用同一 marketplace 的 skills。

```text
Use the installed PM Skills to write a PRD for an AI-powered meeting summarizer. Start by clarifying the product goal, target users, assumptions, and acceptance criteria.
```

预期结果：Codex 按自然语言请求选择相关 PM skills；不会把 Claude slash command 当作 Codex slash command 执行。

注意事项：如果需要把常用 Claude command files 转成 Codex skills，应作为单独任务处理；官方 README 将其描述为 best-effort、model-driven conversion。

来源：`repo_readme_summary.md` 的 Codex 使用差异与转换建议。

### Gemini CLI / OpenCode / Cursor / Kiro

适用场景：客户端支持读取 skill folders，但不支持 Claude plugin runtime。

```text
Use the copied PM skills to plan the launch for an AI-powered meeting summarizer.
```

预期结果：客户端可基于 copied `SKILL.md` 文件使用 PM skill instructions；slash commands 不可用。

来源：`repo_readme_summary.md` 的 Other AI assistants 表格；`skill_for_setup/README.md` 的 Supported Clients。

## 验证与排错

### Codex 插件不可见

适用场景：Codex 中自然语言调用没有明显使用 PM skills，或 plugin list 中看不到目标插件。

```sh
codex plugin list
codex plugin list --marketplace pm-skills
sh scripts_for_install/install.sh --client=codex --verify-only
```

预期结果：`pm-skills` marketplace 可见，已安装插件出现在 plugin list 中；脚本逐个打印 `Verified Codex plugin: ...`。

处理方式：如果 `codex` command 不存在，先安装或暴露 Codex CLI；如果 marketplace 不可见，按安装 Skill 重新添加或刷新 marketplace。

来源：`repo_readme_summary.md` 验证命令；`scripts_for_install/install.sh` 的 `verify_codex`。

### Claude 插件不可见

适用场景：Claude Code 中 slash command 或 PM plugin 不可见。

```sh
claude plugin list
claude plugin list --json --available
sh scripts_for_install/install.sh --client=claude-code --verify-only
```

预期结果：目标 PM plugin 出现在 Claude plugin list 中；脚本逐个打印 `Verified Claude plugin: ...`。

处理方式：如果 `claude` command 不存在，先安装或暴露 Claude Code CLI；如果插件缺失，按安装 Skill 重新安装或更新对应 plugin。

来源：`repo_readme_summary.md` 验证命令；`scripts_for_install/install.sh` 的 `verify_claude_code`。

### Skills-only 客户端没有发现 skills

适用场景：Gemini CLI、OpenCode、Cursor 或 Kiro 中 PM skills 不可用。

```sh
sh scripts_for_install/install.sh --client=opencode --location=local --verify-only /path/to/project
```

预期结果：脚本打印 `Verification passed: found ... SKILL.md file(s)`。

处理方式：确认 `--client` 和 `--location` 与实际复制目标一致；如果之前没有提供 `--repo-dir` 且脚本需要复制 skills，确保本机有 `git` 或传入已有 `phuryn/pm-skills` checkout。

来源：`scripts_for_install/install.sh` 的 copy/verify 逻辑；安装 Skill Troubleshooting。

### Codex 中输入 `/discover` 没有效果

适用场景：插件已安装，但 Codex 不识别 Claude slash command。

```text
Run product discovery on AI-powered meeting summarizer: brainstorm options, map assumptions, prioritize the risky ones, then design experiments -- pause between each step.
```

预期结果：Codex 通过自然语言调用 PM skills，而不是执行 `/discover` slash command。

处理方式：把 Claude slash command 改写成自然语言 workflow 请求；如确实需要 Codex-native command/skill 转换，单独发起转换任务。

来源：`repo_readme_summary.md` Codex CLI 注意事项；安装 Skill Troubleshooting。

## 延伸阅读

- 官方仓库 README：https://github.com/phuryn/pm-skills
- 安装说明：https://github.com/phuryn/pm-skills#installation
- Codex CLI 使用差异：https://github.com/phuryn/pm-skills#codex-cli-openai
- Other AI assistants skills-only：https://github.com/phuryn/pm-skills#other-ai-assistants-skills-only
- Windows Claude Cowork known issue：https://github.com/phuryn/pm-skills#known-issue-on-windows
