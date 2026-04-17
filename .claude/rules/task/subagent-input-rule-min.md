# 子代理输入极简规约

适用于 subagent-driven-development 场景下派发实现/审查子代理。

## 输入构造规则

实现子代理只传：
1. 当前 Task 的完整文本（从计划文档中提取的单个 Task）
2. 已完成文件列表（`已完成: cache/_entry.py, cache/_key.py` 等）
3. 工作目录

**不传：**
- 整份计划文档
- 其他 Task 的文本
- 会话历史

## 审查子代理只传：

1. Spec 要求（对应 Task 的设计约束，3-7 条）
2. 审查范围（文件路径列表）
3. 输出格式要求

## 模型选择

| 子代理类型 | 默认模型 | 升级条件 |
|-----------|---------|---------|
| 实现（1-2 文件，有完整 spec） | Haiku | BLOCKED 或文件 >3 个 |
| Spec 审查 | Haiku | 无需升级 |
| 代码质量审查 | Haiku | 发现 NEEDS_FIXES 时修复用 Sonnet |
| 修复子代理 | Sonnet | — |

## 输出格式（实现子代理）

```
STATUS: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
TESTS: X/X passed
COMMITTED: <SHA>
CONCERNS: <如无则留空>
```

不超过 10 行，不输出完整推理过程。
