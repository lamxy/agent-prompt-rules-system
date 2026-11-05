# myopensupports 技能設計

日期：2026-11-05　狀態：已過建構者審閱，待使用者審閱

## 目的

在任意專案裡用序號列出、安裝、移除本倉庫 `open_supports/` 的支持包，取代手動拼 `install-open-supports.sh -t … -n … -- <參數>`。互動模式參考 `myplugins`（序號清單、腳本做事、本機清單、`add`／`sync`），倉庫定位參考 `myconfig`（環境變數）。

## 使用者已決定

1. **倉庫來源**：支持包一律取自本機克隆的倉庫，路徑由環境變數 `AGENT_RULES_REPO` 指定（與 myconfig 同名）。這是必要前提：未設定、為空或路徑不是本倉庫時，任何子命令只輸出設定提示並停止，不退回其他方式找倉庫。
2. **預設清單**：由倉庫的支持包索引產生；倉庫有新支持包時同步進清單。
3. **sync**：比對倉庫支持包索引與本機清單。
4. **add**：只在倉庫中查找；找不到就提示「尚未建立該支持包」。
5. **不設會話 hook**：只有在呼叫 `/myopensupports` 時才運作。
6. **安裝不直接執行**：`/myopensupports 3` 預設以目前專案目錄為目標，顯示預設安裝參數，以及從安裝腳本註解擷取的安裝示例；由使用者決定採用預設參數或自己輸入參數。
7. **執行方式交給使用者選**：技能給出完整命令，使用者二選一：(1) 讓 Claude 關閉沙箱執行（`dangerouslyDisableSandbox`，仍需使用者在權限提示中核准）；(2) 使用者自己用 `! <命令>` 執行。
8. **移除依倉庫支援的方式**：已確認全部 10 個支持包的安裝腳本與 `install-open-supports.sh` 都不提供卸載。因此移除只撤回本倉庫安裝時自己產生的東西，上游工具的卸載只轉述文件記載的官方命令（見「移除」）。

## 非目標

- 不執行上游工具的卸載命令（如 `codegraph uninstall`、`gstack-uninstall`）。
- 不修改倉庫內容（索引、支持包、場景清單）。
- 不取代 myconfig 的整包安裝，也不處理場景清單分發。
- 不新增卸載邏輯到各支持包的 `install.sh`。

## 反目標（做了也算失敗）

- 會話中未經使用者選擇就執行安裝或刪除。
- 找不到倉庫時默默改用其他路徑或內建清單。
- 「移除」宣稱已卸載上游工具，但實際只刪了複製檔。
- 把文件沒記載的卸載方式當成事實給出。

## 檔案位置

| 檔案 | 用途 |
|---|---|
| `dot_claude/skills/myopensupports/SKILL.md` | 技能主文件（繁體中文，結構仿 myplugins） |
| `dot_claude/skills/myopensupports/references/details.md` | sync、add、remove、錯誤處理細節 |
| `dot_claude/skills/myopensupports/scripts/myopensupports` | Python 3 腳本，所有邏輯都在這裡 |
| `scripts/tests/test-myopensupports.sh` | 測試；用暫存目錄建立假倉庫 |
| `~/.claude/myopensupports/catalog.json` | 本機清單（執行時產生，不進倉庫） |

技能安裝到 `~/.claude/skills/myopensupports/` 的方式與 myplugins 相同，由使用者自己複製。

## 子命令

命令形式比照 myplugins：`python3 ~/.claude/skills/myopensupports/scripts/myopensupports <子命令> [參數]`，照字面單獨執行。

| 使用者輸入 | 腳本子命令 | 行為 |
|---|---|---|
| 空、列出 | `list` | 列出清單 |
| `3` 或包名 | `install 3 [--target DIR] [-- 自訂參數…]` | 輸出安裝方案，不執行 |
| `remove 3` | `remove 3 [--target DIR]`／`remove-apply 3 [--target DIR]` | `remove` 只印方案；`remove-apply` 才刪除（交叉審核後由 `--apply` 改為獨立子命令） |
| `add 名稱` | `add <OwnerName/RepoName 或 ost_…>` | 加入本機清單 |
| `sync` | `sync [--dry-run]` | 比對並更新本機清單 |

`--target` 預設為目前目錄的 git 根目錄；不在 git 倉庫裡時用目前目錄。

### 倉庫定位

- 只讀 `AGENT_RULES_REPO`。檢查條件：`scripts/install-open-supports.sh` 與 `open_supports/INDEX.md` 都存在。
- 失敗時輸出 `錯誤：` 行，說明是「未設定或為空」還是「路徑不是本倉庫」，附上設定方法（shell profile 的 `export AGENT_RULES_REPO=…`，或 `~/.claude/settings.json` 的 `env`），然後以非 0 退出。

### 清單與 sync

- 倉庫索引：解析 `open_supports/INDEX.md` 的「已收录支持包」表，取得包名、上游、用途、分類（A～D）與建議場景。另外掃描 `open_supports/ost_*/`，排除 `ost_GithubName_RepoName_TEMPLATE`。
- 本機清單 `catalog.json`：第一次執行時從倉庫索引產生。
- `list`：每行顯示序號、包名、分類、用途，以及在目標專案是否已安裝（判斷依據：存在 `<專案>/.claude/open_supports/<ost>/`）。只能全域的包不複製檔案，無法判斷，標「全域（未偵測）」。倉庫有、本機清單沒有的包，以 `注意：` 行提示可執行 `sync`；清單中已不存在於倉庫的包，標示「倉庫已無」。
- `sync`：新增倉庫有、清單沒有的包；移除倉庫已無的包；更新用途、分類等描述。輸出新增、移除、更新各幾項。序號會因此重排。
- `add`：在倉庫 `open_supports/` 找目錄（接受 `Owner/Repo` 或 `ost_Owner_Repo`）。找不到時輸出「尚未建立該支持包」；目錄存在但 INDEX 未登記時仍加入，並以 `注意：` 提示 INDEX 未登記。

### install（只產生方案）

輸出順序：

1. 包名、分類、建議場景。
2. **預設參數**及其來源，依序取：
   a0. 只能全域的包（定義見 3）：先取全域清單 `dot_claude_projects/.claude/open_supports_name_list.txt` 的設定行（如 gstack 無參數、task-master `--global`）。
   a. 倉庫各場景清單 `dot_claude_projects/.claude-*/.claude/open_supports_name_list.txt` 中該包的設定行（包含整行註解掉的次場景行，去掉 `#` 再解析）。有多個場景時全部列出，第一個為預設，並標明來自哪個場景。
   b. 都沒有時，從安裝腳本註解「示例」段取示例：只能全域的包取第一條不帶專案路徑的示例；其他包取第一條帶專案路徑的示例，把路徑換成 `{PROJECT_DIR}`，並標明「取自安裝腳本示例」。
   c. 仍取不到，就標「無預設參數」，要求使用者從示例中選。
3. **完整命令**（倉庫路徑展開為絕對路徑）：
   - 專案級：`sh <R>/scripts/install-open-supports.sh -t <專案> -n <包> -- <參數>`
   - 作用域依最終參數判斷，分類只當提示：參數含 `{PROJECT_DIR}`、`--local`、`--location=local` 時用 `-t`；不含且屬於只能全域的包時用 `-g`。例：OpenSpec 分類為「A（項目初始化 B）」，但場景預設行 `--init-project --tools=claude {PROJECT_DIR}` 是專案級，因此用 `-t`。
   - 「只能全域的包」：INDEX 建議場景標「全局」，或已登記在全域清單中（目前是 gstack、task-master）。給 `-g` 命令時註明「此包預設全域安裝，作用於所有專案」。
   - 同時給出加 `--dry-run` 的預演命令。
4. **安裝示例**：照錄安裝腳本開頭註解的「用法／選項／示例」三段（各腳本段名可能是中文或英文，抓不到時輸出 `scripts_for_install/install.*` 路徑請使用者自己看）。
5. 給出自訂參數的形式：`/myopensupports 3 -- <參數…>`，腳本會用使用者參數重組命令。

技能接著用 AskUserQuestion 問兩件事：參數（預設／自訂）與執行方式（Claude 關閉沙箱執行／自己 `!` 執行）。

### remove

- `remove`：列出目標專案中將刪除的項目，並附上完整的 `remove-apply` 命令，執行方式同樣由使用者二選一。
  - `<專案>/.claude/open_supports/<ost>/`
  - `<專案>/.claude/skills/<ost>_install/`：只在帶有 `install-open-supports.sh` 生成標記時刪除；標記已被刪掉（表示手動維護）就保留並提示。
- `remove-apply`：把目錄搬到 `<專案>/.claude/open_supports.backup-<時間戳>/packages/<ost>` 與 `skills/<ost>_install`（與 `-F` 的備份結構一致）。
- 兩種模式都輸出：
  - **官方卸載說明**：擷取該包 `repo_readme_summary.md` 中含「卸载／卸載／uninstall」的行，原樣轉述，不執行。沒有就寫「支持包文件未記載卸載方式」。
  - 專案 `.claude/open_supports_name_list.txt` 仍有這個包時，以 `注意：` 提示：之後依清單重裝會再裝回來。腳本不改這個檔。
- 全域安裝的包在專案裡沒有複製檔，只輸出官方卸載說明。

## 沙箱與權限

- `list`、`sync`、`add` 只寫 `~/.claude/myopensupports/`。比照 myplugins 的處理：寫入被擋時提示使用者把命令加進 `sandbox.excludedCommands`，不改用其他方式寫檔。
- 讀取 `$AGENT_RULES_REPO` 可能需要 `sandbox.filesystem.allowRead`；被擋時提示，不自行修改設定。

## 審閱後由 Claude 決定的事項（請確認）

- 作用域依最終參數判斷，分類只當提示（解決 OpenSpec 分類 A 卻有專案級預設行的衝突）。
- 只能全域的包，預設參數先取全域清單；示例後備改取不帶專案路徑的示例。
- 全域包在 `list` 標「全域（未偵測）」，不嘗試偵測。
- 場景清單去掉 `#` 後只認已知包名；排除 `.claude-FLAG-NAME_template`。

## 驗收

- 測試覆蓋：環境變數未設定、為空、路徑錯誤；INDEX 解析；sync 的新增、移除與更新；add 找到、找不到、未登記三種情況；install 預設參數三種來源與只能全域的包；remove 的計畫輸出、`--apply` 備份後刪除、無生成標記時保留 wrapper skill。
- `sh scripts/tests/run-all.sh` 全部通過。
- 交接文件追加變更紀錄。

## 過程記錄與疑問（2026-11-05 實作）

### 遇到的問題與處理

1. **測試期望與設計不一致**：測試原本預期 `a/one` 的預設參數「取自安裝腳本示例」，但同一份測試替它放了一行註解掉的場景清單設定。依設計，場景清單（含註解行）優先於腳本示例，所以腳本的行為正確。處理：改測試，另外新增 `ost_x_ex` 專門測示例後備。
2. **macOS 暫存路徑**：`/var` 實際是 `/private/var`，腳本用 `realpath` 正規化後，與測試的字面路徑對不上。處理：測試也先用 `pwd -P` 取真實路徑。
3. **「全局」誤判**：cognee 的建議場景是「暂不启用（记忆类由全局 `remember` 插件承担）」，字串包含「全局」，被誤判為只能全域。處理：改成只認以「全局／全域」開頭的欄位，並補上測試。
4. **示例路徑形式多樣**：各安裝腳本示例裡的專案路徑有 `/path/to/project`、`/work/app`、`TARGET_DIR`、`--project-dir=.`、`--project-dir=/path/to/project` 等寫法。處理：凡以 `/`、`~` 開頭，或是 `.`、`TARGET_DIR`、`--project(-dir)=…` 的參數，都換成 `{PROJECT_DIR}`；只有 `--local` 而沒有路徑時，在結尾補上 `{PROJECT_DIR}`。提到 claude 的示例優先。
5. **開發時寫到正式清單位置**：shell 的 `export MYOPENSUPPORTS_HOME` 沒有延續到下一次 Bash 呼叫，實跑時清單寫進了 `~/.claude/myopensupports/catalog.json`。這就是技能的正式位置，內容由倉庫 INDEX 產生，不需清除；之後要重建時，刪掉該檔即可。另外，這次會話直接寫入該位置沒有被沙箱擋下。
6. **本機安裝被拒**：`cp -R … ~/.claude/skills/` 被 auto mode 權限分類器以 Self-Modification 拒絕。依規定不繞過，改由使用者執行 `! cp -R dot_claude/skills/myopensupports ~/.claude/skills/`。

### 疑問（後續備查，未阻塞）

- Q1（2026-11-05 已處理）：agency-agents 從示例取到的預設參數是 `--tool=opencode …`，因為它的示例裡沒有 claude 專案級的寫法。INDEX 標的是「不直接安裝」，所以暫不特別處理。要不要在場景清單或 INDEX 為它補一行 claude 預設參數？→ 使用者決定：它屬於手動挑選，不補參數；list 標〔手動挑選〕，install 印 `注意：`。
- Q2（2026-11-05 已處理）：cognee 的示例都不帶專案路徑，所以顯示「無預設參數」。它在 INDEX 是「D（本地 C）」，但標「暂不启用」，暫時維持現狀。→ 使用者確認不啟用；list 標〔不啟用〕，install 印 `注意：`。
- Q3（2026-11-05 已處理）：會話內 `dangerouslyDisableSandbox` 執行安裝或 `remove-apply`，未在互動模式實測（需要使用者核准權限提示）；可以留到第一次實際使用時驗證。→ test2 會話發現全局 `allowUnsandboxedCommands: false`，此參數無效；使用者決定移除「讓 Claude 關閉沙箱執行」選項，只給 `!` 命令（推翻「使用者已決定」第 7 點的選項 1）。
- Q4（2026-11-05 已處理）：deanpeters 在 INDEX 是「不启用（2026-10-28 用户决定忽略）」，但仍在清單中，可以產生安裝方案。目前不過濾，只靠清單裡的用途欄提示。是否要在 list 中把「不启用」的包另外標出來？→ 使用者決定維持不啟用、照樣列出：list 標〔不啟用〕，install 印 `注意：` 並由 SKILL.md 把「取消」列為推薦。它的預設參數 `--client=codex-zip` 會寫入專案的 `.agents/skills/` 與 `AGENTS.md`，這也是需要提醒的主因。
- Q5：SKILL.md 的 `allowed-tools` 改用 YAML 列表，逐一列出子命令，不含 `remove-apply`。有兩點未實測：(a) 列表形式是否生效；(b) `remove *` 是否不會匹配到 `remove-apply …`。這兩點依 Claude Code 權限規則推論，要等第一次實際使用時確認。如果 `remove-apply` 沒有跳出權限提示，就改回字串形式，或在說明中補充。

### 交叉審核（2026-11-05，子代理獨立審查提交 4273d9c）

審查共提出 9 項（中 4、低 5），已全部依建議修正，並補上測試：

1. **`remove --apply` 原本用 `copytree` 複製再刪除**：碰到斷掉的符號連結會中途失敗，備份只完成一半，且結果訊息在動作前就先印出。已改為 `shutil.move` 搬移到 `packages/`、`skills/`。目錄同名時加後綴；結果訊息改在完成後印出；失敗時轉成 `錯誤：`。
2. **生成的命令沒有加引號**：路徑含空格會斷開；`$(…)` 這類自訂參數會被 shell 展開。已改用 `shlex.quote`。
3. **沒有預設參數時仍印出命令**：已改為只提示使用者自訂參數；SKILL.md 也同步修改，此時只提供「自訂」選項。
4. **`allowed-tools` 預先放行了 `--apply`**：已拆成獨立子命令 `remove-apply`，不放進 `allowed-tools`。`remove --apply` 現在會報錯。
5. **專案級參數缺少 `{PROJECT_DIR}`**：已加上 `注意：` 提示。
6. **`--localhost` 被誤判為專案級**：已改為只比對完整的 token。
7. **`-n` 參數**：已改傳 `ost_` 目錄名，不再用 INDEX 連結文字。
8. **sync 不處理「已從 INDEX 移除但目錄還在」的包**：已改為標記為未登記，並計入「更新」。
9. **只剩保留項時，仍印出「將刪除」標題**：已改為顯示「沒有可刪除的檔案」。

審查者留在 scratchpad 的測試目錄（含 1 份失敗時只完成一半的備份）位於會話暫存區，未影響倉庫或真實專案。
