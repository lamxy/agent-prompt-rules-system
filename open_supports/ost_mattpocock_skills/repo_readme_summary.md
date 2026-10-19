# Skills For Real Engineers (mattpocock/skills) — 仓库核心介绍

> **安装作用域（模式 D）**：Claude Code / Codex / Copilot 插件与 Gemini CLI 默认都是用户级安装；`npx skills@latest add` 不带 `-g` 时默认是项目级，写入 CWD 下该 agent 的项目级 skills 目录（`<agent>` 为占位，实际路径因 agent 而异，如 claude-code→`.claude/skills/`、cursor→`.agents/skills/`，见 [Supported Agents](https://github.com/vercel-labs/skills#supported-agents)）。支持包做项目级安装时必须接收并验证 `TARGET_DIR`，在子 Shell 中 `cd` 后执行；全局安装走 `-g` 或插件路径。依据：[官方 README · Installation](https://github.com/mattpocock/skills#installation-30-second-setup)、[vercel-labs/skills README · Installation Scope](https://github.com/vercel-labs/skills#installation-scope)。

> 官方仓库：[mattpocock/skills](https://github.com/mattpocock/skills)
> 官方文档：[skills.sh/mattpocock/skills](https://skills.sh/mattpocock/skills)

## 1. 概览

Matt Pocock 日常做「真实工程」（而非 vibe coding）所用的 agent skills 集合：体积小、可组合、可随意修改，适用于任意模型；以 `mattpocock-skills` 插件（当前 `plugin.json` version `1.3.1`）或可编辑的 skill 文件两种形式分发。

核心能力：

- **对齐需求**：`/grill-me`（非代码）、`/grill-with-docs`（同时建立 `GLOSSARY.md` 共享术语与 ADR），在动手前让 agent 反复追问。
- **规格到实现**：`/to-spec` → `/to-tickets` → `/implement` / `/implement-spec`，配合 `/wayfinder` 规划跨会话的大块工作。
- **反馈回路**：`tdd`（red-green-refactor）、`diagnosing-bugs`（分阶段调试循环）、`code-review`（Standards + Spec 双轴并行子代理审查）。
- **架构质量**：`/improve-codebase-architecture` 扫描「加深模块」机会并输出 HTML 报告；`codebase-design`、`domain-modeling` 提供共享方法论。
- **两类调用**：User-invoked（只能由用户输入 `/xxx` 触发，负责编排）与 Model-invoked（用户或 agent 均可触发，承载可复用纪律）；共 27 个 skills，分 `skills/engineering` 与 `skills/productivity` 两组。

官方仓库：https://github.com/mattpocock/skills

## 2. 安装与更新

官方 README 说明：插件会自动更新；skills.sh 把可编辑文件复制到项目中，需手动更新。**每个 agent 只选一种方式**，两种都装会让每个 skill 出现两次。

### 前置依赖

- Claude Code：需安装 Claude Code CLI，且可访问 `claude-plugins-official` marketplace（本机 Claude Code 2.1.302 验证 `claude plugin install` 可用）。
- Codex：需安装 Codex CLI，支持 `codex plugin marketplace add` / `codex plugin add`（本机 codex-cli 0.162.1 验证）。
- GitHub Copilot：需 Copilot CLI（`copilot plugin` 子命令）或 VS Code Copilot Chat。
- Gemini CLI：需安装 Gemini CLI，支持 `gemini skills install`。
- 其他 agent / 可编辑文件：需 Node.js 与 `npx`；官方 README 未写明 Node.js 版本要求。

### 第 1 步：获取 skills（按 agent 选一种）

#### Claude Code

```bash
claude plugin install mattpocock-skills@claude-plugins-official
```

Updates itself by default.

#### Codex

```bash
codex plugin marketplace add mattpocock/skills
codex plugin add mattpocock-skills@mattpocock
```

Updates itself at startup.

#### GitHub Copilot（CLI 与 VS Code）

CLI：

```bash
copilot plugin marketplace add mattpocock/skills
copilot plugin install mattpocock-skills@mattpocock
```

然后一次性写入 `~/.copilot/settings.json`（官方原文）：

```json
{
  "extraKnownMarketplaces": {
    "mattpocock": { "source": { "source": "github", "repo": "mattpocock/skills" }, "autoUpdate": true }
  }
}
```

VS Code：运行 **Chat: Install Plugin From Source**，输入 `https://github.com/mattpocock/skills`。It updates daily.

#### Gemini CLI（手动更新）

```bash
gemini skills install https://github.com/mattpocock/skills.git --path skills/engineering
gemini skills install https://github.com/mattpocock/skills.git --path skills/productivity
```

#### 任意其他 agent，或需要可编辑文件（手动更新）

```bash
npx skills@latest add mattpocock/skills -a <agent>  # cursor, opencode, devin, windsurf, amp, pi; omit -a to choose
```

安装器询问选哪些 skills 时，**必须包含 `setup-matt-pocock-skills`**。

> 平台差异：官方 README 对 macOS / Linux / WSL / Windows 未给出不同命令，以上命令在各平台相同；官方亦未单独说明 WSL 差异。

### 第 2 步：在每个仓库运行一次 `/setup-matt-pocock-skills`

在 agent 中执行 `/setup-matt-pocock-skills`（每个 repo 一次）。它会询问：

- 使用哪个 issue tracker（GitHub、GitLab、本地文件或自行描述的其他系统）
- triage 时给 ticket 打哪些 labels（`/triage` 依赖 labels）
- 生成的文档保存位置

### 第 3 步：完成

README 原文：「Bam - you're ready to go.」

### 安装作用域与目标目录

| 字段 | 内容 |
|---|---|
| 分类 | `D` 双模式：插件 / Gemini 路径为用户级（A 类行为）；`npx skills add` 默认项目级且 CWD 敏感（B 类行为），`-g` 切换为全局 |
| 官方默认 | `claude plugin install mattpocock-skills@claude-plugins-official` → 默认 `--scope user`（本机 CLI help：`Installation scope: user, project, or local (default: "user")`）。`codex plugin add` → 用户级（`~/.codex`）。`copilot plugin install` → 用户级（README 配置写入 `~/.copilot/settings.json`）。`gemini skills install ... --path ...` → `--scope` 默认 `user`（`~/.gemini/skills/`）。`npx skills@latest add mattpocock/skills -a <agent>` → 默认 Project，写入该 agent 的项目级 skills 目录（因 agent 而异，见 Supported Agents 表） |
| 项目目录 | 插件与 Gemini 默认路径不需要项目目录。`npx skills add` 不带 `-g` 时结果由 CWD 决定，默认 `.` 仅在调用者已位于目标项目根时成立；`skills` CLI 无原生项目路径 flag。`/setup-matt-pocock-skills` 是 agent 内命令，按当前打开的 repo 生效 |
| 执行要求 | 全局分支：直接执行插件命令、`gemini skills install`（可选 `--scope workspace` 改为项目级），或 `npx skills@latest add mattpocock/skills -g -a <agent>`。项目分支：封装脚本必须接收并验证 `TARGET_DIR`，在子 Shell `(cd "$TARGET_DIR" && npx skills@latest add mattpocock/skills -a <agent>)` 中执行，保持调用端 CWD；Claude 插件项目级可用原生 `--scope project` |
| 官方证据 | [mattpocock/skills README · Installation](https://github.com/mattpocock/skills#installation-30-second-setup)；[vercel-labs/skills README · Installation Scope](https://github.com/vercel-labs/skills#installation-scope)（Project `(default)` → `./<agent>/skills/`；Global `-g` → `~/<agent>/skills/`）；[Gemini CLI docs/cli/skills.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md)（`--scope`: `user` (global, default) or `workspace`）；本机 `claude plugin install --help`（`--scope` default `"user"`） |

### 更新命令

- Claude Code：插件默认自动更新（README：Updates itself by default）。
- Codex：启动时自动更新（README：Updates itself at startup）。
- GitHub Copilot：`~/.copilot/settings.json` 中 `"autoUpdate": true`；VS Code 每日更新。
- Gemini CLI：重新运行两条安装命令（README：Re-run both commands to update）：

```bash
gemini skills install https://github.com/mattpocock/skills.git --path skills/engineering
gemini skills install https://github.com/mattpocock/skills.git --path skills/productivity
```

- skills.sh / npx：

```bash
npx skills@latest update
```

新增的 skills 需重新运行 `add` 才会获取：

```bash
npx skills@latest add mattpocock/skills -a <agent>
```

### 验证命令

官方 README 未给出专门验证命令。以下来自本机 CLI help 或 skills CLI README，用于确认已安装：

```bash
claude plugin list
```

```bash
codex plugin list
```

```bash
npx skills@latest list
npx skills@latest list -g
```

功能验证：在 agent 中输入 `/ask-matt` 或 `/grill-me`，能被识别并开始对话即表示 skills 可用。

## 3. 使用示例

README 推荐的主路径：先对齐需求，再写代码。

```text
/setup-matt-pocock-skills
```

作用：为当前 repo 配置 issue tracker、triage labels 和文档目录；其他 engineering skills 依赖此配置，每个 repo 只需运行一次。

```text
/grill-with-docs I want to add CSV export to the reports page
```

作用：agent 逐条追问需求与设计分支，同时更新 `GLOSSARY.md` 与 ADR。预期结果：得到对齐的需求和共享术语，之后可接 `/to-spec` → `/to-tickets` → `/implement`。

## 4. 注意事项

- **不要同时用插件和 skills.sh 安装同一 agent**，否则每个 skill 出现两次。
- skills.sh / npx 和 Gemini CLI 路径**不会自动更新**，需手动 update 或重新安装；新 skill 需重新 `add`。
- 使用 npx 安装时漏选 `setup-matt-pocock-skills`，会导致 engineering skills 缺少 issue tracker / labels / 文档位置配置。
- User-invoked skills 只能由用户手动输入触发，agent 不会自动调用；User-invoked skill 不会调用另一个 User-invoked skill。
- `/improve-codebase-architecture` 只做调研并给出候选，不会自动重构老旧代码库。
- 项目术语文件约定已从 `CONTEXT.md` 改名为 `GLOSSARY.md`；旧项目中的 `CONTEXT.md` 需注意迁移。

---

## 5. 补充与延伸

- **插件清单**：`.claude-plugin/plugin.json` 列出全部 27 个 skill 路径；marketplace 名称为 `mattpocock`（见 [marketplace.json](https://github.com/mattpocock/skills/blob/main/.claude-plugin/marketplace.json)、[plugin.json](https://github.com/mattpocock/skills/blob/main/.claude-plugin/plugin.json)）。
- **skills CLI 高级用法**（非交互 `-y`、`--skill` 选择、symlink/copy 方式、`remove` 卸载、各 agent 项目/全局路径表）：[vercel-labs/skills README](https://github.com/vercel-labs/skills)。
- **Gemini CLI skills 管理**（`--scope workspace`、`uninstall`、`--consent`）：[Gemini CLI docs/cli/skills.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md)。
- **Claude Code 卸载 / 项目级安装**：`claude plugin uninstall`、`claude plugin install --scope project`（见本机 `claude plugin --help`）。
- **各 skill 说明**：README 的 Reference 段落按 Engineering / Productivity 与调用方式分类，见 [README · Reference](https://github.com/mattpocock/skills#reference)。
- **设计理念**：四类失败模式（需求错位、过度冗长、代码不可用、泥球架构）及对应 skills，见 [README · Why These Skills Exist](https://github.com/mattpocock/skills#why-these-skills-exist)。
- **范围与变更**：[SCOPE.md](https://github.com/mattpocock/skills/blob/main/SCOPE.md)、[CHANGELOG.md](https://github.com/mattpocock/skills/blob/main/CHANGELOG.md)、[LICENSE](https://github.com/mattpocock/skills/blob/main/LICENSE)（MIT）。
