---
paths:
  - "**/es/**/*.go"
  - "**/elasticsearch/**"
  - "**/search/**/*.go"
  - "**/mappings/**"
---

# Elasticsearch

应用侧约定；集群部署与调优属于 `dev-ops` 场景（`middleware-ops` skill）。不用 Elasticsearch 的项目删除本文件。

## 索引与 mapping

- 索引名小写，不以 `-`、`_`、`+` 开头，不含空格、逗号、冒号、`#`、`\ / * ? " < > |`，不超过 255 字节。
- 时间序列数据按日期建索引（如 `app-log-2026.10.21`），配合别名与生命周期管理。
- 显式定义 mapping 并设 `"dynamic": "strict"`，不依赖自动类型推断；新增字段先改 mapping。
- 只做精确匹配、聚合、排序的字段用 `keyword`；需要全文检索的才用 `text`。
- 不用 `nested` 类型；数组内对象需要独立查询时，改为拆成独立文档或扁平化字段。
- 写入前去掉空字段。

## 查询

- 不需要相关度评分的条件放在 `bool.filter`，不放在 `must`。
- 不用 `wildcard` 与前导通配符查询；需要模糊匹配时在 mapping 中用 n-gram 等分词处理。
- `from + size` 不超过 5000；深分页用 `search_after`，导出类遍历用 point in time（PIT）或 `scroll`，每批不超过 500 条。
- 批量写入用 Bulk API；首次全量导入时副本数先设为 0，导入后再恢复。

## 客户端

- 一个进程共享一个客户端；在 `http.Transport` 上设置 `MaxIdleConnsPerHost`、`ResponseHeaderTimeout`，每个请求通过 `context` 设超时，不使用无限超时。
