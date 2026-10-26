# 前端错误送 GlitchTip：分析报告

对应 `2026-10-22-learning-distill-questions.md` 第二节待办 4。目的：在沉淀为 rule 或 skill 之前，厘清实现复杂度、性能与安全问题，并交叉验证原评估。**本文只做分析，配置未改动**；第七节列出需要用户决定的事项。

## 一、结论

值得接，但原评估有四处要修正（第三节）。建议做法：

1. 只上报未捕获异常与未处理的 Promise rejection，关闭会话上报（GlitchTip 不处理 session，每次打开页面白发一个请求）；不启用 tracing、replay。
2. traceId 串联改为「后端生成、前端读响应头」：前端不带 `X-Request-ID`，而是从失败响应的 `X-Request-ID` 读值，作为事件 tag。原因是 Fiber 与 Gin 的 requestid 中间件都会原样采信客户端传来的值。
3. source map 用 `sentry-cli sourcemaps inject` + `upload`（debug ID，不依赖 release），上传后从发布目录删除 `.map`。
4. 防滥用只能靠反向代理限流：GlitchTip 6.2.6 的 DSN key 限流字段不生效，「停用 key」也挡不住上报，撤销 key 必须删除。
5. GlitchTip 项目开启服务端清洗（默认关闭），并在 SDK 的 `beforeSend` 中处理异常消息里的敏感值：两端的清洗都不会处理异常消息与标题中的 URL 参数。

沉淀落点：frontend-dev 新增一个 skill（接入步骤与模板），配一条很短的 path rule；dev-ops `observability.md` 与 backend-dev `fiberhouse.md` 各补几行（第六节）。

## 二、验证方法与环境

交叉验证的做法：每条结论至少有两类依据，即「原始码」加「实测」，或「原始码」加「官方文档」。

| 对象 | 版本 | 方式 |
|---|---|---|
| GlitchTip | 6.2.6（本机镜像） | 从镜像导出源码阅读；Docker all-in-one（无 Valkey）+ Postgres 17 实测 |
| Sentry JS SDK | `@sentry/browser` 11.9.0、`@sentry/cli` 3.8.2 | 读 npm 包源码；esbuild 0.28.2 打包测体积；puppeteer-core 驱动本机 Chrome 155 headless 端到端 |
| Fiber | v2.52.14（本机模块缓存；FiberHouse v1.1.1 用的是 v2.52.16，未比对差异） | 读 `middleware/requestid`、`middleware/cors` 源码 |
| gin-contrib/requestid | v1.0.6 | 读源码 |
| Sentry 官方文档 | `getsentry/sentry-docs`（context7） | DSN 公开性、`tunnel` |
| `sentry` 插件 | `getsentry/plugin-claude@73e5354` | 读 README |

端到端拓扑：测试页 `127.0.0.1:5173` → GlitchTip `localhost:8010`（跨域），模拟后端 `127.0.0.1:8020` 返回 500 与 `X-Request-ID`（`Access-Control-Expose-Headers: X-Request-ID`）。实测日期 2026-10-26。

## 三、对原评估的修正

| 原评估 | 修正 | 依据 |
|---|---|---|
| 前端请求头带 `X-Request-ID` 串联后端 | 改为后端生成、前端读响应头。前端传入的值会被后端原样采信，任何人都能伪造或撞号（不校验长度与字符） | Fiber `requestid.go`：`rid := c.Get(cfg.Header)`，为空才生成；gin-contrib `requestid.go` 同样 |
| DSN 暴露在前端需限流 | GlitchTip 6.2.6 没有可用的 key 级限流：`rate_limit_count/window` 只存储，接收路径不读取；`event_throttle_rate` 按概率随机丢弃，正常事件也会被丢；按配额自动限流只在 `BILLING_ENABLED` 时启用（自建为 False）。限流必须放在反向代理上 | 源码 `apps/event_ingest/authentication.py`、`apps/projects/models.py`；实测：key 限流 2 次 / 60 秒，连发 10 个全部 200；`event_throttle_rate=50` 时 20 个中 5 个 200 |
| （未提及）DSN 泄露后的撤销 | 在界面「停用」key 不生效，必须删除 key 并换新 DSN | 数据库函数 `get_project_auth_info` 只按 `public_key` 关联，不查 `is_active`；实测：停用后仍为 200，删除后为 403 |
| 前端 SDK 上报 GlitchTip 未验证 | 已验证：`@sentry/browser` 11.9.0 跨域上报、未捕获异常、未处理 rejection、手动 `captureException` 均成功；source map 经 debug ID 还原到原始文件与行号 | 第四节 E2E |

## 四、已验证事实

### 4.1 上报与 source map

- GlitchTip 接收端默认 `CORS_ORIGIN_ALLOW_ALL=True`，允许 `sentry-trace`、`baggage` 头（`glitchtip/settings.py`）；实测响应 `Access-Control-Allow-Origin: *`。CORS 只约束浏览器，不能防滥用：伪造 `Origin: https://evil.example` 的请求同样被接收。
- DSN 的 public key 必须是去掉连字号的 hex（GlitchTip 界面给出的即是）；带连字号的 UUID 会被 SDK 判为 `Invalid Sentry Dsn` 并停止上报（SDK 正则 `(\w+)`）。
- source map：GlitchTip 支持 sentry-cli 的 chunk upload 与 artifact bundle（`apps/files/api.py`、`apps/sourcecode/api.py`），按 debug ID 或「release + 文件名」匹配（`process_event.py`）。实测 `sentry-cli sourcemaps inject` + `upload --org --project`（不带 release）后，发布目录不放 `.map`，GlitchTip 仍把 minified 堆栈还原为 `src/cart.js:3 computeTotal`，并附带源码上下文行。
- 上传 source map 需要 GlitchTip API token（`project:releases` 等权限），只能放在 CI 的 secret 中，不能进前端代码。

### 4.2 性能

浏览器端（esbuild minify，gzip -9，只计 SDK 与初始化代码）：

| 组合 | gzip | 说明 |
|---|---|---|
| `Sentry.init` 默认集成 | 31 KB | 含面包屑、控制台、会话等 |
| `BrowserClient` 手动挑选 3 个集成 | 22 KB | `globalHandlers`、`linkedErrors`、`dedupe` |
| + `browserTracingIntegration` | 55 KB | |
| + `replayIntegration` | 76 KB | GlitchTip 不处理 replay |

- 默认集成包含 `browserSessionIntegration`：实测每次打开页面（无错误）都发一个 `session` envelope。GlitchTip 6.2.6 只处理 `event`、`transaction`、`feedback`/`user_report`、`log`（`apps/event_ingest/views.py`），session 收下后不处理，等于每次页面浏览多一个跨域请求。按名称过滤掉 `BrowserSession` 后实测为 0 个。
- `sentry-trace`/`baggage` 头只在启用 `browserTracingIntegration` 时附加，且默认只发往同源请求（`tracing/request.js` 的 `shouldAttachHeaders`）。跨域时要显式配置 `tracePropagationTargets`，后端 CORS 也要放行这两个头。FiberHouse 走的是 `sentryzerolog`，不读取 `sentry-trace`，所以现阶段 tracing 无法串联前后端，只增加体积与预检请求。
- 服务端：GlitchTip all-in-one（容器不限额）20 并发写入 3000 个合成事件，约 480 个/秒全部 200 并即时入库，GlitchTip 进程约 194 MiB、Postgres 约 144 MiB，事件表约 1 KB/个（合成事件很小；真实浏览器事件带面包屑，体积未测）。结论：被刷时先出问题的是磁盘占用与 issue 噪音，不是进程；限流与保留期（`GLITCHTIP_RETENTION_DAYS`）是主要控制手段。

### 4.3 安全

- DSN 可以公开：只能提交事件、不能读取（Sentry 官方 DSN 说明）。风险在于任何人都能伪造事件。
- 清洗，实测（project `scrub_config={"enabled": true}`）：
  - 默认关闭：`GLITCHTIP_PII_SCRUB_DEFAULT` 默认 `{}`，`extra.password=hunter2` 与卡号原样入库。
  - 开启后按 key 过滤（`password` 等）与按值过滤（Luhn 校验的卡号）生效，结果为 `[Filtered]`。
  - **异常消息与事件标题中的 `token=secret123` 不会被过滤**，两端都不处理。
  - SDK 端：面包屑中 fetch URL 的 `token` 参数被过滤为 `[Filtered]`（`@sentry/core` `filtering-snippets.js` 的关键字表）。
- source map 不对外：发布目录的 `.map` 会暴露源码，上传后删除。实测删除后还原不受影响。
- 后端 requestid：Fiber 与 Gin 中间件都原样采信请求头。前端若主动传值，后端需要先校验（如只接受 UUID），再交给中间件。本报告推荐的「后端生成、前端读响应头」方案不需要信任前端传来的值，但已有的中间件仍会采信攻击者直接带的头，校验要不要做是独立的决定（第七节）。
- CORS：Fiber `cors` 中间件在 `AllowHeaders` 为空时回显请求的 `Access-Control-Request-Headers`（`cors.go`），`ExposeHeaders` 默认为空。前后端跨域时，前端要读 `X-Request-ID`，后端需设置 `ExposeHeaders: "X-Request-ID"`；同源（同一域名经反向代理）时不需要。

### 4.4 `sentry` 插件

`getsentry/plugin-claude` 包含 Sentry SDK 安装向导 skills，以及托管的 Sentry MCP（`mcp.sentry.dev`）。该 MCP 连不上自建 GlitchTip（与 backend-dev 当初移除它的理由相同）。向导 skills 的内容未读，是否会引导启用 GlitchTip 不处理的 replay、session 未验证。建议 frontend-dev 与 fullstack-dev 也改为 GlitchTip MCP。

## 五、方案设计（供审核，尚未实施）

### 5.1 前端初始化（已实测的最小形态）

```js
import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,           // 为空时 SDK 不上报
  release: __APP_VERSION__,
  environment: import.meta.env.MODE,
  sampleRate: 1.0,                                // 起步阶段访问量小；量大后下调
  integrations: (defaults) => defaults.filter((i) => i.name !== "BrowserSession"),
});
```

实测过的部分：`dsn` 字面值、`release`、`environment`、`sampleRate`，以及过滤 `BrowserSession`。`import.meta.env`、`__APP_VERSION__` 属于构建工具注入，未实测。噪音过滤（`ignoreErrors`、`denyUrls`，例如浏览器扩展的 `chrome-extension://`）与 `beforeSend` 中对消息的脱敏，在实施时按项目补充，并逐条实测。

### 5.2 API 失败与 traceId

```js
export class ApiError extends Error {
  constructor(status, requestId, url) {
    super(`API ${status} ${new URL(url, location.href).pathname}`);  // 消息不带查询参数
    this.name = "ApiError";
    this.status = status;
    this.requestId = requestId;
  }
}
// 只在需要上报时：Sentry.withScope((s) => { s.setTag("request_id", e.requestId); Sentry.captureException(e); });
```

实测：跨域响应头经 `Expose-Headers` 读到 `request_id` 并成为 tag，可在后端 GlitchTip 项目中按同一个 traceId 搜索。是否上报 API 失败需要定一个范围：5xx 已由后端上报，前端再报一次就是重复；建议前端只在「后端没有记录」的情况上报，即网络中断、超时、网关返回的 502/504。该判定规则未实测。

### 5.3 构建与发布（CI）

```sh
npx sentry-cli sourcemaps inject dist
SENTRY_AUTH_TOKEN=*** npx sentry-cli --url "$GLITCHTIP_URL" sourcemaps upload --org <org> --project <frontend-project> dist
find dist -name '*.map' -delete
```

以 esbuild 产物实测通过。Vite、webpack 的产物与官方 bundler 插件（`@sentry/vite-plugin` 等）未测；sentry-cli 只处理构建后的文件，理论上与构建工具无关（未验证）。

### 5.4 部署（dev-ops）

- 为前端单独建 GlitchTip project，告警与后端分开（原评估，维持）。
- 反向代理只对外开放接收路径 `/api/<project_id>/envelope/`（以及旧版 `store/`）。管理界面维持只绑 127.0.0.1。
- 反向代理按 IP 限流，并限制请求体大小（GlitchTip 解压后上限 `GLITCHTIP_MAX_UNZIPPED_PAYLOAD_SIZE` 默认 5 MB）。具体 nginx / Caddy 配置未验证。
- 前端项目设置 `scrub_config.enabled=true`，或用 `GLITCHTIP_PII_SCRUB_DEFAULT='{"enabled": true}'` 全局开启。
- DSN 泄露被刷时：新建 key → 发布前端 → **删除**旧 key（停用无效）。
- 页面有 CSP 时，`connect-src` 要包含 GlitchTip 域名（Web 标准要求，未实测）。

### 5.5 实现复杂度

| 部分 | 工作量 | 风险 |
|---|---|---|
| 前端初始化 + `ApiError` | 约 30 行 | 低 |
| CI 上传 source map | 3 条命令 + 1 个 secret | 中：token 权限范围、上传失败时是否阻塞发布 |
| 后端 `ExposeHeaders`（仅跨域时） | 1 行配置 | 低 |
| 后端 requestid 校验（可选） | 约 10 行中间件 | 低（未实测） |
| 反向代理限流与路径白名单 | 一段配置 | 中（未实测） |
| 广告拦截绕过 `tunnel`（可选） | 后端转发端点，需校验 DSN 的 host 与 project，否则成为开放代理（Sentry 文档提到 DSN allowlist） | 中，未实测；起步阶段不建议 |

## 六、沉淀建议

| 内容 | 层级 | 理由 |
|---|---|---|
| 接入步骤、5.1～5.3 模板、噪音过滤、`ApiError`、验证清单 | frontend-dev skill（如 `frontend-error-tracking`，含 `references/`） | 只在接入或调整错误追踪时需要，不应常驻上下文 |
| 几条硬约束：不启用 replay、session；不在错误消息中拼接查询参数与 token；DSN 由环境变量注入；`.map` 不发布 | frontend-dev path rule（作用于 Sentry 初始化与 API 客户端文件）或写进 skill | 写代码时需要，但量很少；path 写法要按项目目录调整 |
| 5.4 部署要点 | dev-ops `middleware-ops/references/observability.md`「错误追踪」节补充 | 与现有 GlitchTip 部署说明同处 |
| `ExposeHeaders`、requestid 校验 | backend-dev `rules/framework/fiberhouse.md` 请求 id 一条后补充 | 属于后端边界 |
| `sentry` 插件 → GlitchTip MCP | `settings.project-frontend-dev.json`、`settings.project-fullstack-dev.json`、`dot-mcp-json-frontend-dev.json`、`settings/README.md` | 与 backend-dev 一致 |

只写已验证的内容；第八节的未验证项实施前先测，否则只记在疑问文件中（遵循「配置中的未验证内容」决定）。

## 七、需要用户决定

1. 是否按第一节的建议接入；沉淀为「skill + 短 rule」，还是只用 skill。
2. traceId：是否采用「后端生成、前端读响应头」，放弃原评估的「前端带 `X-Request-ID`」。
3. 后端 requestid 是否加校验（例如只接受 UUID，否则重新生成）。这一项与前端无关，攻击者直接调用 API 时同样存在。
4. 前端是否上报 API 失败，以及范围（建议只报网络中断、超时、502/504）。
5. 是否把 frontend-dev、fullstack-dev 的 `sentry` 插件换成 GlitchTip MCP。
6. 停用 key 无效、key 限流不生效这两个问题，是否向 GlitchTip 上游报告（gitlab.com/glitchtip）。属于对外操作，需你确认。

## 八、未验证边界

- Vite / webpack 产物与官方 bundler 插件上传 source map；hidden source map 的构建配置。
- 广告拦截对 GlitchTip 域名的拦截率，以及 `tunnel`。
- 真实浏览器事件的大小、GlitchTip 在 512 MB 限额下的吞吐。
- 反向代理限流配置、CSP、`ignoreErrors`/`denyUrls` 的具体取值。
- `sentry` 插件向导 skills 的内容。
- Fiber v2.52.16 与 v2.52.14 的 requestid、cors 是否有差异（v2.52.14 已读源码）。
- 其他前端框架的 SDK（`@sentry/vue`、`@sentry/react`）：只测了 `@sentry/browser`，框架 SDK 基于它封装，但未实测。

## 九、本机残留

测试容器以 `--rm` 启动，停止即删除；`docker stop` 与 `docker network rm` 被权限拒绝，需要手动清理：

```sh
docker stop fegt-gt fegt-pg; docker network rm fegt-net
```

测试代码、npm 包与 GlitchTip 源码在会话 scratchpad，随会话清理。
