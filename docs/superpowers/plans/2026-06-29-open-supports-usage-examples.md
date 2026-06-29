# open_supports Optional Usage Examples Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional `usage_examples.md` generation stage to `open_supports` while keeping summaries concise and uninstall behavior reference-only by default.

**Architecture:** Add one reusable Skill, `ost-usage-examples`, and wire it into the existing workflow as an optional stage after setup Skill generation and before optional install testing. Existing stage Skills keep their current responsibilities, with narrower guidance for examples, setup scope, and uninstall behavior.

**Tech Stack:** Markdown Skill files, POSIX `sh` workflow state scripts, repository documentation.

---

## File Structure

- Create: `open_supports/.copilot-skills/ost-usage-examples/SKILL.md`
  - Owns the optional generation of `usage_examples.md`.
  - Defines trigger scope, pre-read order, blocking behavior, output structure, forbidden content, and quality checklist.
- Modify: `open_supports/.copilot-skills/ost-repo-readme-summary/SKILL.md`
  - Clarifies Part 3 as minimal examples with limited explanatory notes.
- Modify: `open_supports/.copilot-skills/ost-install-script/SKILL.md`
  - Adds uninstall policy and checklist guard against default destructive behavior.
- Modify: `open_supports/.copilot-skills/ost-skill-for-setup/SKILL.md`
  - Clarifies setup Skill scope and optional linking to `usage_examples.md`.
- Modify: `open_supports/.copilot-skills/ost-support-workflow/SKILL.md`
  - Adds `optional_usage_examples` stage, checklist, state handling, and subagent dispatch expectations.
- Modify: `open_supports/workflow-plan.md`
  - Keeps the planning/state-machine document aligned with the workflow Skill.
- Modify: `open_supports/README-todo.md`
  - Marks clarified questions as resolved and documents `.copilot-skills/` boundaries.
- Verify existing: `open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh`
  - No planned change unless verification shows it cannot represent the new stage.
- Verify existing: `open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh`
  - No planned change unless state tests hard-code the stage list.

Before touching `open_supports/README-todo.md`, run `git diff -- open_supports/README-todo.md` and preserve all existing user edits.

---

### Task 1: Add `ost-usage-examples` Skill

**Files:**
- Create: `open_supports/.copilot-skills/ost-usage-examples/SKILL.md`

- [ ] **Step 1: Confirm target directory does not already exist**

Run:

```sh
find open_supports/.copilot-skills -maxdepth 2 -type f | sort
```

Expected: existing Skills are listed and `open_supports/.copilot-skills/ost-usage-examples/SKILL.md` is absent.

- [ ] **Step 2: Create the Skill file**

Create `open_supports/.copilot-skills/ost-usage-examples/SKILL.md` with:

`````markdown
---
name: ost-usage-examples
description: 'Write optional usage_examples.md for an open_supports support package when a library has meaningful post-install workflows. Use after repo summary, install script, and setup Skill are complete.'
argument-hint: 'GitHub owner/repo of the target library, e.g. colbymchenry/codegraph'
---

# 编写 open_supports 使用示例（usage_examples.md）

## When to Use

- workflow 在 `skill_for_setup` 完成后检测到该库有足够复杂的安装后用法，并且用户同意生成详细用例
- 用户明确要求为某个支持包补充安装后的常见使用说明
- 官方 README 或 `.ost-refs/` 提供了多个实际用法场景，需要整理为本地快速入口

本 Skill 是可选阶段。没有 `usage_examples.md` 不影响支持包核心完成。

## Pre-read

执行前读取以下内容，按优先级顺序：

1. 目标支持包的 `repo_readme_summary.md`
2. 目标支持包的 `skill_for_setup/README.md`
3. 目标支持包的 `skill_for_setup/ost_*_install/SKILL.md`
4. 目标支持包的 `scripts_for_install/install.*`
5. 目标支持包的 `.ost-refs/` 目录（如存在且有内容）
6. `repo_readme_summary.md` 中引用的官方 README / 官方文档链接（仅在需要确认用法时读取）

## Clarification / Blocking

如果执行本阶段所需信息无法从 `repo_readme_summary.md`、安装脚本、setup Skill、`.ost-refs/` 或官方文档中可靠判断：

1. 不要猜测命令、配置、客户端接入或预期结果
2. 向 workflow 返回一个澄清问题
3. 标明 blocked 字段：
   - `stage`: `usage_examples`
   - `reason`
   - `question`
   - `suggested_default`（如有）
4. 等用户回答后再继续本阶段

典型阻塞点：

- 官方文档没有给出某个常见场景的命令或配置
- setup Skill 与官方文档对客户端接入方式描述不一致
- 无法判断示例应覆盖项目级配置还是全局配置
- 无法确认示例命令的预期成功输出

## 输出文件

写入目标支持包根目录：

```text
usage_examples.md
```

文件头格式：

```markdown
# {LibraryName} — 使用示例

> 來源：官方 README / 文檔；本文件只保留 open_supports 使用者最常見的入口。
```

## 文档结构

按以下顺序编写：

| # | 部分标题 | 内容定位 |
|---|---------|---------|
| 1 | **快速开始** | 安装完成后的第一条可执行路径，不重复安装步骤 |
| 2 | **常见场景** | 2~5 个高频任务，每个任务可独立阅读 |
| 3 | **与 Agent 客户端配合** | Claude Code、Codex、MCP、IDE 等接入或日常使用方式；无相关内容则删除本节 |
| 4 | **验证与排错** | 最小验证命令、常见失败现象、可执行处理方式 |
| 5 | **延伸阅读** | 官方文档中更完整的教程或高级配置链接 |

## 示例条目格式

每个示例尽量使用以下结构：

````markdown
### {场景名称}

适用场景：{什么时候使用}

```sh
{命令或最小配置}
```

预期结果：{成功后应看到什么}

注意事项：{只写会影响执行的限制；没有则删除本行}
````

## 编写原则

- 面向“已经安装完成，现在要开始使用”的用户
- 示例必须能从官方文档、现有支持包文件或 `.ost-refs/` 追溯来源
- 优先保留最常见、最短路径的操作
- 注释用于解释命令目的和成功判断，不展开背景教程
- 安装步骤仍以 `repo_readme_summary.md` 第 2 部分和 `scripts_for_install/install.*` 为准

## 禁止事项

- 不复制大段官方文档
- 不发明官方没有的命令、flag、配置键或客户端接入方式
- 不重写完整安装流程
- 不把卸载流程写成可执行指导；如官方有卸载文档，只能在延伸阅读或排错中给链接
- 不加入与 open_supports 使用者无关的高级场景

## Quality Checklist

- [ ] 文件写入目标支持包根目录 `usage_examples.md`
- [ ] 快速开始不重复安装步骤
- [ ] 每个示例都有适用场景、命令或最小配置、预期结果
- [ ] 命令、配置和客户端接入方式均可追溯到官方文档、支持包文件或 `.ost-refs/`
- [ ] 没有大段复制官方文档
- [ ] 没有发明未确认的命令、flag 或配置键
- [ ] 没有把卸载流程写成默认可执行操作
- [ ] 延伸阅读给出具体链接，不写“详见官方文档”这类无效表述
`````

- [ ] **Step 3: Verify the Skill can be discovered by path**

Run:

```sh
sed -n '1,220p' open_supports/.copilot-skills/ost-usage-examples/SKILL.md
```

Expected: file prints from frontmatter through the quality checklist with no shell errors.

- [ ] **Step 4: Commit Task 1**

Run:

```sh
git add open_supports/.copilot-skills/ost-usage-examples/SKILL.md
git commit -m "skills: add optional usage examples skill"
```

Expected: commit succeeds and includes only the new Skill file.

---

### Task 2: Tighten Existing Stage Skill Boundaries

**Files:**
- Modify: `open_supports/.copilot-skills/ost-repo-readme-summary/SKILL.md`
- Modify: `open_supports/.copilot-skills/ost-install-script/SKILL.md`
- Modify: `open_supports/.copilot-skills/ost-skill-for-setup/SKILL.md`

- [ ] **Step 1: Read current stage Skill text**

Run:

```sh
sed -n '1,260p' open_supports/.copilot-skills/ost-repo-readme-summary/SKILL.md
sed -n '1,320p' open_supports/.copilot-skills/ost-install-script/SKILL.md
sed -n '1,320p' open_supports/.copilot-skills/ost-skill-for-setup/SKILL.md
```

Expected: all three files print successfully.

- [ ] **Step 2: Update `ost-repo-readme-summary` Part 3 guidance**

In `open_supports/.copilot-skills/ost-repo-readme-summary/SKILL.md`, change the Part 3 row in the 5-part table from:

```markdown
| 3 | **使用示例** | 最小可运行示例，覆盖主要用法场景 |
```

to:

```markdown
| 3 | **使用示例** | 最小可运行示例 + 有限理解性注释；只帮助快速读懂，不展开多场景教程 |
```

After the Part 2专项要求 section and before 编写原则, add:

```markdown
## Part 3 专项要求（使用示例）

此部分用于快速理解库的主要用法，不承担完整教程职责。

- 保留最小可运行示例，优先选择官方 README 的第一条主路径
- 可添加简短注释说明“这条命令 / 代码在做什么”和“成功后应看到什么”
- 注释必须服务于快速理解，不展开背景、原理或多场景教程
- 若库有复杂的安装后工作流，由可选 `ost-usage-examples` Skill 生成 `usage_examples.md`
```

Add these checklist items after the existing Part 3 checklist item:

```markdown
- [ ] Part 3：示例包含有限理解性注释，能说明用途或预期结果
- [ ] Part 3：没有扩展成多场景教程；详细用例留给可选 `usage_examples.md`
```

- [ ] **Step 3: Update `ost-install-script` uninstall policy**

In `open_supports/.copilot-skills/ost-install-script/SKILL.md`, add this row to the 设计决策 table:

```markdown
| 卸载策略 | 默认不实现卸载 | 只记录官方卸载方法；仅当官方卸载命令明确且用户要求时，才可扩展 `--uninstall` |
```

After the 设计决策 table, add:

```markdown
## 卸载策略

默认一键脚本只负责安装、更新、配置和验证，不加入删除或卸载逻辑。

- 官方提供卸载文档时，可在 `repo_readme_summary.md` Part 5 或 setup Skill 的 Troubleshooting 中给出链接
- 不要默认删除二进制、配置文件、缓存目录或 Agent 客户端配置
- 只有同时满足以下条件时，才允许把 `--uninstall` 作为可选扩展加入脚本：
  1. 官方文档明确提供卸载命令或可验证的卸载流程
  2. 用户明确要求脚本支持卸载
  3. 脚本在执行前打印将删除或修改的路径 / 配置范围
```

Add this checklist item:

```markdown
- [ ] 未默认加入删除、卸载或清理配置等破坏性逻辑；如支持 `--uninstall`，已确认官方依据和用户要求
```

- [ ] **Step 4: Update `ost-skill-for-setup` scope**

In `open_supports/.copilot-skills/ost-skill-for-setup/SKILL.md`, after “## 设计原则：脚本优先 + 轻量兜底”, add:

```markdown
## 范围边界

setup Skill 聚焦安装、配置、验证和升级入口，不负责生成详细教程。

- 若支持包存在 `usage_examples.md`，安装完成后可提示用户阅读该文件
- 若官方提供卸载文档，可在 Troubleshooting 中链接，但不默认执行卸载
- 详细安装后用例由可选 `ost-usage-examples` Skill 生成
```

In the SKILL.md template's “安装完成后告知用户” block, change:

```markdown
[下一步提示，如需用户手动执行的操作]
```

to:

```markdown
[下一步提示，如需用户手动执行的操作；若 ../../usage_examples.md 存在，提示可阅读该文件]
```

Add these checklist items:

```markdown
- [ ] 范围说明明确 setup Skill 不负责生成详细教程
- [ ] 如 `usage_examples.md` 存在，安装完成后提示用户可阅读该文件
- [ ] Troubleshooting 没有默认执行卸载；如提及卸载，只链接官方说明
```

- [ ] **Step 5: Verify boundary language appears exactly once**

Run:

```sh
rg -n "Part 3 专项要求|卸载策略|范围边界|usage_examples.md" open_supports/.copilot-skills/ost-repo-readme-summary/SKILL.md open_supports/.copilot-skills/ost-install-script/SKILL.md open_supports/.copilot-skills/ost-skill-for-setup/SKILL.md
```

Expected: matches show the new sections and checklist references; no duplicated sections with the same heading in a single file.

- [ ] **Step 6: Commit Task 2**

Run:

```sh
git add open_supports/.copilot-skills/ost-repo-readme-summary/SKILL.md open_supports/.copilot-skills/ost-install-script/SKILL.md open_supports/.copilot-skills/ost-skill-for-setup/SKILL.md
git commit -m "skills: clarify support package generation boundaries"
```

Expected: commit succeeds and includes only the three stage Skill files.

---

### Task 3: Wire `optional_usage_examples` Into Workflow Skill

**Files:**
- Modify: `open_supports/.copilot-skills/ost-support-workflow/SKILL.md`
- Verify existing: `open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh`
- Verify existing: `open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh`

- [ ] **Step 1: Check whether state scripts hard-code stages**

Run:

```sh
rg -n "repo_readme_summary|install_script|skill_for_setup|optional_test_install|stages" open_supports/.copilot-skills/ost-support-workflow/scripts
```

Expected: identify whether `state.sh` or `test-state.sh` requires changes for the new `optional_usage_examples` stage.

- [ ] **Step 2: Update workflow phase list**

In `open_supports/.copilot-skills/ost-support-workflow/SKILL.md`, change:

```markdown
按顺序执行四个阶段：
```

to:

```markdown
按顺序执行五个阶段：
```

Change the list to:

```markdown
1. `repo_readme_summary`：串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-repo-readme-summary/SKILL.md`，产出 `repo_readme_summary.md`
2. `install_script`：串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-install-script/SKILL.md`，产出 `scripts_for_install/install.*`
3. `skill_for_setup`：串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-skill-for-setup/SKILL.md`，产出 `skill_for_setup/README.md` 和 `skill_for_setup/ost_*_install/SKILL.md`
4. `optional_usage_examples`：按 checklist 判断是否建议生成；用户同意后串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-usage-examples/SKILL.md`，产出 `usage_examples.md`
5. `optional_test_install`：询问用户是否测试运行安装脚本并验证安装成功
```

Update this sentence:

```markdown
前三个产出阶段默认使用子代理执行
```

to:

```markdown
前三个核心产出阶段和可选 `optional_usage_examples` 阶段默认使用子代理执行
```

- [ ] **Step 3: Add `optional_usage_examples` context hygiene and subagent handling**

In the Stage Subagents section, replace references to “阶段子代理只执行一个阶段” only if needed to include optional usage examples. Add:

```markdown
`optional_usage_examples` 被用户同意后，按普通阶段子代理处理；用户拒绝或 checklist 未命中时不派发子代理，直接标记为 `skipped`。
```

In the Context Hygiene “阶段子代理不要返回” list, no change is needed unless implementation finds wording that excludes the new stage.

- [ ] **Step 4: Update state shape example**

In the Minimal State Shape example, add:

```json
"optional_usage_examples": "pending",
```

inside `stages`, between `skill_for_setup` and `optional_test_install`.

Add a top-level state section after `test_install`:

```json
"usage_examples": {
  "offered": false,
  "decision": "pending",
  "matched_criteria": [],
  "result": null
},
```

If `state.sh` currently initializes state JSON without this field, update `state.sh` and `test-state.sh` in the same task to include and test the new field.

- [ ] **Step 5: Add Optional Usage Examples section**

Before “## Optional Test Install”, add:

```markdown
## Optional Usage Examples

`skill_for_setup` 完成后，workflow 按 checklist 判断是否建议生成 `usage_examples.md`。

命中以下条件中的 2 项或以上时，询问用户是否生成：

- 该库有 CLI 或可执行命令
- 该库有项目初始化流程
- 该库有配置文件或本地状态目录
- 该库有 Agent、MCP、IDE、Copilot、Claude、Codex 等客户端接入
- 该库有安装后的常见工作流，而不只是执行一次命令
- 官方 README 或文档提供多个用法场景
- `.ost-refs/` 提供本地使用约定

询问用户时，说明命中的条件，并明确这不影响核心支持包完成。

用户拒绝或命中条件不足：

- 将 `optional_usage_examples` 标记为 `skipped`
- 将 `usage_examples.decision` 记为 `declined` 或 `not_applicable`
- 继续进入 `optional_test_install`

用户同意：

- 将 `optional_usage_examples` 标记为 `in_progress`
- 串行派发阶段子代理，读取并遵循 `.copilot-skills/ost-usage-examples/SKILL.md`
- 产出 `usage_examples.md`
- 审查产物路径后，将阶段标记为 `done`

本阶段遇到无法确认的用例命令、配置或预期结果时，使用统一 Clarification / Blocking 协议。
```

- [ ] **Step 6: Update Completion criteria**

Change Completion requirements from:

```markdown
- `optional_test_install` 为 `skipped` 或测试结果为 `passed`
```

to:

```markdown
- `optional_usage_examples` 为 `done` 或 `skipped`
- `optional_test_install` 为 `skipped` 或测试结果为 `passed`
```

- [ ] **Step 7: Run workflow state script tests**

Run:

```sh
sh -n open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh
sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh
```

Expected: syntax check exits 0; state tests exit 0. If tests fail because they assert the old stage shape, update the state scripts/tests to include `optional_usage_examples`, then rerun.

- [ ] **Step 8: Commit Task 3**

Run:

```sh
git add open_supports/.copilot-skills/ost-support-workflow/SKILL.md open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh
git commit -m "skills: add optional usage examples workflow stage"
```

Expected: commit succeeds. If state scripts did not change, `git add` should stage only the workflow Skill.

---

### Task 4: Align Workflow Plan Documentation

**Files:**
- Modify: `open_supports/workflow-plan.md`

- [ ] **Step 1: Read current plan and spec**

Run:

```sh
sed -n '1,320p' open_supports/workflow-plan.md
sed -n '1,260p' docs/superpowers/specs/2026-06-29-open-supports-usage-examples-design.md
```

Expected: both files print successfully.

- [ ] **Step 2: Update plan goal and scope**

In `open_supports/workflow-plan.md`, change the goal list from four stages to five stages:

```markdown
1. `ost-repo-readme-summary`
2. `ost-install-script`
3. `ost-skill-for-setup`
4. `optional_usage_examples`
5. `optional_test_install`
```

Add this sentence after the stage list:

```markdown
第四阶段只在 checklist 命中且用户同意时生成 `usage_examples.md`；用户拒绝或条件不足时跳过，不影响核心支持包完成。
```

Add `可选 usage examples 阶段确认门` to the “包含” scope list.

- [ ] **Step 3: Update state shape and state machine text**

In the Minimal State Shape JSON, add `optional_usage_examples` in `stages` and add:

```json
"usage_examples": {
  "offered": false,
  "decision": "pending",
  "matched_criteria": [],
  "result": null
},
```

Update the state machine text so `SetupSkillDone` flows to `OfferUsageExamples`, then to `OfferTestInstall`. Use this mermaid block:

```markdown
  SetupSkillDone --> OfferUsageExamples

  OfferUsageExamples --> UsageExamplesSkipped: checklist not matched or user declines
  OfferUsageExamples --> UsageExamples: user accepts
  UsageExamples --> ClarificationNeeded: missing usage example info
  UsageExamples --> UsageExamplesDone: usage_examples.md created/updated
  UsageExamplesSkipped --> OfferTestInstall
  UsageExamplesDone --> OfferTestInstall
```

Remove or replace the old direct edge:

```markdown
SetupSkillDone --> OfferTestInstall
```

- [ ] **Step 4: Add optional usage examples section**

Add a section mirroring the workflow Skill:

```markdown
## Optional Usage Examples

`skill_for_setup` 完成后，workflow 使用固定 checklist 判断是否建议生成 `usage_examples.md`。命中 2 项或以上时询问用户；用户同意才执行。

checklist：

- 有 CLI 或可执行命令
- 有项目初始化流程
- 有配置文件或本地状态目录
- 有 Agent / MCP / IDE / Copilot / Claude / Codex 等客户端接入
- 有安装后的常见工作流
- 官方 README 或文档提供多个用法场景
- `.ost-refs/` 提供本地使用约定

用户拒绝或条件不足时，将 `optional_usage_examples` 标记为 `skipped` 并继续 `optional_test_install`。
```

- [ ] **Step 5: Update implementation task checklist**

Add completed or pending implementation tasks describing the new Skill and workflow integration. Use unchecked items until implementation is complete:

```markdown
- [ ] 新增 `.copilot-skills/ost-usage-examples/SKILL.md`
- [ ] 在 workflow Skill 中增加 `optional_usage_examples` 阶段
- [ ] 更新 workflow plan，使状态机包含可选 usage examples 阶段
```

If these edits are made after Tasks 1-3 have already been committed, mark them checked only if the corresponding changes are present in the current branch.

- [ ] **Step 6: Verify documentation mentions the stage consistently**

Run:

```sh
rg -n "optional_usage_examples|usage_examples.md|ost-usage-examples" open_supports/workflow-plan.md open_supports/.copilot-skills/ost-support-workflow/SKILL.md
```

Expected: both files mention the optional stage and the new Skill name.

- [ ] **Step 7: Commit Task 4**

Run:

```sh
git add open_supports/workflow-plan.md
git commit -m "docs: document optional usage examples workflow"
```

Expected: commit succeeds and includes only `open_supports/workflow-plan.md`.

---

### Task 5: Update README-todo and Skill Boundary Documentation

**Files:**
- Modify: `open_supports/README-todo.md`

- [ ] **Step 1: Inspect existing user changes**

Run:

```sh
git diff -- open_supports/README-todo.md
sed -n '1,260p' open_supports/README-todo.md
```

Expected: current uncommitted edits are visible. Preserve them and apply this task as an incremental edit.

- [ ] **Step 2: Add `.copilot-skills/` boundary explanation**

Under the `.copilot-skills/` directory description or after `skill_for_setup/`, add:

```markdown
### `.copilot-skills/`

跨支持包复用的通用 Skill 收录在这里，例如摘要生成、安装脚本生成、setup Skill 生成、workflow 编排、可选用例生成等。

- 放入 `.copilot-skills/`：适用于多个开源库支持包的通用流程、质量标准、状态管理或可选阶段
- 留在各支持包 `skill_for_setup/`：某个库专属的安装 / 配置 Skill，以及该库特有的触发词、参数和排错说明
- 不放入 `.copilot-skills/`：单库 README 摘要、单库安装脚本、单库使用示例产物
```

- [ ] **Step 3: Mark clarified questions resolved**

In the “待澄清问题” section, change:

```markdown
- [ ] ost_readme_summary.md 的示例部分显得过于单薄：适当增加注释说明和可理解性？
- [ ] 考虑增加单独技能，用于在工作流结束后建立更详细的示例使用说明和更多的用例？如有。
- [ ] 一键脚本的部分只有安装和更新，缺乏删除的操作？
```

to:

```markdown
- [x] `repo_readme_summary.md` 的示例部分保持轻量，只增加有限理解性注释；详细用例不放入摘要
- [x] 增加可选 `ost-usage-examples` Skill，用于在 workflow 后生成 `usage_examples.md`
- [x] 一键脚本默认不包含删除 / 卸载；官方卸载方法只记录为参考，`--uninstall` 仅作为明确要求下的可选扩展
```

- [ ] **Step 4: Update system checklist**

In the 体系层待办清单, mark the `.copilot-skills/` boundary item complete if Step 2 was added:

```markdown
- [x] `.copilot-skills/` 补充说明：明确哪类通用 Skill 应沉淀至此（如通用 MCP 注册、版本检测等），以及与各库 `skill_for_setup/` 的边界
```

Add:

```markdown
- [x] 新增可选 `ost-usage-examples` Skill 设计：用于生成安装后的详细用例入口
```

- [ ] **Step 5: Verify README has no stale misspelling**

Run:

```sh
rg -n "ost_readme_summary|repo_readme_sunmary|ost-usage-examples|\\.copilot-skills" open_supports/README-todo.md
```

Expected: no `repo_readme_sunmary`; `ost_readme_summary` should only appear if intentionally discussing the old pending-question wording. Prefer `repo_readme_summary.md`.

- [ ] **Step 6: Commit Task 5**

Run:

```sh
git add open_supports/README-todo.md
git commit -m "docs: clarify open supports skill boundaries"
```

Expected: commit succeeds. Confirm no unrelated files are staged.

---

### Task 6: Final Verification

**Files:**
- Verify all modified files from Tasks 1-5

- [ ] **Step 1: Check shell syntax**

Run:

```sh
sh -n open_supports/.copilot-skills/ost-support-workflow/scripts/state.sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh
```

Expected: exit 0.

- [ ] **Step 2: Run workflow state tests**

Run:

```sh
sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh
```

Expected: exit 0 and no failure output.

- [ ] **Step 3: Verify required strings across Skill files**

Run:

```sh
rg -n "optional_usage_examples|ost-usage-examples|usage_examples.md|卸载策略|Part 3 专项要求|范围边界" open_supports/.copilot-skills open_supports/workflow-plan.md open_supports/README-todo.md
```

Expected: all required concepts are present in the intended files.

- [ ] **Step 4: Verify no unresolved markers were introduced**

Run:

```sh
rg -n "TB""D|TO""DO|待""定|fill"" in|implement"" later" open_supports/.copilot-skills open_supports/workflow-plan.md open_supports/README-todo.md
```

Expected: no matches introduced by this implementation. Existing unrelated待办清单 items in `README-todo.md` may remain; inspect any matches manually.

- [ ] **Step 5: Verify git state and commit boundaries**

Run:

```sh
git status --short
git log --oneline -6
```

Expected: only pre-existing unrelated user changes remain unstaged, if any. Recent commits correspond to the task commits in this plan.

- [ ] **Step 6: Summarize implementation**

Prepare a short final summary including:

- New optional Skill path
- Existing Skill boundary changes
- Workflow/documentation updates
- Verification commands and results
- Any pre-existing uncommitted files left untouched

No commit is required for this final summary step unless verification forced a small fix.

---

## Self-Review Notes

Spec coverage:

- Concise Part 3 examples are covered by Task 2.
- New `ost-usage-examples` Skill is covered by Task 1.
- Optional workflow stage and checklist are covered by Task 3.
- Workflow plan and README-todo updates are covered by Tasks 4 and 5.
- Uninstall reference-only default is covered by Task 2.
- Final verification covers shell syntax, state tests, required terms, unresolved markers, and git state.

Marker scan:

- The plan intentionally includes template variables such as `{LibraryName}` inside Skill templates because those are part of the Skill's generated-output instructions.
- There are no plan-action blanks requiring future invention by the implementer.

Risk notes:

- `open_supports/README-todo.md` already had uncommitted edits before this plan was written. Execution must inspect and preserve those edits.
- If `state.sh` hard-codes the stage list, Task 3 must update both `state.sh` and `test-state.sh`; otherwise only the workflow Skill changes.
