# CLAUDE.md — 前端开发

<!--
维护说明（注入上下文前会被移除）：
- 只写与 Claude Code 默认行为不同的约定；工具由 settings/settings.project-frontend-dev.json 启用
  （typescript-native-lsp、frontend-design、playwright、chrome-devtools-mcp 等）。
- 项目已有设计系统、API 契约路径或测试命令时，改成项目自己的约定。
-->

## 对接后端 API

- 以 API 契约（OpenAPI / Swagger 或后端提供的接口文档）为准；契约缺失或与实现不一致时先指出并询问，不臆造字段、状态码或错误格式。
- 请求统一处理加载中、空数据、错误、超时与重复提交。
- 请求失败时从响应头 `X-Request-ID` 取请求 id 并在错误提示中显示，便于查服务端日志；前端不生成、不发送该头。

## UI 实现

- 优先使用项目的设计系统组件与 design token，不硬编码颜色、间距、字号。
- 有设计稿时先对照设计稿实现，偏离处说明原因。

## 完成前在浏览器验证

声称 UI 完成前，用 Playwright 或 Chrome DevTools 实际打开页面：

- 控制台无报错，关键请求成功
- 检查 375px、768px、1280px 三种宽度的布局
- 键盘可操作、表单有 label、图片有 alt

## 依赖

新增第三方依赖前先说明用途与体积影响，得到确认后再安装。
