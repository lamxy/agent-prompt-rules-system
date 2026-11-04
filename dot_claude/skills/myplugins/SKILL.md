---
name: myplugins
description: 在當前目錄按序號啟用或關閉全局未啟用的可選插件（如 frontend-design、chrome-devtools-mcp、skill-creator），預設寫入共享設定 .claude/settings.json，也可寫本地個人設定，並增刪可選插件清單。
when_to_use: 使用者輸入 /myplugins，或說「列出可選插件」「啟用插件 3」「這個專案開 frontend-design」「關掉插件」「把 xxx 加入／移出插件清單」時。安裝場景配置包用 myconfig；修改權限、環境變數等其他設定用 update-config。
argument-hint: "[序號… | all | off 序號… | add 名稱@市場 說明 | remove 序號] [--local|-c] [--dry-run|-t|--test]"
allowed-tools: Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/myplugins *)
---

# 可選插件管理

全局只保留基礎插件，其餘列在可選清單中，由使用者在各專案按需啟用。所有動作都交給腳本執行，不要自己編輯 settings 檔：

```sh
python3 ${CLAUDE_SKILL_DIR}/scripts/myplugins <子命令> [參數]
```

命令要照這個寫法單獨執行：不加引號、不串接其他命令、不重導向，否則對不上沙箱排除規則。

## 依使用者輸入執行

| 使用者輸入 | 執行 |
|---|---|
| 沒有附任何內容，或要求列出 | `list`，按下方「列出時的呈現」轉成表格，並附用法 |
| 序號、插件名稱或 `all`（例如 `3`、`1 4 6`、`frontend-design`） | `enable <選擇>` |
| `off <選擇>` | `off <選擇>` |
| `add <名稱@市場> [說明]` | `add`；使用者沒給說明時，可從 `claude plugin details <id>` 的 Description 取一句 |
| `remove <選擇>` | `remove` |

用自然語言描述時（例如「這個專案開前端插件」），先執行 `list` 找出對應序號，再告訴使用者要執行的命令並執行；對應不明確時先問。

## 寫入範圍與預演

- 預設寫 `.claude/settings.json`（共享，會進版控），直接執行，不先預演。
- 使用者帶 `--local` 或 `-c`，或說「只給自己」「本地」「不進版控」時，加 `--local` 寫 `.claude/settings.local.json`（個人設定）。
- 使用者帶 `--dry-run`、`-t` 或 `--test` 時，照原參數執行（腳本只預演、不寫入），把輸出給使用者看並詢問是否照此寫入；使用者確認後去掉預演旗標再執行一次，不確認就不寫入。
- `off` 預設移除共享層的設定，`--local` 移除本地層；只移除該層，讓值回到下一層（本地 → 共享 → 全局），不寫 `false`。

## 執行後

- 腳本有寫入時，提醒使用者在會話中輸入 `/reload-plugins`（或重開 Claude）才會生效；這是使用者自己執行的斜線命令，你無法代為執行。
- 腳本報「無法寫入…sandbox.excludedCommands」時，不要改用其他方式寫檔；告訴使用者在 `~/.claude/settings.json` 的 `sandbox.excludedCommands` 加入 `python3 <本技能絕對路徑>/scripts/myplugins *`（路徑見錯誤訊息前的命令），再重試。
- 腳本輸出「注意：」的行要轉告使用者，例如插件未安裝時附上的安裝命令；不要自行安裝。
- 增刪清單後序號會重排，以腳本重新列出的清單為準。

## 列出時的呈現

腳本輸出的狀態已帶符號（`✅` 啟用、`⬜` 停用、`⚠️` 未安裝）。回覆時：

- 第一行照抄腳本的「已啟用：」一行。
- 清單轉成 Markdown 表格，欄位為 `#`、插件（去掉 `@市場`）、狀態（含符號與來源層）、類別、說明；已啟用的整列用粗體。不要改寫狀態或省略項目。
- 使用者問到 `/plugin` 為什麼把插件列在 User 分組時說明：那是插件的安裝範圍（`installed_plugins.json` 的 `scope`），不代表在哪一層啟用；是否啟用以本清單的來源層為準。

## 列出時的用法說明

```
/myplugins 3            啟用第 3 個（寫入 .claude/settings.json，會進版控）
/myplugins 1 4 6        批量啟用
/myplugins all          全部啟用
/myplugins 3 --local    只寫入本地個人設定 .claude/settings.local.json（同 -c）
/myplugins 3 --test     預演，確認後才寫入（同 -t、--dry-run）
/myplugins off 3        關閉，回到下一層的值
/myplugins add 名稱@市場 說明    加入清單
/myplugins remove 3     從清單移除
```

清單存在 `~/.claude/myplugins/catalog.json`，第一次執行時從本技能的 `catalog.default.json` 複製。
