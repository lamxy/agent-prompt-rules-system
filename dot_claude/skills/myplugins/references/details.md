# myplugins 細節

## 預演

使用者帶 `--dry-run`、`-t` 或 `--test` 時照原參數執行（腳本只預演、不寫入），把輸出給使用者看並詢問是否照此寫入；確認後去掉預演旗標再執行一次，不確認就不寫入。`sync` 同樣適用。

## off

預設移除共享層的設定，`--local` 移除本地層；只移除該層，讓值回到下一層（本地 → 共享 → 全局），不寫 `false`。

## 維護清單

- `add <名稱@市場> [說明]`：使用者沒給說明時，可從 `claude plugin details <id>` 的 Description 取一句。
- `remove <選擇>`：從清單移除，之後 `sync` 不會加回。
- `sync`：依預設清單更新本機清單，保留自己加的。使用者同意加入腳本提示的新插件時才執行，不自行執行。
- 增刪清單或 `sync` 後序號會重排，以腳本重新列出的清單為準。
- 清單存在 `~/.claude/myplugins/catalog.json`，第一次執行時從本技能的 `catalog.default.json` 複製；預設清單更新不會自動套用，要 `sync`。

## 錯誤與常見問題

- 腳本報「無法寫入…sandbox.excludedCommands」時，不要改用其他方式寫檔；告訴使用者在 `~/.claude/settings.json` 的 `sandbox.excludedCommands` 加入 `python3 ~/.claude/skills/myplugins/scripts/myplugins *`（照字面，含 `~`），再重試。
- `/plugin` 把插件列在 User 分組：那是插件的安裝範圍（`installed_plugins.json` 的 `scope`），不代表在哪一層啟用；是否啟用以本清單的來源層為準。
