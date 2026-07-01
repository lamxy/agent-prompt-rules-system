# open_supports Workflow Quickstart

本教程说明如何使用 `ost-support-workflow` 工作流 Skill 创建或更新 `open_supports/` 支持包。

## 推荐方式：当前仓库直接对话使用

这是最稳的方式，不需要安装 Skill。

对话开头可以这样写：

```text
请使用 open_supports/.copilot-skills/ost-support-workflow/SKILL.md 工作流，
为 GitHub 仓库 owner/repo 创建 open_supports 支持包。

要求：
1. 先阅读 open_supports/README.md
2. 读取或初始化目标 .ost-workflow-state/ 状态文件
3. 使用 .ost-workflow-state/ 记录状态
4. 主 workflow 不要预读阶段 Skill、官方 README 或长文档；阶段 Skill 只在子代理 contract 中引用
5. 三个核心产出阶段用子代理串行执行；可选 usage examples 阶段在用户同意后也串行执行
6. 如果子代理工具未显示，先用 tool_search 搜索 multi-agent / subagent / spawn-agent 工具，不得直接 inline
7. 每次派发前记录 dispatch contract；所有 state.sh 写入必须串行
8. inline fallback 只在工具确认不可用、schema 不支持、我明确要求不用子代理，或子代理连续失败后我同意接管时使用，并必须用 inline-run 记录具体原因
9. 如需澄清，只问当前一个问题
10. workflow checklist 命中时，生成 usage_examples.md 前必须先问我
11. 最后测试安装前必须先问我
```

示例：

```text
请使用 open_supports/.copilot-skills/ost-support-workflow/SKILL.md 工作流，
为 open-gsd/gsd-core 创建支持包。
```

恢复断点时：

```text
继续 open-gsd/gsd-core 的 open_supports workflow。
先读取 .ost-workflow-state/open-gsd_gsd-core.json，然后从断点恢复。
如果子代理工具未显示，先用 tool_search 搜索 multi-agent / subagent / spawn-agent 工具，不得直接 inline。
```

## 可选方式：复制到 Codex 全局技能目录

如果希望以后自然语言自动触发，可以复制到 Codex 全局技能目录。

当前默认目录：

```text
~/.codex/skills/
```

目标结构：

```text
~/.codex/skills/ost-support-workflow/SKILL.md
~/.codex/skills/ost-support-workflow/scripts/state.sh
~/.codex/skills/ost-support-workflow/scripts/test-state.sh
```

复制后通常需要新开会话，技能列表才会刷新。当前会话仍建议直接指定仓库内 Skill 文件路径。

## 项目内 Skill 位置

本仓库保留的 workflow Skill 位于：

```text
open_supports/.copilot-skills/ost-support-workflow/SKILL.md
```

优点是跟项目一起版本管理，适合维护本仓库。缺点是 Codex 不一定会自动发现 `.copilot-skills`，所以使用时最好明确告诉模型读取并遵循该文件。

## 需要提供的信息

最少只需要：

```text
owner/repo
```

可选补充：

```text
这是新增支持包 / 更新已有支持包
优先支持哪些客户端：Claude Code、Codex、Cursor 等
是否有特殊本地约定：写入 .ost-refs/
```

## 安装验证

workflow 最后会询问是否测试运行安装脚本并验证安装是否成功。

默认不会执行安装验证；只有用户明确同意后才执行，因为安装脚本可能访问网络、安装 CLI 或写入本机 Agent 配置。
