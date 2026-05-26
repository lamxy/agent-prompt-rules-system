# 周期性任务（loop/cron）极简规约

适用于 `loop`、`/loop`、cron、定时、周期执行、后台巡检、向主线持续上报等任务。

规则：
- 只传变化，不传全史。
- 主线只保留状态、摘要、风险、下一步。
- 详细日志、diff、堆栈外置，不写主线。
- 无变化时不扩写。
- 仅在成功、失败、阻塞、需要确认时上报。
- 需要确认时，只问一个最小问题。
- 上报尽量短、结构化、可扫描。

推荐格式：
[loop] id=<run_id>
state=<success|partial|failed|blocked>
delta=<本轮新增变化>
evidence=<关键证据>
risk=<low|medium|high>
next=<下一步，如没有留空>
ask=<需要确认时填写，否则留空>
