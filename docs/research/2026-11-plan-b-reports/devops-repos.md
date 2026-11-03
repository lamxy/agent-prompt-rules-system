# dev-ops 社區對標與文章補取（2026-11-03）

本文件是調研結果，建議都待使用者決定；未改倉庫與本機配置。外部 skill 的內容只證實「來源這樣說」，都未在本機實測。

## 0. 結論

| 項目 | 建議 | 理由 |
|---|---|---|
| Compose 層備份還原與還原演練 | 採納做法（先實測再寫入），不安裝任何社區 skill | 現況只有 MongoDB 備份與 Redis 持久化；監控主機的 `pg-data`、`kuma-data`、`beszel-data` 無備份說明 |
| 備份任務的失敗告警 | 採納做法（併入上項） | 現況無對應監控；Uptime Kuma README 列有 Push 監控，可沿用現有棧，不新增工具 |
| `incident-response-commander` 等 agent 的 kubectl 範例 | 使用者決定（建議處理） | 與「不用 K8s」及 `CLAUDE.md`「先取證不先重啟」方向不一致 |
| 事故排查補「主動找反證」、部署驗證補「依賴路徑檢查與重試窗口」 | 暫緩，階段 3 有缺口再加 | 成本各一行，但目前無本倉庫失敗證據 |
| 3 個指定倉庫與 3 個搜尋倉庫 | 全部不安裝 | 見各節 |

第 25 條（不採納 B8、C10）不受影響：本輪沒有發現應改變此決定的內容。

## 1. 方法

- 3 個指定倉庫與 3 個搜尋倉庫都以 `git clone --depth 1` 加 `core.hooksPath=/dev/null` 取到 scratchpad 跨檔掃描，未執行倉庫內程式。**偏離「優先用 MCP」的原因**：要跨檔掃描，任務已允許。元資料來自 GitHub REST API。
- K8s 關鍵字：`kubernetes|kubectl|k8s|k3s|helm|EKS|AKS|GKE`，按行計數，範圍含 skill 目錄下所有檔案。
- 排除工具關鍵字：`飛書/飞书|feishu|lark|釘釘/钉钉|dingtalk|aliyun|alibaba|阿里云|tencent|騰訊/腾讯|wechat|wecom|企业微信|huawei|baidu`。
- 分類定義：「依賴 K8s」＝步驟或前置條件要求 K8s；「K8s 僅為選項」＝只作例子、替代方案或交叉引用；「未提及」＝關鍵字零命中。

過程異常：

1. 第一版排除工具掃描的 `\bACK\b` 不分大小寫，命中 4 個 skill，看內容後全是訊息確認的 `ack`（如 `auto_ack`），屬誤報，已移除該詞重掃。
2. 第一次全倉 grep 因 zsh 展開 `--include=*` 失敗而未執行；第一次取文章因 zsh 不拆字串、第二次因 `g` 已是別名也失敗。都已修正重跑，以本文數字為準。
3. 第一次全倉排除詞掃描用 `head -20` 截斷，輸出全是 claude-code-config，可能遮住其他倉庫；已分倉重掃。
4. dev.to CDX 查詢一次 curl 28 逾時但已回傳部分內容，archive.org 可用性查詢一次 429。兩者都改用單一 URL 的 CDX 查詢補齊。全程未出現 curl 35。

## 2. A：指定倉庫

### 2.1 sanjay3290/ai-skills

- 維護者：Sanjay Ramadugu（個人，貢獻 49 commits，另有 2 位各 1 次）。最後 push：2026-11-02。星數 450，fork 49。Apache-2.0。
- 共 25 個 skill（倉庫描述寫 24）。
- 排除工具：全倉零命中。

| Skill | K8s 分類 | 排除工具 | 與現況相比 | 建議 |
|---|---|---|---|---|
| azure-devops | 未提及 | 否 | 綁 Azure DevOps，現行不用 | 不採納 |
| apple-container | 未提及（唯一命中是「不是 K8s」的否定句） | 否 | macOS 專用，與單主機 Docker 部署無關；無 Compose、無備份 | 不採納 |
| postgres | 未提及 | 否 | 唯讀查詢；腳本同時做語句前綴檢查與 `set_session(readonly=True)`（已讀 `scripts/`） | 暫緩：排障唯讀帳號的做法可參考；未安裝 |
| mysql、mssql | 未提及 | 否 | 同類唯讀查詢；SKILL 已掃描，腳本未讀 | 不採納：不是現況 dev-ops 缺口；mssql 不在現行技術棧 |
| telegram | 未提及 | 否 | Agent 主動發 Telegram、手機按鈕審批 | 不採納：現況告警由 Kuma、Beszel、GlitchTip relay 發出，已滿足；「手機審批」會繞開 permissions 的確認路徑 |

其餘 19 個（Google Workspace、語音、研究、WhatsApp、atlassian 等）非 dev-ops，都無 K8s 依賴（`deep-research` 的 3 個命中只是範例查詢字串）。

無 Compose、備份還原、部署驗證、事故處理類 skill。對現況無可補能力。

### 2.2 pravinmishraaws/Ultimate-Agentic-DevOps-with-Claude-Code

- 維護者：Pravin Mishra（個人）。最後 push：2026-05-10。星數 31，fork 578（課程範本，fork 數不代表採用品質）。無授權條款，不能複製文字。
- **文件與現況不符**：`CLAUDE.md` 列 4 個 agent、`scaffold-cicd`、`infra-status`、`infra-audit`、`tf-destroy`、`project-scope` 與 4 層安全 hook，但唯一的 `main` 分支只有 4 個 skill，無 `agents/`、無 settings、無 `terraform/`。`README.md` 講的則是 Ubuntu + Nginx 實習作業。描述中的安全機制無法從本倉庫驗證。
- 排除工具：零命中。

| Skill | K8s 分類 | 排除工具 | 全文已讀 | 與現況相比 | 建議 |
|---|---|---|---|---|---|
| deploy | 未提及 | 否 | 是 | S3 + CloudFront 同步，不適用 | 不採納 |
| tf-plan | 未提及 | 否 | 是 | 摘要增刪改數與爆炸半徑；現況 `CLAUDE.md` 已要求先給差異 | 不採納 |
| tf-apply | 未提及 | 否 | 是 | 用 `-auto-approve`，與現況「確認後變更」方向相反（雖設 `disable-model-invocation`） | 不採納 |
| scaffold-terraform | 未提及 | 否 | 是（未讀 template-spec） | AWS 靜態站專用 | 不採納 |

可記一筆但不必改動的做法：動作類 skill 設 `disable-model-invocation: true`，只允許手動呼叫。現況 skill 是知識型，無動作型，不需要。

### 2.3 selvarajmurugesan90/ops-engineering-skills

- 維護者：Selvaraj Murugesan（個人，API 顯示 2 commits 全為本人）。最後 push：2026-07-28。星數 43，fork 18。Apache-2.0。
- 共 296 個 skill、22 領域。排除工具：全倉零命中（修正誤報後）。
- 逐 skill 分類見附錄：依賴 113、僅為選項 40、未提及 143。其中＊為讀全文後人工判定；其餘為規則分類，規則與限制見附錄前言。

**品質訊號**：296 個全標 `maturity: stable`，2 個 commit 批次提交，無實測紀錄。讀到明顯未經執行的痕跡：`etcd-backup-restore-and-cluster-health` 第 334 行 `ETCDCTL_API3=3`（應為 `ETCDCTL_API=3`）。整體可當清單看，內容不可直接照用。

**全文已讀（Compose、備份還原、部署驗證、事故處理相關，共 19 個）**：

| Skill | K8s | 排除 | 可取內容 | 與現況相比 | 建議 |
|---|---|---|---|---|---|
| database-backup-and-restore-strategies | 未提及 | 否 | 還原到隔離環境、獨立驗資料、記錄實測耗時；操作保留與合規保留分開；絕不直接覆蓋線上 | **現況缺**（MySQL、PostgreSQL 與通用流程） | 採納做法 |
| disaster-recovery-and-backup-strategy | 未提及 | 否 | 備份放在主帳號信任邊界外、不可變；只測「還原」不信任任務成功 | 工具全是 AWS／Azure／GCP，但原則適用 | 採納原則，工具不採納 |
| complete-idp-deployment-with-docker-from-scratch | 僅為選項＊ | 否 | `down -v` 影響整個專案；列出 Compose 缺什麼 | `down -v` 已由第 12、13 條處理；Backstage、Dapr 與「畢業到 K8s」不適用 | 不採納 |
| infrastructure-post-deployment-validation-and-smoke-testing | 僅為選項＊ | 否 | 淺層存活 vs 依賴路徑；重試窗口；失敗後動作要先定 | 現況只寫「核對版本」 | 暫緩（一行可補） |
| cloud-resource-post-provisioning-validation-and-drift-detection | 僅為選項＊ | 否 | `terraform plan -refresh-only`；漂移不自動修 | 現況有 Terraform 預覽，無漂移檢查；單主機效益低 | 暫緩 |
| incident-investigation-using-metrics-logs-traces | 未提及 | 否 | 先定範圍再查日誌；**明確假設並找反證**；對照部署時間線 | 現況有取證與假設，無反證；追蹤與 Loki 部分不適用 | 暫緩（一行可補） |
| incident-response-and-on-call-management | 未提及 | 否 | 明確宣告結束 | 多人值班結構，單人不適用 | 不採納 |
| blameless-postmortem-and-root-cause-analysis | 未提及 | 否 | 至少 2～3 個獨立因素；行動項要有負責人與期限 | `incident-response-commander` 已有複盤模板 | 不採納 |
| operational-runbook-execution-and-escalation | 僅為選項＊ | 否 | 每步驗證；結果與預期不符即停；紀錄偏差 | 現況未規定，但無 runbook 庫 | 暫緩 |
| chatops-runbook-automation | 僅為選項＊ | 否 | 破壞性動作要獨立確認並複述目標 | 依賴 Slack／Teams 與 StackStorm；現況不走 ChatOps | 不採納 |
| emergency-hotfix-deployment-procedure | 未提及 | 否 | 從生產 tag 開分支；不可略過清單（針對性測試、掃描、回滾） | 現況未寫從生產 tag 開分支 | 暫緩 |
| pipeline-failure-triage-and-recovery | 未提及 | 否 | 先分類再重跑 | 通用知識，非現況缺口 | 不採納 |
| critical-vulnerability-emergency-response | 僅為選項＊ | 否 | 先做可立即生效的緩解；檢查暴露期有無被利用 | 依賴 SBOM 與資產清單；個人規模過重 | 暫緩 |
| production-model-rollback-procedure | 未提及 | 否 | 回滾前檢查舊版與現有資料結構相容 | ML 專用；相容性思路可轉用於 migration，但第 22 條已暫緩 | 不採納 |
| blue-green-canary-deployments | 依賴＊ | 否 | expand／contract 遷移 | 全部實作靠 K8s、Argo、Flagger | 不採納 |
| container-runtime-docker-containerd | 依賴＊ | 否 | rootless Docker 指令 | 主題是 K8s 節點執行環境 | 不採納 |
| velero-backup-and-restore | 依賴 | 否 | 先還原到暫存命名空間；排程停擺要告警 | 工具綁 K8s；原則同上 | 不採納 |
| etcd-backup-restore-and-cluster-health | 依賴 | 否 | 快照後立即驗證、送離節點 | 工具綁 K8s | 不採納 |
| kubernetes-cluster-post-provision-conformance-validation | 依賴 | 否 | 無可轉用部分 | 不適用 | 不採納 |

只看命中片段、未讀全文的 Compose 命中：`golden-path-template-validation-and-testing`（6）、`humanitec-score-workload-specification`（7）、`airflow-dag-authoring-and-validation`、`temporal-durable-workflow-orchestration`、`pact-contract-testing-configuration`（各 1）。它們主題不是 Compose，未列入全文範圍。

## 3. B：GitHub 搜尋

**查詢（單一查詢，未用 OR；1 輪 5 個查詢）**：

1. repo：`claude skills docker compose self-hosted`（5 筆）
2. code：`"docker compose" backup restore path:.claude/skills filename:SKILL.md`（375）
3. code：`"Uptime Kuma" filename:SKILL.md`（384）
4. code：`restic "docker compose" filename:SKILL.md`（320）
5. code：`glitchtip filename:SKILL.md`（143）

**選定 3 個**（搜尋結果的星數都很低，選擇依據是內容切題，不是採用度）：

### 3.1 John6810/Ratatoskr（價值最高）

維護者 John6810（個人）。最後 push 2026-10-10。星數 0。AGPL-3.0，**只借做法，不複製文字**。主體是 UNIT3D 的部署範本（含 Helm、Kustomize）；其中 Compose 備份管線可獨立參考。7 個 skill，排除工具零命中。

| Skill | K8s | 全文已讀 | 內容 | 建議 |
|---|---|---|---|---|
| restore-drill | 未提及 | 是，含 `scripts/restore-test.sh`、`docs/backup-restore.md` 大部分 | 取最新快照→在暫存目錄準備→啟臨時資料庫（無網路）→斷言哨兵資料列→結束時一定清理；不碰線上資料；改備份工具前必須演練通過；沒有略過旗標 | **採納做法** |
| docker-build-local | 未提及 | 是 | 獨立專案名與測試覆蓋檔、`up -d --wait`、失敗先收日誌、結束必清理 | 暫緩：改映像時的本地煙霧測試，應用專案需要時再加 |
| helm-lint、kustomize-validate | 依賴 | 否（主題不適用） | | 不採納 |
| prepare-release、sync-readme-versions、check-upstream-versions | 僅為選項 | 否（只看命中） | 版本管理 | 不採納 |

`docs/backup-restore.md` 另有兩點現況沒有：**逐卷區分「可重建」與「必須備份」**（只備不可重建的卷，並寫明其餘怎麼重建）；**金鑰託管**（restic 密碼遺失則所有快照不可讀，不可與備份、`.env` 放在一起）。

### 3.2 MassimilianoPili/claude-code-config

維護者 Massimiliano Pili（個人）。最後 push 2026-06-20。星數 0。無授權條款，不能複製文字。103 個 skill，多數非 dev-ops，只評估兩個；另有 `kubernetes-openshift-patterns`、`portainer-management` 等未讀。

排除工具命中在 `plans/`（提到 Baidu、Tencent、Alibaba 的研究筆記）與 `aws-sdk-java-v2-bedrock` 的模型清單（Alibaba Qwen），看內容都不是工具依賴；讀的兩個 skill 零命中。

| Skill | K8s | 全文已讀 | 內容 | 建議 |
|---|---|---|---|---|
| restic-backup | 未提及 | 是 | 夜間備份、備份前先 `pg_dumpall`、保留策略、`restic check`、卷還原流程 | 暫緩：可當起點，但綁作者主機；「資料檔不可備份」過於絕對；還原步驟 `rm -rf` 線上資料，且未先還原到隔離環境 |
| docker-compose-patterns | 未提及 | 是 | Nginx 用 `resolver 127.0.0.11` 延遲解析，避免上游未啟動就崩潰；bind mount 換 inode 導致設定不生效 | 暫緩：這兩點可測後加入；其餘**不採納**：大量 `latest`、`--auth none`、`INSECURE` 旗標、全部服務共用一個外部網路，與現況固定 tag 與隔離方向相反 |

### 3.3 TMHSDigital/Home-Lab-Developer-Tools

維護者 TMHSDigital（個人）。最後 push 2026-11-02。星數 0。授權 NOASSERTION，不能複製文字。22 個 skill 全部未提及 K8s，排除工具零命中；但全都綁樹莓派與其 50 個 `homelab_*` MCP 工具。

| Skill | 全文已讀 | 內容 | 建議 |
|---|---|---|---|
| docker-compose-stacks | 是 | 分棧目錄；MCP 工具對 up、down、restart 要求 `confirm=true` | 不採納：現況已有 permissions.ask |
| backup-recovery | 是 | 備份範圍清單；SQLite 在寫入中複製可能損壞，要用 `.backup` 或先停容器（**作者稱 Uptime Kuma 用 SQLite，未驗證**） | 暫緩：SQLite 提醒實測後併入 |
| disaster-recovery | 是 | 新機遷移清單（fstab、hostname、DNS） | 暫緩：換主機檢查表可參考 |
| troubleshooting | 是 | 先看日誌再重啟；但也建議除錯前先拉新映像、損壞時刪卷重建 | 不採納：後兩者與現況「先取證」相反 |
| service-monitoring | 是 | Prometheus、Grafana、ntfy 棧 | 不採納：與現況選型不同 |
| 其餘 17 個 | 否（只掃描） | Pi、DNS、憑證等 | 不採納 |

**看到但未選**：`mtgibbs/pi-cluster`（K3s + Flux，描述即依賴 K8s；已克隆未讀全文）；`ericrisco/rsc-harness`（443 星，274 個 skill，`monitoring` 命中 Uptime Kuma，**未讀**，超出 3 個上限，是下一步候選）；`Ismail-Mirza/selfhog`（PostHog 專用，未讀）；GlitchTip 命中多為錯誤分流 skill，未讀。

## 4. 現況缺口

已核對 `CLAUDE-dev-ops.md`、`middleware-ops`（`SKILL.md` 與對 `references/observability.md`、`assets/observability/*.yml`、`README.md`、`CLAUDE.md` 的關鍵字搜尋）。

| 能力 | 現況 | 社區做法 | 建議 |
|---|---|---|---|
| Compose 卷備份與還原 | 無通用流程。`mongodb.md` 有備份與時間點恢復，`redis.md` 有持久化；`observability.md` 與監控 compose 對 `backup|备份|restore|恢复` 零命中，但 `compose.monitor.yml` 有 `pg-data`、`kuma-data`、`beszel-data` | 逐卷分類、邏輯 dump 再送離主機 | 採納 |
| 還原演練 | 只有 `mongodb.md` 一句「定期演练恢复并记录耗时」 | 隔離環境→哨兵斷言→記錄耗時 | 採納 |
| 備份失敗告警 | 無 | 排程停擺要告警（Velero 版的思路）；可對應 Uptime Kuma Push | 採納 |
| 金鑰託管 | `CLAUDE.md` 只管密鑰注入 | 密碼與備份分離 | 採納（一句） |
| 依賴路徑健康檢查 | 只核對版本；`grpc.md` 有健康檢查 | 深層檢查與重試窗口 | 暫緩 |
| 事故找反證 | 有「說明假設」 | 行動前找反證 | 暫緩 |

**建議的實施方式（待決定）**：在 `middleware-ops` 加 `references/backup-restore.md` 與 `SKILL.md` 一行索引，涵蓋 PostgreSQL（GlitchTip 所用）與 Compose 卷，不新增 skill；description 可視情況加「備份」「還原」觸發詞。

- **與第 26 條的關係**：第 26 條是「不寫新 skill，有缺口再寫」。參考檔不是新 skill，但屬新增內容；建議使用者明確同意，或先在階段 3 加一道備份題驗證缺口。
- **寫入門檻**：依 `AGENTS.md`，寫入前要有測試或一手來源。已確認的一手來源：Uptime Kuma README 列有 Push；Docker 文件有「Back up, restore, or migrate data volumes」（`--volumes-from` 方法）；restic 文件有 `read-data`（僅確認字串存在，未通讀）。**備份、還原、Push 告警的實際流程未實測**，應先用暫存 Compose 專案跑通，否則只記入 `docs/plans/` 疑問清單。
- **工具選擇未定**：restic 只是社區常見選擇，不是結論；是否用 restic 或純 dump 加異地複製，由使用者決定。

**Agent 內容衝突（本輪新發現）**：`incident-response-commander.md` 有 10 行 K8s 相關內容，範本的回滾與巡檢用 `kubectl rollout undo`，且設有「Restart」選項；`devops-automator.md` 6 行、`security-engineer.md` 2 行。在 `docs/research/2026-11-plan-b-candidates.md` 與 `docs/handoff/HANDOFF.md` 都未查到對此 agent 的處理紀錄。`CLAUDE.md` 的優先級是否足以蓋過 agent 範本未測。選項：改範本為 Compose 版本（這些 agent 若來自外部同步，會有維護成本，來源未查）、或由階段 3 測驗觀察實際是否輸出 kubectl。

## 5. C：文章

### 5.1 GitHub 無障礙 agent

- **取得**：是，全文（curl HTTP 200，1 次）。之前抽取為空的原因未驗證；本次第一版解析器在正文中途停止，改為依標題定位到「Written by」前才完整。文中「ordered phases」的內容是圖片，未取得。
- **核心做法**：兩個隔離子代理（只審查的 reviewer、只實作的 implementer），不直接溝通，以結構化模板交給父代理驗證與分派；固定順序的階段與步驟；複雜度腳本打分，超過閾值就不改碼、轉介人工；高風險模式清單（拖放、toast、富文本、樹狀、資料表格）禁止生成；有防止繞過禁令的指令；以團隊歷史 issue 與對應 PR 當參考資料；定期人工審輸出。作者自述 3,535 個 PR、68% 解決率。
- **對應問題**：前端 skill 未被調用與 agent 過度行動；(a)、(d) 判斷題。
- **與既有決策**：第 25 條「加 skill 無益」不衝突，本文也指出模糊的 skill 檔沒用。第 27 條不加 hook 不衝突，本文是專職 agent 的結構，且數據為自述。`CLAUDE-frontend-dev.md` 對 `a11y|accessib|无障碍` 零命中。
- **建議**：暫緩；若前端要加無障礙要求，先考慮「高風險元件不自行生成，先告知」一行，並記入疑問清單。「確定性腳本決定是否放行」比提示文字可靠，值得在第 26 條重評時參考。

### 5.2 builtbyzac「Scope management…」

- **取得**：**否**。原網址 404；作者頁 404；dev.to API `articles?username=` 回傳空陣列，`users/by_username` 回傳 404；archive.org 只有 2026-03-19 的一筆 404 快照。CDX 顯示作者頁 2026-03-17 還是 200，3 月 19 日多篇已 404，帳號疑似已移除（推論）。
- **替代**：同作者 `how-to-stop-claude-from-doing-more-than-you-asked-4io7`（archive.org 2026-03-17 快照，200，約 600 字）。**這不是原文，不能當原文內容引用。**
- **替代文核心做法**：`CLAUDE.md` 放常駐的「minimal footprint」指令：只改必要處，不重構鄰近程式碼；範圍外的改進列為建議，不實作。要點是給它一個放建議的出口；大範圍任務再明確覆蓋。
- **對應問題**：D-1、F-4、(a) 範圍外改動。
- **與既有決策**：與第 27 條一致，未提供效果數據，不足以改變決定。`CLAUDE-frontend-dev.md`「改動範圍」已寫「不做未要求的改動」「有用的想法放到最後提出」，等於已有此出口；其他場景未逐一核對。
- **來源可信度**：同作者其他標題有「I'm an AI agent trying to make $100…」，作者可能是實驗中的 AI agent（僅依標題，未驗證），不宜作為依據。

### 5.3 Chaayush Malik（Medium）

- **取得**：是，全文約 790 字。來源是 Medium 官方公開 RSS（`https://medium.com/feed/@chaayushmalik`），未碰防護；archive.org 無此文快照。發表於 2026-06-14。
- **核心做法**：用 Claude Code 做可視原型對齊願景；PRD 與原型互補（原型講方向，PRD 記驗收、緣由、非目標），並有內部 PRD skill；由 PRD 生成發布公告初稿；串 GDocs、Slack、JIRA 作上下文（搜 issue、整理 backlog、季度算 KTLO 比例）；自由書寫後讓 Claude 質疑假設。
- **對應問題**：prd-design 場景對標；無失敗案例或量化數據。
- **與既有決策**：與第 20、21 條方向一致，現況 `CLAUDE-prd-design.md` 已有原型驗證假設、驗收標準。可新增的只有「非目標」與「發布公告」：`非目标`、`non-goal` 在現況零命中（只查了這兩個詞，未逐節核對同義寫法）。JIRA、Slack 不是現行工具鏈。
- **建議**：不採納為配置；可在階段 3 看 PRD 產出是否缺非目標，再決定是否加一行。

## 6. 邊界

**已驗證**：倉庫元資料（API）；讀過全文的 skill 內容；排除工具掃描（含命中內容）；現況關鍵字搜尋；Kuma Push、Docker 卷備份章節、restic `read-data` 字串存在；文章 1、3 全文。

**未驗證**：所有社區 skill 的做法與數字；Uptime Kuma 使用 SQLite；selvaraj 附錄中規則分類的 skill；`CLAUDE.md` 能否蓋過 agent 範本。

**未做或未取得**：

- builtbyzac 原文未取得。
- selvaraj 的 277 個 skill 未讀全文：規則分類；低密度的只看第一個命中，高密度的未逐一看命中。
- sanjay 的 `azure-devops`、`atlassian` 等只掃描；mysql、mssql 腳本未讀。
- Ratatoskr `docs/backup-restore.md` 第 200 行後只讀了雲端後端、還原演練與部分注意事項，未通讀。
- `ericrisco/rsc-harness` 的 monitoring 未讀；GitHub 搜尋只做 1 輪（要求 1～2 輪）。
- 未實測任何備份流程；agent 範本來源未查。

**下一步（待使用者決定）**：是否實測並新增 `references/backup-restore.md`；如何處理 agent 的 kubectl 範本。

## 附錄：selvaraj 逐 skill 分類

規則：屬 `kubernetes-platform`、`gitops-argo-ecosystem`，或名稱含 K8s 生態詞，或命中密度 ≥ 2%，或 frontmatter 提及且 ≥ 3 行命中，判「依賴」；其餘有命中判「選項」；零命中判「未提及」。＊為讀全文後人工判定。限制：規則可能把「多處舉例」誤判為依賴，也不偵測 `pod`、`namespace` 等詞。全倉排除工具零命中，故不另列欄位。命中數為含關鍵字的行數。

| 領域 | Skill | K8s 命中行 | 分類 |
|---|---|---|---|
| ai-agent | agent-architecture-design | 0 | 未提及 |
| ai-agent | agent-bad-response-triage-and-root-cause-classification | 0 | 未提及 |
| ai-agent | agent-cost-and-latency-spike-investigation | 0 | 未提及 |
| ai-agent | agent-evaluation-and-guardrails | 0 | 未提及 |
| ai-agent | agent-tool-call-loop-diagnosis-and-circuit-breaking | 0 | 未提及 |
| ai-agent | agent-tool-use-patterns | 0 | 未提及 |
| ai-agent | code-knowledge-graph-tools-for-ai-agents | 0 | 未提及 |
| ai-agent | complete-ai-agent-stack-deployment-cloud-managed-from-scratch | 0 | 未提及 |
| ai-agent | complete-ai-agent-stack-deployment-self-hosted-from-scratch | 8 | 依賴 |
| ai-agent | crewai-and-autogen-multi-agent-frameworks | 0 | 未提及 |
| ai-agent | langchain-and-langgraph-agent-orchestration | 0 | 未提及 |
| ai-agent | llm-cost-and-latency-optimization | 0 | 未提及 |
| ai-agent | llm-gateway-and-multi-provider-routing | 0 | 未提及 |
| ai-agent | mcp-server-development | 0 | 未提及 |
| ai-agent | multi-agent-orchestration | 0 | 未提及 |
| ai-agent | prompt-and-context-engineering | 0 | 未提及 |
| ai-agent | rag-pipeline-design | 0 | 未提及 |
| ai-agent | vector-database-configuration-validation | 0 | 未提及 |
| ai-agent | vector-database-ingestion-pipeline-for-rag | 0 | 未提及 |
| ai-agent | vector-database-operations-pinecone-weaviate-milvus | 0 | 未提及 |
| cicd-tooling | aws-codepipeline-and-codedeploy | 0 | 未提及 |
| cicd-tooling | azure-pipelines-yaml-and-multi-stage | 1 | 選項 |
| cicd-tooling | bamboo-pipeline-yaml-and-java-specs | 0 | 未提及 |
| cicd-tooling | complete-cicd-pipeline-deployment-for-kubernetes-from-scratch | 15 | 依賴 |
| cicd-tooling | complete-cicd-pipeline-deployment-for-serverless-from-scratch | 10 | 依賴 |
| cicd-tooling | complete-cicd-pipeline-for-vm-based-workloads-from-scratch | 7 | 選項＊ |
| cicd-tooling | gitea-actions-and-ci | 0 | 未提及 |
| cicd-tooling | github-actions-centralized-reusable-workflows | 0 | 未提及 |
| cicd-tooling | github-actions-single-repo-workflows | 0 | 未提及 |
| cicd-tooling | gitlab-cicd-pipeline-design | 1 | 選項 |
| cicd-tooling | jenkins-centralized-shared-library | 0 | 未提及 |
| cicd-tooling | jenkins-declarative-pipeline-per-repo | 0 | 未提及 |
| cicd-tooling | jenkins-groovy-scripting-best-practices | 0 | 未提及 |
| cloud | aws-landing-zone-setup | 0 | 未提及 |
| cloud | azure-landing-zone-setup | 0 | 未提及 |
| cloud | cloud-access-request-and-iam-lifecycle-management | 0 | 未提及 |
| cloud | cloud-cost-anomaly-investigation | 0 | 未提及 |
| cloud | cloud-cost-finops-optimization | 3 | 選項 |
| cloud | cloud-iam-hardening | 0 | 未提及 |
| cloud | cloud-native-storage-strategy | 0 | 未提及 |
| cloud | cloud-resource-post-provisioning-validation-and-drift-detection | 1 | 選項＊ |
| cloud | disaster-recovery-and-backup-strategy | 0 | 未提及 |
| cloud | gcp-landing-zone-setup | 1 | 選項 |
| cloud | multi-cloud-networking-patterns | 0 | 未提及 |
| cloud | oci-landing-zone-setup | 0 | 未提及 |
| cloud | on-prem-infrastructure-patterns | 0 | 未提及 |
| cloud | orphaned-cloud-resource-cleanup | 0 | 未提及 |
| database-operations | arangodb-multi-model-database-operations | 0 | 未提及 |
| database-operations | cassandra-wide-column-database-operations | 0 | 未提及 |
| database-operations | clickhouse-analytical-database-operations | 0 | 未提及 |
| database-operations | cloud-data-warehouse-operations-snowflake-bigquery-redshift | 0 | 未提及 |
| database-operations | database-backup-and-restore-strategies | 0 | 未提及 |
| database-operations | database-connection-pooling-strategies | 0 | 未提及 |
| database-operations | database-schema-migration-with-liquibase-and-flyway | 0 | 未提及 |
| database-operations | elasticsearch-opensearch-cluster-operations | 0 | 未提及 |
| database-operations | elasticsearch-opensearch-configuration-validation | 0 | 未提及 |
| database-operations | liquibase-advanced-changelog-management-and-rollback-strategies | 0 | 未提及 |
| database-operations | mongodb-configuration-validation | 0 | 未提及 |
| database-operations | mongodb-operations-and-scaling | 0 | 未提及 |
| database-operations | mysql-mariadb-configuration-validation | 0 | 未提及 |
| database-operations | mysql-mariadb-high-availability-and-replication | 0 | 未提及 |
| database-operations | mysql-mariadb-operations-and-performance-tuning | 0 | 未提及 |
| database-operations | neo4j-graph-database-operations | 0 | 未提及 |
| database-operations | postgresql-configuration-validation | 0 | 未提及 |
| database-operations | postgresql-high-availability-and-failover | 0 | 未提及 |
| database-operations | postgresql-operations-and-performance-tuning | 0 | 未提及 |
| database-operations | redis-caching-strategy-and-invalidation-patterns | 0 | 未提及 |
| database-operations | redis-configuration-validation | 0 | 未提及 |
| database-operations | redis-operations-and-cluster-management | 0 | 未提及 |
| database-operations | timescaledb-time-series-operations-and-configuration | 0 | 未提及 |
| devops | artifact-and-dependency-management | 0 | 未提及 |
| devops | blue-green-canary-deployments | 8 | 依賴＊ |
| devops | ci-access-and-credential-lifecycle-management | 0 | 未提及 |
| devops | ci-cd-pipeline-design | 0 | 未提及 |
| devops | container-build-and-release | 0 | 未提及 |
| devops | devops-delivery-metrics-and-dora-analysis | 0 | 未提及 |
| devops | emergency-hotfix-deployment-procedure | 0 | 未提及 |
| devops | environment-promotion-strategy | 1 | 選項 |
| devops | gitops-workflow | 13 | 依賴 |
| devops | infrastructure-as-code-terraform | 1 | 選項 |
| devops | jfrog-artifactory-configuration | 0 | 未提及 |
| devops | merge-queue-and-trunk-based-development-configuration | 0 | 未提及 |
| devops | pipeline-failure-triage-and-recovery | 0 | 未提及 |
| devops | release-versioning-and-changelog-automation | 0 | 未提及 |
| devops | sonatype-nexus-repository-configuration | 0 | 未提及 |
| devops | terraform-cloud-and-spacelift-iac-orchestration-platforms | 1 | 選項 |
| devsecops | checkov-and-tfsec-iac-security-scanning | 4 | 依賴 |
| devsecops | complete-devsecops-pipeline-for-kubernetes-from-scratch | 21 | 依賴 |
| devsecops | complete-devsecops-pipeline-for-serverless-from-scratch | 9 | 依賴 |
| devsecops | complete-devsecops-pipeline-for-vm-based-workloads-from-scratch | 9 | 依賴 |
| devsecops | container-image-hardening | 15 | 依賴 |
| devsecops | critical-vulnerability-emergency-response | 3 | 選項＊ |
| devsecops | dast-integration | 0 | 未提及 |
| devsecops | policy-as-code-guardrails | 17 | 依賴 |
| devsecops | sast-integration | 0 | 未提及 |
| devsecops | secrets-management | 7 | 依賴 |
| devsecops | secure-cicd-gates | 0 | 未提及 |
| devsecops | security-finding-backlog-triage | 0 | 未提及 |
| devsecops | security-gate-exception-management | 0 | 未提及 |
| devsecops | security-posture-metrics-and-trend-analysis | 0 | 未提及 |
| devsecops | snyk-vulnerability-and-license-scanning | 4 | 選項 |
| devsecops | software-composition-analysis-sca | 0 | 未提及 |
| devsecops | supply-chain-security-slsa-sbom | 2 | 選項 |
| enterprise-collaboration | confluence-page-authoring-and-governance | 0 | 未提及 |
| enterprise-collaboration | jira-comments-and-tracking-automation | 0 | 未提及 |
| enterprise-collaboration | jira-ticket-best-practices-and-workflow | 0 | 未提及 |
| gitops-argo-ecosystem | argo-events-and-event-driven-automation | 13 | 依賴 |
| gitops-argo-ecosystem | argo-rollouts-progressive-delivery | 22 | 依賴 |
| gitops-argo-ecosystem | argo-workflows-pipeline-design | 5 | 依賴 |
| gitops-argo-ecosystem | argocd-application-configuration | 11 | 依賴 |
| gitops-argo-ecosystem | argocd-applicationset-patterns | 11 | 依賴 |
| gitops-argo-ecosystem | argocd-sync-failure-and-drift-investigation | 24 | 依賴 |
| gitops-argo-ecosystem | complete-gitops-argocd-deployment-on-aks-from-scratch | 60 | 依賴 |
| gitops-argo-ecosystem | complete-gitops-argocd-deployment-on-eks-from-scratch | 71 | 依賴 |
| gitops-argo-ecosystem | complete-gitops-argocd-deployment-on-gke-from-scratch | 55 | 依賴 |
| gitops-argo-ecosystem | complete-gitops-argocd-deployment-on-prem-from-scratch | 51 | 依賴 |
| gitops-argo-ecosystem | gitops-multi-cluster-management | 12 | 依賴 |
| iac-and-automation-tooling | ansible-playbook-and-role-design | 0 | 未提及 |
| iac-and-automation-tooling | aws-cloudformation-templates | 0 | 未提及 |
| iac-and-automation-tooling | chef-puppet-saltstack-legacy-config-management | 0 | 未提及 |
| iac-and-automation-tooling | feature-flag-configuration-launchdarkly-and-unleash | 1 | 選項 |
| iac-and-automation-tooling | gremlin-chaos-engineering-configuration | 12 | 依賴 |
| iac-and-automation-tooling | infrastructure-post-deployment-validation-and-smoke-testing | 2 | 選項＊ |
| iac-and-automation-tooling | makefile-authoring-and-validation | 1 | 選項 |
| iac-and-automation-tooling | openfeature-vendor-neutral-feature-flag-standard | 0 | 未提及 |
| iac-and-automation-tooling | pact-configuration-validation | 0 | 未提及 |
| iac-and-automation-tooling | pact-contract-testing-configuration | 0 | 未提及 |
| iac-and-automation-tooling | python-automation-scripting-for-ops | 0 | 未提及 |
| iac-and-automation-tooling | shell-scripting-best-practices | 0 | 未提及 |
| iac-and-automation-tooling | terragrunt-configuration-and-dry-run-validation | 0 | 未提及 |
| iac-and-automation-tooling | testcontainers-integration-testing-configuration | 0 | 未提及 |
| incident-tooling-and-itsm | chatops-runbook-automation | 5 | 選項＊ |
| incident-tooling-and-itsm | linear-issue-tracking-best-practices | 0 | 未提及 |
| incident-tooling-and-itsm | pagerduty-and-opsgenie-oncall-configuration | 0 | 未提及 |
| incident-tooling-and-itsm | pagerduty-opsgenie-configuration-validation | 0 | 未提及 |
| incident-tooling-and-itsm | servicenow-itsm-configuration-validation | 0 | 未提及 |
| incident-tooling-and-itsm | servicenow-itsm-integration | 0 | 未提及 |
| internal-developer-platform | backstage-plugin-development | 1 | 選項 |
| internal-developer-platform | complete-idp-deployment-on-aws-from-scratch | 29 | 依賴 |
| internal-developer-platform | complete-idp-deployment-on-azure-from-scratch | 26 | 依賴 |
| internal-developer-platform | complete-idp-deployment-on-gcp-from-scratch | 29 | 依賴 |
| internal-developer-platform | complete-idp-deployment-on-k3s-from-scratch | 34 | 依賴 |
| internal-developer-platform | complete-idp-deployment-on-kubernetes-from-scratch | 40 | 依賴 |
| internal-developer-platform | complete-idp-deployment-on-oci-from-scratch | 13 | 依賴 |
| internal-developer-platform | complete-idp-deployment-on-prem-from-scratch | 23 | 依賴 |
| internal-developer-platform | complete-idp-deployment-with-docker-from-scratch | 37 | 選項＊ |
| internal-developer-platform | developer-experience-measurement-and-platform-adoption | 0 | 未提及 |
| internal-developer-platform | golden-path-template-design-for-developer-platforms | 0 | 未提及 |
| internal-developer-platform | golden-path-template-validation-and-testing | 1 | 選項 |
| internal-developer-platform | humanitec-score-configuration-validation | 3 | 選項 |
| internal-developer-platform | humanitec-score-workload-specification | 12 | 依賴 |
| internal-developer-platform | idp-adoption-rollout-and-change-management-strategy | 0 | 未提及 |
| internal-developer-platform | multi-tenancy-and-team-workspace-design-for-idp | 20 | 依賴 |
| internal-developer-platform | no-code-idp-service-catalog-tools-port-cortex-opslevel | 0 | 未提及 |
| internal-developer-platform | platform-engineering-team-topology-and-operating-model | 0 | 未提及 |
| internal-developer-platform | platform-self-service-api-and-workflow-design | 0 | 未提及 |
| internal-developer-platform | service-scorecards-and-maturity-model-design | 0 | 未提及 |
| kubernetes-platform | cert-manager-tls-automation | 25 | 依賴 |
| kubernetes-platform | cni-networking-calico-flannel | 37 | 依賴 |
| kubernetes-platform | complete-kubernetes-deployment-on-aks-from-scratch | 68 | 依賴 |
| kubernetes-platform | complete-kubernetes-deployment-on-eks-from-scratch | 67 | 依賴 |
| kubernetes-platform | complete-kubernetes-deployment-on-gke-from-scratch | 68 | 依賴 |
| kubernetes-platform | complete-kubernetes-deployment-on-oke-oci-from-scratch | 48 | 依賴 |
| kubernetes-platform | complete-kubernetes-deployment-on-prem-with-kubeadm-from-scratch | 55 | 依賴 |
| kubernetes-platform | complete-kubernetes-deployment-with-k3s-from-scratch | 103 | 依賴 |
| kubernetes-platform | container-runtime-docker-containerd | 40 | 依賴＊ |
| kubernetes-platform | crossplane-configuration-validation | 17 | 依賴 |
| kubernetes-platform | crossplane-kubernetes-native-provisioning | 35 | 依賴 |
| kubernetes-platform | etcd-backup-restore-and-cluster-health | 34 | 依賴 |
| kubernetes-platform | flux-cd-configuration-and-reconciliation | 18 | 依賴 |
| kubernetes-platform | flux-cd-configuration-validation | 22 | 依賴 |
| kubernetes-platform | helm-chart-authoring | 71 | 依賴 |
| kubernetes-platform | ingress-nginx-configuration | 40 | 依賴 |
| kubernetes-platform | keda-configuration-validation | 20 | 依賴 |
| kubernetes-platform | keda-event-driven-autoscaling-configuration | 10 | 依賴 |
| kubernetes-platform | kubernetes-cluster-post-provision-conformance-validation | 41 | 依賴 |
| kubernetes-platform | kubernetes-cluster-provisioning-with-kubeadm-and-cluster-api | 46 | 依賴 |
| kubernetes-platform | kubernetes-node-maintenance-and-troubleshooting | 50 | 依賴 |
| kubernetes-platform | kubernetes-operator-development | 27 | 依賴 |
| kubernetes-platform | kubernetes-service-connectivity-troubleshooting | 41 | 依賴 |
| kubernetes-platform | kustomize-overlay-management | 42 | 依賴 |
| kubernetes-platform | lightweight-kubernetes-k3s | 79 | 依賴 |
| kubernetes-platform | longhorn-storage-configuration | 29 | 依賴 |
| kubernetes-platform | managed-kubernetes-eks-aks-gke | 48 | 依賴 |
| kubernetes-platform | metallb-bare-metal-load-balancer-configuration | 20 | 依賴 |
| kubernetes-platform | metallb-configuration-validation | 19 | 依賴 |
| kubernetes-platform | openshift-and-rosa-platform | 23 | 依賴 |
| kubernetes-platform | pod-crashloop-and-oom-troubleshooting | 34 | 依賴 |
| kubernetes-platform | rook-ceph-configuration-validation | 35 | 依賴 |
| kubernetes-platform | rook-ceph-storage-operations | 41 | 依賴 |
| kubernetes-platform | service-mesh-istio | 13 | 依賴 |
| kubernetes-platform | testkube-kubernetes-native-test-execution | 23 | 依賴 |
| messaging-and-data-orchestration | airflow-dag-authoring-and-validation | 2 | 選項 |
| messaging-and-data-orchestration | airflow-scheduler-and-dag-troubleshooting | 9 | 依賴 |
| messaging-and-data-orchestration | dagster-and-prefect-pipeline-authoring | 0 | 未提及 |
| messaging-and-data-orchestration | kafka-cluster-configuration | 0 | 未提及 |
| messaging-and-data-orchestration | kafka-configuration-validation | 0 | 未提及 |
| messaging-and-data-orchestration | kafka-consumer-lag-and-partition-troubleshooting | 0 | 未提及 |
| messaging-and-data-orchestration | kafka-schema-registry-and-compatibility-management | 0 | 未提及 |
| messaging-and-data-orchestration | nats-and-pulsar-lightweight-messaging-configuration | 0 | 未提及 |
| messaging-and-data-orchestration | rabbitmq-configuration | 0 | 未提及 |
| messaging-and-data-orchestration | rabbitmq-configuration-validation | 0 | 未提及 |
| messaging-and-data-orchestration | rabbitmq-queue-and-dead-letter-troubleshooting | 0 | 未提及 |
| messaging-and-data-orchestration | temporal-configuration-validation | 2 | 選項 |
| messaging-and-data-orchestration | temporal-durable-workflow-orchestration | 1 | 選項 |
| mlops | complete-mlops-platform-deployment-on-aws-from-scratch | 32 | 依賴 |
| mlops | complete-mlops-platform-deployment-on-azure-from-scratch | 23 | 依賴 |
| mlops | complete-mlops-platform-deployment-on-gcp-from-scratch | 22 | 依賴 |
| mlops | complete-mlops-platform-deployment-self-hosted-k8s-from-scratch | 35 | 依賴 |
| mlops | data-and-model-lineage | 0 | 未提及 |
| mlops | data-catalog-and-lineage-governance-datahub-amundsen | 2 | 選項 |
| mlops | experiment-tracking | 0 | 未提及 |
| mlops | feature-pipeline-failure-investigation | 0 | 未提及 |
| mlops | feature-store-design | 0 | 未提及 |
| mlops | gpu-accelerator-configuration-validation | 23 | 依賴 |
| mlops | gpu-accelerator-infrastructure-for-ml-training | 27 | 依賴 |
| mlops | kubeflow-ml-pipeline-orchestration | 10 | 依賴 |
| mlops | llmops-fine-tuning-and-deployment | 0 | 未提及 |
| mlops | mlflow-experiment-tracking-and-model-registry | 0 | 未提及 |
| mlops | model-drift-alert-triage | 0 | 未提及 |
| mlops | model-monitoring-and-drift-detection | 0 | 未提及 |
| mlops | model-packaging-and-versioning | 0 | 未提及 |
| mlops | model-serving-and-scaling | 3 | 選項 |
| mlops | production-model-rollback-procedure | 0 | 未提及 |
| mlops | ray-distributed-ml-orchestration | 22 | 依賴 |
| mlops | training-pipeline-orchestration | 0 | 未提及 |
| mlops | weights-and-biases-experiment-tracking | 0 | 未提及 |
| observability-and-platform-extras | backstage-developer-portal | 5 | 選項 |
| observability-and-platform-extras | distributed-tracing-with-tempo-and-jaeger | 0 | 未提及 |
| observability-and-platform-extras | fluent-bit-configuration-validation | 10 | 依賴 |
| observability-and-platform-extras | fluent-bit-log-forwarding-configuration | 27 | 依賴 |
| observability-and-platform-extras | incident-investigation-using-metrics-logs-traces | 0 | 未提及 |
| observability-and-platform-extras | karpenter-cluster-autoscaling | 24 | 依賴 |
| observability-and-platform-extras | kubecost-cost-visibility | 23 | 依賴 |
| observability-and-platform-extras | kubernetes-network-policy-zero-trust | 35 | 依賴 |
| observability-and-platform-extras | logql-query-authoring | 0 | 未提及 |
| observability-and-platform-extras | loki-configuration-validation | 6 | 選項 |
| observability-and-platform-extras | loki-log-aggregation-configuration | 7 | 選項 |
| observability-and-platform-extras | opentelemetry-configuration-validation | 5 | 選項 |
| observability-and-platform-extras | opentelemetry-instrumentation-and-collector-configuration | 1 | 選項 |
| observability-and-platform-extras | prometheus-and-grafana-monitoring-stack | 15 | 依賴 |
| observability-and-platform-extras | promql-query-authoring | 0 | 未提及 |
| observability-and-platform-extras | velero-backup-and-restore | 14 | 依賴 |
| policy-and-governance-tooling | fairwinds-polaris-and-goldilocks | 25 | 依賴 |
| policy-and-governance-tooling | kyverno-policy-management | 24 | 依賴 |
| policy-and-governance-tooling | opa-gatekeeper-policy-authoring | 15 | 依賴 |
| role-based-engineering-practices | independent-solution-design-and-technical-review | 0 | 未提及 |
| role-based-engineering-practices | operational-runbook-execution-and-escalation | 3 | 選項＊ |
| role-based-engineering-practices | system-design-technology-selection-and-decision-records | 3 | 選項 |
| role-based-engineering-practices | technical-roadmap-ownership-and-cross-team-coordination | 0 | 未提及 |
| security-scanning-tooling | certificate-lifecycle-management-at-scale | 24 | 依賴 |
| security-scanning-tooling | enterprise-sso-and-idp-federation-configuration | 1 | 選項 |
| security-scanning-tooling | falco-configuration-validation | 9 | 依賴 |
| security-scanning-tooling | falco-runtime-threat-detection-configuration | 18 | 依賴 |
| security-scanning-tooling | fortify-static-analysis | 0 | 未提及 |
| security-scanning-tooling | kubewarden-admission-policy-configuration | 24 | 依賴 |
| security-scanning-tooling | owasp-zap-dast-configuration | 0 | 未提及 |
| security-scanning-tooling | prisma-cloud-cspm-and-workload-protection | 8 | 依賴 |
| security-scanning-tooling | sealed-secrets-and-external-secrets-operator | 34 | 依賴 |
| security-scanning-tooling | sonarqube-code-quality-and-security | 0 | 未提及 |
| security-scanning-tooling | spiffe-spire-workload-identity-configuration | 20 | 依賴 |
| security-scanning-tooling | sysdig-secure-runtime-security | 21 | 依賴 |
| security-scanning-tooling | trivy-vulnerability-scanning | 10 | 依賴 |
| security-scanning-tooling | vault-configuration-validation | 8 | 依賴 |
| security-scanning-tooling | vault-operations-and-pki-engine-configuration | 5 | 選項 |
| serverless-and-alternative-compute | aws-lambda-configuration-validation | 1 | 選項 |
| serverless-and-alternative-compute | aws-lambda-packaging-and-configuration | 0 | 未提及 |
| serverless-and-alternative-compute | azure-functions-configuration | 0 | 未提及 |
| serverless-and-alternative-compute | dapr-configuration-validation | 16 | 依賴 |
| serverless-and-alternative-compute | dapr-distributed-runtime-configuration | 13 | 依賴 |
| serverless-and-alternative-compute | google-cloud-functions-configuration | 1 | 選項 |
| serverless-and-alternative-compute | hashicorp-nomad-scheduling-and-configuration | 20 | 依賴 |
| serverless-and-alternative-compute | knative-configuration-validation | 16 | 依賴 |
| serverless-and-alternative-compute | knative-eventing-configuration | 4 | 依賴 |
| serverless-and-alternative-compute | knative-serverless-configuration | 17 | 依賴 |
| service-mesh-and-api-gateway | api-gateway-rate-limiting-and-quota-management | 1 | 選項 |
| service-mesh-and-api-gateway | apigee-api-management-and-governance | 1 | 選項 |
| service-mesh-and-api-gateway | cilium-configuration-validation | 17 | 依賴 |
| service-mesh-and-api-gateway | cilium-ebpf-cni-and-mesh-configuration | 13 | 依賴 |
| service-mesh-and-api-gateway | consul-configuration-validation | 14 | 依賴 |
| service-mesh-and-api-gateway | consul-service-mesh-and-discovery-configuration | 21 | 依賴 |
| service-mesh-and-api-gateway | grpc-service-troubleshooting | 9 | 依賴 |
| service-mesh-and-api-gateway | kong-api-gateway-configuration | 12 | 依賴 |
| service-mesh-and-api-gateway | kong-configuration-validation | 13 | 依賴 |
| service-mesh-and-api-gateway | linkerd-configuration-validation | 13 | 依賴 |
| service-mesh-and-api-gateway | linkerd-service-mesh-configuration | 18 | 依賴 |
| site-reliability-engineering | blameless-postmortem-and-root-cause-analysis | 0 | 未提及 |
| site-reliability-engineering | capacity-planning-and-load-testing | 0 | 未提及 |
| site-reliability-engineering | chaos-engineering-and-resilience-testing | 1 | 選項 |
| site-reliability-engineering | incident-response-and-on-call-management | 0 | 未提及 |
| site-reliability-engineering | slo-sli-and-error-budget-design | 0 | 未提及 |
| site-reliability-engineering | toil-reduction-and-operational-automation | 3 | 選項 |
| standards-and-compliance-frameworks | cis-benchmarks-hardening | 23 | 依賴 |
| standards-and-compliance-frameworks | cloud-well-architected-framework-review | 0 | 未提及 |
| standards-and-compliance-frameworks | owasp-top-10-secure-coding-standards | 0 | 未提及 |
| standards-and-compliance-frameworks | security-compliance-mapping-soc2-iso-pci-nist | 0 | 未提及 |
