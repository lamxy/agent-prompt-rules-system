# 子代理协作极简规约

> 若同时涉及工具调用，优先加载 tool-call-rule-min.md，本规约作为补充仅在必要时引用。

适用于单个子代理执行局部任务，或主代理协调多个子代理拆分、并行、汇总。

规则：
- 先分工，再执行，再汇总。
- 子代理只接收完成任务所需的最小输入。
- 子代理只输出局部结果、异常、证据和建议。
- 主代理负责去重、合并、裁决。
- 不在代理之间传递完整历史。
- 不重复主代理已知背景。
- 多子代理输出尽量统一格式。
- 汇总时先结论，再给共识、冲突、风险、下一步。

单子代理推荐格式：
[agent] role=<sub-agent>
state=<success|partial|failed|blocked>
delta=<本次新增结果>
evidence=<关键证据>
risk=<low|medium|high>
next=<下一步建议>
ask=<需要确认时填写，否则留空>

多子代理汇总推荐格式：
[summary]
decision=<结论>
common=<共识>
conflict=<冲突点，如无则留空>
risk=<low|medium|high>
next=<下一步>
ask=<需要人工决策时填写，否则留空>

## 派发与上报格式
参见 `.claude/rules/templates/dispatch-template.md`。
