---
name: ost-support-workflow
description: Use when creating or updating an open_supports support package end-to-end, especially when coordinating repo summary, install script, setup skill, clarification, resume, or optional install verification.
argument-hint: 'GitHub owner/repo, e.g. colbymchenry/codegraph'
---

# open_supports 支持包工作流

## When to Use

- 为 `open_supports/` 新增一个开源库支持包
- 更新已有支持包的摘要、安装脚本或安装 Skill
- 从 `.ost-workflow-state/` 恢复中断的支持包工作流

## Pre-read

执行前先读取：

1. `open_supports/README-todo.md`
2. `open_supports/workflow-plan.md`
3. 目标支持包的 `.ost-refs/` 目录（如存在且有内容）
4. 目标阶段对应的 `.copilot-skills/*/SKILL.md`

## Workflow

按顺序执行五个阶段：

1. `repo_readme_summary`：串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-repo-readme-summary/SKILL.md`，产出 `repo_readme_summary.md`
2. `install_script`：串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-install-script/SKILL.md`，产出 `scripts_for_install/install.*`
3. `skill_for_setup`：串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-skill-for-setup/SKILL.md`，产出 `skill_for_setup/README.md` 和 `skill_for_setup/ost_*_install/SKILL.md`
4. `optional_usage_examples`：按 checklist 判断是否建议生成；用户同意后串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-usage-examples/SKILL.md`，产出 `usage_examples.md`
5. `optional_test_install`：询问用户是否测试运行安装脚本并验证安装成功

不要假设客户端支持嵌套调用 Skill；本 Skill 的职责是编排、状态管理、澄清和恢复。阶段细节以对应阶段 Skill 为准。

三个核心产出阶段和可选 `optional_usage_examples` 阶段默认使用子代理执行，但必须串行执行，不能并行。`optional_test_install` 默认由主 workflow 控制，因为它可能真实修改本机 CLI / Agent 配置。

## Stage Subagents

主 workflow 是唯一状态管理者和唯一用户交互者。阶段子代理只执行一个阶段，不直接询问用户，不直接写 `.ost-workflow-state/*.json`。

派发阶段子代理前：

1. 使用状态脚本将阶段设为 `in_progress`
2. 给子代理提供目标阶段、目标支持包目录、对应阶段 Skill 路径、必要的上一阶段产物路径、已有用户澄清答案
3. 明确要求子代理只返回结构化结果

阶段子代理只能返回：

- `DONE`
- `NEEDS_CLARIFICATION`
- `FAILED`

收到 `DONE`：主 workflow 审查产物路径，使用状态脚本记录 `agent-run ... DONE ...`，再将阶段设为 `done`。

收到 `NEEDS_CLARIFICATION`：主 workflow 使用状态脚本记录 `agent-run ... NEEDS_CLARIFICATION ...`，再用 `block ...` 写入阻塞问题，然后只向用户提出该问题。

收到 `FAILED`：主 workflow 使用状态脚本记录 `agent-run ... FAILED ...`，将阶段标记为 `failed`，再询问用户下一步。

`optional_usage_examples` 被用户同意后，按普通阶段子代理处理；用户拒绝或 checklist 未命中时不派发子代理，直接标记为 `skipped`。

## Context Hygiene

主 workflow 必须尽可能保持上下文干净、节省。阶段子代理用于隔离重上下文，避免把官方 README、长文档、详细推理过程或完整中间草稿回灌给主 workflow。

阶段子代理只返回满足编排所需的最小关键信息：

- `status`: `DONE`、`NEEDS_CLARIFICATION` 或 `FAILED`
- `stage`: 当前阶段名
- `summary`: 1-3 条结果摘要
- `files_changed`: 产物文件路径列表
- `verification`: 已执行的轻量检查及结果
- `clarification`: 仅当 `NEEDS_CLARIFICATION` 时返回，包含 `reason`、`question`、`suggested_default`
- `failure`: 仅当 `FAILED` 时返回，包含失败命令、退出码和关键输出摘要

阶段子代理不要返回：

- 大段官方文档摘录
- 完整 README 或完整安装文档
- 详细逐步推理过程
- 与当前阶段无关的发现
- 可从产物文件直接读取的完整内容

主 workflow 若需要审查产物，应读取目标文件本身，而不是要求子代理复制文件内容。状态文件只保存恢复和决策所需信息，不保存长文档或冗余中间过程。

## State Management

状态目录：

```text
open_supports/.ost-workflow-state/
```

状态文件：

```text
open_supports/.ost-workflow-state/{GithubName}_{RepoName}.json
```

状态 JSON 包含阶段状态和可选用法示例决策，例如：

```json
{
  "stages": {
    "repo_readme_summary": "pending",
    "install_script": "pending",
    "skill_for_setup": "pending",
    "optional_usage_examples": "pending",
    "optional_test_install": "pending"
  },
  "usage_examples": {
    "offered": false,
    "decision": "pending",
    "matched_criteria": [],
    "result": null
  }
}
```

状态 JSON 默认不提交 Git。恢复工作流时，先读取对应状态文件：

- 若存在 `blocked` 或 `waiting_user`，先复述当前断点和唯一待回答问题
- 用户回答后，把回答写入状态，再回到下一阶段检测
- 若不存在状态文件，创建新状态并从 `PreparePackage` 开始

状态读写必须优先通过内部脚本完成：

```text
open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh
```

该脚本使用 `sh + jq`，只负责 JSON 状态机械读写，不负责 workflow 决策。只有主 workflow 可以调用该脚本；阶段子代理不能直接调用。

常用命令：

```sh
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh init OWNER/REPO
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh show OWNER/REPO
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh set-stage OWNER/REPO STAGE STATUS
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh block OWNER/REPO STAGE REASON QUESTION [SUGGESTED_DEFAULT]
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh answer OWNER/REPO ANSWER
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh agent-run OWNER/REPO STAGE STATUS SUMMARY
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh usage-examples OWNER/REPO DECISION MATCHED_CRITERIA [RESULT]
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh test-result OWNER/REPO RESULT COMMAND EXIT_CODE SUMMARY
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh complete OWNER/REPO
```

阶段状态只使用：

```text
pending
in_progress
done
blocked
waiting_user
skipped
failed
```

## Package Preparation

目标支持包目录不存在时，可以自动创建最小目录结构：

```text
ost_{GithubName}_{RepoName}/
ost_{GithubName}_{RepoName}/scripts_for_install/
ost_{GithubName}_{RepoName}/skill_for_setup/
ost_{GithubName}_{RepoName}/skill_for_setup/ost_{GithubName}_{RepoName}_install/
```

可以创建缺失目录，但不要自动覆盖已有文件。目标产物已存在时，进入对应阶段的更新或确认逻辑。

## Clarification / Blocking

任何阶段遇到关键行为无法从官方文档、现有支持包文件或 `.ost-refs/` 可靠判断时：

1. 不要猜测关键行为
2. 将当前阶段标记为 `blocked`
3. 记录一个澄清项：
   - `stage`
   - `reason`
   - `question`
   - `suggested_default`（如有）
4. 将 `workflow_status` 标记为 `blocked`
5. 向用户提出这个问题，等待回答

最小恢复策略：只处理当前唯一 open clarification，不维护多问题队列。

## Optional Usage Examples

三个核心产出阶段完成后，先按以下 checklist 判断是否建议生成 `usage_examples.md`：

- 官方文档包含 CLI 或可执行命令示例
- 官方文档包含项目初始化流程
- 支持包涉及配置文件或状态目录
- 支持包涉及 Agent、MCP、IDE、Copilot、Claude 或 Codex 接入
- 安装后存在常见工作流或后续操作
- 官方文档提供多个用法场景
- `.ost-refs/` 中存在本地约定、项目约定或推荐实践

命中 2 项或以上才询问用户是否生成用法示例。未命中时：

- 将 `optional_usage_examples` 标记为 `skipped`
- 将 `usage_examples.decision` 记为 `not_applicable`
- 继续进入 `optional_test_install`

命中 2 项或以上时，询问用户：

```text
检测到该支持包适合生成 usage_examples.md。是否要派发 ost-usage-examples 阶段子代理生成安装后的用法示例？
回复“是”则生成，回复“否”则跳过并继续 optional_test_install。
```

主 workflow 在 checklist 判断或询问用户并做出决策后，必须使用状态脚本记录 `usage_examples.decision`、`usage_examples.matched_criteria` 和 `usage_examples.result`：

```sh
sh open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh usage-examples OWNER/REPO DECISION MATCHED_CRITERIA [RESULT]
```

用户拒绝：

- 将 `optional_usage_examples` 标记为 `skipped`
- 将 `usage_examples.decision` 记为 `declined`
- 继续进入 `optional_test_install`

用户同意：

- 将 `usage_examples.offered` 记为 `true`，记录命中的 `usage_examples.matched_criteria`
- 将 `usage_examples.decision` 记为 `accepted`
- 将 `optional_usage_examples` 标记为 `in_progress`
- 串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-usage-examples/SKILL.md`
- 子代理产出 `usage_examples.md`
- 主 workflow 审查产物后，记录 `agent-run ... DONE ...`，将 `usage_examples.result` 记为 `generated`，并将 `optional_usage_examples` 标记为 `done`

## Optional Test Install

三个核心产出阶段和 `optional_usage_examples` 完成或跳过后，必须询问用户：

```text
是否要测试运行 scripts_for_install/install.* 并验证安装是否成功？
这可能会修改本机 CLI / Agent 配置。回复“是”则执行，回复“否”则跳过并完成工作流。
```

用户拒绝：

- 将 `optional_test_install` 标记为 `skipped`
- 将 `test_install.decision` 记为 `declined`
- 将 `workflow_status` 标记为 `done`

用户同意：

- 将 `optional_test_install` 标记为 `in_progress`
- 运行安装脚本
- 运行验证命令
- 记录执行命令、结果和关键输出摘要

验证命令优先来自 `repo_readme_summary.md` 第 2 部分，其次来自安装脚本或 setup Skill；仍不能判断时进入澄清。

## Test Failure

测试安装失败后不要自动修复。保存失败状态并暂停：

- `optional_test_install` 标记为 `failed`
- `workflow_status` 标记为 `blocked`
- 记录失败命令、退出码和关键输出摘要
- 询问用户下一步：修复支持包文件、跳过测试并完成，或停在失败状态稍后恢复

## Completion

完成时确认：

- `repo_readme_summary` 为 `done`
- `install_script` 为 `done`
- `skill_for_setup` 为 `done`
- `optional_usage_examples` 为 `done` 或 `skipped`
- `optional_test_install` 为 `skipped` 或测试结果为 `passed`
- `workflow_status` 为 `done`
