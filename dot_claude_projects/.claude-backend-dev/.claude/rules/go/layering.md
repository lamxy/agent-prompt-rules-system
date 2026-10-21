---
paths:
  - "**/apivo/**/*.go"
  - "**/api/**/*.go"
  - "**/command/**/*.go"
  - "**/service/**/*.go"
  - "**/repository/**/*.go"
  - "**/model/**/*.go"
  - "**/entity/**/*.go"
  - "**/dto/**/*.go"
---

# 分层与依赖方向

依赖只向内：`api / command → service → repository → model`，`entity` 与 `dto` 可被各层引用。

| 层 | 可以 | 不可以 |
|---|---|---|
| `api/`（handler） | 绑定与校验 `requestvo`，转换为 service 入参；把结果转换为 `responsevo`；把领域错误映射为 HTTP 状态 | 直接调用 repository 或 model；写业务规则 |
| `command/` | 解析命令行参数后调用 service | 同 `api/` |
| `service/` | 业务规则、事务边界、缓存读写、派发任务；入参与返回值用 `dto` / `entity` / 基本类型 | import `apivo`、框架包（fiber、gin、hertz）或接收 `*fiber.Ctx`、`*gin.Context`；只接收 `context.Context` |
| `repository/` | 组合 model 完成存取；把存储错误（如 `mongo.ErrNoDocuments`、`gorm.ErrRecordNotFound`）转换为领域错误（如 `ErrNotFound`） | 引用 service、api；向上暴露驱动专属的错误 |
| `model/` | 面向单一存储的访问代码（集合、表、索引） | 业务判断 |

## 类型转换

- `requestvo → dto`、`entity/dto → responsevo` 只在 `api/` 层完成；`responsevo` 中不出现 BSON、GORM 等存储类型（如 `bson.ObjectID` 对外转为字符串）。
- 不同传输层（Fiber、Gin、CLI）复用同一个 service，不为每种框架各写一份业务逻辑；只有请求绑定、响应写出、错误翻译随框架变化。

## 错误映射

领域错误集中定义（如 `transport/domain_error.go`），各传输层按同一张表映射：参数或 ID 非法 → 400，不存在 → 404，冲突 → 409，其他 → 500。

## 生成文件

`*_wire_gen.go`、`docs/swagger.*` 等生成文件不手改；修改源头（provider 定义、注解）后用项目的生成脚本重新生成。
