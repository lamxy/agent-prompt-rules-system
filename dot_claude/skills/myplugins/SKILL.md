---
name: myplugins
description: 在目前專案按序號臨時啟用或關閉全局未啟用的可選插件（如 frontend-design、chrome-devtools-mcp、skill-creator），寫入本地個人或專案共享設定，並增刪可選插件清單。
when_to_use: 使用者輸入 /myplugins，或說「列出可選插件」「啟用插件 3」「這個專案開 frontend-design」「關掉插件」「把 xxx 加入／移出插件清單」時。安裝場景配置包用 myconfig；修改權限、環境變數等其他設定用 update-config。
argument-hint: "[序號… | all | off 序號… | add 名稱@市場 說明 | remove 序號] [--shared]"
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
| 沒有附任何內容，或要求列出 | `list`，原樣顯示輸出，並說明下方用法 |
| 序號、插件名稱或 `all`（例如 `3`、`1 4 6`、`frontend-design`） | `enable <選擇>` |
| `off <選擇>` | `off <選擇>` |
| `add <名稱@市場> [說明]` | `add`；使用者沒給說明時，可從 `claude plugin details <id>` 的 Description 取一句 |
| `remove <選擇>` | `remove` |

用自然語言描述時（例如「這個專案開前端插件」），先執行 `list` 找出對應序號，再告訴使用者要執行的命令並執行；對應不明確時先問。

## 寫入範圍

- 預設寫 `.claude/settings.local.json`：只影響使用者自己，不進版控。
- 使用者說「共享」「給團隊」或帶 `--shared` 時寫 `.claude/settings.json`。先加 `--dry-run` 執行一次，把預演輸出給使用者看，說明這會被提交、同事信任資料夾後才會載入，使用者確認後再去掉 `--dry-run` 執行。
- `off` 只移除指定層的設定，讓值回到下一層（本地 → 共享 → 全局），不寫 `false`。

## 執行後

- 腳本有寫入時，提醒使用者在會話中輸入 `/reload-plugins`（或重開 Claude）才會生效；這是使用者自己執行的斜線命令，你無法代為執行。
- 腳本報「無法寫入…sandbox.excludedCommands」時，不要改用其他方式寫檔；告訴使用者在 `~/.claude/settings.json` 的 `sandbox.excludedCommands` 加入 `python3 <本技能絕對路徑>/scripts/myplugins *`（路徑見錯誤訊息前的命令），再重試。
- 腳本輸出「注意：」的行要轉告使用者，例如插件未安裝時附上的安裝命令；不要自行安裝。
- 增刪清單後序號會重排，以腳本重新列出的清單為準。

## 列出時的用法說明

```
/myplugins 3            啟用第 3 個（本地個人設定）
/myplugins 1 4 6        批量啟用
/myplugins all          全部啟用
/myplugins 3 --shared   寫入專案共享設定（會進版控）
/myplugins off 3        關閉，回到全局預設
/myplugins add 名稱@市場 說明    加入清單
/myplugins remove 3     從清單移除
```

清單存在 `~/.claude/myplugins/catalog.json`，第一次執行時從本技能的 `catalog.default.json` 複製。
