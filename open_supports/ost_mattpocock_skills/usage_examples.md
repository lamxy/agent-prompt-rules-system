# Skills For Real Engineers（mattpocock/skills）— 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 安装范围

分类 `D`（双模式），与 `repo_readme_summary.md` 第 2 部分一致：

| 安装方式 | 官方默认 | 写入位置 | 是否需要项目目录 |
|---|---|---|---|
| Claude Code / Codex / Copilot 插件 | 用户级 | 各客户端用户配置（如 `~/.codex`、`~/.copilot`）；Claude 可用原生 `--scope project` | 否 |
| `gemini skills install` | 用户级（`--scope user`） | `~/.gemini/skills/`；`--scope workspace` 改为项目级 | 否（workspace 时需要） |
| `npx skills@latest add mattpocock/skills -a <agent>` | 项目级，CWD 敏感 | CWD 下该 agent 的项目级 skills 目录（如 claude-code→`.claude/skills/`、cursor→`.agents/skills/`）；`-g` 为全局 | 是，须在 `(cd /work/app && ...)` 子 Shell 中执行 |

用法层面的影响：

- `/setup-matt-pocock-skills` 和各 skill 都按 **agent 当前打开的仓库** 生效，与安装范围无关；项目级 npx 安装只在该项目内可见。
- 每个 agent 只保留一种安装方式，否则每个 skill 出现两次。

证据：[官方 README · Installation](https://github.com/mattpocock/skills#installation-30-second-setup)、[vercel-labs/skills · Installation Scope](https://github.com/vercel-labs/skills#installation-scope)、[vercel-labs/skills · Supported Agents](https://github.com/vercel-labs/skills#supported-agents)

## 快速开始

### 为当前仓库初始化（每个 repo 一次）

适用场景：安装完成并重启 agent 后，第一次在某个项目（如 `/work/app`）里使用 engineering skills。

```text
/setup-matt-pocock-skills
```

预期结果：agent 依次询问 issue tracker（GitHub、GitLab、本地文件或自定义）、triage 用的 labels、生成文档的保存位置，并把配置写入当前仓库。

注意事项：会在当前打开的仓库内写入配置文件；先确认 agent 打开的是目标项目。npx 安装时漏选 `setup-matt-pocock-skills` 会导致此命令不可用。

来源：[README · 2. Run /setup-matt-pocock-skills](https://github.com/mattpocock/skills#2-run-setup-matt-pocock-skills)

### 不知道该用哪个 skill

适用场景：刚接触这套 skills，想让 agent 根据当前情况推荐流程。

```text
/ask-matt
```

预期结果：agent 作为 user-invoked skills 的路由器，询问情况并建议合适的 skill 或流程。

来源：[README · Reference / Engineering](https://github.com/mattpocock/skills#engineering)

## 常见场景

### 动手前对齐需求（主路径）

适用场景：要做一个代码改动，想先让 agent 把需求和设计分支问清楚，同时沉淀项目术语。

```text
/grill-with-docs I want to add CSV export to the reports page
```

预期结果：agent 逐条追问直到设计树的每个分支都有结论，并在仓库内更新 `GLOSSARY.md` 与 ADR。

注意事项：会修改仓库中的文档文件。非代码类讨论（计划、写作、决策）改用 `/grill-me`，它不写项目文档。

来源：[README · #1 / #2](https://github.com/mattpocock/skills#1-the-agent-didnt-do-what-i-want)；`repo_readme_summary.md` 第 3 部分

### 从对话到规格、工单、实现

适用场景：已经通过 grilling 对齐需求，要把结论落地成可追踪的工作并实现。

```text
/to-spec
/to-tickets
/implement
```

预期结果：

- `/to-spec`：把当前对话整理成 spec 并发布到已配置的 issue tracker（不再追问，只综合已讨论内容）。
- `/to-tickets`：把 spec 拆成带阻塞关系的 tracer-bullet 工单（本地文件或 tracker 原生链接）。
- `/implement`：按 spec / 工单实现，在约定接缝处驱动 `/tdd`，提交前用 `/code-review` 收尾。

注意事项：User-invoked skill 不会自动调用下一个 user-invoked skill，三步需逐条手动输入。`/to-spec`、`/to-tickets` 会在 issue tracker 上创建内容；`/implement` 会修改代码并提交，执行前确认分支与未提交改动。整份 spec 想在一个集成分支上用子代理并发实现时，改用 `/implement-spec`。

来源：[README · Reference / Engineering](https://github.com/mattpocock/skills#engineering)

### 规划跨会话的大块工作

适用场景：工作量超出单个 agent 会话能承载的范围，需要先拆出决策点。

```text
/wayfinder
```

预期结果：在 issue tracker 上建立一组决策工单作为共享地图，逐个解决直到路径清晰。

注意事项：会在 issue tracker 上创建多个工单。

来源：[README · Reference / Engineering](https://github.com/mattpocock/skills#engineering)

### 测试驱动开发与调试

适用场景：实现功能或修 bug 时需要稳定反馈回路；或遇到难复现的 bug / 性能回退。

```text
/tdd
/diagnosing-bugs
```

预期结果：`/tdd` 按 red-green-refactor 一次推进一个垂直切片；`/diagnosing-bugs` 按“复现变红 → 最小化 → 假设 → 插桩 → 修复 → 回归测试”分阶段推进。

注意事项：两者都是 model-invoked，agent 在任务匹配时也可能自动采用；都会修改代码与测试。

来源：[README · #3 The Code Doesn't Work](https://github.com/mattpocock/skills#3-the-code-doesnt-work)

### 定期检查架构

适用场景：代码库在 agent 加速下复杂度上升，想找“加深模块”的重构候选（官方建议每隔几天运行一次）。

```text
/improve-codebase-architecture
```

预期结果：扫描代码库，输出可视化 HTML 报告列出候选，再就你选中的一项进行 grilling。

注意事项：只做调研并给候选，不会自动重构老旧代码库；会在仓库内生成报告文件。

来源：[README · #4 We Built A Ball Of Mud](https://github.com/mattpocock/skills#4-we-built-a-ball-of-mud)

## 与 Agent 客户端配合

| 客户端 | 日常调用 | 说明 |
|---|---|---|
| Claude Code | 在会话中输入 `/grill-me`、`/to-spec` 等 | 插件自动更新 |
| Codex | 同上，输入对应 skill 名 | 启动时自动更新 |
| GitHub Copilot（CLI / VS Code） | 在 Copilot Chat / CLI 中调用 skill | `~/.copilot/settings.json` 的 `autoUpdate` 或 VS Code 每日更新 |
| Gemini CLI | 在会话中调用已安装的 skill | 需重新运行两条 install 命令更新 |
| Cursor / OpenCode / Windsurf 等（npx） | 在该 agent 中调用项目级 skill | 文件可直接编辑；`npx skills@latest update` 手动更新（项目级需在目标项目子 Shell 中运行） |

通用规则：

- **User-invoked**（如 `ask-matt`、`grill-with-docs`、`to-spec`、`implement`、`grill-me`、`handoff`）只能由你手动输入触发。
- **Model-invoked**（如 `tdd`、`diagnosing-bugs`、`code-review`、`domain-modeling`、`prototype`）你可手动调用，agent 也会在任务匹配时自动使用。
- 换 agent 或会话前可用 `/handoff` 把当前对话压缩成交接文档，供另一个 agent 继续。

来源：[README · Installation](https://github.com/mattpocock/skills#installation-30-second-setup)、[README · Reference](https://github.com/mattpocock/skills#reference)

## 验证与排错

最小验证：

```sh
sh scripts_for_install/install.sh --client=claude-code --verify-only
sh scripts_for_install/install.sh --client=npx --verify-only /work/app
```

然后在 agent 中输入 `/ask-matt`，能被识别并开始对话即表示可用。

| 现象 | 处理 |
|---|---|
| 每个 skill 出现两次 | 同一 agent 同时用了插件和 npx；只保留一种（卸载方式见下方延伸阅读链接，不默认执行） |
| engineering skills 提示缺少 tracker / labels / 文档位置 | 在该仓库运行 `/setup-matt-pocock-skills`；npx 安装时需勾选该 skill |
| `/to-spec` 后 agent 没有继续拆工单 | 设计如此：user-invoked skill 不互相调用，手动输入 `/to-tickets` |
| 在另一个项目里找不到 skills | npx 项目级安装只对安装时的目录生效；在目标项目重新 add 或改用 `-g` / 插件 |
| 文档里提到 `CONTEXT.md` | 术语文件约定已改名为 `GLOSSARY.md`，旧项目注意迁移 |
| 新 skill 没出现（npx / Gemini） | npx 需重新运行 `add`；Gemini 重新运行两条 install 命令 |

来源：`skill_for_setup/ost_mattpocock_skills_install/SKILL.md` Troubleshooting；`repo_readme_summary.md` 第 4 部分

## 延伸阅读

- 全部 skill 说明（Engineering / Productivity，按调用方式分类）：https://github.com/mattpocock/skills#reference
- 设计理念与四类失败模式：https://github.com/mattpocock/skills#why-these-skills-exist
- 单个 skill 源文件，例如 grill-with-docs：https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md
- skills CLI 高级用法（`--skill`、`-y`、`remove`、各 agent 路径）：https://github.com/vercel-labs/skills
- Gemini CLI skills 管理（`--scope workspace`、`uninstall`）：https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md
- 范围与变更记录：https://github.com/mattpocock/skills/blob/main/SCOPE.md 、https://github.com/mattpocock/skills/blob/main/CHANGELOG.md
