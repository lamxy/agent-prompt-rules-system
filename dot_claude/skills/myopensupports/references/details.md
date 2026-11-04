# myopensupports 細節

## 倉庫與清單

- 倉庫只從環境變數 `AGENT_RULES_REPO` 取得；該路徑下必須有 `scripts/install-open-supports.sh` 與 `open_supports/INDEX.md`。
- 本機清單存在 `~/.claude/myopensupports/catalog.json`。第一次執行時，從倉庫 `open_supports/INDEX.md` 的「已收录支持包」表產生，只收目錄確實存在的包，並排除 `ost_GithubName_RepoName_TEMPLATE`。

## sync

- 比對倉庫與本機清單：新增 INDEX 已登記、清單裡沒有的包；移除倉庫目錄已不存在的包；用 INDEX 的內容更新用途、分類與建議場景。
- 用 `add` 加入、但 INDEX 未登記的包，只要目錄還在就保留。
- 帶 `--dry-run`／`-t`／`--test` 時只預演：把輸出給使用者看，並詢問是否寫入；使用者確認後，去掉預演旗標再執行一次。
- `list` 出現「倉庫有 N 個新支持包」的 `注意：` 時，先問使用者再 sync，不要自行執行。
- sync 之後序號會重排，以重新 list 的結果為準。

## add

- 接受 `Owner/Repo` 或 `ost_Owner_Repo`，只在倉庫的 `open_supports/` 查找。
- 找不到時，腳本會報「尚未建立該支持包」，照樣轉告使用者，不要自行建立。
- 目錄存在但 INDEX 未登記時仍會加入，並以 `注意：` 提示。

## 預設參數的來源（依序）

1. 只能全域的包（INDEX 建議場景以「全局」開頭，或已登記在全域清單）：取全域清單 `dot_claude_projects/.claude/open_supports_name_list.txt`。
2. 場景清單 `dot_claude_projects/.claude-<場景>/.claude/open_supports_name_list.txt`：未註解的行優先；註解行是次場景。
3. 安裝腳本註解的「示例」段：提到 claude 的示例優先。專案級的包取帶路徑的示例，路徑換成 `{PROJECT_DIR}`；全域包取不帶路徑的示例。
4. 以上都沒有時，顯示「無預設參數」。

要用 `-t`（專案級）還是 `-g`（全域），依最終參數判斷：參數含 `{PROJECT_DIR}`、`--local` 或 `--location=local` 時用 `-t`；屬於只能全域的包且沒有專案級參數時用 `-g`。參數值不能含空格，這是 `install-open-supports.sh` 的限制。

## remove 的範圍

所有支持包的安裝腳本與 `install-open-supports.sh` 都不提供卸載（2026-11-05 已逐一核對），因此只撤回本倉庫專案級安裝時產生的檔案：

- `<專案>/.claude/open_supports/<ost>/`
- `<專案>/.claude/skills/<ost>_install/`：只刪帶有生成標記的；標記行被刪掉的，視為手動維護，予以保留。

`--apply` 會先把上述目錄備份到 `<專案>/.claude/open_supports.backup-<時間戳>/`，再刪除。

腳本也會轉述支持包 `repo_readme_summary.md` 中記載的官方卸載命令，但不代為執行。專案 `.claude/open_supports_name_list.txt` 裡的設定行不會修改；腳本只用 `注意：` 提醒，依清單重裝時會再裝回來。

全域安裝的包在專案裡沒有可刪的檔案，所以只會輸出官方卸載說明。

## 沙箱

- 寫清單時若出現「無法寫入…sandbox.excludedCommands」：請使用者在 `~/.claude/settings.json` 的 `sandbox.excludedCommands` 加入 `python3 ~/.claude/skills/myopensupports/scripts/myopensupports *`（照字面，含 `~`），然後重試。不要改用其他方式寫檔。
- 讀倉庫出現 `Operation not permitted`：請使用者在 `sandbox.filesystem.allowRead` 加入 `AGENT_RULES_REPO` 的路徑。不要自行修改設定。
- 安裝與 `remove --apply` 都會寫入專案的 `.claude/skills/`，沙箱會擋下，所以一律交由使用者選擇執行方式（見 SKILL.md）。
