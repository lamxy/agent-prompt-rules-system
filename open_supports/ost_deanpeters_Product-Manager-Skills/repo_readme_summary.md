# Product Manager Skills - 仓库核心介绍

> 官方仓库：[deanpeters/Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills)  
> 官方文档：[README](https://github.com/deanpeters/Product-Manager-Skills#readme) · [Install guides](https://github.com/deanpeters/Product-Manager-Skills/tree/main/docs) · [Latest release](https://github.com/deanpeters/Product-Manager-Skills/releases/latest)

## 1. 概览

Product Manager Skills 是一套面向 PM 工作的结构化 AI skills / commands 库，把 discovery、strategy、delivery、finance、AI product work 和 leadership transition 等产品管理框架整理成可被 Claude、Codex、ChatGPT 及其他 agent 读取的 Markdown 知识包。

核心能力：

- 提供 PM framework skills：component skills、interactive skills、workflow skills 三类能力，覆盖从单个产物到端到端流程。
- 支持 Claude Desktop / Claude Web 的 ZIP skill upload 流程。
- 支持 Claude Code 的 plugin marketplace 安装路径。
- 支持 Codex 的 `.agents/skills` ZIP、本地 repo 路径、GitHub-connected Codex，以及 `npx skills` 安装方式。
- 附带本地 Streamlit playground，用于浏览、选择和试跑 skills。

官方仓库：https://github.com/deanpeters/Product-Manager-Skills

## 2. 安装与更新

### 前置依赖

- Claude Desktop / Claude Web：需要可使用 Claude 的 `Settings -> Capabilities -> Skills` 上传 skill ZIP。
- Claude Code：需要 Claude Code，并能在 Claude Code 中运行 `/plugin marketplace add`、`/plugin install`、`/reload-plugins`。
- Codex：ZIP 方式需要在目标 repo 根目录展开 `.agents/skills` 和 `AGENTS.md`；`npx skills` 方式需要可运行 `npx`。
- Streamlit playground：需要 Python 环境；官方 `app/requirements.txt` 声明 `streamlit>=1.32.0`、`anthropic>=0.40.0`、`openai>=1.40.0`、`pyyaml>=6.0`、`python-dotenv>=1.0.0`。

官方文档没有给出 macOS、Linux、WSL、Windows 的不同 shell 命令；ZIP 上传、Claude Code slash command、Codex repo 展开和 `npx skills` 命令按平台中立方式描述。

### Claude Desktop / Claude Web 安装

官方 quick setup：

1. Open the [Product Manager Skills Releases page](https://github.com/deanpeters/Product-Manager-Skills/releases/latest).
2. Download [`pm-skills-starter-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-starter-pack.zip), or choose a different pack from the table below.
3. Unzip the pack on your computer.
4. Open Claude.
5. Go to `Settings -> Capabilities -> Skills`.
6. Upload the individual skill ZIPs inside the pack.
7. Start a new chat and ask Claude to use the Product Manager Skills.

官方列出的 Claude Desktop / Web packs：

- [`pm-skills-starter-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-starter-pack.zip)
- [`02-discovery-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/02-discovery-pack.zip)
- [`03-strategy-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/03-strategy-pack.zip)
- [`04-delivery-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/04-delivery-pack.zip)
- [`05-ai-pm-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/05-ai-pm-pack.zip)
- [`99-all-skills-pack.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/99-all-skills-pack.zip)

验证提示：

```text
Use the Product Manager Skills to help me frame this product problem.
```

### Claude Code 安装

官方 quick setup：

```text
/plugin marketplace add deanpeters/Product-Manager-Skills
/plugin install jobs-to-be-done@pm-skills
/reload-plugins
```

官方 helpful commands：

```text
/plugin marketplace add deanpeters/Product-Manager-Skills
/plugin install user-story@pm-skills
/plugin install prd-development@pm-skills
/plugin install product-strategy-session@pm-skills
/reload-plugins
```

验证提示：

```text
Use the jobs-to-be-done skill to analyze this customer problem.
```

### Codex 安装：Codex ZIP

官方 quick setup：

1. Open the [Product Manager Skills Releases page](https://github.com/deanpeters/Product-Manager-Skills/releases/latest).
2. Download [`pm-skills-codex.zip`](https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-codex.zip).
3. Unzip it into your project or repo root.
4. Confirm your project now has:

```text
.agents/
  skills/
    <skill-name>/
      SKILL.md
AGENTS.md
```

5. Open Codex in that repo.
6. Ask Codex to use a named skill.

验证提示：

```text
Use the jobs-to-be-done skill to analyze this customer problem.
```

### Codex 安装：本地 repo / GitHub-connected Codex

官方高级路径：clone whole repo and run Codex from the repo root。这样 Codex 可访问 `skills/`、`commands/`、`catalog/`、repo scripts 和 docs。

Codex on ChatGPT 路径：

1. Open [Codex](https://chatgpt.com/codex).
2. Connect GitHub when prompted (or via ChatGPT settings).
3. Select this repo and branch.
4. Prompt Codex to use a specific skill path.

官方示例：

```text
Use skills/finance-based-pricing-advisor/SKILL.md to evaluate whether we should test a 10% price increase. Show assumptions and risks.
```

### Codex 安装：Skills CLI / `npx skills`

官方 discover 命令：

```bash
npx skills find product management
npx skills add deanpeters/Product-Manager-Skills --list
```

官方 install 命令：

```bash
npx skills add deanpeters/Product-Manager-Skills --skill <skill-name> -a codex -g
```

官方 examples：

```bash
npx skills add deanpeters/Product-Manager-Skills --skill user-story -a codex -g
npx skills add deanpeters/Product-Manager-Skills --skill prd-development -a codex -g
npx skills add deanpeters/Product-Manager-Skills --skill finance-based-pricing-advisor -a codex -g
```

官方 GitHub URL form：

```bash
npx skills add https://github.com/deanpeters/Product-Manager-Skills --skill <skill-name>
```

验证命令：

```bash
npx skills list -a codex
```

### Streamlit playground

官方 README 的本地 playground 命令：

```bash
pip install -r app/requirements.txt
streamlit run app/main.py
```

用途：在浏览器中 Learn、Find My Skill、Run Skills。API keys 只通过环境变量配置，不在 app 内输入。

### 更新

官方文档没有提供单一的独立 update 命令。官方所有下载链接均指向 `releases/latest`；ZIP 路径的可操作更新方式是重新下载 latest release pack、解压并按对应平台重新安装 / 上传。Claude Code 与 `npx skills` 文档给出的是 install / list 流程，未单独声明 update command。

## 3. 使用示例

最小 Codex / local repo 用法：

```text
Using skills/prd-development/SKILL.md:
1) Ask up to 3 clarifying questions.
2) Follow the skill sections exactly.
3) Show output in markdown.
4) End with risks, assumptions, and next steps.
```

作用：让 Codex 读取仓库中的 `prd-development` skill，并按 skill 结构产出 PRD。成功时应先进入最多 3 个澄清问题，随后输出 markdown 产物、风险、假设和下一步。

Claude Code 已安装 plugin 后可直接提示：

```text
Use the jobs-to-be-done skill to analyze this customer problem.
```

## 4. 注意事项

- Claude Desktop / Web 不要上传外层 pack ZIP；必须先 unzip，再上传里面的 individual skill ZIPs。
- Claude Code users should usually use the plugin marketplace；Claude Desktop ZIP packs 是为 Claude Desktop / Claude Web 设计的。
- Codex ZIP 期望在目标 repo 根目录生成 `.agents/skills/<skill-name>/SKILL.md` 和 `AGENTS.md`。
- Codex on ChatGPT availability can vary by plan and rollout region。
- 官方 README 与 latest release notes 对 skill 总数表述不完全一致；安装脚本应以实际 release assets 和 repo tree 为准，不硬编码 README 中的计数。
- Generated `dist/` artifacts 是 downloadable packages；`skills/` 是 source library。
- 本地 Streamlit playground 的 provider API keys 只走环境变量。

---

## 5. 补充与延伸

- **Claude Desktop / Web 安装细节**：pack 选择、upload 步骤和注意事项见 [INSTALL-CLAUDE-DESKTOP.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/INSTALL-CLAUDE-DESKTOP.md)。
- **Claude Code marketplace 安装**：推荐的 plugin marketplace 路径和示例 skill 安装见 [INSTALL-CLAUDE-CODE.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/INSTALL-CLAUDE-CODE.md)。
- **Codex ZIP / clone 安装**：`.agents/skills` 结构和 clone-whole-repo 高级路径见 [INSTALL-CODEX.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/INSTALL-CODEX.md)。
- **Codex `npx skills` 路径**：local workspace、GitHub-connected Codex、Skills CLI 三种路径见 [Using PM Skills with Codex.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/Using%20PM%20Skills%20with%20Codex.md)。
- **平台选择器**：Claude、Codex、ChatGPT、Cursor、Windsurf、n8n、LangFlow、Python agents、CrewAI、Gemini 等入口见 [Platform Guides for PMs.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/Platform%20Guides%20for%20PMs.md)。
- **本地 onboarding**：快速选择 skill、helper scripts 和第一条 prompt 见 [START_HERE.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/START_HERE.md)。
- **Release packaging**：`dist/` 包结构、maintainer build scripts 和 release artifact 规则见 [RELEASE-PACKAGING.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/RELEASE-PACKAGING.md)。
- **Streamlit playground**：本地 app 说明见 [app/STREAMLIT_INTERFACE.md](https://github.com/deanpeters/Product-Manager-Skills/blob/main/app/STREAMLIT_INTERFACE.md)，环境变量示例见 [app/.env.example](https://github.com/deanpeters/Product-Manager-Skills/blob/main/app/.env.example)。
