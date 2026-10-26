# Elasticsearch 运维

应用侧的使用规范见 backend-dev 场景的 `.claude/rules/database/elasticsearch.md`。参数名以所用版本的文档为准。

## 系统

- JVM 堆不超过 32GB，大堆使用 G1 GC（技术规范）；同时不超过内存的一半（容器内按容器可见内存），且低于压缩指针阈值（官方：26GB 在多数系统安全，部分系统可到 30GB；日志中 `compressed ordinary object pointers [true]` 确认）。
- 关闭 swap（或 `bootstrap.memory_lock: true`）。
- 文件句柄数与 `vm.max_map_count` 设为 655360（技术规范，默认值，项目可调整）；官方 bootstrap check 下限分别为 65535、262144（`vm.max_map_count` 官方推荐 1048576）；线程数（nproc）不少于 4096（官方 bootstrap check）。
- 磁盘使用率保持在 85% 以下（低水位线默认即为 85%）。

## 集群拓扑

- 3 个专用 master 节点，不承担数据；数据节点数量按容量计算。
- 集群规模大、聚合查询多时，增加专用协调（coordinating）节点。
- 线程池大小以 CPU 核数为准，不随意调大。

## 分片与索引

- 单个分片 20GB～40GB，不超过 50GB。
- 副本数默认 1；可以重建的数据可设为 0。首次全量导入时副本数设为 0，完成后恢复。
- 时间序列数据按日期建索引，配合 ILM 管理滚动与删除。
- 写入量大时调大 `index.refresh_interval`（默认 1s，可调到 20～60s，代价是新数据可见延迟增加）与 `index.translog.flush_threshold_size`，减少刷新与 flush 次数。
- 设置 `indices.fielddata.cache.size`（如 10%），避免 fielddata 占满堆导致 GC 或 OOM。
- 节点恢复较慢时调大 `indices.recovery.max_bytes_per_sec`（如 500mb），按磁盘与网络能力设置。
- 定期对只读的旧索引执行 force merge，减少 segment 数量。

## 安全

- 9200（HTTP）只对集群内部与指定业务开放，**绝不暴露到公网**；9300（节点通信）只对集群内部开放。
- 开启认证与 TLS。
