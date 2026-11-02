# 外部對標來源候選清單（2026-11-03）

只列候選，供確認後再決定深入哪些。未做深入調研，也不含配置修改建議。

## 閱讀前須知

- **已讀範圍**：「MCP」是用 GitHub MCP 讀到原文；「WebFetch」是經小模型回傳的摘要與引文，引用前要回原文核對。
- **日期**：倉庫取最後 push 日；文章取發布日。星數取自 2026-11-03 的 GitHub 搜尋結果。
- **「同用」**：是否與 gstack、gsd-core、OpenSpec、pm-skills、mattpocock-skills、superpowers、codegraph 相同。本清單的候選都不是這些工具，下表不再逐項寫，僅在有關聯時註明。
- **「大廠」的認定**：使用者未定義規模。Docker、GitHub、Spotify、Vercel、Grafana、Sentry、Trail of Bits、PlanetScale 歸 B；PlanetScale、Trail of Bits 規模較小，是否算大廠請使用者判斷。

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
- Node.js、MongoDB、Redis 未單獨搜尋大廠或社區來源。
- `samber/cc-skills`、`cxuu/golang-skills`、`FlorianBruniaux/claude-code-ultimate-guide`、`ChrisWiles/claude-code-showcase`、`disler/claude-code-hooks-mastery`、`cloudflare/skills` 只看到搜尋結果的描述，未讀。

## 過程異常

1. **有兩處偏離讀取要求**：Writ（C1）用 WebFetch 讀 README，未用 GitHub MCP。文章與 issue 也經 WebFetch，取得的是摘要，不是逐字原文。
2. **部分大型 README 未讀完**：B4、C6、C8、C9 超過單次回傳上限並存檔，只讀了部分內容。
3. **寫了報告以外的暫存檔**：曾把 3 份 README 文字抽到 scratchpad 的 `r-*.txt` 以便查詢，超出「只寫報告檔」的限制，已刪除。工具也自動把超大回傳存到會話的 `tool-results/`。
4. **GitHub 搜尋不穩定**：多個 `org:` 以 OR 組合查詢回傳 0 筆，改為逐一查詢。部分查詢的 0 筆可能是語法或關鍵字造成的，不能視為確實不存在。
5. **`levi-openclaw/taskmaster` 來歷未明**：README 安裝指令指向 `blader/taskmaster`，唯一提交的作者也不同，可能是 fork，星數未取得，因此不列為候選。其內容是掃描 transcript 的 Stop hook，可當 (a) 的線索。
6. **可信度**：C7 的評測、B5 的省量、B3 的解決率、C5 的統計皆為作者自述，未驗證。
