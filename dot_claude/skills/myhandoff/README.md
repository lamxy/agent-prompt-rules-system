# myhandoff 技能維護說明

本檔案面向維護者，不會被模型載入。行為規則一律寫在 `SKILL.md`。

## 版本規則

採語意化版本，記錄於 `SKILL.md` 的 frontmatter。

修改行為規則時提升次版本號。只調整措辭時提升修訂號。改變產出檔案結構、或使既有交接文件不再相容時提升主版本號。

## Claude Code 與 Codex 兩份副本

`~/.claude/skills/myhandoff/` 是唯一來源。`~/.codex/skills/myhandoff/` 由腳本產生，不要手動編輯：

```bash
python3 ~/.claude/skills/myhandoff/scripts/handoff-check sync-codex --check   # 只比對
python3 ~/.claude/skills/myhandoff/scripts/handoff-check sync-codex           # 同步
```

Codex 副本與來源唯一的差異是 `SKILL.md` 移除了 Claude Code 專屬的 `allowed-tools` 欄位。每次修改來源後都要同步，否則同一個專案在不同客戶端會產生不一致的交接文件。

## 硬性約束的組成

| 層 | 機制 | 位置 |
|---|---|---|
| 1 | `scripts/handoff-check`：frontmatter 錨點、結構、秘密掃描、進版控、入口檔、過期判斷 | 技能目錄，兩個客戶端共用 |
| 2 | git pre-commit：秘密掃描、交接提交純度、結構 | 各專案 `.git/hooks/pre-commit`，由 `install-git-hook` 安裝，與客戶端無關 |
| 3 | 客戶端 hook：SessionStart 注入索引或提示開錯位置；Stop、PreCompact、StopFailure（僅 Claude Code）寫 `.git/handoff/snapshot.md` | `~/.claude/settings.json` 與 `~/.codex/hooks.json`，定義固定呼叫 `scripts/handoff-hook`，由 `install-hooks` 寫入 |

設計依據：

兩個客戶端的 PreCompact 輸出都不會進入模型上下文，因此 PreCompact 只寫檔，壓縮後由 `source=compact` 的 SessionStart 重新注入。兩邊 SessionStart 的純文字 stdout 都會成為上下文，所以腳本只輸出純文字，不輸出 JSON。純文字不得以 `{` 或 `[` 開頭：Codex 把這類 stdout 當 JSON 解析（`codex-rs/hooks/src/engine/output_parser.rs` 的 `looks_like_json`），解析失敗時回報 hook 失敗並丟棄整段注入。

hook 指令以 `"$HOME/..."` 表示路徑。Claude Code 以 `sh -c` 執行 hook 指令，Codex 以 `$SHELL -lc` 執行（見 `openai/codex` 的 `codex-rs/hooks/src/engine/command_runner.rs`），`$HOME` 都會展開；`~` 放在引號內不會展開，因此不用。

hook 裝在使用者層級，可避開 Codex「專案 `.codex/` 需先被信任才載入專案 hook」的限制。hook 定義固定為 `sh "$HOME/.../handoff-hook" <客戶端> <事件>`：Codex 的 hook 定義一經改動就需重新審核信任，因此判斷邏輯一律放在 `handoff-hook` 與 `handoff-check`，不動定義。

`handoff-hook` 是 sh 前置判斷，只有命中時才啟動 Python。實測（`audit-bench`）非開發場景 SessionStart 約 1.5 ms、Stop 約 0.6 ms；啟動 Python 本身約 15 ms，開發場景整體約 40 ms。

只在專案根目錄運作。Stop、PreCompact、StopFailure 只檢查目前目錄的 `docs/handoff/HANDOFF.md`，不往上下搜尋。SessionStart 另外偵測開錯位置：git 倉庫的子目錄（根目錄有 `active` 交接）或父目錄（下一層有 `active` 交接），以 JSON 的 `systemMessage` 直接顯示給使用者，並以 `additionalContext` 告知模型不得在此保存或恢復；不阻止工作。`systemMessage` 由客戶端直接顯示，不依賴模型轉述：Claude Code 顯示給使用者；Codex 轉為 hook 的 Warning，互動介面顯示在 hook 訊息中（`codex-rs/tui/src/history_cell/hook_cell.rs`），但 `codex exec` 只印出 hook 名稱與狀態，不顯示警告（`codex-rs/exec/src/event_processor_with_human_output.rs`），因此非互動執行時只有模型會收到提示。`/mnt/` 下的路徑走 9p，git 探測約 90 ms，因此略過開錯位置的偵測。SessionStart 也偵測巢狀參考倉庫（git 根目錄沒有交接文件、上層有），因為技能的 `where` 在客戶端沙箱內可能看不到上層目錄。

交接文件為 `status: closed` 時，所有 hook 都不注入、不寫快照，作為「開發期結束」的開關。

Stop 每回合執行，為了降低寫入，以 HEAD、`git status --porcelain`、stash 與對話紀錄路徑計算雜湊，未變化時不重寫快照。快照記錄對話紀錄路徑（`transcript`）但不抄內容，供中斷恢復時取得意圖證據。Claude Code 的 StopFailure 在 API 錯誤（含 `rate_limit`、`billing_error`）時觸發，快照標記 `event: stop-failure` 與錯誤類型；Codex 沒有對應事件，額度用盡時是否仍觸發 Stop 未驗證，最壞情況損失最後一個回合的快照，git 狀態本身不受影響。

備援快照放在 `.git/handoff/` 而非 `docs/handoff/`：快照只服務同一台機器上的客戶端切換，放進工作樹會在每次壓縮後產生未追蹤檔案，弄髒工作樹，也可能被誤提交進交接提交。

注入字數以 Codex 預設的 2,500 tokens 上限為準，實際只有數行。

審計：`audit-on` 後，每次 hook 呼叫在 `~/.local/state/handoff/audit.jsonl` 追加一行（時間、客戶端、事件、cwd、判定、結果、耗時），不記錄對話或檔案內容，超過 5 MB 時捨棄較舊的一半。`audit-report` 以非開發場景（判定 `skip`）的 p95 與每日總耗時對照門檻給出判定；`audit-bench` 在暫存目錄模擬各情境即時量測。

## 評估後不採納的做法

以下做法在設計時評估過，基於所列理由不採納。重新提議前先確認理由是否已不成立。

| 做法 | 來源 | 不採納理由 |
|---|---|---|
| 每則訊息都注入交接指令 | Sonovore/claude-code-handoff | 持續消耗上下文 |
| 交接文件 HMAC 簽章 | Sting25/claude-code-handoff | 單人使用沒有偽造交接的威脅 |
| 交接未寫完前阻擋壓縮 | raichominev/compaction-handoff | 出錯時阻斷工作，代價高 |
| 認領一次即失效的狀態機 | akitaonrails/ai-memory | 單人單文件情境下 git 歷史已足以追溯 |
| 常駐服務或資料庫 | ai-memory、OpenViking | 破壞「交接文件隨倉庫走、任何客戶端可讀」的前提 |
| L0／L1 分層摘要 | OpenViking | 交接文件本身應夠短，改以三行摘要取代 |
| 由外部系統接管入口檔 | ai-memory | 使專案綁定特定工具 |
| 舊檔名與舊位置的查找與遷移 | 1.3.0 | 屬既有專案的遺留問題，不由技能本身處理 |
| 支援研究型父目錄（根下 `src/` 或 `src/*` 為獨立倉庫）與子目錄啟動 | 2.1.0 討論 | 研究可在獨立目錄完成後再進入專案根目錄開發；子目錄啟動屬誤操作，由提示糾正即可。支援它們需多倉庫快照與更多判斷，測試組合倍增 |
| 開錯位置時以 `continue: false` 阻止會話 | 2.1.0 討論 | 使用者可能刻意在子目錄做與交接無關的工作，阻止過於強硬 |
| 只在技能觸發時才提示開錯位置 | 2.1.0 討論 | 提示太晚，誤入期間沒有快照保護而使用者不知情；改由 SessionStart 的 `systemMessage` 即時提示，技能的 `where` 作後備 |
| 注入到模型上下文作為開錯位置的唯一提示 | 2.1.0 討論 | 兩個客戶端都不把注入內容顯示為訊息，是否告知使用者取決於模型 |
| 偵測到中斷就自動 WIP 提交或建分支 | 2.1.0 討論 | 會暗中搬動使用者的半成品，也可能把秘密值帶進提交 |

若將來需要跨機器的長期記憶，ai-memory 可與本技能並存：前者負責記憶，本技能負責單次工作的交接。

## 變更紀錄

### 2.2.0

技能改名為 `myhandoff`，避免與第三方的 `handoff` 技能撞名。Claude Code 以目錄名作為技能的呼叫名稱，只改 frontmatter 的 `name` 時清單顯示為 `handoff (myhandoff)`，呼叫名稱仍是 `handoff`，因此目錄一併改為 `~/.claude/skills/myhandoff/`。`handoff-check` 的 `CLAUDE_SKILL_DIR`、`CODEX_SKILL_DIR` 與 `~/.claude/settings.json` 的 hook 路徑同步更新；hook 輸出中的「handoff 技能」改為「myhandoff 技能」。

腳本檔名、`docs/handoff/HANDOFF.md`、`handoff.allow` 設定鍵與 pre-commit 標記維持不變，既有專案的交接文件與 pre-commit 檢查不受影響，因此不提升主版本號。安裝路徑與 hook 定義有變動，不只是措辭調整，因此提升次版本號。

### 2.1.4

巢狀參考倉庫的偵測移入 SessionStart hook。實測發現 2.1.3 的 `NESTED` 在 Claude Code 從巢狀倉庫開啟時失效：使用者層級沙箱設定 `denyRead: ["~/"]`、`allowRead: ["."]`，而外層專案用來關閉沙箱的 `.claude/settings.local.json` 不適用於以巢狀倉庫為專案根的會話，模型的 Bash 看不到上層目錄，`where` 因而回報 `OK`。hook 不受客戶端沙箱限制，所以改由 `handoff-hook` 在 git 根目錄沒有交接文件時往上逐層檢查（只用 shell 內建判斷，不啟動行程），命中即以 `systemMessage` 警告使用者、以 `additionalContext` 告知模型不得在此建立交接。巢狀警告不論上層交接狀態都會出現，因為其風險是把交接寫進別人的倉庫，與開發期是否結束無關。SKILL.md 規定警告與 `where` 不一致時以警告為準。

### 2.1.3

`where` 新增 `NESTED`（exit 3）：目前位於 git 倉庫根目錄、自己沒有交接文件、上層某目錄已有交接文件時，判定為可能的巢狀參考倉庫（例如 `dify_works/dify/`）。原本會判為合法根目錄，使交接文件被寫進上游倉庫、專案出現兩份交接。技能遇到 `NESTED` 時停止並請使用者選擇，不直接阻擋：使用者確認要為該倉庫建立獨立交接後，它有了自己的交接文件，之後 `where` 即回傳 `OK`，不再重複詢問。hook 不需修改：巢狀倉庫沒有交接文件時 hook 本來就靜默。

### 2.1.2

修正 `where` 與 hook 的根目錄判斷不一致。非 git 目錄底下有 git 倉庫時，`where` 原本一律判為父目錄；但專案根目錄底下常放參考用的上游原始碼（例如 `dify_works/dify/`），會使保存被擋下，而 hook 此時卻把該目錄當根目錄注入。改為目前目錄已有 `docs/handoff/HANDOFF.md` 即視為根目錄，只有沒有交接文件時才以「底下有 git 倉庫」判定父目錄。

### 2.1.1

修正 Codex 端 Stop 快照失敗。Codex 在部分情況（例如 `--ephemeral` 會話）傳入的 `transcript_path` 為 `null`，原程式只處理欄位不存在的情形，組合狀態雜湊時拋出例外，被 hook 的放行機制吞掉，快照因此未寫入。所有 payload 欄位改為同時處理不存在與 `null`。此問題由審計記錄（`outcome: error`）發現。

### 2.1.0

限定只在專案根目錄運作，新增 `where` 子命令；保存與恢復的第一步都必須執行，不在根目錄時停止並提示。SessionStart 偵測子目錄與父目錄的誤入，以 `systemMessage` 直接提示使用者，不阻止工作。

新增 `scripts/handoff-hook` 作為所有客戶端 hook 的固定入口與前置判斷；非開發場景不再啟動 Python，由約 31 ms 降至約 1.5 ms。hook 定義因此變更，Codex 需重新審核信任一次，之後的邏輯變更不再影響定義。

新增 Stop（兩個客戶端）與 StopFailure（Claude Code）快照，Stop 以狀態雜湊避免重複寫入；快照改為 frontmatter 格式並記錄對話紀錄路徑與觸發事件。`status` 與 SessionStart 會回報上一個會話是否因錯誤中斷。

`status: closed` 時所有 hook 靜默，作為開發期結束的開關。

恢復模式新增中斷恢復流程：判定條件、證據分級（git／diff、驗證結果、對話紀錄、推測）、先回報後動手、不得丟棄或搬移未提交的變更。

新增 `audit-on`、`audit-off`、`audit-report`、`audit-bench`，用實測數據判斷 hook 在非開發場景的影響。`install-hooks` 改為就地取代既有的 handoff 項目，不再只做新增。

### 2.0.1

修正 Codex 端 SessionStart 注入失效。原輸出以 `[handoff]` 開頭，被 Codex 誤判為 JSON，解析失敗後整段注入被丟棄；Claude Code 同時看開頭與結尾，因此未受影響。前綴改為 `handoff 提示：`，hook 定義不變，Codex 不需重新審核信任。

重寫 `description` 的觸發條件。開頭寫出產出物路徑 `docs/handoff/HANDOFF.md`，作為與其他技能的區分依據，也與 SessionStart hook 注入的文字對應；觸發詞改按保存、恢復分組，補上 compact、換客戶端與英文說法，並納入「hook 已提示有交接文件」的情境。

移除單獨的「目前進度到哪」與「交接」：前者在 GSD 專案會與 `gsd-progress` 搶觸發，後者也可能指一般的團隊交接文件。末尾明確排除 GSD 階段進度查詢與 gstack 的 `/context-save`、`/context-restore`，正文「兩種模式」同步加入歧義時先問的規則。

描述長度的依據：Claude Code 對單一技能的 `description` 加 `when_to_use` 截斷於 1,536 字元，技能清單總預算為上下文視窗的 1%，超出時先移除最少被呼叫的技能的描述；Codex 的技能清單最多佔上下文視窗的 2%（無法得知時為 8,000 字元），技能多時先縮短描述。兩者都建議把關鍵用途與觸發詞放在最前面，因此排除規則放在描述末尾。`when_to_use` 是 Claude Code 專屬欄位，Codex 是否支援未查證，所以觸發條件全部寫在 `description`。

### 2.0.0

交接文件固定為 `docs/handoff/HANDOFF.md`，檔名一律英文；內容語言依專案明確指定，未指定時用繁體中文。依舊檔名寫成的交接文件不再被識別，因此提升主版本號。

撤回 1.3.0 的舊位置查找與 `git mv` 遷移。舊檔名屬既有專案的遺留問題，不由技能本身處理；「兩種檔名並存時停止詢問」的規則隨之移除。

模板改名為 `templates/HANDOFF.md`，加入英文鍵的 frontmatter（`branch`、`head`、`status`、`updated`）、語言無關的章節錨點與三行摘要。檢查只依錨點判斷，不比對標題文字，內容語言改變時不受影響。

新增 `scripts/handoff-check`，把可機械判斷的規則從提示詞移到腳本；新增 git pre-commit 與兩個客戶端的 SessionStart、PreCompact hook。1.1.0 因模型無法主動執行而移除的「會話開始時檢查交接文件」，改由 SessionStart hook 實現。

改為以 `~/.claude/skills/handoff/` 為唯一來源，Codex 副本由 `sync-codex` 產生。

### 1.3.0

交接文件改存於 `docs/handoff/` 專屬目錄，並加入舊位置查找與遷移。遷移部分已於 2.0.0 撤回。

### 1.2.0

補上同一會話內功能與交接的提交切分規則。原第五步只規定不夾帶未完成變更，未涵蓋「功能已完整驗證通過」的情形，模型會據此自行判斷可合併為單一提交，使 `git log -- <交接文件>` 的狀態演進史與功能提交纏在一起，且功能 revert 時會連帶撤銷交接文件的更新。

修正入口檔的存在性判斷。原規則只寫「已經有這行時不重複加」，未定義判斷依據。那行可能由其他客戶端或先前會話以不同措辭寫成，比對句子會誤判為不存在而重複加。現改為以交接文件路徑為判斷依據。

補上兩種檔名並存時的處理。技能同時接受 `docs/進度交接.md` 與 `docs/HANDOFF.md`，兩者並存時入口檔會指向兩份文件，接手者無從判斷該讀哪份。現規定停止並詢問使用者。

### 1.1.0

依審計結果修正。

解除「未提交即不可保存」的循環矛盾。原設計要求工作樹乾淨才能保存，但工作到一半正是最需要交接的場景；第五步又要求提交交接文件，本身會製造未提交變更。現改為記錄而非阻塞。

加入敏感資訊硬性規則。原範本的「含必要的環境變數」與「說明各服務的位址」會誘導把秘密寫入一份強制進版控的檔案。現規定只寫變數名不寫值，內部端點以佔位符代替。

移除不可執行的觸發條件。原恢復模式寫「新會話開始時發現檔案存在」，但技能只在被觸發時才載入，模型無法主動執行此檢查。

解除中文與 git 的硬綁定。檔名改為跟隨專案主語言，接受 `docs/進度交接.md` 與 `docs/HANDOFF.md` 兩種；git 相關步驟改為條件執行，非 git 專案有替代路徑。

補上分支與 HEAD SHA 錨點，使恢復模式能判定文件是否過期。

補上偵測鏈的可用性檢查。目錄存在不代表 CLI 已安裝，指令失敗時改讀原始檔案或續往下一層。

補上未提交變更、環境前置條件、與既有狀態文件重複時的處理規則。

移除正文中的維護者註解，改置於本檔案。

### 1.0.0

初版。

## 後續擴充方向

多人協作時的交接衝突處理，例如兩人同時保存造成覆蓋、多分支各有一份交接文件時的合併。

從交接文件反向生成任務系統條目。

跨專案的交接索引，讓使用者能查詢所有專案的當前狀態。
