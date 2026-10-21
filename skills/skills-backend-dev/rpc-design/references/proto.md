# Protobuf 兼容性与 buf 检查

实测环境：buf 1.74.0，`buf.yaml` v2；规则依据 protobuf 官方「Updating A Message Type」与 JSON 映射规范。

## 为什么字段号是契约

wire 上每个字段只编码「字段号 + wire type + 值」，不编码字段名。接收方按字段号解析：

- 复用已删除的字段号：老客户端按旧类型解析新数据，静默得到错误值。
- proto3 不编码零值（`0`、`""`、`false`、枚举 0 值）：「传了零值」与「没传」在 wire 上完全相同，服务端无法区分。`optional` 生成指针（底层是单成员 `oneof`），可以区分；message 类型字段本身可用 `nil` 区分。

## 改动兼容性表

| 改动 | wire | JSON / 生成代码 | buf `WIRE` | buf `WIRE_JSON` | buf `FILE` |
|---|---|---|---|---|---|
| 新增字段（新号） | 兼容 | 兼容 | 通过 | 通过 | 通过 |
| 枚举新增值 | 兼容（Go 保留未知数值） | 兼容 | 通过 | 通过 | 通过 |
| 改字段名 | 兼容 | **破坏**（JSON 键名、Go 字段名都变） | 通过 | 报错 | 报错 |
| `int32` ↔ `int64` | 兼容，但窄类型一方读超范围值会静默截断 | JSON 中 64 位整数是字符串 | 通过（两个方向都不拦） | 报错 | 报错 |
| `int32` ↔ `sint32` | **静默错值**（同为 varint，编码不同） | — | 报错 | 报错 | 报错 |
| 删除号复用为其他类型 | **静默错值或解析失败** | — | 报错 | 报错 | 报错 |
| 字段移入 / 移出 `oneof` | 可能丢值（官方文档：只有单个字段移入新 `oneof` 安全） | 生成代码变化 | 报错 | 报错 | 报错 |
| 单个 ↔ `repeated` | 部分兼容（数值标量的 packed 编码不兼容） | **破坏**（JSON 变数组） | 报错 | 报错 | 报错 |
| 删字段且未 `reserved` | 留下复用隐患 | — | 报错 | 报错 | 报错 |
| 删字段并 `reserved` 号与名 | 兼容 | 兼容 | 通过 | 通过 | **仍报错** |

`string` → `bytes` 在 wire 上兼容，反向不一定（`string` 要求合法 UTF-8）；一般不做这类修改，加新字段代替。

## buf 检查类别怎么选

- `FILE`（buf 默认）：最严，生成代码层面也不能破坏；连「删除并 reserved」也报错，只能先 `[deprecated = true]` 保留字段。
- `WIRE_JSON`：保证 wire 与 JSON 兼容，允许 reserved 后删除；有 JSON 转码（网关、protojson）时的最低要求。
- `WIRE`：只保证二进制兼容，不拦改名；只在确定没有 JSON 用途时考虑。

项目已有 `buf.yaml` 时以项目配置为准。

`buf lint` 的 `STANDARD` 规则会拦：package 没有版本后缀、服务名不以 `Service` 结尾、请求与响应复用同一 message 或使用 `Empty`、请求／响应名不是 `<方法>Request` / `<方法>Response`、枚举值没有前缀、零值不是 `_UNSPECIFIED`、字段名不是 `lower_snake_case`（均已实测）。

```sh
buf lint
buf breaking --against '.git#branch=main'
```

## 标量类型怎么选

| 数据 | 类型 | 原因 |
|---|---|---|
| ID、数量、时间戳等非负整数 | `int64` / `int32` | varint，小值占用少 |
| 经常为负的数 | `sint64` / `sint32` | `int64` 的 -1 占 10 字节，zigzag 只占 1 字节 |
| 哈希、随机 64 位 ID | `fixed64` | 大值的 varint 需 9～10 字节 |

只在高频调用或大 `repeated` 列表中值得为体积斟酌；已上线的字段不为此改类型。

## well-known types

| 用途 | 类型 | Go |
|---|---|---|
| 时间点 | `google.protobuf.Timestamp` | `timestamppb.New(t)` / `.AsTime()` |
| 时长 | `google.protobuf.Duration` | `durationpb.New(d)` / `.AsDuration()` |
| 部分更新 | `google.protobuf.FieldMask` | `fieldmaskpb` |
| 可空标量（旧代码） | `google.protobuf.*Value` | `wrapperspb`；新代码优先 `optional` |
