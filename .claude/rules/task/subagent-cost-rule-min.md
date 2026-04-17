# 子代理成本控制极简规约

适用于任何派发子代理（实现、审查、修复）的场景。

## 输入构造规则

- 只传当前任务文本 + 依赖文件列表，不传整份文档/计划/历史
- 审查子代理：只传 spec 要求（3-7 条）+ 文件路径，不传实现细节
- 不在子代理之间传递完整上下文或其他子代理的原始输出

## 模型选择

| 子代理类型 | 默认模型 | 升级条件 |
|-----------|---------|---------|
| 实现（1-2 文件，有明确 spec） | Haiku | BLOCKED 或涉及文件 >3 个 |
| Spec / 合规审查 | Haiku | 无需升级 |
| 代码质量审查 | Haiku | 发现 NEEDS_FIXES 时修复子代理用 Sonnet |
| 修复 / 架构判断 | Sonnet | — |

## 输出格式

实现子代理返回（不超过 10 行）：
```
STATUS: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
TESTS: X/X passed
COMMITTED: <SHA>
CONCERNS: <如无则留空>
```

审查子代理返回（不超过 5 行）：
```
RESULT: COMPLIANT/APPROVED | NON_COMPLIANT/NEEDS_FIXES
MISSING/ISSUES: <问题描述，如无则留空>
```

## 避免
- 子代理接收整份计划文档作为输入
- Sonnet 处理结构化对照类审查任务
- 子代理输出完整推理过程或原始日志
