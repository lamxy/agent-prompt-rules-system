# Loop Report Template

用于周期性任务、`/loop`、cron、后台巡检等场景。

```text
[loop] id=<run_id>
state=<success|partial|failed|blocked>
delta=<本轮新增变化，尽量短>
evidence=<关键证据，尽量短>
risk=<low|medium|high>
next=<下一步动作>
ask=<需要确认时填写，否则留空>
```

## 使用规则
- 尽量控制在 5 行以内。
- 无新增变化时，delta 只写“无变化”或“保持成功”。
- 阻塞时必须使用 `blocked`。
- ask 仅在需要主线确认时填写，且只问一个最小问题。
