# Reddit、Hacker News 實踐者討論補充調研（2026-11-03）

對照：`docs/research/2026-10-best-practices.md` 第 4 節、`docs/research/2026-11-plan-b-candidates.md`「社區經驗」。

## 讀法與可信度

- **Reddit 全部被擋，本報告沒有任何 Reddit 原文**，以下每條都來自 HN 或 HN 連到的頁面。問題組的「各查一次 Reddit」只完成了嘗試，沒有取得內容。
- HN 內容由 Algolia API 以 curl 取得，是留言原文。
- 「已讀範圍」的意思：
  - **留言原文（關鍵字篩選）**：下載整串，只讀關鍵字命中的留言，且只讀前幾則；不是通讀整串。
  - **留言原文（搜尋命中）**：搜尋 API 回傳該留言全文，討論串沒有下載，所以沒有整串的分數。
- 單則留言的分數 API 不提供。「分數／留言」是整串的 story 分數與 API 樹內留言數。
- 長留言只讀前 450～1300 字元，引用都落在已讀部分內。
- **所有留言都是個人經驗，不是定論**，除非另外標明。「有效」只代表作者這樣說，都沒有對照量測。有產品立場的作者會標「有立場」。

---

## (a) 不先問就動手、忽略 CLAUDE.md

### a-1 明確要求先問問題、再寫交接文件

- 來源：https://news.ycombinator.com/item?id=49852221（討論串「Plan mode is dead」）
- 日期：2026-09-26；分數／留言：593／509
- 已讀：留言原文（關鍵字篩選）
- 引用：「don't write any code yet.」「Ask me the top ten relevant questions」「This has never not worked as expected.」
- 關係：**補充**。現有結論是「沒找到專門測先問再做的資料」，這裡是做法，仍沒有量測。
- 做法：把這句當成任務開頭的提示範本，或做成指令。經驗，未實測。

### a-2 計畫模式加訪談；不再把規劃當獨立大流程

- 來源：
  - https://news.ycombinator.com/item?id=49851085
  - https://news.ycombinator.com/item?id=49851420
  - https://news.ycombinator.com/item?id=49857123
  - https://news.ycombinator.com/item?id=49857763（作者自述任職 GitHub，有立場）
- 日期：2026-09-25～26；分數／留言：593／509
- 已讀：留言原文（關鍵字篩選）
- 引用：
  - 49851085：「especially when you add interviewing into the equation」
  - 49851420：「rather than plan mode or a complex, spec-driven set of skills」
  - 49857123：「quite good at surfacing and clarifying these issues」
- 關係：**補充**。這是本輪「先問」最集中的實踐訊號，比 hook 更常被提到。
- 做法：在 prd-design 與需求不明的任務試「訪談式 skill」（討論中反覆出現 Matt Pocock 的 `grill-me`）。該 skill 本身未讀，不可直接採用；先讀原文再比較。

### a-3 計畫模式的價值在機制，不在提示

- 來源：https://news.ycombinator.com/item?id=49854835 ；對照 https://news.ycombinator.com/item?id=49851044
- 日期：2026-09-25～26；分數／留言：593／509
- 已讀：留言原文（關鍵字篩選）。49851044 作者經營相關產品，有立場。
- 引用：
  - 49854835：「it's restricted to readonly tools」「re-reads its plan into context after compaction」
  - 49851044：「helping the human understand what's being built」
- 關係：**補充**。與「硬邊界用機制」一致：要確保不動手，唯讀模式比「請先問」可靠。
- 做法：高風險任務要求先進計畫模式。49854835 對機制的描述未對照官方文件。

### a-4 規則隨上下文增長而淡化，放哪裡都一樣

- 來源：
  - https://news.ycombinator.com/item?id=49299380
  - https://news.ycombinator.com/item?id=49297638
  - https://news.ycombinator.com/item?id=49298381
- 日期：2026-08-14；分數／留言：993／872
- 已讀：留言原文（關鍵字篩選）
- 引用：
  - 49299380：「As the context fills up the models will happily firget and ignore」（原文拼錯）
  - 49297638：「within a few messages, the instructions in the skill will be ignored」
  - 49298381：「forgot after 6 interactions」
- 關係：**支持**「長規則會被忽略」，並**補充**一點：有人回報不只是長度問題，換到 skill、記憶也一樣。這些留言都圍繞溝通風格與註解，未必能外推到「先問」。
- 做法：不要期待把規則搬到別的檔案能解決；可量測的改用 hook（見 a-5）。

### a-5 Stop hook 擋可量測的輸出

- 來源：https://news.ycombinator.com/item?id=49300197
- 日期：2026-08-14；分數／留言：993／872
- 已讀：留言原文（關鍵字篩選，全文約 500 字元）
- 引用：「a stop hook that blocks it if it exceeds 150 words」「it's like night and day」
- 關係：**補充**決策 27。決策 27 說「先問」是判斷題不加 hook，這則不矛盾，但指出 hook 對「字數、禁用詞」這類可機器判定的項目有效。同一作者說程式碼註解問題還沒解決。
- 做法：只對可判定的不變量加 Stop hook，例如改了原始碼但沒跑測試。

### a-6 Stop hook 本身也有回報失效，且討論串對原因有錯誤說法

- 來源：
  - https://news.ycombinator.com/item?id=47895029（原文）
  - https://news.ycombinator.com/item?id=47895250（回覆）
  - https://news.ycombinator.com/item?id=47897679（回覆，作者開發授權工具，有立場）
- 日期：2026-04-24～25；分數／留言：109／90
- 已讀：留言原文（關鍵字篩選）；官方 `code.claude.com/docs/en/hooks.md` 以 curl 取得，按關鍵字定位閱讀
- 引用：
  - 原文：「Now, Claude routinely ignores the hook rules.」
  - 47895250：「You need to exit with code 2.」
  - 47897679：「JSON in stdout degrades to a string in the model's tool-result context」
- 官方核對：官方寫 exit 0 加 JSON「is the intended exit code when you print JSON for structured control」，且 Stop 支援 `decision: "block"`。所以 47895250 說「必須 exit 2」與現行官方文件不符。47897679 的機制說法未驗證。文件是今天的版本，貼文是 4 月，當時文件可能不同。
- 關係：**部分反駁**「不變量放 hook 就可靠」。Stop hook 的 block 仍是把原因回饋給模型，模型繼續做；與 PreToolUse 實際擋下工具呼叫不同。後半是根據官方表格的理解，未實測。
- 做法：阻止類用 PreToolUse；Stop hook 當提醒，不當硬邊界。階段 3 若加 Stop hook，要實測模型是否照做。

### a-7 意見分歧：有人說 CLAUDE.md 對同一問題有效

- 來源：
  - https://news.ycombinator.com/item?id=49297545（有效）
  - https://news.ycombinator.com/item?id=49297560（無效）
  - https://news.ycombinator.com/item?id=49304744（無效）
  - https://news.ycombinator.com/item?id=49299328（事後補救）
- 日期：2026-08-14；分數／留言：993／872
- 已讀：留言原文（關鍵字篩選）
- 引用：
  - 49297545：「My rules in the CLAUDE.md specify that comments are evil」，加上程式碼庫本身註解少，「less likely」照抄
  - 49304744：「CLAUDE.md is a joke, it has little to no effect.」
  - 49299328：「But only ever during an extra pass that I initiate」
- 關係：**支持**現有對遵守率不下定論的處理；**補充**現有程式碼的風格可能和規則一樣有影響，以及事後補一輪常比首次就對更可行。
- 做法：完成前要求按規則自查一輪；這比期待首次遵守便宜。經驗。

### a-8 完成前清單被跳過

- 來源：https://news.ycombinator.com/item?id=46050854（討論串 46038047）
- 日期：2025-11-25；分數／留言：未取得（留言搜尋命中，未下載整串）
- 已讀：留言原文（搜尋命中）
- 引用：「It routinely ignores my instructions of checklist items」「goes back and fixes it correctly the second time」
- 關係：**支持**「任務壓力勝過規則」。日期較舊，模型已換多代。
- 做法：驗證步驟放腳本或 hook，不放清單文字。

---

## (b) auto 模式用 Bash 改檔

### b-1 獨立來源逐字引用系統提示，並給出出現時間

- 來源：https://news.ycombinator.com/item?id=49373083（討論串「Feature Request: Support AGENTS.md」）
- 日期：2026-08-20；分數／留言：379／210
- 已讀：留言及整棵回覆樹（留言前 1300 字元）
- 引用：「make file changes with sed, heredocs, or short scripts」「new as of August 18th」「Prompting around it (even with CLAUDE.md) results in low adherence.」
- 關係：
  - **支持** 4.1 的 B-4 成因，提供 #87971 以外的第二個來源。系統提示原文是留言者貼的，本輪未自行取得。
  - **反駁傾向**：與 #87971 的 Bash 寫入 12/15 → 2/15 不同。「low adherence」沒有數字，也沒說明版本或模型，證據弱於 #87971，但兩者都是單人。
- 做法：決策 14 不需改，但階段 3 統計時把 Bash 寫入次數當主要指標，不預設一行規則有效。

### b-2 連帶成本：LSP 不用、權限錯誤、白耗 token

- 來源：
  - https://news.ycombinator.com/item?id=49377005
  - https://news.ycombinator.com/item?id=49373974
  - https://news.ycombinator.com/item?id=49399055
  - 同上 49373083
- 日期：2026-08-20～22；分數／留言：379／210
- 已讀：留言原文（回覆樹）
- 引用：
  - 49377005：「gets blocked on "must read file before writing it"」
  - 49373083：「started ignoring my LSP tools」
  - 49399055：「Read does, but it rarely uses it.」
- 關係：**補充**。現有連帶後果只寫 hook、path rules、`/rewind`。新增兩點：
  - 用 Bash 讀檔後再用 Write，會撞上「必須先讀」；auto 分類器可能擋 Bash 讀檔（作者自己標「I think」）
  - 使用者本機 CLAUDE.md 要求優先用 LSP，這條可能同樣受影響
- 做法：階段 3 統計加「工具呼叫失敗次數」與 LSP 使用次數。兩項都是假設，須實測。

### b-3 關閉開關的證據

- 來源：同 49373083
- 日期：2026-08-20；分數／留言：379／210
- 已讀：留言原文
- 引用：「setting CLAUDE_CODE_THRIFTY_SONIC to 0」
- 關係：**支持**決策 14 不採用。只有「當時可用」的留言，沒有官方來源，且現有文件記了後續失效回報。
- 做法：維持不用。

### b-4 r/ClaudeCode 原文（1vruj7h）：沒讀到

- 來源：`https://www.reddit.com/r/ClaudeCode/comments/1vruj7h/psa_claude_will_now_use_bash_instead_of`（來自 WebSearch 回傳，網址看起來被截斷）
- 日期、分數、留言：未取得
- 已讀：**都沒讀，連完整標題都沒有**
- 引用：無
- 關係：無法判斷
- 做法：請使用者在瀏覽器開啟，或提供內容

### b-5 未驗證線索（只來自 WebSearch 摘要，不是原文）

`anthropics/claude-code` 的 #88041（binary 分析、約 1200 個會話量測）、#89251（繞過 Write|Edit hook）、#92407（Windows）；另有留言稱 2.1.288 起 rules 與巢狀 CLAUDE.md 也隨 Edit、Write 載入。未開原文，不作結論。其中 #88041 若屬實，會比現有 15 次樣本大得多，**值得下一步讀 GitHub 原文**。

---

## (c) skill、外掛過多與工作流框架

### c-1 skill 框架的公開基準：效果小於模型自身漂移

- 來源：https://orcabot.com/benchmarks/agent-skills（HN 線索 https://news.ycombinator.com/item?id=49233628）
- 日期：2026-07-31；HN 留言所在討論串分數未取得
- 已讀：頁面原文約 23500 字元，讀了前約 9500 字元、June verdict 與 Methodology 片段；**July verdict 未完整讀**
- 引用：「The model got better at these tasks in one month by more than any skill pack's advantage」「no arm separates from the baseline anywhere along the curve」「SWE-bench Pro is single-seed」
- 數字（2026-07，相對基線）：
  - SWE-bench Pro：Oh My ClaudeCode +1.65、Superpowers +1.51、Karpathy +0.96、GSD −0.14、Agent Skills −1.10
  - SlopCodeBench Strict：基線 13.9、Superpowers 14.5、GSD 13.1、Karpathy 12.9、Oh My ClaudeCode 12.1
- **重要限制**：
  - 全部用 **Codex CLI + gpt-5.5，不是 Claude Code**，多代理框架被改成單代理循序執行，作者自己也說可能低估
  - 作者是 OrcaBot，有立場
  - 測的是解題率，不是「是否先問」「是否遵守範圍」
- 關係：**支持**決策 25、26、28（不多裝、要跟無 skill 基線比）。**部分反駁**「框架沒價值」的極端解讀：Superpowers 的 Erosion 約 0.46，基線 0.59，作者認為這是工作流的屬性；不過作者也提醒雜訊大。
- 做法：階段 3 的有無 skill 對比要在同一時間跑基線，不能跟之前的結果比，因為模型會漂移。**這點可以直接採納。**

### c-2 實際使用者：框架有用但不一定划算

- 來源：
  - https://news.ycombinator.com/item?id=49855463
  - https://news.ycombinator.com/item?id=49871794
- 日期：2026-09-26～27；分數／留言：593／509
- 已讀：49855463 全文；49871794 關鍵字篩選
- 引用：
  - 49855463：「It's really quite effective, I don't generally read the code that comes out.」；另一工具上「slowed the agent down considerably without much benefit」
  - 49871794：「I am not sure how to tell when they have become obsolete」
- 關係：**補充**。框架效果和執行環境有關，同一人換工具結論就相反。「不讀產出程式碼」不符合本倉庫的審查要求，不該當正面例子。
- 做法：框架留在可選，不當預設。

### c-3 skill 名稱錯誤會靜默失效

- 來源：https://news.ycombinator.com/item?id=46983893（Show HN，作者賣自己的工具 agnix，有立場）
- 日期：2026-02-12；分數／留言：未取得（留言搜尋命中）
- 已讀：留言原文（前 1000 字元）
- 引用：「It never auto-triggered. No error message.」
- 關係：**補充**。現有文件談的是預算截斷，這是另一種靜默失效。留言已隔九個月，現行版本行為未驗證。
- 做法：`scripts/tests/` 加檢查 skill 名稱與 frontmatter 格式。可自行寫，不需裝 agnix。寫入前先實測現行版本。

### c-4 skill 只載摘要，少量、有目的地用才划算

- 來源：https://news.ycombinator.com/item?id=49761350（討論串 49760187）；對照 https://news.ycombinator.com/item?id=48901572（作者推自己的工具，有立場）
- 日期：2026-09-18、2026-07-14；分數／留言：未取得（留言搜尋命中）
- 已讀：留言原文（搜尋命中）
- 引用：
  - 49761350：「if you have too many skills, it can get confused」「a few and they're used tactically」
  - 48901572：「solves the too many skills problem」
- 關係：**支持**現有 (c) 結論；「4～6 個」這種數字本輪沒看到佐證，維持不引用。
- 做法：無新增。按需注入 skill 的 hook 只是線索，未讀。

### c-5 有團隊回報極簡配置就夠用

- 來源：https://news.ycombinator.com/item?id=47330784（討論串「Agents that run while I sleep」）
- 日期：2026-03-11；分數／留言：429／475
- 已讀：留言原文（關鍵字篩選）
- 引用：「We have a very uncomplicated setup with claude code.」「It works wonderfully well.」
- 關係：**支持**決策 26 與瘦身方向。只有這一則，不是統計。
- 做法：無新增。

---

## (d) 範圍外改動與審查流程

### d-1 提交當審查點，丟棄多餘改動

- 來源：https://news.ycombinator.com/item?id=49627523（討論串「Claude, change the "Add to Cart" button to blue」）；另 https://news.ycombinator.com/item?id=49630277
- 日期：2026-09-09；分數／留言：1215／451
- 已讀：留言原文（關鍵字篩選）
- 引用：
  - 49627523：「commit time is review time for me」「take the blue change and discard the rest」
  - 49630277：「revert the change, start a new session」
- 關係：**支持**「靠 diff 審查兜底」；**補充**出問題時回退並換新會話，而不是繼續修。
- 做法：不讓 agent 自動提交；走偏就回退、開新會話、把提示寫具體。

### d-2 分權：程式碼、測試、審查分開

- 來源：
  - https://news.ycombinator.com/item?id=47328133
  - https://news.ycombinator.com/item?id=47330784
  - https://news.ycombinator.com/item?id=47327794
  - https://news.ycombinator.com/item?id=47328275
- 日期：2026-03-10～11；分數／留言：429／475
- 已讀：留言原文（關鍵字篩選）
- 引用：
  - 47328133：「splitting authority, not just prompts」「make test files read only for the coding agent」
  - 47330784：「code reviews with Claude Code, but in a separate session」
  - 47327794：「mount a test folder with just read permissions」
- 關係：**補充**現有「審查與修復分開」。**這裡有一個對 (b) 重要的連結**：現有結論指出 deny 不涵蓋腳本自行寫檔，唯讀掛載則是檔案系統層，不受這個漏洞影響（推論，未實測）。
- 做法：backend、frontend 需要保護測試時，用 devcontainer 唯讀掛載，或搭配沙箱，不只靠 deny。審查開新會話。

### d-3 跨模型、多代理對抗：兩種相反的回報

- 來源：
  - https://news.ycombinator.com/item?id=49704808
  - https://news.ycombinator.com/item?id=49631098
  - https://news.ycombinator.com/item?id=49626158
  - https://news.ycombinator.com/item?id=47327938
- 日期：2026-03-10、2026-09-09～14；分數／留言：1215／451、429／475
- 已讀：留言原文（關鍵字篩選）
- 引用：
  - 49704808：「20-30 agents probably touch an average ticket, but I sign off about twice.」
  - 49626158：「a simple grep or diff is sufficient」
- 關係：**支持**決策 27 的不採納理由「可靠性都是作者自述」；49704808 是反方，見下方反駁清單。49626158 的語境是嘲諷網頁，分量更低。
- 做法：維持不加。

### d-4 agent 主動提「順便」的事，要有意識地不接

- 來源：https://news.ycombinator.com/item?id=49626310
- 日期：2026-09-09；分數／留言：1215／451
- 已讀：留言原文（前 600 字元）
- 引用：「very intentional about not letting it manipulate me」「"one more thing worth noting, unrelated..."」
- 關係：**補充**。範圍外改動也可能由使用者接受建議造成；現有結論只看 agent 主動改。
- 做法：順手發現只記 TODO，這條現有結論已有；提醒使用者端也適用。無配置改動。

### d-5 大 PR 的審查

- 來源：https://news.ycombinator.com/item?id=48538778（回覆 https://news.ycombinator.com/item?id=48538819）
- 日期：2026-06-15；分數／留言：4／1（低關注）
- 已讀：原文前 700 字元與唯一回覆
- 引用：「multi thousand file changes」「unable to comprehend the changes」「run /simplify skill from claude, then do /code-review」
- 關係：**支持**「一任務一分支」；**補充**人工審查前先跑自動審查。
- 做法：無新增，樣本小。

---

## 場景

### prd-design

- 來源：https://news.ycombinator.com/item?id=48490291（討論串 48490057）
- 日期：2026-06-11；分數／留言：未取得
- 已讀：留言原文（搜尋命中）
- 引用：「an AI generated PRD (complete with a Claude Code spec!) to build a core feature which we have had for over 2 years」
- 關係：**補充**。AI PRD 沒查現有產品就寫，開發者會失去信任。現有結論未涉及這個角度。
- 做法：prd-design 可考慮「寫 PRD 前先確認功能是否已存在」，須階段 3 確認有這個缺口再加。

另有 https://news.ycombinator.com/item?id=47263702（2026-03-05，130KB 的 PM skill，作者自推，有立場）：單檔路由、按需載入。只讀前 1000 字元，不建議採納。

### frontend-dev

- 來源：
  - https://news.ycombinator.com/item?id=48146161（2026-05-15）
  - https://news.ycombinator.com/item?id=44777210（2025-08-03，較舊）
  - https://news.ycombinator.com/item?id=46957026（2026-02-10，作者賣工具，有立場）
- 分數／留言：未取得（留言搜尋命中）
- 已讀：留言原文（搜尋命中）
- 引用：
  - 48146161：「including concrete user flows」「attaching screenshots」
  - 44777210：「uses Playwright to verify」
  - 46957026：「bulldoze the good parts instead of making small, surgical tweaks」
- 關係：**支持**「截圖對照循環」，比現有「第一手回顧少」多了第一手說法。46957026 **補充**「精修時會破壞好的部分」，現有結論未提。
- 做法：精修視覺時限制修改範圍，指定要動的元件。

### backend-dev

- 來源：https://news.ycombinator.com/item?id=49261133（Google 文章「Go is an ideal language…」的討論）；https://news.ycombinator.com/item?id=49264855（討論串同上）
- 日期：2026-08-11；分數／留言：444／541
- 已讀：留言原文（關鍵字篩選，只讀 6 則加 1 則搜尋命中），**沒讀到與配置有關的具體做法**；文章本身未讀
- 引用：49264855：「Golang has numerous "compiles but has incorrect behavior"」
- 關係：**補充**，但薄弱。討論主要是語言之爭。
- 做法：沒有。Go 相關只能當背景，會編譯過不代表正確，與現有測試規則一致。

MongoDB、Redis、MySQL、Node.js：**沒查到實踐者內容**，命中的幾乎都是求職貼。見「查不到」。

### dev-ops

- 來源：
  - https://news.ycombinator.com/item?id=47911524（Cursor + Opus 4.6 透過 Railway API 刪除生產庫與卷層備份）
  - 其中 https://news.ycombinator.com/item?id=47913885、https://news.ycombinator.com/item?id=47911859
  - https://news.ycombinator.com/item?id=47918606（討論串同上）
  - https://news.ycombinator.com/item?id=47287420（Tom's Hardware 報導的討論，文章本身未讀）
  - https://news.ycombinator.com/item?id=47289206
- 日期：2026-03-07、2026-04-26～27；分數／留言：860／1032、43／28
- 已讀：留言原文（關鍵字篩選）。1032 則只讀了 8 則加搜尋命中 1 則。**推特原文未讀，事實經過都是留言轉述。**
- 引用：
  - 47913885：「don't give LLMs the keys to prod」「keep backups」
  - 47911859 引當事人規則：「NEVER FUCKING GUESS!」
  - 47918606：「time limits and least privilege」
  - 47288772：「no offsite backups*」
  - 47289206：「run as their own user account with no credentials」
- 關係：
  - **支持**決策 12、13、19 的方向。
  - **補充**：Railway 案例的備份與資料在同一爆炸半徑內，刪除時一起消失。現有決策只處理命令確認，沒處理備份位置與憑據範圍。
  - **補充**：當事人的強硬規則文字沒擋住，支持「硬邊界不靠提示」。
- 做法：dev-ops 規則可考慮加入「部署前確認備份在異地、不與資料同卷，並實際還原過」與「agent 不持有生產憑據」。middleware-ops 是否已涵蓋未查，寫入前先核對。**不是 Compose 案例**，只能類推。

---

## 反駁現有結論的內容

| # | 被反駁的內容 | 反方 | 強度 | 建議處理 |
|---|---|---|---|---|
| 1 | 4.1 #87971 的「CLAUDE.md 明寫有效」（2/15） | b-1：「low adherence」 | 弱：無數字、單人 | 不改決策 14；階段 3 量測 |
| 2 | 「不變量放 hook」的隱含可靠性 | a-6：Stop hook 回報被模型無視 | 中：貼文與官方文件對得上寫法，但未複現，也沒看到後續 | 分開看待：PreToolUse 可擋，Stop 是回饋給模型 |
| 3 | 決策 27 不加跨模型審查 | d-3：多代理流水線自述有效 | 弱：自述，也沒有量測 | 維持不加 |
| 4 | 「skill 價值低」的簡化解讀（現有文件沒有明寫，但決策 25、26 傾向如此） | c-1：Superpowers 的 Erosion 較低；SWE-bench 有正向差距 | 中弱：非 Claude Code、單種子 | 維持不裝，不寫成「框架無效」 |

**討論中的錯誤說法（反駁的是留言，不是現有結論）**：

- 47328268 稱 PreToolUse「It's a guarantee and will always work」。這只對它攔得到的工具成立，現有 (b) 結論已說明 Bash 與腳本可繞過。
- 47895250 稱 Stop hook 必須 exit 2。現行官方文件不是這樣寫（a-6）。

**沒有找到反駁**：Compose 卷資料風險、deny 不涵蓋腳本寫檔、不用 `CLAUDE_CODE_THRIFTY_SONIC`。

---

## 查不到或被擋的部分

### Reddit（全部被擋，0 篇原文）

| 嘗試 | 結果 |
|---|---|
| `https://old.reddit.com/r/ClaudeCode/comments/1vruj7h/.json?limit=100` | 302，導向 `old.reddit.com/login/?reason=lor2...` |
| `https://www.reddit.com/r/ClaudeCode/comments/1vruj7h/.json?limit=100` | 403（回傳 HTML 頁面） |
| `https://old.reddit.com/r/ClaudeCode/comments/1vruj7h/` | 302 |
| `old.reddit.com/r/ClaudeCode/search.json`，`q=bash`（問題 b） | 302 |
| 同上，`q=ignores CLAUDE.md`（問題 a）、`q=too many skills`（問題 c）、`q=unrelated changes review`（問題 d） | 全部 302 |
| WebSearch 加 `allowed_domains: reddit.com` | 400，工具回應該網域無法存取 |
| WebSearch `reddit ClaudeCode "PSA: Claude will now use Bash instead of" Edit Write auto mode` | 原文未出現，只從 GitHub issue 得到被截斷的網址 |

沒有改試瀏覽器自動化、第三方鏡像或封存站：Reddit 要求登入是存取限制，任務要求被擋就記錄。場景組的 Reddit 查詢因此也沒有另外送。

### Hacker News（查了，但無可用內容）

沒命中不代表不存在：Algolia 預設要求所有詞都出現，長查詢容易 0 筆。

| 查詢（tags=comment，除非另註） | 結果 |
|---|---|
| `claude bash instead of edit tool sed auto mode` | 0 筆，改短後才找到 b-1 |
| `CLAUDE.md ignored hook enforce deterministic` | 0 筆，改短後有結果 |
| `claude code superpowers GSD workflow plan mode overkill` | 0 筆，改短後有結果 |
| `docker compose down -v claude deleted volume` | 0 筆 |
| `claude docker volume deleted` | 1 筆，只是一句諷刺，無 Compose 事故第一手內容 |
| `coding agent scope creep review diff`（tags=story） | 0 筆 |
| `claude code golang mysql migration` | 0 筆 |
| `claude code mongodb` | 只有求職貼 |
| `claude code node.js backend tests` | 只有求職貼 |
| `claude code observability logs debugging production` | 0 筆 |
| `claude asks questions before implementing plan mode` | 0 筆 |

**場景未涵蓋**：Redis 未單獨查；MySQL 只在上述合併查詢中；可觀測性沒有內容；https://news.ycombinator.com/item?id=47301395（Ask HN: How are you monitoring AI agents in production?，5 分 8 留言）只看到標題，而且談的是監控 agent，不是服務的可觀測性。

### 取得問題

- `orcabot.com/benchmarks` 首次未跟隨重導向（307），第二次加 `-L` 成功。
- 本輪沒有遇到 curl 35。

---

## 未驗證邊界

- **已驗證**：
  - 上述引用確實出現在 API 回傳的留言文字（寫報告時比對）
  - 官方 hooks 文件對 exit 0 加 JSON 的說法
- **未驗證**：
  - 所有留言中的做法成效，都是個人經驗，沒有對照實驗
  - 系統提示文字（b-1）與 Bash 優先的「8 月 18 日」時間點，只有留言者自述
  - PreToolUse 與 Stop 的差異對這些案例的實際影響，以及 Stop hook 的 block 是否被模型遵守
  - 唯讀掛載能擋住 Bash 寫入，屬推論
  - 計畫模式的唯讀與壓縮後重讀（a-3），未對照官方
  - 舊留言（2025-08～2026-03）的行為是否適用目前版本
- **樣本偏差**：
  - HN 只有關鍵字命中的留言，抱怨串占多數，且不少串是在罵模型或公司
  - Reddit 完全缺席；若 Reddit 使用者體驗不同，本報告看不出來
- **未做**：
  - Reddit 全部
  - #88041、#89251、#92407 原文
  - `grill-me` skill 原文
  - 報導與推特原文、Go 文章
  - orcabot July verdict 全文
  - HN 大型討論串的通讀
- **下一步**：
  1. 使用者手動提供 1vruj7h 內容，或決定是否允許其他取得方式。
  2. 讀 #88041 原文，判斷是否比 #87971 的樣本更適合當依據。
  3. 階段 3 統計加入：Bash 寫入、工具失敗、LSP 使用；對比要同時跑基線。

依 `AGENTS.md`，本報告內容未經測試或主要來源佐證的部分，只能進 `docs/plans/` 疑問清單，不直接寫入配置。

## 過程異常

1. **請求數超出**：約 40 次的目標實際用了 51 次。原因是每題都要查 Reddit、場景要涵蓋，以及額外查官方 hooks 文件核對一條錯誤說法。
2. **偏離「只查 HN、Reddit」**：讀了 orcabot（HN 留言連到）與官方 hooks 文件，都已註明。
3. **首輪篩選有雜訊**：關鍵字 `sed ` 也會命中 `used ` 等詞，所以改為直接讀目標留言的回覆樹。
4. **暫存檔**：工作中在 `phase2-gaps/` 下放了原始回應與解析腳本（`raw/`、`*.sh`、`*.py`），超出「只寫報告檔」的限制。刪除命令被權限系統拒絕，所以**這些檔案還在**，未再嘗試其他刪除方式，由使用者決定是否清理；同目錄的 `art`、`go-migrations-lab`、`repos`、`tools` 不是本任務建立的，未動。比對結果：89 句引用中 4 句因原文是彎引號等轉義未自動匹配，已對照先前輸出確認相符，1 句是文章標題縮寫。需要複查時，可看 `raw/`，或用上面的 URL 與 Algolia `items/<id>` 重新取得。
