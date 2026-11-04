# 分层规则严格度调研（B-9）

日期：2026-11-04　关联：`docs/evaluation/2026-10-final.md` 4.1 B-9；计划文件「需要用户决定」；规则 `dot_claude_projects/.claude-backend-dev/.claude/rules/go/layering.md`

状态：调研完成；**用户 2026-11-04 选方案 C**（默认 B，满足条件升 A），改动见第 6 节。

## 1. 起因与现状

`rules/go/layering.md` 规定 `service` 不可 import `apivo`，`requestvo → dto`、`entity/dto → responsevo` 只在 `api/` 层完成。阶段 3 B4 中 Claude 指出 FiberHouse 示例违反此条。2026-11-04 核对本机 FiberHouse（`~/workspace/github_repos/fiberhouse`，HEAD `2133a88`）：

| 位置 | 现状 | 框架自述 |
|---|---|---|
| `example-module/service/example_service.go` | `Create`、`Get`、`List`、`Update` 入参 `requestvo`、返回 `responsevo` | 包注释：service「依赖 repository（以及与调用方交换的 entity/apivo 类型）」——有意为之 |
| `example-module/repository/example_repository.go:228` | `CreateExample` 接收 `requestvo.ExampleReqVo` | 注释：「在传输层于下一个切片迁移完成之前，临时支撑旧的演示服务」，只被 `test_service.go` 调用——临时兼容 |
| `example_application/apivo/` | 顶层共享包，结构只带 `json`、`validate` 标签，不 import 框架；Fiber 与 Gin 适配器共用 | README：「严格分层」指依赖方向 `transport → service → repository → model` |

即 FiberHouse 的「严格」只管依赖方向，把 `apivo` 当作与框架无关的共享契约包；本仓库规则额外要求 VO 不进 service。

## 2. 来源核对

均读原文。等级：A 官方／规范／原作者，B 大厂或大型项目实践，C 实践者经验。

| 来源 | 级 | 原文结论 | 对 B-9 的含义 |
|---|---|---|---|
| Go 官方《Organizing a Go module》 | A | 只讲 `internal/`、`cmd/` 与包划分；服务端「结构差异很大」，未规定分层或层间类型 | 官方无立场 |
| Google Go Style Guide · Best Practices「Package size」与错误处理 | A | 按耦合度决定包的分合；在 RPC、IPC、存储等系统边界把领域错误转为规范错误空间；无层间类型规定 | 支持现规则的「错误映射」，对 VO 无立场 |
| Uber Go Style Guide | A | 唯一相关：业务逻辑放在与 `package main` 不同的抽象层 | 无立场 |
| Robert C. Martin〈The Clean Architecture〉(2012) | A | 内圈代码不得提及外圈声明的任何名称；外圈的数据格式（尤其框架生成的）不得被内圈使用；跨边界数据「总是采用对内圈最方便的形式」 | 按字面，service 用 `apivo`（外层声明）违规；但允许「结构由 service 定义、api 层直接使用」 |
| Alistair Cockburn〈Hexagonal Architecture〉 | A | 端口的协议是应用定义的 API，适配器把外部信号转换为该 API | 同上：类型由内层定义，转换在适配器 |
| Martin Fowler〈LocalDTO〉(2004) | A | DTO 为远程调用而生，本地使用有害；反对为隔离 service 客户端与领域模型而在 Service Layer 用 DTO（引 Randy Stafford：映射成本「仅次于 ORM」）；建议 service 签名用领域对象，远程边界才加 Facade；表现层与领域模型显著不一致时才值得做专用映射 | 支持宽松：HTTP 层（远程边界）转换已足够，service 与 repository 之间再加 dto 属额外成本 |
| 阿里巴巴 Java 开发手册（`alibaba/p3c` gitbook「应用分层」）**【来源：中国大陆】** | A（开源文档） | 应用分层为【推荐】，开放接口层可直接依赖 Service；「分层领域模型规约」为【参考】（最弱一级），只定义 DO／DTO／BO／AO／VO／Query 含义，不禁止跨层 | 常被引用为「严格分层」依据，原文强度其实是参考；gitbook 版本较旧，新版（黄山版 PDF）是否改动**未验证** |
| Kubernetes《API changes》 | B | 内部表示与任一 API 版本解耦，以内部形式为中心互转；需要「robust infrastructure」（代码生成）支撑 | 严格分离的前提是同时维护多个对外版本，且有生成工具 |
| Google AIP-131 | B | 每个方法有自己的 `XxxRequest`；Get 直接返回资源本身 | 只规定对外 API 形状，不涉及内部分层 |
| Microsoft《Common web application architectures》 | B | ViewModel 属 UI 层；service 需要的非 entity 类型在 Application Core（内层）定义为简单 DTO；简单应用可用单项目 | 类型由内层定义；承认规模分级 |
| go-kratos `kratos-layout` 的 `AGENTS.md` **【来源：中国大陆】** | B（开源框架） | DTO（proto）只在其 service 层（相当于本仓库 `api/`）；biz 只用 DO，「反向 import 是分层 bug」；PO 只在存储形状与 DO 不同时才定义 | Go 社区里明确的严格派；但存储侧按需建模 |
| Three Dots Labs〈Common Anti-Patterns in Go Web Applications〉(2021-08-12) | C | 「单一模型」是反模式；HTTP、存储、应用模型分开，手写映射或生成；同一 API 四种实现：紧耦合 292 行、松耦合手写 345、松耦合生成 298、带应用层 408（另 2154 行生成） | 支持分离，并给出成本量级；文中未给可例外的条件 |
| Russ Cox，`golang-standards/project-layout` #117 (2021-04) | C（Go 核心成员个人意见） | 该仓库不是 Go 标准，Go 仓库通常简单得多 | 警惕照搬复杂目录；不涉及层间类型 |
| Hacker News 评论（#40632508、#47584170） | C | 「不需要时就别做 DTO……大多数简单应用一层就够」（C#）；「少一点仪式，多一点责任」 | 零散个人经验，只作参考 |

未做：Reddit（暂时移除，见交接文件用户约束）。

## 3. 五个问题的回答

**Q1 收益与代价**

| | 严格（VO 只在 api 层） | 宽松（service 用共享契约类型） |
|---|---|---|
| 收益 | API 改字段不波及 service；service 可被非 HTTP 调用方复用而不带 HTTP 形状；内层不受外部契约变化影响（Clean、kratos、K8s） | 少一层映射与对应测试；新增字段只改一处；Fowler 所说映射成本消失 |
| 代价 | 每个资源多一组转换函数（Three Dots 例中约 +18%，有应用层时 +40%）；转换遗漏字段是常见 bug 来源 | API 契约与 service 签名绑定；表现层与业务形状分歧时被迫加 hack（Three Dots 的「单一模型」问题） |
| 适用 | 多版本对外 API、多种传输层形状不同、表现层与领域差异大 | 单版本 API、传输层共享同一契约（如 FiberHouse 的 Fiber／Gin 共用 `apivo`）、CRUD 为主 |

**Q2 规范与大厂怎么规定**：官方（Go、Google、Uber）都没有规定。原作者里，Clean／Hexagonal 要求类型由内层定义，Fowler 反对 service 层内部再做 DTO。明确禁止的只有 kratos（大陆开源框架）和 Kubernetes（多版本前提）。阿里手册的强度是【参考】。没有任何一手来源把「service 不得使用 API 层类型」列为普适硬规则。

**Q3 硬约束、建议还是分级**：来源都支持「依赖方向」作硬约束（Clean 的依赖规则、kratos、Microsoft 都一致，也最容易机械检查）。至于「类型由哪层定义」，各来源分歧明显，并且都和规模、API 版本数挂钩，适合作默认规则加例外条件，不适合用 depguard 一刀切。

**Q4 框架与规则谁跟谁**：规则所在场景包要求「以 FiberHouse `example_application/` 为准」（`go-new-module` 照它生成模块）。规则和示例冲突时，每个照示例写的新模块都会被判违规，B1、B4 的判定口径也会因此摇摆。FiberHouse 是用户自己的框架，两条路都走得通：改示例，或者改规则。这要看 Q1 选择哪种取舍，没有来源能替你决定。

**Q5 repository 接收 requestvo**：没有任何来源支持。Clean、Hexagonal、kratos、Three Dots 都明确反对；就连主张宽松的 Fowler，也只让 service 签名用领域对象，并没有让表现层对象进入数据层。FiberHouse 自己的注释也把它标为临时兼容。无论选哪个方案，这一条都应继续禁止。

## 4. 方案

| 方案 | 规则内容 | depguard | FiberHouse | 代价 |
|---|---|---|---|---|
| A 维持严格 | 现规则不变 | 加 `service` 禁 `apivo` | 示例 service 不合规；要一致就得改 FiberHouse 示例（另一仓库、要发版） | 每资源一组转换；规则与框架示例长期冲突，直到框架改 |
| B 共享契约放宽 | `service` 可以接收／返回**与框架无关的共享契约包**（如 `apivo`）的类型，条件：该包不 import 框架与存储驱动、不带存储标签；`repository`、`model` 一律不得 import `apivo`；表现层形状与业务不一致时，在 `api/` 转换 | `repository`、`model` 禁 `apivo`；`service` 继续禁框架包与 `go-redis` | 与示例 service 一致；`repository` 的临时兼容仍算违规 | 按 Clean 字面仍属违规（契约包由外层声明）；API 契约变化会波及 service |
| C 分级 | 默认 B；满足任一条件时改用 A：对外 API 同时维护多个版本、多种传输层需要不同形状、对外公开 SDK／第三方调用；切换写进 ADR | 同 B，升级后加 A 的规则 | 同 B | 规则多一段判断；升级时机靠人判断 |

## 5. 建议

建议 **C**（默认 B，满足条件时升到 A）。理由：

1. 一手来源一致认可的硬约束只有「依赖方向」和「不让框架、存储类型进入内层」。B 保住了这两条，FiberHouse 的 `apivo` 也满足（只带 `json`、`validate` 标签，不 import 框架）。
2. 严格分离的大型实践（Kubernetes、kratos）都有明确前提：多个对外版本，或靠 proto 生成契约。本仓库的场景（单版本 REST、Fiber 和 Gin 共用一份契约）不满足这些前提；硬套严格分离，付出的成本得不到对应收益（Fowler、Three Dots 的行数对比）。
3. 规则和框架示例保持一致，新模块就不会一生成就违规，B1、B4 的判定口径也能稳定下来。
4. repository 不得接收 VO 这一条继续是硬约束，并改由 depguard 机械检查。现在规则里只写了「不可引用 service、api」，没有点名 `apivo`。

需要明说的代价：C 按 Clean Architecture 的字面仍属违规；如果你更看重和 Clean／kratos 一致，应该选 A，同时排期修改 FiberHouse 示例。

## 6. 决定后的改动范围（未做）

- `rules/go/layering.md`：`service` 一行的「不可以」、「类型转换」一节、`repository` 一行补「不得 import `apivo`」。只在场景包 `dot_claude_projects/.claude-backend-dev/.claude/rules/go/` 一份。
- `go-new-module` 的 `references/depguard.yml`：按方案加规则；skill 两份（`skills/skills-backend-dev/` 与场景包）同步。
- `docs/evaluation/2026-10-final.md` 与基线的 B1、B4 观察点：按新口径补注。
- 方案 A 另需：FiberHouse 示例改为 service 用 dto，并在 FiberHouse 仓库发版（英文提交）。
- 不论哪个方案：建议 FiberHouse 移除 `repository.CreateExample` 的临时兼容（另一仓库，由用户决定时机）。

## 7. 验证边界

- 已验证：上表各来源的原文内容；FiberHouse 当前代码与注释。
- 未验证：阿里手册新版（黄山版）是否修改了分层模型条款；各方案在真实项目中的维护成本（只有 Three Dots 一例的行数）；depguard 对「只禁 repository、model import `apivo`」的写法（改动时实测 golangci-lint）。
