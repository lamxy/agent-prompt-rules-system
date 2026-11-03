# Go 資料庫遷移工具調研（backend-dev）

調研日期 2026-11-03。實測環境：mysql:8.0（實際 8.0.46，sql_mode 含 STRICT_TRANS_TABLES）、goose v3.29.0、golang-migrate v4.20.1，linux/arm64。
實測腳本與原始輸出：同目錄 `go-migrations-lab/`（`scripts/`、`m/`、`out/`；`bin/` 與 Go 快取未入庫）。腳本內的 `fake-test-pass` 是臨時容器的測試密碼。下文 G1、M1、C1、L1、V1 等編號對應 `out/` 內的情境。

## 結論

**第 22 條建議拆成三部分，不再整條暫緩。** 原暫緩理由「單一作者、PostgreSQL、MySQL 未實測」已有一部分不成立：schema 比對與行數比對在 MySQL 上實測可行，golang-migrate 與 Atlas 官方文件也有相近建議。

| 部分 | 建議 | 依據 |
|---|---|---|
| up、down 後 schema 比對；前後行數比對；帶種子資料試跑 | 寫入 `db-schema-design` skill（不新建 skill） | C1 至 C8 |
| 半途失敗、一個檔案一條 DDL、明寫 ALGORITHM | 寫入 `rules/database/mysql.md` | G1 至 G3、M1、L1 至 L5、V2 |
| 接近線上規模、脫敏快照的影子庫試跑 | **維持暫緩** | 本次僅 26 萬行、tmpfs、無複製、無線上流量 |

**工具不指定。** FiberHouse 的 `go.mod` 只有 GORM 與 MySQL 驅動，沒有遷移工具；skill 已要求先確認專案現有工具。三者取捨見第 1 節，是否給新專案設預設值由使用者決定。

## 1. 工具比較

| 項目 | goose v3.29.0 | golang-migrate v4.20.1 | Atlas（只讀文件，未實測） |
|---|---|---|---|
| MySQL | 支援（README） | 支援（`database/mysql/README.md`） | 支援（`skills/atlas-mysql/SKILL.md`） |
| down | 同檔 `-- +goose Down`，可選 | 獨立 `.down.sql`，官方「strongly recommended」 | `migrate down` 依資料庫現況計算；`cmdapi.go` 的提示文字說社群版缺 down |
| dry-run / plan | 無；`-dry-run` 報 `flag provided but not defined`（實測） | 無；`-help` 沒有此選項（實測） | `migrate apply --dry-run`（官方 skill） |
| lint | 無；`goose -dir X validate` 只查解析（V1：含不存在資料表的檔案也 exit 0） | 無 | `migrate lint`，有 MY1xx、DS10x；需 `atlas login`；lint 頁稱 v0.38 起僅限 Pro（文件互有出入，見下） |
| 測試 | 無內建 | 無內建，文件建議 up、down、再 up，並用容器 | `migrate test`，需登入 |
| 失敗狀態記錄 | **無**，只是不寫版本 | **dirty 旗標** | 記錄已執行語句數，下次從失敗語句續跑（`sql/migrate/migrate.go`） |
| 續跑 | 從檔案開頭重跑 | 拒絕，先 `force` | 續跑；可 `migrate down` 復原 |
| DML 失敗回滾 | 預設包交易，實測回滾（G4） | 不包交易，實測留下部分結果（M3） | 未實測 |
| 多語句 | 自行切分逐條送出；DSN 沒有 `multiStatements` 也能跑（G5），與 README「must be enabled」不符 | 驅動強制 `config.MultiStatements = true`（`mysql.go`）；自帶連線才需手動設 | 逐條執行並記錄 |
| 併發鎖 | `lock/mysql.go` 有 `NewMySQLTableLocker`（需用 Provider API，未實測） | `GET_LOCK`（`mysql.go`） | `GET_LOCK`（官方 skill，未細讀） |
| 內嵌到 Go 程式 | `embed` 範例（README） | `WithInstance` 範例（README） | CLI 為主；本次未查 Go 內嵌 |

補充：

- **Atlas 授權分界是採用前最大的未知數。** 官方 skill 寫「Lint, custom rules, and seed data need `atlas login`」；`/features` 頁（WebFetch 摘要）又稱社群版有基本 lint。實際門檻要裝起來才能確認，已列入待驗證。
- **sqlc**：「does not perform database migrations」，但能解析 goose、golang-migrate、atlas 等目錄並忽略 down（`docs.sqlc.dev/en/latest/howto/ddl.html`，WebFetch 摘要）。它與遷移工具的選擇互不衝突。
- **GORM AutoMigrate**：會建立表、外鍵、索引，改欄位大小；「WON'T delete unused columns」（`gorm.io/docs/migration.html`，WebFetch 摘要）。沒有版本記錄和 down，與現有規則「不用 AutoMigrate 管理线上表结构」一致。
- **與 FiberHouse 的整合**：框架沒有遷移機制。`go.mod` 無遷移工具；`CLAUDE.md`、`AGENTS.md` 搜不到 migration 相關內容；GitHub code search 回傳 0（該倉庫可能未被索引，不算否定證據）。可掛接處是 `CommandStarter` 與 `example_application/command/`（框架已有命令列應用形態），但**我沒有寫過也沒有跑過這種整合**，只是從介面判斷，不寫入配置。

出處：
[goose README](https://github.com/pressly/goose/blob/main/README.md)、[goose provider_run.go](https://github.com/pressly/goose/blob/main/provider_run.go)、[goose lock/mysql.go](https://github.com/pressly/goose/blob/main/lock/mysql.go)、[migrate GETTING_STARTED](https://github.com/golang-migrate/migrate/blob/master/GETTING_STARTED.md)、[migrate FAQ](https://github.com/golang-migrate/migrate/blob/master/FAQ.md)、[migrate MIGRATIONS](https://github.com/golang-migrate/migrate/blob/master/MIGRATIONS.md)、[migrate mysql.go](https://github.com/golang-migrate/migrate/blob/master/database/mysql/mysql.go)、[Atlas MySQL skill](https://github.com/ariga/atlas/blob/master/skills/atlas-mysql/SKILL.md)、[Atlas migrations 參考](https://github.com/ariga/atlas/blob/master/skills/atlas-mysql/references/migrations.md)、[Atlas testing 參考](https://github.com/ariga/atlas/blob/master/skills/atlas-mysql/references/testing.md)、[Atlas lint](https://atlasgo.io/versioned/lint)、[Atlas down](https://atlasgo.io/versioned/down)、[Atlas community edition](https://atlasgo.io/community-edition)、[fiberhouse](https://github.com/lamxy/fiberhouse)。

### 多語句半途失敗：實測結果

測試檔依序為：`ALTER 加 a1`、`INSERT`、`CREATE TABLE audit_x`、`INSERT 不存在的表`（失敗）、`ALTER 加 a2`。

| 情境 | 工具記錄的版本 | 實際 schema 與資料 | 再次 up |
|---|---|---|---|
| G1 goose 預設交易 | 1，`status` 顯示 00002 Pending，看不出半途 | a1、audit_x、INSERT 的列**都留下** | `Duplicate column name 'a1'`，卡住 |
| G3 goose `NO TRANSACTION` | 同 G1 | 同 G1 | 未跑 |
| M1 golang-migrate | 2，dirty=1 | 同 G1 | `Dirty database version 2. Fix and force version.`，down 也被拒 |
| M1 續：`force 1` 不清理就 up | 再次變 2 dirty | 未改變 | `Duplicate column name 'a1'` |
| M2：`force 2` 後 down | 1，dirty=1 | 未改變 | down 檔第一句 `DROP COLUMN a2` 就失敗 |
| **G2：goose 失敗後直接 `down`** | 0 | **`orders` 表被刪，audit_x 留下，exit=0** | 不適用 |
| G4 goose 只有 DML | 1 | 全部回滾 | 未跑 |
| M3 golang-migrate 只有 DML、無包裹 | 2 dirty | INSERT、UPDATE **已生效** | 未跑 |
| M4 同上、包 `START TRANSACTION` | 2 dirty | 未生效，但**仍標 dirty**，要 `force 1` | 未跑 |
| G6 goose 手動清理並修檔 | 2 | 正常 | 成功 |

重點：

1. goose 的交易在 MySQL 上保護不了 DDL。它把語句和版本寫入放進同一交易（`provider_run.go` 的 `beginTx`），但第一條 DDL 就隱式提交了，G1 與 G3 結果相同。
2. **G2 最危險。** goose 沒有失敗標記，`down` 作用在最後一個已記錄版本，也就是**上一個成功的 migration**。agent 看到失敗後順手回滾，就會丟掉無關的表，而且 exit=0。goose 的 PostgreSQL 交易 DDL 行為未測，這個風險在 MySQL 上才確認。
3. golang-migrate 的 dirty 能擋住 G2 這種誤操作，代價是連 M4 這種資料其實沒變的情況也要手動 `force`。官方也要求先查明「applied partially, or was it not applied at all」再 force。
4. 單條多子句 ALTER 失敗時全部不生效（L4），這是最便宜的防護。官方依據：atomic DDL「either committed… or is rolled back」，但「Atomic DDL is not transactional DDL」。

## 2. MySQL 線上 DDL 與 PlanetScale `online-ddl.md` 比較

官方：[online DDL operations](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-operations.html)、[ALTER TABLE](https://dev.mysql.com/doc/refman/8.0/en/alter-table.html)、[online DDL performance](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-performance.html)、[atomic DDL](https://dev.mysql.com/doc/refman/8.0/en/atomic-ddl.html)、[implicit commit](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html)。

| 主題 | MySQL 官方 | PlanetScale | 實測 | 判定 |
|---|---|---|---|---|
| 明寫 ALGORITHM 以便失敗 | 「fail with an error otherwise」 | 相同 | L2 報 1845、1846 | 一致 |
| **INSTANT 配 LOCK** | 「Only LOCK = DEFAULT is permitted for operations that use ALGORITHM=INSTANT」 | 「**Always request `LOCK=NONE` (and an explicit `ALGORITHM`)**」 | L1：`ALGORITHM=INSTANT, LOCK=NONE` 報 ERROR 1221 | **PlanetScale 這句照抄會失敗**，只適用 INPLACE |
| 加列 | Instant；8.0.29 前只能加在最後 | 相同 | L2：`AFTER id` + INSTANT 成功 | 一致 |
| 改欄位型別 | Instant 否、In Place 否、不允許並行 DML | 列為非 INSTANT，未提 INPLACE 也不行 | L2：INSTANT、INPLACE 都報錯 | 官方與實測更完整 |
| 擴 VARCHAR | 長度位元組數須不變 | 只說「uses INPLACE」 | L2：50 到 60 成功；60 到 100（utf8mb4，跨 255 位元組）INPLACE 報錯，要 COPY | **PlanetScale 漏了限制** |
| INSTANT 限制 | 上限 64 個 row version；FULLTEXT、COMPRESSED 不可 | **未提** | L5：第 65 次報 ERROR 4092；**不寫 ALGORITHM 時靜默重建**，row version 歸 0 | PlanetScale 不足；實測證實「明寫才會失敗」的價值 |
| INPLACE 含意 | 「avoid copying table data but may rebuild」 | 「Rebuilds in background」 | V2：加索引不重建，row version 不變 | PlanetScale 過度簡化 |
| COPY | 「Concurrent DML is not permitted」 | DML Blocked | L6：262144 rows affected | 一致 |
| Metadata lock | 可能等長交易；pending 的 exclusive 鎖會擋後續交易 | 提到會等待，未提擋後續 | L7：連 INSTANT 都等 5 秒，後續 SELECT 等 4 秒；`lock_wait_timeout=1` 得 ERROR 1205 | **「INSTANT 不阻塞」不成立** |
| gh-ost、pt-osc | 本次未查官方說法 | 建議大表使用 | 未測 | 未驗證 |

**與倉庫現況的衝突（改動與否由使用者決定）：**

- `rules/database/mysql.md:47`「同一张表的多个变更合并为一条 `ALTER`」：V2 實測，把加列與加索引合併後整條重建表，row version 從 2 歸 0，耗時 0.59 秒；分開時加列 0.00 秒、加索引 0.09 秒。L3：合併後不能用 INSTANT。這條規則在純重建類變更上仍合理，但需要例外。
- `skills/db-schema-design/references/mysql.md:32` 把「不改字段类型、不删字段」的在線方案列出「8.0 的 `INSTANT` 算法」：改型別不支援 INSTANT（官方表、L2），這句對型別變更不正確。
- `references/mysql.md:186`「8.0.29 起支持任意位置但仍建议追加」：本次沒找到「仍建議追加」的依據，官方只說能加在任意位置。`mysql.md:47`「新增字段不用 `AFTER`」在 8.0.29 之前有依據（官方；Atlas MY142），8.0.29 以後效能理由不成立（L2）。
- `references/anti-patterns.md:55` 反對條件式 DDL，而 golang-migrate 文件建議「Consider making your migrations idempotent」並提醒慎用。後者同時指出 `IF NOT EXISTS` 會掩蓋 down 的遺漏，與倉庫立場不矛盾，**不需要改**，記此備查。

## 3. Agent 寫遷移的實踐者經驗

**搜尋結果：沒找到 agent 搭配 MySQL 加 goose、golang-migrate 或 Atlas 的第一手事故或使用回報。** 這是有限搜尋（3 次網頁搜尋、1 次 issue 搜尋）的結果，不等於不存在。

| 來源 | 性質 | 內容 | 能否作依據 |
|---|---|---|---|
| [Yureki Lab](https://dev.to/yureki_lab/how-i-let-my-ai-coding-agent-write-database-migrations-without-losing-data-5dc2)（已核對頁面原文） | 第一手；Claude Code；**PostgreSQL** | 用了六個月；第一週約三分之一草稿未過可逆性檢查，典型是「an `up` that does three things and a `down` that undoes two」；shadow run 抓到重寫 180 萬列的 UPDATE；用 `EXPECTED_ROW_LOSS` 註解標明預期減少的列 | 只證實作者這樣回報；MySQL 部分已由本次實測另行驗證 |
| [AWS Builders](https://dev.to/aws-builders/the-setup-is-the-strategy-how-i-orchestrated-a-product-migration-with-claude-code-b92)（WebFetch 摘要） | 第一手；MySQL 遷到 PostgreSQL | 給 AI 唯讀開發庫連線，逐欄比對找出 DDL 不一致；未報告資料庫事故 | 與「不給憑據」看似衝突，實際是**唯讀、開發庫** |
| [claude-code#88753](https://github.com/anthropics/claude-code/issues/88753) | 使用者自述；Go 後端；PostgreSQL | compact 後 agent 從設定檔註解選錯 DSN，對真實 RDS 執行 `TRUNCATE`，刪掉 11 列 | 單一自述；支持「憑據不放在 agent 讀得到的地方」，未獨立驗證 |
| [claude-code#99329](https://github.com/anthropics/claude-code/issues/99329)、[#100449](https://github.com/anthropics/claude-code/issues/100449) | 使用者自述，細節極少 | migration 順序被跳過；agent 清空生產庫 | 僅作線索 |
| [Atlas AI-safe](https://atlasgo.io/use-cases/ai-safe-migrations)、[Agent skills](https://atlasgo.io/guides/ai-tools/agent-skills) | 廠商 | 頁面沒有具名客戶或實際數據 | 不算實踐者回報 |
| [danielvaughan](https://codex.danielvaughan.com/2026/05/12/codex-cli-atlas-agent-skill-database-schema-migrations-policy-as-code/) | 文件整理 | 範例為假設對話，無實測 | 不算第一手 |
| gopherplate skill、mysql-audit（「10 of 10」為作者自評）、Neural Base（「80%」無出處） | 搜尋摘要，**未讀原文** | | 未驗證，不採用 |

值得單獨記下的一點：Atlas 官方已經為 Claude Code 等 agent 提供 skill，內含 MySQL 半途失敗的恢復規則，可作為寫法參考。但它與 Atlas 綁定，不能直接搬到 goose 或 golang-migrate 專案。

## 4. 實測

全部在 `--internal` 網路 `mig-probe-net` 內進行，不暴露埠，資料放 tmpfs。

### 可行性結論

| 做法 | 結果 | 情境 |
|---|---|---|
| up、down 後 schema 比對 | **可行**：正確的 migration 無差異；down 漏刪索引時 diff 精確指出 `KEY idx_note` | C1、C2 |
| AUTO_INCREMENT 雜訊 | **必須過濾**：灌資料後 dump 出現 `AUTO_INCREMENT=6` | C6 |
| 前後行數比對 | **可行**：`INNER JOIN` 重建表漏掉孤兒列，5 變 4 被抓到 | C4 |
| 行數用估算值 | **不可用**：`COUNT(*)`=131072，`table_rows`=130036 | C7 |
| **schema 與行數都相同，資料卻丟了** | **兩種比對都抓不到**：刪欄再由 down 加回，schema、行數皆相同，`note` 全變 NULL；只有 `CHECKSUM TABLE` 不同 | C3 |
| 空庫通過、有資料失敗 | **空庫測試不足**：`ADD UNIQUE` 空庫成功，重複資料時 ERROR 1062，且前一句加的 `nick` 已留下 | C5 |
| 複製到影子庫再遷移 | **可行**：來源版本 1 不動，影子版本 2；行數相等 | C8 |

### 命令

```sh
# schema 快照（排除工具表、去掉 AUTO_INCREMENT 值）
mysqldump -h$H -uroot --no-data --skip-comments --skip-dump-date \
  --routines --triggers --events --no-tablespaces --set-gtid-purged=OFF \
  --ignore-table=$DB.goose_db_version --ignore-table=$DB.schema_migrations "$DB" \
  | sed -E 's/ AUTO_INCREMENT=[0-9]+//' > before.sql
# 執行 up、down 後再 dump 成 after.sql
diff before.sql after.sql

# 精確行數：逐表執行
SELECT COUNT(*) FROM `t`;

# 資料比對：up、down 後 schema 相同時才有意義
CHECKSUM TABLE `t`;

# 影子庫
mysqldump --single-transaction --no-tablespaces --set-gtid-purged=OFF src | mysql shadow

# 線上 DDL 版本號與 row version
SELECT NAME, TOTAL_ROW_VERSIONS FROM INFORMATION_SCHEMA.INNODB_TABLES WHERE NAME='db/t';
```

C3 注意：`CHECKSUM TABLE` 在 schema 變動時本來就會變，所以它只適合 up、down 之後與原值比，不能用在 up 前後。

### 過程異常（備查）

- 權限系統拒絕過 3 條 Bash 命令，均無說明原因：兩條長合併命令、一條單獨的 `docker network rm mig-probe-net`。前兩條拆開後，相關步驟執行成功。額度中斷恢復後，協調者要求清理，同一條 `docker network rm` 再送一次仍被拒絕；**沒有改用其他方式，網路因此未移除**（當時確認：internal=true、0 個容器；無 mig-probe 容器或具名卷）。
- goose v3.29.0 要求 Go 1.26，本機映像為 1.25，建置時設 `GOTOOLCHAIN=auto` 下載工具鏈。
- mysql:8.0 映像沒有 `diff`，容器內用 shell 比對，host 再用真 `diff` 複核 C1 至 C3，結果一致（`out/02b-hostdiff.txt`）。第一次 02 的輸出因此無效，已覆蓋重跑。
- `goose ... mysql DSN validate` 回 `no such command`，但 `-help` 有列；要用不帶 driver 和 DSN 的形式（V1）。
- 模組建置時 `mig-probe-build` 走預設 bridge 下載依賴，未連任何資料庫。
- 本機時鐘與容器日誌相差一天屬時區顯示差異，未影響結果。

## 5. 可寫入的文字（簡體）

**2026-11-03 已寫入**（第三輪第 30、31 條）。每句後方括號是依據，寫入時未保留。

### 放 `rules/database/mysql.md`「变更（migration）」

需同時修改第 47 行「同一张表的多个变更合并为一条 `ALTER`」，否則會與第 2 條衝突。

1. MySQL 的 DDL 会隐式提交，事务包不住：一个 migration 文件只写一条 DDL，DML 与 DDL 分文件。〔implicit-commit、atomic-ddl；G1、G3〕
2. 同一张表的多个变更写进一条 `ALTER`（失败时整条不生效），但能 `INSTANT` 的加列单独一条：与加索引合并会重建整张表。〔L3、L4、V2〕
3. 线上 `ALTER` 写明 `ALGORITHM`，不支持时直接报错：加列用 `ALGORITHM=INSTANT`，且不能再写 `LOCK=NONE`；其余用 `ALGORITHM=INPLACE, LOCK=NONE`，报错后再决定方案。〔alter-table；L1、L2、L5〕
4. migration 半途失败后，先查实际 schema 与工具记录是否一致，再决定修复方式；不要直接执行 down：goose 的 `down` 回滚的是上一个成功的版本，golang-migrate 的 down 文件假定 up 已全部成功。〔G2、M2、GETTING_STARTED〕

### 放 `skills/db-schema-design`（步驟段落或新 reference）

5. 提交前在临时库验证：先灌入种子数据，再比对 up、down 前后的 `mysqldump --no-data` 结果，排除工具版本表并去掉 `AUTO_INCREMENT` 值。〔C1、C2、C6〕
6. 空库通过不算验证：唯一索引、数据转换类 migration 要用含重复或边界值的数据试跑。〔C5；Atlas testing 參考〕
7. 用 `COUNT(*)` 比对 up 前后每张表的行数，不用 `information_schema.tables.table_rows`，它是估算值。〔C4、C7〕
8. 比对 schema 和行数都相同，不代表 down 能恢复数据：删列或改写数据的 migration 要在 up、down 后比对 `CHECKSUM TABLE`，确认不可恢复时在回滚步骤写明。〔C3〕

## 待驗證（進 `docs/plans/`，不進配置）

- 接近線上規模（千萬行以上）的影子庫：耗時、磁碟、`mysqldump` 匯入可行性。
- 脫敏快照的流程；本次沒有任何依據。
- 複製延遲、線上併發流量下的 DDL 行為；gh-ost、pt-online-schema-change。
- Atlas 全部行為，特別是未登入時能用哪些功能、`--dir-format` 能否搭配 goose 或 golang-migrate 目錄（搜尋摘要提到，未讀原文）。
- goose `NewMySQLTableLocker` 與 golang-migrate `GET_LOCK` 的多實例併發行為。
- MySQL 8.4 是否一致（本次只測 8.0.46）；MariaDB。
- 把 goose 或 golang-migrate 接到 FiberHouse `CommandStarter` 的實際寫法。
- 「不給 agent 生產憑據」：目前只有 Yureki 與 #88753 的自述。依 `AGENTS.md`，硬邊界應放 `settings.json` 或 hook，不寫規則文字；是否需要另案評估。

## 已驗證／未驗證邊界／未做／下一步

**已驗證**

- 實測：第 4 節全部、第 1 節的 goose 與 golang-migrate 行為、第 2 節「實測」欄。
- 頁面原文核對：MySQL「Only LOCK = DEFAULT」「fail with an error otherwise」「Atomic DDL is not transactional DDL」、64 row versions、VARCHAR length bytes、8.0.29；Yureki 關鍵數字。
- GitHub 原文：goose、golang-migrate、Atlas skill 與原始碼片段。

**未驗證邊界**

- 只經 WebFetch 摘要，未回原文逐字核對：implicit-commit、online DDL performance、Atlas lint 與 down 與 community 頁、GORM、sqlc、AWS Builders。其中前兩者的行為已被實測佐證；Atlas 的授權說法沒有。
- 實測規模小（最大 26 萬行）、資料在 tmpfs、單機、無併發負載，耗時數字只有相對意義。

**未做**

- PostgreSQL 上的比對與失敗實測（第 5 節的文字全部只針對 MySQL，寫入 `mysql.md` 與 skill 時要標明適用範圍）。
- MongoDB 遷移，不在本次命令實測範圍。
- Atlas 實測。
- 移除 docker 網路 `mig-probe-net`（被權限系統拒絕）。

**下一步（由使用者決定）**

1. 執行 `docker network rm mig-probe-net` 移除殘留網路。
2. 決定是否採用第 5 節文字，並同意修改 `mysql.md:47`。
3. 決定是否修正 `references/mysql.md:32`。
4. 更新 `docs/research/2026-10-best-practices.md` 第 22 條與 `docs/plans/2026-10-22-learning-distill-questions.md` 第 12 條的暫緩理由。
