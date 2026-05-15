# 派发模板使用规则

> **每次派发子代理时，必须在 prompt 末尾追加 `dispatch-footer.md` 的输出约束内容。**
> 路径：`.claude/expandable/templates/dispatch-footer.md`

## 判断规则（决策树）
- 第一步：是否低上下文场景（高频重复 / token紧张 / 快速协作）
	- 是：优先“低上下文极简示例”
	- 否：进入第二步
- 第二步：是否简单派发（命令 ≤ 1条，格式要求 ≤ 3行）
	- 是：自由组织，无需模板
	- 否：进入第三步
- 第三步：是否复杂派发（多命令 / 含依赖 / 多步骤 / 需传上下文）
	- 是：使用“派发模板”或“严格短句示例”
	- 否：自由组织
- 多子代理或代理团队场景：除 `output_format` 外，建议同时提供 `summary_format`

## 派发模板
[dispatch]
task=<任务描述，1行>
cmd=<命令，多条换行>
context=<依赖文件或前置条件，如无则留空>
contract=<子代理极简规约摘要，2-4行；必须包含范围、阻塞上报、分流规则>
output_format=<期望输出格式>
summary_format=<多代理汇总格式；单代理可留空>

## 一致性与冲突处理
- `output_format` 和 `summary_format` 的字段名应与对应模板保持一致。
- `contract` 必须给出子代理极简规约摘要，且与 `output_format` 字段一致，不可冲突。
- 低上下文示例中的字段缩写仅用于派发说明，不替代真实输出模板字段。
- 若本文件示例与 task 规约冲突，以 task 规约为准。
- `ask` 字段仅在需要确认时填写，且一次只问一个最小问题。

## 最小合规模板检查清单（4项）
- 已明确范围：`task` 与 `context` 不含超范围要求。
- 已附带规约：`contract` 已提供子代理极简规约摘要（范围、阻塞上报、结果分流）。
- 已明确输出：`output_format`（多代理时含 `summary_format`）字段齐全。
- 已明确异常：包含“审批即时上报 + 阻塞20-30分钟上报”规则。
- 已明确分流：包含“简单直返 + 复杂落盘并回传 artifact”规则。

## 严格短句示例

### 1) 单子代理（可独立完成）
```text
[dispatch]
task=请独立完成当前任务并返回最小结果
cmd=仅使用给定输入范围，不扩展目标
cmd=简单结果（≤150行且≤3000字符）直接返回；复杂结果先落盘再回传摘要与artifact
cmd=遇到权限或审批限制立即上报并等待
cmd=阻塞超过20-30分钟时返回已完成证据并标记partial或blocked
context=输入文件: <file_a>, <file_b>
contract=仅处理指定范围；禁止长背景复述；按[agent]字段回传；需要确认时仅填写ask
output_format=
[agent] role=<sub-agent>
state=<success|partial|failed|blocked>
delta=<本次新增结果>
evidence=<关键证据>
artifact=<复杂结果文件路径；无则留空>
risk=<low|medium|high>
next=<下一步建议；如无则留空>
ask=<需要确认时填写，否则留空>
```

### 2) 多子代理（并行协作）
```text
[dispatch]
task=你只负责子任务A，不处理其他范围
cmd=仅处理指定范围并返回局部结论
cmd=简单结果直接返回；复杂结果先落盘再回传artifact
cmd=遇到权限或审批限制立即上报并等待
cmd=阻塞超过20-30分钟时返回已完成证据并标记partial或blocked
context=输入文件: <scope_a_files>
contract=仅处理A范围；按[agent]字段回传；不得输出完整日志；阻塞先上报再等待
output_format=
[agent] role=<sub-agent-A>
state=<success|partial|failed|blocked>
delta=<子任务A新增结果>
evidence=<子任务A关键证据>
artifact=<复杂结果文件路径；无则留空>
risk=<low|medium|high>
next=<子任务A下一步建议；无则留空>
ask=<需要确认时填写，否则留空>
```

```text
[summary]
decision=<最终结论>
common=<多子代理共识>
conflict=<冲突点，如无则留空>
artifacts=<需复核文件路径列表；无则留空>
risk=<low|medium|high>
next=<下一步；如无则留空>
ask=<需要人工决策时填写，否则留空>
```

### 3) 代理团队（多实例协作）
```text
[dispatch]
task=你是team agent，只处理分配子任务
cmd=仅回传局部结果，不转述团队背景
cmd=简单结果直接返回；复杂结果先落盘再回传artifact
cmd=遇到权限或审批限制立即上报并等待
cmd=阻塞超过20-30分钟时返回已完成证据并标记partial或blocked
context=输入文件: <assigned_scope_files>
contract=只返回局部结果；按[team-agent]字段回传；不得转述团队历史
output_format=
[team-agent] role=<agent role>
state=<success|partial|failed|blocked>
delta=<本次新增结果>
evidence=<关键证据>
artifact=<复杂结果文件路径；无则留空>
risk=<low|medium|high>
next=<建议下一步；无则留空>
ask=<需要leader确认时填写，否则留空>
```

```text
[team-summary]
decision=<团队结论>
progress=<当前阶段>
common=<团队共识>
conflict=<冲突点，如无则留空>
artifacts=<需复核文件路径列表；无则留空>
risk=<low|medium|high>
next=<下一步；如无则留空>
ask=<需要人工确认时填写，否则留空>
```

## 低上下文极简示例

### 1) 单子代理（<=8行）
```text
[dispatch]
task=独立完成当前任务
cmd=仅处理指定范围；简单直返（≤150行且≤3000字符），复杂落盘并回传artifact
cmd=遇审批立即上报；阻塞20-30分钟返回partial或blocked
context=<file_a>, <file_b>
contract=按[agent]字段回传；禁止完整推理与长日志
output_format=[agent] state/delta/evidence/artifact/risk/next/ask
```

### 2) 多子代理（<=8行）
```text
[dispatch]
task=你只负责子任务A
cmd=仅处理A范围；简单直返，复杂落盘并回传artifact
cmd=遇审批立即上报；阻塞20-30分钟返回partial或blocked
context=<scope_a_files>
contract=按[agent]字段回传；禁止输出完整日志
output_format=[agent] role/state/delta/evidence/artifact/risk/next/ask
summary_format=[summary] decision/common/conflict/artifacts/risk/next/ask
```

### 3) 代理团队（<=8行）
```text
[dispatch]
task=你是team agent，仅处理分配子任务
cmd=仅回传局部结果；简单直返，复杂落盘并回传artifact
cmd=遇审批立即上报；阻塞20-30分钟返回partial或blocked
context=<assigned_scope_files>
contract=按[team-agent]字段回传；禁止团队背景复述
output_format=[team-agent] state/delta/evidence/artifact/risk/next/ask
summary_format=[team-summary] decision/progress/common/conflict/artifacts/risk/next/ask
```

## 子代理错误上报压缩规则
- 错误超过5行 → 只保留：错误类型 + 第一条关键行 + 影响范围
- 多个同类错误 → 合并为一条，注明数量
- 原始 traceback 禁止回灌主会话，只提取 error_type + message
- 压缩后格式：error=<type>: <message>  scope=<影响范围>
