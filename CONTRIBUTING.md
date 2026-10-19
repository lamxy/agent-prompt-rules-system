# Contributing

感谢你对本项目的关注。

本仓库是以个人使用为主的 Agent 配置、技能与工具管理仓库（2026-10 由提示词规则系统转型，原因见 README「转型说明」），不主动征集贡献；发现问题欢迎开 issue。  
在提交改动前，请先理解本仓库的核心原则：

- 只写与默认行为不同的约束
- 需要强制的边界用 settings、hook，而不是提示词
- 场景化指引做成 skill
- 工具接入可复现：安装脚本幂等、可验证
- 安装脚本不覆盖需要人工合并的内容

---

## 贡献前建议

在提交 PR 之前，请先自问：

1. 删掉这条规则后，Claude Code 的默认行为会不会改变？不会就不该写。
2. 它需要强制执行吗？需要就用 `settings.json` 的权限、沙箱或 hook，而不是提示词。
3. 它只在部分场景需要吗？是就做成 skill 或带 `paths` frontmatter 的 rule。
4. 它会和现有规则或设定冲突吗？
5. 它是否会增加上下文膨胀风险？

如果这些问题里有多个答案偏负面，建议先不要把变更并入主文件。

---

## 贡献方向

欢迎以下类型的贡献：

- 修正文档错误、链接错误、命名错误
- 优化 `dot_claude/CLAUDE.md` 的表达，使其更稳定、简洁、可执行
- 删除已被 Claude Code 默认行为覆盖的规则
- 把软约束改为 settings、hook 或 skill 等更可靠的机制
- 改进 examples 示例
- 改进项目结构与可维护性

---

## 不建议的贡献方向

以下改动通常不建议直接提交：

- 把 `dot_claude/CLAUDE.md` 扩展成巨大的万能提示词
- 在主文件中加入大量低频、场景化细节
- 为了“完整”而堆砌规则
- 引入重复表达或大段说明性文字
- 在没有明确收益的情况下增加复杂度

---

## 文件修改建议

### 修改 `dot_claude/CLAUDE.md` 前
请优先判断：

- 这是否与 Claude Code 默认行为不同，且确有需要？
- 需要强制执行时，是否应改放 `dot_claude/settings.json`（权限、沙箱、hook）？
- 只在特定场景需要时，是否应做成 skill，或放入带 `paths` frontmatter 的 `.claude/rules/` 文件？

主文件应尽量保持短、小、稳；`dot_claude/` 下的内容使用繁体中文。修改后可执行 `/doctor prompt-audit` 检查过时或冲突的指令。

### 关于 `dot_claude_legacy/`

`dot_claude_legacy/` 是 2026-10-19 之前分层规约系统的只读备份，不被任何安装脚本使用。请勿在其中新增内容；替换原因与迁移对照见 `dot_claude/README.md`。

---

## 提交风格建议

建议提交信息清晰说明改动意图，例如：

- `docs: refine README wording`
- `refactor: reduce duplication in CLAUDE.md`
- `settings: move claude-api trigger rule to skillOverrides`

---

## Pull Request 建议

PR 描述建议至少包含：

1. 改动目标
2. 为什么要改
3. 改动范围
4. 是否增加了上下文或维护成本
5. 为什么该改动应该放在当前层，而不是其他层

---

## 讨论建议

如果你不确定某条规则是否应该加入，建议先开 issue 或 draft PR 讨论，而不是直接扩大主文件。

---

## 行为约定

请保持讨论：

- 简洁
- 聚焦问题
- 基于长期可维护性
- 尊重已有设计边界

感谢贡献。
