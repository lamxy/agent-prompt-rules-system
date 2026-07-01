# PM Skills Marketplace — 仓库核心介绍

> 官方仓库：[phuryn/pm-skills](https://github.com/phuryn/pm-skills)

## 1. 概览

PM Skills Marketplace 是面向产品经理、Founder 和 AI 辅助交付场景的 Claude/Codex 插件市场，提供 68 个 PM skills 和 42 个链式工作流，覆盖 discovery、strategy、execution、launch、growth、analytics 和 AI-built code shipping。

核心能力：

- 通过 9 个插件分发 PM 领域 skills 和 Claude `/slash` commands。
- Claude Cowork 可从 GitHub 添加 marketplace，并自动安装全部 9 个插件。
- Claude Code 可通过 `claude plugin marketplace add` 和 `claude plugin install` 安装插件。
- Codex CLI 可读取同一 marketplace 文件并原生安装 skills；Claude slash commands 会随插件文件安装，但不会作为 Codex slash commands 运行。
- 其他 AI assistants 可复制 `skills/*/SKILL.md` 使用 skills-only 模式。

官方仓库：https://github.com/phuryn/pm-skills

## 2. 安装与更新

### 前置依赖

- Claude Cowork：README 推荐给非开发者使用；需可使用 Cowork 的插件浏览与 GitHub marketplace 添加能力。
- Claude Code：需安装 Claude Code CLI，且本机 `claude plugin` 支持 marketplace 与 plugin install 命令。
- Codex CLI：需安装 Codex CLI，且本机 `codex plugin` 支持 marketplace 与 plugin add 命令。
- 其他 AI assistants：需支持读取 skill folders，或允许把 skill folders 复制到对应本地目录。

### Claude Cowork 安装

官方 README 给出的安装步骤：

1. Open **Customize** (bottom-left)
2. Go to **Browse plugins** → **Personal** → **+**
3. Select **Add marketplace from GitHub**
4. Enter: `phuryn/pm-skills`

结果：All 9 plugins install automatically. You get both commands (`/discover`, `/strategy`, etc.) and skills.

### Claude Code 安装

官方 README 给出的命令：

```bash
# Step 1: Add the marketplace
claude plugin marketplace add phuryn/pm-skills

# Step 2: Install individual plugins
claude plugin install pm-toolkit@pm-skills
claude plugin install pm-product-strategy@pm-skills
claude plugin install pm-product-discovery@pm-skills 
claude plugin install pm-market-research@pm-skills 
claude plugin install pm-data-analytics@pm-skills
claude plugin install pm-marketing-growth@pm-skills
claude plugin install pm-go-to-market@pm-skills
claude plugin install pm-execution@pm-skills
claude plugin install pm-ai-shipping@pm-skills
```

### Codex CLI 安装

官方 README 给出的命令：

```bash
# Step 1: Add the marketplace
codex plugin marketplace add phuryn/pm-skills

# Step 2: Install the plugins you want
codex plugin add pm-toolkit@pm-skills
codex plugin add pm-product-strategy@pm-skills
codex plugin add pm-product-discovery@pm-skills
codex plugin add pm-market-research@pm-skills
codex plugin add pm-data-analytics@pm-skills
codex plugin add pm-marketing-growth@pm-skills
codex plugin add pm-go-to-market@pm-skills
codex plugin add pm-execution@pm-skills
codex plugin add pm-ai-shipping@pm-skills
```

Codex 使用差异：skills 可用并可按名称调用；`/discover`、`/write-prd` 等 Claude slash commands 不会作为 Codex slash commands 运行。README 建议用自然语言描述工作流，例如：

```text
Run product discovery on *[your idea]*: brainstorm options, map assumptions, prioritize the risky ones, then design experiments — pause between each step.
```

可选转换提示：

```text
Read the command files in the pm-execution plugin and create equivalent Codex skills for the workflows I use most often.
```

### 其他 AI assistants（skills only）

官方 README 说明：`skills/*/SKILL.md` follow the universal skill format and work with any tool that reads it. Commands (`/slash-commands`) are Claude-specific.

| Tool | How to use | What works |
|------|-----------|------------|
| **Gemini CLI** | Copy skill folders to `.gemini/skills/` | Skills only |
| **OpenCode** | Copy skill folders to `.opencode/skills/` | Skills only |
| **Cursor** | Copy skill folders to `.cursor/skills/` | Skills only |
| **Kiro** | Copy skill folders to `.kiro/skills/` | Skills only |

官方 README 给出的复制示例：

```bash
# Example: copy all skills for OpenCode (project-level)
for plugin in pm-*/; do
  mkdir -p .opencode/skills/
  cp -r "$plugin/skills/"* .opencode/skills/ 2>/dev/null
done

# Example: copy all skills for Gemini CLI (global)
for plugin in pm-*/; do
  cp -r "$plugin/skills/"* ~/.gemini/skills/ 2>/dev/null
done
```

### 更新命令

官方 README 未给出专门的更新命令。以下命令来自本机 Claude Code 2.1.191 与 Codex CLI 0.142.3 的 CLI help，用于更新 marketplace snapshot 或已安装 Claude plugins：

```bash
claude plugin marketplace update pm-skills
claude plugin marketplace update
claude plugin update pm-toolkit
claude plugin update pm-product-strategy
claude plugin update pm-product-discovery
claude plugin update pm-market-research
claude plugin update pm-data-analytics
claude plugin update pm-marketing-growth
claude plugin update pm-go-to-market
claude plugin update pm-execution
claude plugin update pm-ai-shipping
```

```bash
codex plugin marketplace upgrade pm-skills
codex plugin marketplace upgrade
```

Codex CLI help only documents marketplace snapshot refresh, not a separate per-plugin update command.

### 验证命令

官方 README 未给出专门的验证命令。以下命令来自本机 CLI help，用于确认 marketplace/plugins 可见：

```bash
claude plugin list
claude plugin list --json --available
```

```bash
codex plugin list
codex plugin list --marketplace pm-skills
codex plugin list --available --json
```

## 3. 使用示例

README 的主路径是直接使用 commands 或 skills。

Claude Code / Cowork 中使用 command：

```text
/discover AI-powered meeting summarizer for remote teams
```

作用：启动 discovery cycle，依次进行 ideation、assumption mapping、assumption prioritization 和 experiment design。

Codex CLI 中用自然语言调用等价工作流：

```text
Run product discovery on *AI-powered meeting summarizer for remote teams*: brainstorm options, map assumptions, prioritize the risky ones, then design experiments — pause between each step.
```

预期结果：Codex 使用已安装插件中的 PM skills 推进同一类 discovery workflow，但不依赖 Claude slash command 运行时。

## 4. 注意事项

- Codex plugins do not expose commands；Claude `/slash` commands 文件会安装，但不会作为 Codex slash commands 运行。
- README 建议安装 whole plugins，而不是 cherry-picking individual skills，因为一个 workflow 通常依赖同一插件内的多个 skills。
- 其他 AI assistants 仅支持 skills-only；commands (`/slash-commands`) 是 Claude-specific。
- Claude Cowork on Windows 若 VM 不稳定，README 提供 Scheduled Task 方式监控并启动 `CoworkVMService`；仍失败时需手动在 `services.msc` 启动 "Claude" service。
- Codex 将 command files 转成 skills 是 best-effort, model-driven conversion；部分 Claude-specific command syntax 不能保证可转换。

---

## 5. 补充与延伸

- **插件清单与版本**：`.claude-plugin/marketplace.json` 当前声明 marketplace name `pm-skills`、version `2.0.0`，包含 9 个插件；原文见 [marketplace.json](https://github.com/phuryn/pm-skills/blob/main/.claude-plugin/marketplace.json)。
- **Claude Cowork 图形安装**：README 的 Installation → Claude Cowork 段落包含 GIF 示例；原文见 [README · Installation](https://github.com/phuryn/pm-skills#installation)。
- **Codex 使用差异与转换建议**：README 的 Codex CLI 段落说明 commands 不作为 Codex slash commands 运行，并给出自然语言工作流与转换提示；原文见 [README · Codex CLI](https://github.com/phuryn/pm-skills#codex-cli-openai)。
- **其他 assistant 手动复制 skills**：README 给出 OpenCode 与 Gemini CLI 复制命令，以及 Gemini/OpenCode/Cursor/Kiro 的目标目录；原文见 [README · Other AI assistants](https://github.com/phuryn/pm-skills#other-ai-assistants-skills-only)。
- **Windows Cowork known issue**：README 给出 PowerShell Scheduled Task workaround；原文见 [README · Known Issue on Windows](https://github.com/phuryn/pm-skills#known-issue-on-windows)。
- **贡献与许可**：贡献说明见 [CONTRIBUTING.md](https://github.com/phuryn/pm-skills/blob/main/CONTRIBUTING.md)，许可证见 [LICENSE](https://github.com/phuryn/pm-skills/blob/main/LICENSE)。
