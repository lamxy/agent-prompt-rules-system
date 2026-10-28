# CLAUDE.md — PRD 与原型设计

<!--
维护说明（注入上下文前会被移除）：
- 只写与 Claude Code 默认行为不同的约定；工具由 settings/settings.project-prd-design.json 启用
  （document-skills、playground），PM Skills 由 open_supports/ost_phuryn_pm-skills 以项目级插件安装，
  mattpocock-skills 也在本场景 settings 启用；全局另有 gstack（本场景打开 gstack-office-hours、gstack-plan-ceo-review）。
- 文档路径是建议值，项目已有约定时改成项目自己的路径。
-->

## 产出物

- PRD 写到 `docs/prd/<功能名>.md`；需要交付 Word / PPT 时，再用 document-skills 从 Markdown 生成 docx / pptx。
- 线框图与基础原型做成单文件 HTML，放在 `docs/prototypes/`，可用 playground 生成；原型只用于演示交互，不写生产代码。

## 写 PRD 之前

需求模糊或只有一句话时，先追问（如 `/grill-me` 或 pm-skills 的 discovery 流程），确认目标用户、核心场景和成功指标后再动笔。

## PRD 必含内容

1. 背景、目标与成功指标（北极星指标及可量化的验收口径）
2. 目标用户与核心场景
3. 功能需求：按 P0 / P1 / P2 排优先级，每条附验收标准
4. 非功能需求：性能与并发预期、可用性、数据合规与隐私
5. 埋点与数据：需要采集的事件与属性
6. 发布策略：灰度、A/B 实验、回滚条件
7. 异常、空状态与边界情况
8. 待定问题：列出尚未确认的决策，不自行假设答案
