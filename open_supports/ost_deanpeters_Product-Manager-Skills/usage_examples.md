# Product Manager Skills — 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

### 用已安装的 Codex skill 产出 PRD

适用场景：已经通过 Codex ZIP、Skills CLI、GitHub-connected Codex 或本地 repo 路径让 Codex 能读取 `skills/prd-development/SKILL.md`，现在要直接生成一个结构化 PRD。

```text
Using skills/prd-development/SKILL.md:
1) Ask up to 3 clarifying questions.
2) Follow the skill sections exactly.
3) Show output in markdown.
4) End with risks, assumptions, and next steps.
```

预期结果：Codex 先提出最多 3 个澄清问题，随后按 skill 的结构输出 markdown 产物，并列出风险、假设和下一步。

来源：`repo_readme_summary.md` 第 3 部分；官方 `docs/Using PM Skills with Codex.md` 的 practical prompt pattern。

## 常见场景

### 发现并安装一个 Codex skill

适用场景：不想 clone 整个仓库，只想通过 Skills CLI 找到并安装一个 Product Manager skill 到 Codex。

```sh
npx skills find product management
npx skills add deanpeters/Product-Manager-Skills --list
npx skills add deanpeters/Product-Manager-Skills --skill prd-development -a codex -g
npx skills list -a codex
```

预期结果：`--list` 显示可安装 skill；安装后 `npx skills list -a codex` 能看到已安装的 `prd-development`。

注意事项：官方 Codex Skills CLI 示例使用全局安装 `-g`；支持包安装脚本的 `--client=codex-cli` 也要求 `--location=global`。

来源：`repo_readme_summary.md` 第 2 部分；`scripts_for_install/install.sh` 的 `codex-cli` 分支；官方 `docs/Using PM Skills with Codex.md`。

### 让 Codex 按本地 skill 文件执行

适用场景：已经 clone 官方仓库，或已把 Codex ZIP 展开到目标 repo，想让 Codex 明确读取某个 skill 文件而不是泛泛回答。

```text
Using the skill at skills/prd-development/SKILL.md, create a PRD for a mobile onboarding redesign. Ask up to 3 clarifying questions first, then proceed.
```

预期结果：Codex 使用指定路径的 `SKILL.md`，先澄清关键信息，再产出对应 PM artifact。

注意事项：如果 Codex 提示找不到文件，先确认 repo/branch、当前工作目录，以及路径大小写。

来源：官方 `docs/Using PM Skills with Codex.md`；`repo_readme_summary.md` 第 3、4 部分。

### 串联问题定义和用户故事

适用场景：已经有产品方向，但需要先收敛问题，再把选定方案拆成用户故事。

```text
First use skills/problem-framing-canvas/SKILL.md to define the problem.
Then apply skills/user-story/SKILL.md to write stories for the chosen solution.
```

预期结果：Codex 先用 problem framing 结构重述和收敛问题，再基于选定方案输出 user stories 和验收标准。

来源：官方 `docs/Using PM Skills with Codex.md` 的 chain multiple skills 示例；官方 README 的 skill catalog。

### 在本地 playground 里先试跑

适用场景：还不确定要用哪个 PM skill，或想在接入 Codex / Claude 前先浏览、筛选和试跑。

```sh
pip install -r app/requirements.txt
streamlit run app/main.py
```

预期结果：浏览器打开 Streamlit playground，可以使用 Learn、Find My Skill 和 Run Skills 入口。

注意事项：命令需要在官方仓库根目录执行；API keys 通过环境变量配置，不在 app 内输入。

来源：官方 README 的 Streamlit beta 部分；`repo_readme_summary.md` 第 2 部分。

## 与 Agent 客户端配合

### Claude Code plugin 安装后验证

适用场景：已在 Claude Code 中完成 `/plugin marketplace add`、`/plugin install` 和 `/reload-plugins`，现在要确认 skill 可被调用。

```text
Use the jobs-to-be-done skill to analyze this customer problem.
```

预期结果：Claude Code 调用已安装的 `jobs-to-be-done` skill，并按该 skill 的流程分析客户问题。

注意事项：`/plugin ...` 是 Claude Code 内部 slash command，不是 shell 命令；支持包脚本的 `--client=claude-code` 只打印官方命令。

来源：`repo_readme_summary.md` 第 2 部分；`scripts_for_install/install.sh` 的 `claude-code` 分支；`skill_for_setup/ost_deanpeters_Product-Manager-Skills_install/SKILL.md`。

### Claude Desktop / Web 上传后验证

适用场景：已下载官方 pack、解压，并在 Claude 的 `Settings -> Capabilities -> Skills` 上传了内部 individual skill ZIP。

```text
Use the Product Manager Skills to help me frame this product problem.
```

预期结果：Claude 在新 chat 中识别已上传的 Product Manager Skills，并开始按相关 skill 引导问题 framing。

注意事项：不要上传外层 pack ZIP；必须先解压，再上传里面的 individual skill ZIPs。

来源：官方 README 的 Get Started / themed packs 部分；`repo_readme_summary.md` 第 2、4 部分。

## 验证与排错

### 验证 Codex ZIP 本地安装

适用场景：通过支持包脚本把 Codex ZIP 安装到目标 repo 后，检查 `.agents/skills` 和 `AGENTS.md` 是否可用。

```sh
sh scripts_for_install/install.sh --client=codex-zip --project-dir=/path/to/project --verify-only
```

预期结果：脚本报告在目标 repo 的 `.agents/skills` 下找到了 `SKILL.md` 文件；如果存在 `AGENTS.md`，也会报告验证通过。

注意事项：该命令只验证文件结构，不会自动证明 Codex 当前会话已经加载；验证后开启新的 Codex 会话再用 skill prompt 测试。

来源：`scripts_for_install/install.sh` 的 `verify_codex_zip`；setup Skill 的验证部分。

### 输出过于泛化时收紧 prompt

适用场景：Agent 没有明显使用 skill 结构，或输出像普通产品建议而不是 framework-guided artifact。

```text
Using skills/prd-development/SKILL.md:
Follow Purpose, Key Concepts, Application, Examples, Common Pitfalls, and References.
Use these constraints: stage=<stage>, KPI target=<metric>, customer segment=<segment>, timeline=<timeline>.
```

预期结果：Agent 明确按 skill 文件章节执行，并把真实约束纳入产物。

来源：官方 `docs/Using PM Skills with Codex.md` troubleshooting；官方 README 的 `How a Skill File Works` 部分。

## 延伸阅读

- 官方仓库 README：https://github.com/deanpeters/Product-Manager-Skills#readme
- Codex 使用指南：https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/Using%20PM%20Skills%20with%20Codex.md
- Claude Desktop / Web 安装：https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/INSTALL-CLAUDE-DESKTOP.md
- Claude Code 安装：https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/INSTALL-CLAUDE-CODE.md
- 平台选择器：https://github.com/deanpeters/Product-Manager-Skills/blob/main/docs/Platform%20Guides%20for%20PMs.md
- Streamlit playground：https://github.com/deanpeters/Product-Manager-Skills/blob/main/app/STREAMLIT_INTERFACE.md
