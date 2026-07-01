# Codex 專案指令

此專案可以將 Claude 導向的規則來源作為共用代理規則材料。此檔案是 Codex-native 的指令入口。

## 規則來源

使用第一個存在的規則來源：

1. `.agent-rules/claude/`
2. `.claude/`

Claude 規則來源是參考材料。不要盲目載入或遵循整份 `CLAUDE.md`。先使用此 `AGENTS` 檔案，再只讀取目前任務需要的規則檔案。

除非已另行安裝 Codex-native 設定，否則 Claude 專用的 `settings.json`、`hooks/`、外掛與 `SendMessage` 指令不是生效中的 Codex 執行時設定。

## 核心行為

- 直接回應目前請求。
- 先給結論，再只補充必要細節。
- 保持上下文精簡；不要載入無關的規則、模板、日誌或文件。
- 如果不確定，說明不確定性以及缺少哪些證據。
- 只有當答案會實質改變工作時，才提出一個關鍵釐清問題。
- 優先採用既有專案模式，而不是新增抽象。
- 未經 approval，不要執行破壞性或對外可見的操作。

## 規則載入

使用最小且足夠的指令層。

1. 先套用此 `AGENTS` 文件。
2. 對一般任務，除非需要更多細節，否則使用上方核心行為。
3. 當任務符合「情境提示」列出的情境時，只讀取作用中規則來源下列出的路徑。列出的路徑具有權威性，可能位於 `rules/` 或 `expandable/`。
4. 當沒有適用的情境提示時，只讀取目前任務最相關的本地規則檔案。
5. 只有在輸出結構必須穩定時，才使用 `expandable/templates/` 下的模板。
6. 不要只因規則存在就載入無關規則。

## 情境提示

- 一般工作：`rules/task/general-task-rule-min.md`
- 工具使用：`rules/task/tool-call-rule-min.md`
- 子代理工作：`rules/task/sub-agent-rule-min.md`
- 設計、規劃、架構或腦力激盪：`expandable/task/design-first-rule-min.md`
- 迴圈、cron 或重複監控：`expandable/task/loop-cron-rule-min.md`
- Agent 團隊工作流程：`expandable/task/agent-team-rule-min.md`
- 輸出格式：`expandable/templates/`

當被引用的檔案不存在時，使用可取得的最佳本地指令繼續，不要因此阻塞。
