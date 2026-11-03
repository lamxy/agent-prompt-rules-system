# 外部對標來源候選清單（2026-11-03）

只列候選，供確認後再決定深入哪些。未做深入調研，也不含配置修改建議。

## 閱讀前須知

- **已讀範圍**：「MCP」是用 GitHub MCP 讀到原文；「WebFetch」是經小模型回傳的摘要與引文，引用前要回原文核對。
- **日期**：倉庫取最後 push 日；文章取發布日。星數取自 2026-11-03 的 GitHub 搜尋結果。
- **「同用」**：是否與 gstack、gsd-core、OpenSpec、pm-skills、mattpocock-skills、superpowers、codegraph 相同。本清單的候選都不是這些工具，下表不再逐項寫，僅在有關聯時註明。
- **「大廠」的認定**（使用者 2026-11-03 定義）：商業上是具千億級資本體量、跨賽道生態與極強抗風險能力的巨型科技平台；技術上是掌控底層基礎設施、主導開源與工程標準的生態統治者。「技術角度的大廠」的創始人員與技術員工，其影響力（引領、制定、開源行業規範等）也算。依使用者判斷，Docker、GitHub、Spotify、Vercel、Grafana、Sentry、Trail of Bits、PlanetScale 都歸 B。

## 候選總表

同一來源可對應多項，只在此記錄一次。

| ID | 名稱與 URL | 類別 | 作者／維護者 | 日期 | 星數 | 對應 | 已讀範圍 |
|---|---|---|---|---|---|---|---|
| B1 | [docker/skills](https://github.com/docker/skills) | B | Docker | 2026-11-02 | 611 | a、dev-ops、c | MCP：README、`docker-destructive-guardrails/SKILL.md` 全文 |
| B2 | [How to write a great agents.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) | B | Matt Nigh，GitHub | 2025-11-19（更新 11-25） | - | d、a | WebFetch：只取邊界段落。對象是 Copilot，非 Claude Code |
| B3 | [Building a general-purpose accessibility agent](https://github.blog/ai-and-ml/github-copilot/building-a-general-purpose-accessibility-agent-and-what-we-learned-in-the-process/) | B | Eric Bailey，GitHub | 2026-05-15 | - | frontend-dev、d | WebFetch。對象是 Copilot |
| B4 | [trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config) | B | Trail of Bits | 2026-08-24 | 2146 | b、d、c | MCP 取得全文（存檔），只讀目錄與約 6 行關鍵段落，未通讀 |
| B5 | [Portal by Spotify cut my Claude Code token usage by 90%](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90) | B | Dimitri Mazmanov，Spotify | 2026-09-03 | - | c、a | WebFetch。文中的 shunt 外掛未開。屬作者個人用法，不是全公司配置 |
| B6 | [getsentry/skills](https://github.com/getsentry/skills) | B | Sentry | 2026-11-02 | 1113 | c、dev-ops | MCP：README 全文，個別 skill 未讀 |
| B7 | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | B | Vercel | 2026-10-28 | 33415 | frontend-dev | MCP：README 全文，個別 skill 未讀 |
| B8 | [grafana/skills](https://github.com/grafana/skills) | B | Grafana Labs | 2026-11-01 | 302 | dev-ops | MCP：README 全文，個別 skill 未讀 |
| B9 | [planetscale/database-skills](https://github.com/planetscale/database-skills) | B | PlanetScale | 2026-10-07 | 734 | backend-dev | MCP：README 全文，個別 skill 未讀 |
| B10 | [A Prototype's Worth 1,000 Minutes](https://www.cloudzero.com/blog/claude-prototypes-accelerate-product/) | B（弱） | Scott Castle，CloudZero CPO | 2026-04-16 | - | prd-design | WebFetch。CloudZero 不算大廠，文章也不含配置 |
| C1 | [infinri/Writ](https://github.com/infinri/Writ) | C | infinri | 2026-10-19 | 287 | a、d | WebFetch 讀 README 摘要，**未依要求用 MCP** |
| C2 | [Workflow Example: Autonomous Agent](https://handsonai.info/ai-workflow-framework/examples/autonomous-agent/) | C | 頁面無署名，由連結推測為 James Gray（未驗證） | 2026-10-05 更新 | - | a | WebFetch |
| C3 | [diet103/claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) | C | diet103 | 2026-07-13 | 10046 | a、c、backend-dev、frontend-dev | MCP：README 全文，hook 原始碼未讀 |
| C4 | [umekatu/claude-code-bash-write-guard](https://github.com/umekatu/claude-code-bash-write-guard) | C | umekatu | 2026-10-02 | 0 | b | MCP：README 全文 |
| C5 | [calebschalesky-ops/claude-agent-guardrails](https://github.com/calebschalesky-ops/claude-agent-guardrails) | C | calebschalesky-ops | 2026-10-23 | 0 | b、d、a | MCP：README 全文 |
| C6 | [Dicklesworthstone/destructive_command_guard](https://github.com/Dicklesworthstone/destructive_command_guard) | C | Dicklesworthstone | 2026-11-02 | 6240 | b | MCP 取得全文（存檔，3600 餘行），只讀開頭、章節目錄與關鍵字，未通讀 |
| C7 | [samber/cc-skills-golang](https://github.com/samber/cc-skills-golang) | C | Samuel Berthe | 2026-11-01 | 3754 | backend-dev、c | MCP：README 全文 |
| C8 | [parcadei/Continuous-Claude-v3](https://github.com/parcadei/Continuous-Claude-v3) | C | parcadei | 2026-01-26 | 3947 | c | MCP 取得全文（存檔），只讀開頭、章節目錄與關鍵字，未通讀 |
| C9 | [wilwaldon/Claude-Code-Frontend-Design-Toolkit](https://github.com/wilwaldon/Claude-Code-Frontend-Design-Toolkit) | C | wilwaldon | 2026-04-11 | 1260 | frontend-dev | MCP 取得全文（存檔），只讀開頭與章節目錄 |
| C10 | [addxai/enterprise-harness-engineering](https://github.com/addxai/enterprise-harness-engineering) | C | AddX.ai（積加科技） | 2026-04-17 | 46 | dev-ops、prd-design | MCP：README 全文 |
| C11 | [shinpr/claude-code-discover](https://github.com/shinpr/claude-code-discover) | C | shinpr | 2026-08-29 | 12 | prd-design | MCP：README 全文 |

## 問題組

### (a) 讓 agent 確實遵守「先詢問使用者」

| ID | 可對標的內容（只寫已讀到的） |
|---|---|
| B1 | `docker-destructive-guardrails`：動手前說明會失去什麼並取得確認，按風險分 Tier 1／Tier 2，並附不良／良好對話的人工檢查手冊。**這是文字規範，沒有強制機制** |
| C1 | 寫原始碼前有「計畫核准、測試骨架核准」兩道閘門；使用者回覆由 prompt-submit hook 讀取並發一次性 token，agent 無法自行核准。README 自述不是沙箱 |
| C2 | 由主代理用 AskUserQuestion 提問，PreToolUse hook 檢查 `APPROVED` 標記後才放行派工。明寫 Claude 仍可能自己寫入標記，且遇到不認得的 payload 會放行 |
| C3 | UserPromptSubmit hook 依 `skill-rules.json` 判定該用的 skill，PreToolUse 在未載入前擋編輯（兩次嘗試模型）。解決的是 skill 啟用，不是 skill 內的步驟 |

**關係**：C1、C2 最貼近問題；C5 的 `ceiling` 也有「對外動作先問人」，但比對的是工具名稱。

### (b) 避免用 Bash 改檔繞過規則

| ID | 可對標的內容 |
|---|---|
| B4 | 設定範本用 PreToolUse 擋 `rm -rf` 與直推 main，寫明 hook 是護欄而非安全邊界，並主張 deny 規則與 `/sandbox` 併用 |
| C4 | 直接針對本問題：命令同時含受保護路徑與寫入語法（`>`、`sed -i`、`tee`、Python 寫檔）就擋下，導向 Edit／Write。附自我測試，並列出 `cp`、`mv`、`git apply` 等測不到的情況 |
| C5 | `territory` 為各子代理限定可寫路徑並檢查 shell 寫入，附實跑紀錄；只限制具名子代理，不管主會話 |
| C6 | Rust 製 hook，有模組化規則包與 heredoc／內嵌腳本掃描，涵蓋多種 agent。**目標是破壞性命令**，是否涵蓋一般寫檔未確認 |

**待核對**：B4 寫「沒有 `/sandbox` 時 deny 規則只擋內建工具」；另一搜尋摘要稱官方文件說 Read／Edit deny 也適用 Claude Code 辨識得出的 Bash 檔案命令。兩者可能不一致，也可能是版本差異，未驗證。

**線索（搜尋摘要，未開原文，不列為推薦）**：`anthropics/claude-code` issues [#31292](https://github.com/anthropics/claude-code/issues/31292)、[#29709](https://github.com/anthropics/claude-code/issues/29709)、[#87971](https://github.com/anthropics/claude-code/issues/87971)、[#89716](https://github.com/anthropics/claude-code/issues/89716)。

### (c) 管理大量 skill、工作流框架與上下文成本

| ID | 可對標的內容 |
|---|---|
| B5 | CLAUDE.md 路由規則只是建議、Claude 可能忽略，因此改用 PreToolUse hook 擋大檔讀取；文章稱批量讀取平均省約 90%（作者自測） |
| B6 | 把 skill 分為全公司、領域、單一倉庫三層放置，領域 skill 拆成可單獨安裝的 plugin；外部 skill 複製進庫管理；每個 skill 附 `SPEC.md` 維護契約 |
| C7 | 逐 skill 列 description、SKILL.md、整個目錄的 token 數，並訂預算（單一 description 約 100 tokens、同時載入低於約 10k）；自報評測：有 skill 97%、無 skill 57% |
| C8 | 109 skills、32 agents、30 hooks 的整合環境，以 YAML handoff 取代 compaction，並主張抗拒外掛膨脹。**最後 push 為 2026-01** |

**補充**：B1 以 `catalog.yaml` 產生目錄與版本；C3 主張 SKILL.md 控制在 500 行內並漸進載入。

### (d) 約束範圍外改動

| ID | 可對標的內容 |
|---|---|
| B2 | agent 檔案的邊界分三級：Always do、Ask first、Never do |
| B3 | 唯讀審查者與實作者分開；腳本評複雜度，超過門檻只給指引；高風險 UI 模式不產生程式碼 |
| C5 | 路徑決策順序：exact deny → exact allow → sealed folder → allowed folder → out of scope；設定檔對受限代理自動封存 |
| C1 | 寫入前須有核准的計畫，屬於間接約束範圍，README 未提對照 diff 檢查 |

**反向參考**：B4 的 anti-rationalization Stop hook 專抓「這超出範圍」之類的藉口，可能與本問題衝突，比較時要留意。

**未讀原文，不列為推薦**：`Lucface/harness-guard`、`cc-safe-setup` 的 scope-guard、mcpmarket 上的 Scope Guard 類 skill。

## 對標組

### prd-design

| ID | 可對標的內容 |
|---|---|
| C11 | 從假設到 PRD：按價值、可用性、可行性、可行度四類風險選驗證方式；必要時才產單檔 HTML 原型；PRD 交由獨立代理審查；證據留在 `docs/` 跨會話使用。僅 12 星 |
| C10 | `story-craftsman` 訪談式產出 User Story、`voc-analysis` 客戶聲音分析（只讀到 README 一句話） |
| B10 | 流程層參考：PRD 保留、原型取代其視覺溝通層，連 `design.md` 交工程審查。無配置可對標 |

**不推薦**：[Luciq 的文章](https://www.luciq.ai/blog/pm-builds-with-claude-code)已讀，不含 CLAUDE.md、skill 或審查步驟。`Digidai/product-manager-skills`（195 星）只看到描述，未讀 README。

### frontend-dev

| ID | 可對標的內容 |
|---|---|
| B7 | `react-best-practices`（40+ 規則，按影響排序）、`web-design-guidelines`（100+ 規則）、`composition-patterns`、`react-view-transitions` |
| B3 | 前端變更自動做無障礙審查，有分工與複雜度閘門；文中稱審過 3,535 個 PR、解決率 68% |
| C9 | 按用途整理 70+ 工具（設計 skill、設計 token、Figma、瀏覽器測試）。屬整理清單，非實戰配置；標示 2026 年 4 月 |
| C3 | `frontend-dev-guidelines`（React／TypeScript／MUI v7）與 `frontend-error-fixer` |

### backend-dev

| ID | 可對標的內容 |
|---|---|
| C7 | Go 全面涵蓋：錯誤處理、並行、資料庫、測試、可觀測性；另有 CI 內用 skill 審 PR 的做法 |
| B9 | `mysql` skill：InnoDB schema、索引、查詢調校、交易、遷移、複製與連線排錯 |
| C3 | `backend-dev-guidelines`（Node.js／Express／TypeScript），並有 tsc 檢查的 Stop hook |

**缺口**：未找到 MongoDB、Redis 的大廠或社區新候選（現行配置已用 mongodb、redis-development 外掛，本次未重讀）。Go 與 Node.js 未找到大廠開源配置。

### dev-ops

| ID | 可對標的內容 |
|---|---|
| B1 | `docker-compose-patterns`、`docker-build-strategies`、破壞性操作護欄、用 microVM 隔離 agent 的 Docker Sandboxes skill |
| B8 | LGTM 可觀測性：`promql`、`alerting-irm`、`loki`、`tempo`、`alloy`、基數排查、k6。部分偏 Grafana Cloud 或 K8s，需篩選 |
| B6 | CI/CD 相關：`gha-security-review`（GitHub Actions 安全審查）、`iterate-pr`（迭代到 CI 通過） |
| C10 | `sre-agent`、`gitlab-ci`（15 條規則）、`prometheus`、`grafana`、`mock-engine`（Compose 本機模擬）。**偏 K8s、ArgoCD、GitLab，與使用者環境差距大；維護者為積加科技，個別 skill 是否依賴被排除的工具未查** |

## 逐項覆蓋表

| 項目 | B | C | 備註 |
|---|---|---|---|
| (a) 先詢問使用者 | 已找到 | 已找到 | B 只有文字規範（B1），未找到大廠的強制機制 |
| (b) Bash 改檔 | 已找到 | 已找到 | B4 只涉及 deny＋sandbox，未找到大廠專擋 Bash 改檔的 hook；C4、C5 皆 0 星 |
| (c) 大量 skill 與成本 | 已找到 | 已找到 | 未找到大廠對工作流框架取捨的說明；已用工具未重讀 |
| (d) 範圍外改動 | 已找到 | 已找到 | B 都是 Copilot 文章；C 只有 0 星的 C5 與間接相關的 C1 |
| prd-design | **未找到**（大廠） | 已找到 | 僅有非大廠文章 B10，且無配置；C 星數低 |
| frontend-dev | 已找到 | 已找到 | C9 是工具清單，C3 只是其中一部分 |
| backend-dev | 部分 | 已找到 | MySQL 有 B9；**Go、Node.js、MongoDB、Redis 的大廠配置未找到** |
| dev-ops | 已找到 | 部分 | C 只有 C10，且不合不用 K8s 的環境；**Compose／可觀測性的社區配置未找到合適者** |

### 「未找到」的搜尋關鍵字

- **prd-design × B**：`company engineering blog Claude Code product managers PRD prototype workflow how our PM team uses agents`；GitHub `product manager PRD skills claude code`
- **backend-dev × B**：GitHub `golang go skills claude code agent`、`golang skills agent`；未針對 Node.js、MongoDB、Redis 另外搜尋，這部分應視為**未做**，不等於確實不存在
- **dev-ops × C**：GitHub `claude code skills docker compose observability devops`（0 筆）、`observability prometheus grafana claude code skill plugin`（0 筆）、`devops skills claude code agents`（4 筆，只讀 C10）；`sanjay3290/ai-skills`、`pravinmishraaws/Ultimate-Agentic-DevOps-with-Claude-Code`、`selvarajmurugesan90/ops-engineering-skills` 未讀

### 未做

- 已用工具（gstack、gsd-core、OpenSpec、pm-skills、mattpocock-skills、superpowers、codegraph）未重讀，未列為候選。
- 上方 dev-ops × C 的 3 個倉庫（`sanjay3290/ai-skills` 等）仍未讀，不在本輪補做範圍。

## 第二輪補做（2026-11-03）

使用者確認：補 Node.js、MongoDB、Redis 定向搜尋；6 個未讀倉庫只讀 README 篩選；新增技術大廠人員一輪；C4、C5 只作設計參考，採用其做法前須實測。

| ID | 名稱與 URL | 類別 | 作者／維護者 | 對應 | 已讀範圍 | 篩選結論 |
|---|---|---|---|---|---|---|
| B11 | [mongodb/agent-skills](https://github.com/mongodb/agent-skills) | B | MongoDB 官方 | backend-dev | MCP：README 全文；skill 未讀 | **深入**。自架部署要用 `mongodb` 外掛，不是 `mongodb-atlas` |
| B12 | [redis/agent-skills](https://github.com/redis/agent-skills) | B | Redis 官方 | backend-dev、dev-ops | MCP：README 全文；skill 未讀 | **深入**。對照 `redis-core`、`redis-connections`、`redis-clustering`、`redis-observability` 與現行規則 |
| B13 | [mcollina/skills](https://github.com/mcollina/skills) | B（人員） | Matteo Collina | backend-dev | MCP：README 全文；skill 未讀 | **深入** `node`、`typescript-magician`、`skill-optimizer`。屬個人倉庫，非 Node.js 官方；搜尋摘要稱他是 core contributor，TSC 身分未確認 |
| B14 | [ghostty AGENTS.md](https://github.com/ghostty-org/ghostty/blob/main/AGENTS.md) | B（人員） | Ghostty（Mitchell Hashimoto 的專案） | (d) | MCP：全文 | **已讀完，只作參考**。短小，只含指令、目錄與硬性禁止。「每條都來自實際錯誤」是二手說法，此檔無法佐證 |
| B15 | [cloudflare/skills](https://github.com/cloudflare/skills) | B | Cloudflare | frontend-dev | MCP：README 全文 | **只看** `web-perf`。其餘綁定 Cloudflare 平台 |
| C12 | [cxuu/golang-skills](https://github.com/cxuu/golang-skills) | C | cxuu | backend-dev、(c) | MCP：README 全文 | **深入**，與 C7 比較。依 Google、Uber Go 規範；附檢查腳本、評測與 `RULE_OWNERSHIP.md` |
| C13 | [samber/cc-skills](https://github.com/samber/cc-skills) | C | Samuel Berthe | frontend-dev、dev-ops、(c) | MCP：README 全文 | **只看** `frontend-design-deslop`、`promql-cli`、`skill-progressive-disclosure-design`。評測數字為自述 |
| C14 | [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | C | ChrisWiles | (c)、frontend-dev | MCP：README 開頭與章節目錄，未讀完 | **只看** hook 與排程 workflow 範例。無法確認是實際生產配置 |
| C15 | [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) | C | disler | (a)、(b) | MCP：README 開頭與章節目錄，未讀完 | **只查** hook 流程控制段落，機制仍以官方文件為準 |
| C16 | [FlorianBruniaux/claude-code-ultimate-guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) | C | Florian Bruniaux | (a)～(d) | MCP：README 開頭與章節目錄，未讀完 | **暫不深入**。是綜合指南，引用需回溯原始來源 |

**B11、B12 已在使用**：`settings/settings.project-backend-dev.json` 已啟用 `mongodb`、`redis-development`；`settings/README.md` 記錄 `mongodb` 外掛來自 `mongodb/agent-skills`，`redis/agent-skills` 的 README 也指向 `redis-development@claude-plugins-official`。所以它們不是新能力，深入時只檢查與 backend-dev 規則是否衝突或重複。

**技術大廠人員**：

- Boris Cherny（Claude Code 作者）：只找到 VentureBeat 等二手轉述，包含「Claude 犯錯就寫進 CLAUDE.md」與驗證是品質關鍵。**未讀到一手來源，未驗證，不列候選**。
- Simon Willison：只找到指南摘要，未驗證，不列候選。

**MongoDB、Redis、Node.js 搜尋結果**：GitHub 依星數各查一次，除官方外多為 0～54 星，且未讀 README，不列候選。`Ashfaqbs/software-dev-ai-claude-toolkit`（27 星）、`seed-forge/harness-ai-kit`（25 星）描述涵蓋這些主題但也含 K8s，同樣未讀。

**覆蓋變化**：backend-dev × B 的 MongoDB、Redis、Node.js 已有來源（B11、B12、B13）；Go 的大廠配置仍未找到，只有依大廠規範整理的 C12。prd-design × B 仍未找到。

**K8s 掃描**：本輪新增候選未做，深入時再查。

## 社區經驗與常見解法（2026-11-03）

**可信度**：

- 「原文」是用 GitHub MCP 或官方文件讀到的；其中 issue 內容仍是回報者自述，未經本倉庫實測。
- 「摘要」只看過搜尋摘要，未開原文。
- 部分作者賣模板或工具，有立場。
- Reddit、Hacker News 沒有搜到討論串，也未直接查，這是**未做**。

### 問題組

| 問題 | 常見解法 | 社區經驗 | 來源層級 |
|---|---|---|---|
| (a) 不先問就動手 | 判斷題放規則，不變量放 hook；縮短 `CLAUDE.md`；把流程移到 skill | 多篇回報長規則會被忽略，任務壓力常勝過規則；「遵守率 70～90%」沒有量測依據，不引用。沒有找到專門測「先問再做」的資料 | 摘要 |
| (b) Bash 改檔 | PreToolUse 擋 Bash 寫入；收窄 `Bash(python3 *)` 這類放行；在 `CLAUDE.md` 明寫 | 詳見下方 | 原文 |
| (c) skill 過量 | 定期稽核；`disable-model-invocation: true`；用 `/context` 或 `/skill-doctor` 量測 | 有人回報 skill 太多會被靜默截斷，與本倉庫實測的預算問題相符；「4～6 個外掛」只是個人說法 | 摘要 |
| (d) 範圍外改動 | 順手發現只記 TODO 不修；中途看 `git diff --name-only`；一任務一分支；審查與修復分開；Stop hook 把大 diff 送交叉審查 | 都是個人經驗，沒有成效量測 | 摘要 |

### (b) 的重要發現

- **官方現行說法**（[permissions](https://code.claude.com/docs/en/permissions)，原文）：Read、Edit 的 deny 規則涵蓋內建工具、Claude Code 辨識得出的 Bash 檔案命令（`cat`、`sed`、`tee` 等）與重導向目標；不涵蓋 `grep -r` 這類沒有點名檔案的命令，也不涵蓋 Python、Node 腳本自行開檔。官方建議搭配沙箱做縱深防禦。
- **B4 待核對項已解決**：B4 寫的「只擋內建工具」比官方現行說法窄，以官方為準。
- **B-4 有更明確的成因**（[#87971](https://github.com/anthropics/claude-code/issues/87971)，原文，開放中）：回報者引用 auto 模式注入的指令，要求改檔優先用 sed、heredoc 或短腳本。留言稱這是按會話分組的實驗，子代理會繼承。**本機預設是 auto 模式，可能適用；本機是否被分到這一組未驗證。**
- **連帶後果**（同上，留言自述）：Bash 寫入不觸發 `Write|Edit` hook，path rules 與巢狀 `CLAUDE.md` 也不載入，`/rewind` 也可能失效。這與本倉庫「path rules 的載入時機」實測方向一致。
- **`CLAUDE.md` 寫明有幫助，但樣本小**（同上，2026-10-13 留言，2.1.296，Opus，auto 模式，每組 15 次）：

| | 沒有說明 | 明寫只用 Edit/Write | 先讀再做的說明 |
|---|---|---|---|
| 規則有載入 | 5/15 | 15/15 | 15/15 |
| 用 Bash 寫入 | 12/15 | 2/15 | 2/15 |

- **`CLAUDE_CODE_THRIFTY_SONIC=0` 不採用**：未見官方文件記載，是實驗開關；留言另稱 Opus 5.5 起可能失效。
- **常見的 hook 做法**：留言附了擋 `.md` 的 PreToolUse 範例；[claude-bash-bridge](https://github.com/JasonGDG/claude-bash-bridge) 會在 Bash 前後比對檔案並補跑 hook（未讀倉庫，每次寫入多約 0.4～0.5 秒，均為作者自述）。任何 hook 都攔不住所有寫法，要保留「擋常見寫法、靠 diff 審查兜底」的預期。
- **其他實測**（原文，作者自述）：[Mervin Praison](https://mer.vin/news/why-blocking-edit-and-write-doesnt-stop-claude-rewriting-files/) 回報 Edit、Write 被禁且 Bash 明列放行時，8/8 用 Python 改檔成功；不列放行清單時 0/6；同樣放行但提示明寫不要用 Bash 寫檔時 0/6；連 Bash 也禁時 0/5。

### 場景組

| 場景 | 常見解法與經驗 | 來源 |
|---|---|---|
| prd-design | PRD 保留細節與驗收條件，原型負責溝通；寫 PRD 前先訪談，問題段落沒定不寫方案；不要整份 PRD 丟進去要求全做；確認原型真的在驗證你關心的假設；別把原型當可上線成品 | 摘要：[Chaayush Malik](https://chaayushmalik.medium.com/five-ways-i-use-claude-code-as-a-product-manager-dc8c76419eff)、[AI Spaces](https://aispaces.substack.com/p/product-management-in-the-age-of)、[Vibe Coding Academy](https://www.vibecodingacademy.ai/blog/claude-code-workflows-prd-to-shipped-feature)（賣課）、[Alloy](https://alloy.app/library/claude-for-pms-complete-guide-10x-productivity)（賣工具） |
| frontend-dev | 先定視覺方向與 token 來源；列「AI 味」禁止清單；有參考圖；走「寫 → 截圖 → 對照 → 修」循環 | 摘要，第一手回顧少：[How-To Geek](https://www.howtogeek.com/i-tested-10-claude-plugins-for-web-design-here-are-the-3-that-are-actually-essential/)、[Mowgli](https://mowgli.ai/blog/claude-code-ui-design-workflow)（廠商） |
| backend-dev | 遷移用影子庫試跑、可逆性檢查、資料列數比對；空庫測試不足以驗證；不給 agent 生產憑據；移植時用真實資料比對新舊行為，留意孤兒程式碼 | 摘要：[Yureki Lab](https://dev.to/yureki_lab/how-i-let-my-ai-coding-agent-write-database-migrations-without-losing-data-5dc2)、[Winder.ai](https://winder.ai/python-to-go-migration-with-claude-code/)（Go 相關只找到這篇）。另一篇 [AWS Builders](https://dev.to/aws-builders/the-setup-is-the-strategy-how-i-orchestrated-a-product-migration-with-claude-code-b92) 主張直連資料庫，兩者有衝突，要看環境 |
| dev-ops | 調查唯讀、修復另走審查；用 hook 擋不可逆命令；稽核憑據範圍；用實際回應驗證部署，不只看腳本退出碼 | 摘要：[Matthew Wong](https://www.matthewswong.com/en/blog/claude-code-production-incident-debugging/)。事故原文：[#63644](https://github.com/anthropics/claude-code/issues/63644)（`compose down -v` 清掉資料庫）、[#41357](https://github.com/anthropics/claude-code/issues/41357)（`system prune -af --volumes` 波及其他專案），都已關閉為 not planned |

### 對照現行配置發現的缺口（待第二輪決策）

`settings/settings.user.json` 的 `allow` 有 `Bash(docker compose down *)` 與 `Bash(docker-compose *)`，字面上都涵蓋 `down -v`，`deny` 沒有對應項目。#63644 正是這個命令造成資料遺失。

- dev-ops 模板把 `docker compose down*` 列為需確認；其他場景沒有。
- `docker-compose down -v` 這個舊寫法在 dev-ops 是否也會詢問、auto 分類器會不會攔，都未實測。
- 本機 `~/.claude/settings.json` 有同一條放行，未改動。

### 未做

- Reddit、Hacker News 討論串。
- 上表「摘要」來源未開原文，寫入配置前要回原文核對或自行實測。
- 前端、後端、Go 的第一手回顧仍少；Go 工具（goose、golang-migrate、Atlas）未單獨搜尋。

## K8s 依賴梳理（2026-11-03）

**方法**：淺克隆 9 個 skill 倉庫，以 `kubernetes|kubectl|k8s|helm|argocd|argo cd|kustomize|eks|gke|aks` 逐 skill 計數，再看命中行與部分前置條件。這是關鍵字快篩，不是逐 skill 通讀；沒命中只代表沒提到這些詞。

**未掃**：C1、C2、C4、C5、C6、C8、C9，以及 B2、B3、B5、B10 等文章。

| 候選 | SKILL 數／命中數 | 依賴 K8s，排除 | K8s 只是選項或局部，可篩用 | 未命中，可進入下一步評估 |
|---|---|---|---|---|
| C10 | 25／12 | `k8s-ops`；`sre-agent`（診斷與巡檢需 kubectl，通知含飛書）；`gitlab-ci` 的 ArgoCD 部分 | `prometheus`（有 `kube_*` 查詢範例）、`architect`、`dev-workflow`（CD 步驟指向 ArgoCD，需求步驟可接 `lark-mcp`）、`testing-strategy`（L3-k8s 是選用子層）、`security-compliance-review` | `mock-engine`（Docker Compose）、`grafana`、`story-craftsman`、`voc-analysis` 等 13 個 |
| B8 | 54／26 | `grafana-app-sdk` 4 個（命中多，未細讀；用途與本倉庫無關） | `alloy`、`opentelemetry`、`beyla`、`tempo`、`mimir`、`loki`；`grafana-cloud/*` 另依賴 Grafana Cloud，與現行自架方案要分開判斷 | `promql`、`alerting-irm`、`grafana-oss`、`dashboarding`（僅 1 處）、k6 系列等 |
| B1 | 12／1 | 無 | `docker-docs` 只是把 K8s manifests 劃在範圍外 | 其餘 |
| B6 | 30／2 | 無 | `security-review` 的 SPEC 明寫不涵蓋 K8s；`claude-settings-audit` 只用於偵測專案類型 | 其餘 |
| B9 | 4／1 | 無 | `postgres` 的 1 處參考文件，未細看 | `mysql` 等 |
| C7 | 46／9 | 無 | 多為範例或背景；`golang-benchmark` 參考文件有 kubectl 操作範例 | 其餘 37 個 |
| B7、C3、C11 | 9／0、9／0、15／0 | 無 | — | 全部 |

**被排除工具（同次掃描，只查 C10）**：`sre-agent` 附 `feishu_notify.py` 與飛書模板；`multi-worktree-dev` 的飛書命中 20 次，含 `feishu-switch.sh`；`dev-workflow` 含 `lark-mcp`。`architect`、`testing-strategy` 只是順帶提及。

**結論**：C10 從 dev-ops 主要對標降為只評估 `mock-engine`、`grafana` 與 `prometheus` 的通用部分；B8 優先評估 `promql`、`alerting-irm`、`tempo`、`loki`、`alloy`，只取 Docker 或主機路徑。

## 過程異常

0. **GitHub code search 的 OR 查詢不可靠**：同一倉庫 `kubernetes OR kubectl ... filename:SKILL.md` 回傳 0 筆，單查 `kubectl` 卻有 9 筆，所以 K8s 梳理改用淺克隆後掃描。之後的倉庫內查詢不要依賴這種組合。
1. **有兩處偏離讀取要求**：Writ（C1）用 WebFetch 讀 README，未用 GitHub MCP。文章與 issue 也經 WebFetch，取得的是摘要，不是逐字原文。
2. **部分大型 README 未讀完**：B4、C6、C8、C9 超過單次回傳上限並存檔，只讀了部分內容。
3. **寫了報告以外的暫存檔**：曾把 3 份 README 文字抽到 scratchpad 的 `r-*.txt` 以便查詢，超出「只寫報告檔」的限制，已刪除。工具也自動把超大回傳存到會話的 `tool-results/`。
4. **GitHub 搜尋不穩定**：多個 `org:` 以 OR 組合查詢回傳 0 筆，改為逐一查詢。部分查詢的 0 筆可能是語法或關鍵字造成的，不能視為確實不存在。
5. **`levi-openclaw/taskmaster` 來歷未明**：README 安裝指令指向 `blader/taskmaster`，唯一提交的作者也不同，可能是 fork，星數未取得，因此不列為候選。其內容是掃描 transcript 的 Stop hook，可當 (a) 的線索。
6. **可信度**：C7 的評測、B5 的省量、B3 的解決率、C5 的統計皆為作者自述，未驗證。
