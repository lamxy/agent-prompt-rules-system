# open_supports Workflow State

此目录用于存放 workflow Skill 的运行时状态。

状态 JSON 文件用于问题澄清、断点续传和恢复执行，可能包含本机路径、失败输出摘要或用户回答，因此默认不提交 Git。

约定：

- 状态文件命名：`{OwnerName}_{RepoName}.json`
- 示例：`colbymchenry_codegraph.json`
- 具体 JSON 状态文件由仓库根目录 `.gitignore` 忽略
- 本说明文件可以提交，用于保留目录约定
- `execution.agent_runs` 只记录真实子代理执行结果
- `execution.inline_runs` 记录 fallback inline 执行及具体 `fallback_reason`
- `execution.dispatch_contracts` 记录每次子代理派发的可审计 contract 摘要
- `installation_scope` 记录摘要 Part 2 已确认的 A/B/C/D 分类、官方默认、目标目录机制、执行方式和官方证据；它是脚本、setup Skill 与 usage examples 的一致性依据
- 所有状态写入必须通过 workflow 主代理串行调用 `state.sh`
