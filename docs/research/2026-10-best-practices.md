# 阶段 2 调研：现状汇总与最佳实践

## 1. 四场景现状汇总（2026-11-03，Claude Code 2.1.316）

来源：各场景 `claude --debug` 会话的 `skill_listing` 与 debug log；自定义 agent 数取基线 T1 表；`.mcp.json` 与 `settings.json` 取测验项目实际文件。插件自带的 MCP 不在下表。

| 场景 | Skill 数 | 清单字符（去 description 前 → 后，预算 30000） | 只列名称 | 自定义 agent | `.mcp.json` |
|---|---|---|---|---|---|
| prd-design | 154 | 39312 → 29.6k，**超预算** | 37 | 7 | 无 |
| frontend-dev | 147 | 27.5k | 0 | 47 | 无 |
| backend-dev | 114 | 32978 → 28.8k，**超预算** | 13 | 13 | mysql、postgres、glitchtip、codegraph |
| dev-ops | 72 | 18.2k | 0 | 12 | glitchtip |

四个场景共有 62 个相同 skill（全局插件、个人 skill 与内置）。

### 各场景占用最大的来源（去 description 后的字符数）

| 场景 | 主要来源 |
|---|---|
| prd-design | pm-skills 5 个插件共 73 项、7.8k（其中 36 项只列名称）；document-skills 3.0k；mattpocock-skills 2.5k |
| frontend-dev | gsd-core 77 项（与内置等合计 13.7k）；sentry 2.9k；modern-web-guidance 1.9k |
| backend-dev | mongodb 4.4k；redis-development 4.0k；mattpocock-skills 11 项（9 项只列名称） |
| dev-ops | semgrep 1.3k；sonatype-guide 0.7k；gstack 4 项 |
| 全局（四场景都有） | superpowers 2.8k；chrome-devtools-mcp 2.1k |

### 功能可能重叠（按名称与 description 归类，未读正文，未验证）

| 功能 | 同时存在的项 | 场景 |
|---|---|---|
| 代码审查 | 内置 `code-review`、`open-code-review`、`pr-review-toolkit`、`mattpocock-skills:code-review`、`gsd-code-review` | 按各场景启用情况 |
| 调试 | `superpowers:systematic-debugging`、`mattpocock-skills:diagnosing-bugs`、`gsd-debug` | backend-dev、prd-design、frontend-dev |
| TDD | `superpowers:test-driven-development`、`mattpocock-skills:tdd` | backend-dev、prd-design |
| 规格流程 | `opsx:*` 6 项与 `openspec-*` 6 项 | backend-dev |
| 浏览器 | `playwright`、`chrome-devtools-mcp` | frontend-dev |

### 从数字可得的判断

- frontend-dev 距预算约 2.5k 字符，按已定方向移除 sentry 后约有 5.4k 余量；新增插件前要先算预算。
- backend-dev 超出约 3k 字符，且被去掉 description 的主要是 mattpocock-skills；自写 skill 均保留。
- prd-design 超出约 9.3k 字符，被去掉的主要是 pm-skills 的 skill 版本；S3 显示有 command 指向时不妨碍使用。

## 2. 官方来源核对（2026-11-03 取得；大型文档按关键字定位阅读，未通读）

| 问题 | 结论 | 来源 |
|---|---|---|
| 预算控制 | `skillOverrides` 含 `name-only` 都不影响插件 skill（"Plugin skills are not affected by `skillOverrides`."）；`skillListingBudgetFraction` 默认 0.01，可放项目设置；插件只有整包开关 | `code.claude.com/docs/en/skills.md`、`settings-reference.md` |
| skill 规则被跳过 | 每次都必须成立的放 hook；需判断的指引写成适用整个任务；重点放最前，有顺序的流程写步骤与 checklist；没有「先询问用户」的专门写法 | `skills.md`、平台 skill 编写最佳实践 |
| Bash 改文件 | 必须每次成立的放 hook 或 deny，`CLAUDE.md` 是指引；PreToolUse 可查命令文字但不是安全边界，脚本自行写文件拦不到 | `best-practices.md`、`hooks-guide.md`、`permissions.md` |
| 范围外改动 | 官方范例："Don't add features, tests, files, docs or refactors that weren't asked for."，有用的想法留到最后提出；属非确定性指令 | 平台 Sonnet 5.5 提示工程页 |
| Playwright 输出目录 | `--output-dir`、`PLAYWRIGHT_MCP_OUTPUT_DIR`、`outputDir`，只影响自动命名的文件；默认 `.playwright-mcp` 来自源码，与发布版是否对应未验证 | `microsoft/playwright-mcp` README、`microsoft/playwright` 源码 |
| Compose 与秘密 | 官方未把选项描述为秘密保护。实测 v5.5.0（假值）：验证用 `--quiet`；`--no-interpolate --no-env-resolution` 不展开变数与 env file，但写死的值仍会打印；`--environment` 打印整个 shell 环境 | `docs.docker.com/reference/cli/docker/compose/config.md`、本机实测 |

未验证：插件 command 是否占清单预算、同一插件内 command 与 skill 同名的行为；30000 字符如何由 1% 换算；`skillListingBudgetFraction` 调高后的实际效果。

过程异常：调研子代理实测 `--environment` 时，把一个环境变量的明文值印进了子代理会话记录（值未写入任何报告；用途与有效期未验证）。

## 3. 采纳决策表

用户 2026-11-03 确认：全部按「决定」一栏的建议执行；「建议采纳」「已定」项已实施，阶段 3 验证。

| # | 问题 | 建议 | 决定 | 理由与成本 |
|---|---|---|---|---|
| 1 | D-1 | dev-ops `CLAUDE.md` 常驻一行「规划规格、节点数、内存上限前先询问可用资源上限」，`middleware-ops` 把该条移到开头 | 建议采纳 | 官方：贯穿任务的指引写成常驻；不用 hook，询问不是可机械判断的规则 |
| 2 | B-4 | 四场景 `CLAUDE.md` 各加一行「改代码与配置一律用 Edit/Write」 | 已定，维持 | hook 拦不全，先观察阶段 3 |
| 3 | P-2 | prd-design、backend-dev 项目模板设 `skillListingBudgetFraction: 0.015`，阶段 3 核对警告消失 | 建议采纳 | 约 45000 字符（按 1M 窗口推算），常驻多约 2.3k、0.8k tokens；`name-only` 对插件无效 |
| 4 | F-3 / P-2 | 不移除 pm-skills、mattpocock-skills | 建议不移除 | S2、S3 已自然触发 |
| 5 | F-3 | gsd-core 去留：阶段 3 补测一个规划型任务后再定 | 建议暂缓 | F 系列偏实现型，证据不足；占 77 项 skill、40 个 agent |
| 6 | F-3 | playwright、chrome-devtools 两者都留 | 建议不改 | F 系列用 playwright、P4 用 chrome-devtools；后者为用户刻意全局保留 |
| 7 | F-3 | frontend-dev 移除 sentry | 已定，维持 | 省约 2.9k 字符 |
| 8 | F-4 | frontend-dev `CLAUDE.md` 加「不做未要求的改动；删除元素、改变业务行为前先确认；有用的想法放到最后提出」 | 建议采纳 | 改写自官方范例，非确定性 |
| 9 | F-1、F-2 | 说明把 `.playwright-mcp/` 加进 `.gitignore`，不设 `--output-dir` | 已定，维持 | 改目录只影响自动命名文件，且默认值与发布版的对应未验证 |
| 10 | D-2 | `middleware-ops` 写明：验证用 `docker compose config --quiet`；看结构用 `--no-interpolate --no-env-resolution`；不用 `--environment` | 建议采纳 | 有实测依据，本次调研也发生同类外泄 |
| 11 | P-1 | 不加「章节以本文件为准」 | 建议不采纳 | S1 未冲突；阶段 3 再观察 |

不在本轮：B-1、B-2、B-6、D-3、P-3 未调研。

范围更正（2026-11-03）：本轮只查了官方与上游原文，大厂、社区与场景对标未做，不代表阶段 2 完成；用户已选方案 B 补做，结果追加第二轮决策表。
