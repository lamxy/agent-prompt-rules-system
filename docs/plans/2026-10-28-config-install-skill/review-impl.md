# myconfig 实现审查（2026-10-29，独立复核）

范围：`dot_claude/skills/myconfig/`（SKILL.md、scripts/catalog、references/commands.md）、`scripts/tests/test-myconfig-catalog.sh`，对照设计 v2、官方 skills.md 与实际脚本源码。
做过的验证：逐个读安装脚本的参数解析与输出；`install-claude-project.sh -f backend-dev -t "<含空格路径>" -d`（rc=0）；catalog 在 sh(bash posix)/dash、副本安装、符号链接安装、`AGENT_RULES_REPO` 指向错误路径下的输出；`test-myconfig-catalog.sh` 通过；简体字扫描；`description`+`when_to_use` 共 303 字符（远低于 1,536）；SKILL.md 94 行。
注意：审查期间 SKILL.md 与测试被并行修改（注入改为 `… || printf 'REPO=UNREADABLE\n'`，测试新增第 7 条），以下以修改后的版本为准。`||` 复合命令的 allowed-tools 匹配已有 probe 实测（临时探测技能，结果见设计文档 §11；result 为 `REPO=UNREADABLE`，无 permission_denials），不再列为风险。

---

## Blocker

### B1. 单个支持包的「预演」模板会被拼成真实安装，且缺少安装参数

证据：
- `scripts/install-open-supports.sh:171-181`：遇到 `--` 后把其余参数全部收作 `SINGLE_ARGS` 并 `break`，之后的 `--dry-run` 不会被解析为选项（`163` 行的 `--dry-run)` 分支走不到）。
- `commands.md:19` 的预演模板是 `install-open-supports.sh -t <P> -n <包> --dry-run`，说明栏又写「支援包參數放在 `--` 之後」。按字面把参数接在末尾（`-n X --dry-run -- args` 正确；`-n X -- args --dry-run` 错误）时，`DRY_RUN=0`，脚本会真的 vendor、生成 wrapper Skill 并运行安装脚本（OpenSpec `npm -g`、codegraph `curl | sh`），违反 SKILL.md 硬性规则第 1 条，且副作用不可回滚。
- `install-open-supports.sh:526-545` 注释：安装脚本在 vendored 目录中运行，不带 `{PROJECT_DIR}` 时默认目标 `.` 指向支持包目录本身。`-n` 模式不读清单，参数必须由技能补齐；`commands.md` 没说参数从哪来。`commands.md:59`（失败后重跑）同样问题。

修改（`commands.md:19`）：
- old：`| 單個支援包 | \`install-open-supports.sh -t <P> -n <包> --dry-run\` | 去掉 \`--dry-run\` | 支援包參數放在 \`--\` 之後；項目級參數須帶 \`{PROJECT_DIR}\` |`
- new：`| 單個支援包 | \`install-open-supports.sh -t "<P>" -n <包> --dry-run -- <參數>\` | 去掉 \`--dry-run\` | \`--dry-run\` 必須在 \`--\` 之前，\`--\` 之後全部傳給支援包；\`<參數>\` 照抄 \`<R>/dot_claude_projects/.claude-<FLAG>/.claude/open_supports_name_list.txt\` 中該包那一行（含 \`{PROJECT_DIR}\`） |`

修改（`commands.md:59`）：
- old：`支援包失敗時，只建議重跑失敗的那一個：\`install-open-supports.sh -t <P> -n <包> --dry-run\`，確認後再正式執行。不重跑整包。`
- new：`支援包失敗時，只建議重跑失敗的那一個：\`install-open-supports.sh -t "<P>" -n <包> --dry-run -- <清單中該行的參數>\`，確認後去掉 \`--dry-run\`。不重跑整包。`

建议在 `test-install-open-supports.sh` 或 myconfig 测试中加一条：`-n X -- a --dry-run` 不应被当作预演（锁定该行为，提醒文档维护者）。可选。

---

## Should-fix

### S1. 预演摘要的 `copied=` 恒为 0，SKILL 第 4 步的「將新增 N 個檔案」无从得出

证据：`install-claude-project.sh:255-257` 预演分支打印 `[DRY-RUN] copy` 后直接 `return 0`，不累加 `COPIED`；`:298` 摘要因此是 `copied=0`（实测 backend-dev 预演：49 行 `[DRY-RUN] copy`，摘要 `copied=0 … manual=0`）。`commands.md` §2 没写这一点，模型很可能照摘要报「新增 0 個」。

修改（`commands.md` §2 表格后、「需要計數並回報的標籤」前加一行）：
- new：`預演（\`-d\`）時摘要的 copied、forced 恆為 0：新增數以 \`[DRY-RUN] copy\` 行計，已存在數以 \`[MANUAL]\` 行計；支援包以 \`==> ost_…\` 行計。`

### S2. `install-settings.sh` 的输出判读不准

证据：`install-settings.sh:484-488` 目标文件不存在时打印 `[CREATED]` 后 `exit 0`，不会输出 `配置安装完成。`（`:536`）；覆盖、合并分别打印 `[OVERWRITE]`、`[MERGE]`；`[WARN]`（`:524`）只在 merge 且未给 `-K` 时出现。

修改（`commands.md:48`）：
- old：`| \`install-settings.sh\` | \`配置安装完成。\`；merge 未寫入的欄位以 \`[WARN]\` 列出 | 錯誤時 exit 1 |`
- new：`| \`install-settings.sh\` | 單行標籤：新建 \`[CREATED]\`（之後不再輸出其他行）、覆蓋 \`[OVERWRITE]\`、合併 \`[MERGE]\`；後兩者先有 \`[BACKUP]\`，結尾 \`配置安装完成。\`（原文）；merge 未寫入的欄位以 \`[WARN]\` 列出 | 錯誤時 exit 1 |`

### S3. catalog 的 `NOTE` 永远不会输出（子 shell 赋值丢失）

证据：`catalog:18` 在 `locate_repo` 内给 `NOTE` 赋值，但 `catalog:124` 以 `repo="$(locate_repo)"` 调用，命令替换是子 shell，赋值不回传。实测：副本安装 + `AGENT_RULES_REPO=<不存在路径>` 在 dash 下输出只有 `REPO=NOT_FOUND` 和通用提示，没有「注意：AGENT_RULES_REPO=… 不是本倉庫」；在仓库内运行时也一样被静默改用其他定位。测试第 5 条只检查 `NOT_FOUND`，没覆盖。

修改：从 `locate_repo` 删除 `catalog:18` 这行赋值，改在 `main` 开头算：
```sh
main() {
  if [ -n "${AGENT_RULES_REPO:-}" ] && ! is_repo "$AGENT_RULES_REPO"; then
    NOTE="注意：AGENT_RULES_REPO=$AGENT_RULES_REPO 不是本倉庫或無法讀取（沙箱限制讀取時，要在 sandbox.filesystem.allowRead 加入此路徑），已改用其他方式定位"
  fi
  repo="$(locate_repo)" || repo=""
  ...
```
测试第 5 条后加：`grep -q '注意：AGENT_RULES_REPO' "$TMP_DIR/out" && pass "bad env var: note" || fail "bad env var: note missing"`。

### S4. SKILL.md 残留「技能执行」的说法

- `SKILL.md:43` old：`合併為一份預演、一次確認，依 \`commands.md\` 的順序執行，遇到第一個失敗就停`
  new：`合併為一份預演、一次確認；交付時依 \`commands.md\` 的順序用 \`&&\` 串成一條命令（任一步失敗即停）`
- `SKILL.md:16` old：`失敗時原樣給出錯誤行與退出碼，不自動重跑有副作用的命令。`
  new：`使用者貼回失敗輸出時，原樣引用錯誤行與退出碼；只建議重跑失敗的單元，不建議整段重跑。`
- `SKILL.md:60` 的「參數中已含「確認」或 `-y` 時視為已確認」来自「技能执行写入」时期，现在确认只决定给哪条命令，可删以省行；保留则改为「視為選了推薦項，直接交付命令」。

### S5. settings 的 overwrite/merge 选项被写成对所有单元适用

证据：`SKILL.md:58` 只说「目標已有 `settings.json` 時」。整包脚本没有 merge：已存在的 `settings.json` 只能 `[MANUAL]` 跳过或 `-F` 备份后覆盖（`install-claude-project.sh:246-250`、`:259-265`）；overwrite/merge 只属于 `install-settings.sh -m`。

修改（`SKILL.md:58`）：
- old：`- 目標已有 \`settings.json\` 時，選項改為「overwrite：先備份，模板 permissions 生效」與「merge：只合併插件與 skillOverrides，permissions 不寫入」。`
- new：`- 單裝 settings 且目標已有同名檔時，選項改為「overwrite：先備份，模板 permissions 生效」與「merge：只合併外掛與 skillOverrides，permissions 不寫入」。整包遇到已存在的 \`settings.json\` 只有跳過或 \`-F\`（先備份再整檔覆蓋）。`

### S6. 第 1 步与第 22 行重复，且没涵盖 `REPO=UNREADABLE`

证据：`SKILL.md:22` 已说明 `NOT_FOUND` / `UNREADABLE` 的处理；`:49` 又写一遍、只提 `NOT_FOUND` 且只让加仓库路径（漏了 `~/.claude/skills/myconfig`）。

修改（`SKILL.md:49`）：
- old：`1. **前置**：清單顯示 \`REPO=NOT_FOUND\`，或預演出現 \`Operation not permitted\`，多半是沙箱擋住讀取倉庫。請使用者在 \`~/.claude/settings.json\` 的 \`sandbox.filesystem.allowRead\` 加入倉庫路徑，不自行修改。`
- new：`1. **前置**：\`REPO=\` 不是路徑，或預演出現 \`Operation not permitted\` 時，照「目前倉庫的配置」下方的說明請使用者調整 allowRead 後停止。`

### S7. `! <命令>` 交付方式的未验证点与部分写入

证据：`SKILL.md:62-63`。(a) `!` bash 模式是否受沙箱限制未验证（任务说明已标注）；(b) 是否受 Bash 工具默认 2 分钟超时约束未验证（skills.md:763 只说明注入命令的超时），而 `SKILL.md:63` 自己说含支持包「可能要幾分鐘」；(c) 若 `!` 受沙箱限制，整包脚本在 `set -eu`（`install-claude-project.sh:19`）下复制到 `.claude/settings.json` 时 `cp` 失败即中止，留下部分文件；改到终端重跑时这些文件会显示为 `[MANUAL]`，模型可能误报「已存在、未更動」。

修改：
- `SKILL.md:62-63` 改为：
  `- 只含配置複製的命令，建議在提示列輸入 \`! <命令>\`，輸出會回到會話；出現 \`Operation not permitted\` 就改到一般終端機執行，再貼回輸出。含支援包的命令直接建議到終端機執行（會跑 \`npm\`、\`git clone\`，可能要幾分鐘）。`
  `- 從 \`!\` 改到終端機重跑時，先前已複製的檔案會顯示 \`[MANUAL]\`，內容與倉庫相同，回報時說明這是上一次部分寫入的結果。`
- 按 MEMORY「配置不含未验证内容」，把 (a)(b) 写进设计文档 §9「未验证」清单，不写进 SKILL.md。

### S8. 「settings 的 deny 攔不到 MCP 呼叫」说法不准确

证据：`commands.md:80`。`settings/settings.project-backend-dev.json` 的 `permissions.deny` 全是 `Bash(mysql *-e *DROP*)` 等 Bash 规则，所以模板的 deny 拦不到 MCP 的 `execute_sql`；但这不等于 settings 的 deny 机制拦不到 MCP（权限规则可以按 MCP 工具名写，本次未核对官方文档，不作结论）。改成只描述模板事实：
- old：`- 資料庫 MCP 的 \`execute_sql\` 可以寫入，settings 的 deny 攔不到 MCP 呼叫。只用唯讀帳號，只連開發或測試庫。`
- new：`- 資料庫 MCP 的 \`execute_sql\` 可以寫入；模板的 deny 只攔 Bash 的 mysql、psql、mongosh、redis-cli 破壞性命令，不涵蓋 MCP 呼叫。只用唯讀帳號，只連開發或測試庫。`

### S9. 命令模板未给路径加引号

证据：脚本都能处理含空格的路径（实测 `-t ".../proj with space" -d` rc=0；`install-open-supports.sh:529-531` 也说明 `{PROJECT_DIR}` 在分词后替换），但 `commands.md:11-19`、`:31-35` 的 `-t <P>`、`-p <P>/.claude`、`sh <R>/scripts/…` 都没加引号，技能交付「可直接複製的命令」时容易漏。
修改（`commands.md:3` 末尾加一句）：`命令中的 \`<R>\`、\`<P>\` 一律加雙引號（例如 \`-t "<P>"\`、\`-p "<P>/.claude"\`），路徑可能含空格。`

### S10. 测试覆盖缺口

`scripts/tests/test-myconfig-catalog.sh`：
1. 第 1 条「self path」在 `$REPO_ROOT` 下运行，cwd git 根回退也能命中，没有隔离「脚本自身路径」这条定位。改为 `run_catalog "$TMP_DIR"`（原副本尚未建立，此时 `$CATALOG` 仍是仓库内的脚本）。
2. 没测符号链接安装（设计 §5.1 与 dot_claude/README 都宣称零配置）。加：
   ```sh
   LINK_HOME="$TMP_DIR/link home"; mkdir -p "$LINK_HOME/.claude/skills"
   ln -s "$SKILL_DIR" "$LINK_HOME/.claude/skills/myconfig"
   CATALOG="$LINK_HOME/.claude/skills/myconfig/scripts/catalog"; run_catalog "$TMP_DIR"; check_ok "symlink" "$REPO_ROOT"
   ```
   （顺带覆盖技能路径含空格。注意放在第 2 条改写 `CATALOG` 之前或之后都要显式赋值。）
3. 没测 `NOTE`（见 S3）。
4. 只用 `sh` 跑。macOS 的 `/bin/sh` 是 bash posix 模式，Debian 系是 dash。建议对 `dash`（存在时）再跑一遍第 1、4 条：`command -v dash >/dev/null && { … dash "$CATALOG" … }`。本次手动在 dash 下跑过，结果正确。
5. 可选：断言 `commands.md` 引用的每个 `install-*.sh`、`multi_client_support/codex.sh` 都存在，防止脚本改名后文档失效。

### S11. 文档未同步（设计文档、HANDOFF、README）

设计文档 `docs/plans/2026-10-28-config-install-skill-design.md` 已与实现脱节：
- 第 3 行状态：「草案 v2 … 待用户确认 … 尚未实现」→ 改为「v3（2026-10-29）：§9 已由用户确认；已实现未提交；2026-10-29 `claude -p` 实测后改为技能只预演、写入交给用户执行」。
- §2 表最后一列「技能是否执行」：项目级各行由「是」改为「只预演；交付命令」，或删掉这一列。
- §3.1 「裝 gstack…」行与 §3.2 第 2 步（判断能否在会话中执行）、第 7 步（执行、`timeout: 600000`）按新流程重写：第 6 步确认的是「交付哪条命令」，第 7 步改为「交付命令（`!` 或终端）」，第 8 步改为「用户贴回输出后报告」。
- §5.4 frontmatter 草案的 `description`、`allowed-tools` 与实现不同（实现加了 `|| printf 'REPO=UNREADABLE\n'`）；同步，并说明 `||` 的原因（沙箱 denyRead 时 `sh` 非 0 会中断整个技能）。
- §6 硬性规则同步为 SKILL.md 现行 4 条。
- §7 补：沙箱 `denyRead ~/` 时须在 `sandbox.filesystem.allowRead` 加仓库路径与 `~/.claude/skills/myconfig`。
- §8 第 4 条「`.claude/settings.json`… 确实写入（验证沙箱下可行）」已被实测否定，改为「给出命令；用户执行后报告含 README 手动步骤」；第 10 条「只输出命令，不执行」现在对所有写入都成立，可并入第 4 条。
- §9 待验证清单：第 1 项（cwd 内写 `.claude/settings.json`）改为已验证：被拒，`.claude/skills/`、`.claude/hooks/` 同样被拒；新增已验证：`AGENT_RULES_REPO` 会传入注入命令、`||` 复合注入命令可被 allowed-tools 放行（probe）；新增未验证：`!` bash 模式是否受沙箱限制、是否有 2 分钟超时。§9 决定 2「目标不在 cwd」已无区分意义，注明被新流程取代。

`docs/handoff/HANDOFF.md`：
- frontmatter `updated: 2026-10-28` → `2026-10-29`，`head` 按提交后更新。
- 当前状态表第 43 行：状态「设计 v2 完成，待用户确认第 9 节决定后实现」→「已实现（未提交）；2026-10-29 `claude -p` 实测：沙箱禁止 cwd 内写 `.claude/settings.json`、`skills/`、`hooks/`，改为技能只预演、写入由用户执行；跨项目使用需 allowRead 仓库路径」。
- 「待处理事项」加：会话实测设计 §8 第 3～11 条与触发评估；验证 `!` 模式的沙箱与超时；本机是否加 allowRead（属本机配置，须用户执行）。
- 文末「变更日志」追加一条。

`dot_claude/README.md`：
- 第 23 行空行把「安裝注意」列表断成两段，删除。
- 第 22 行「只更新技能」命令后补：`以符號連結安裝 myconfig 時加 \`-E skills/myconfig\`，否則 \`cp\` 同一檔案會報錯中斷。`（与 `commands.md:32` 一致）
- 第 22 行 allowRead 只提仓库路径，按 SKILL.md:22 补 `~/.claude/skills/myconfig`（若以复制安装）。

`scripts/README.md:179-185` 测试表缺 `test-myconfig-catalog.sh` 一行；根 `README.md:55` 的 `skills/（myhandoff）` 应加 myconfig。

---

## Nit

N1. `commands.md:34`：`install-settings.sh -l user -m merge -K skillOverrides` 缺 `sh "<R>/scripts/"` 前缀，与同表其他行不一致。

N2. `commands.md:37`「目標不在目前目錄時，預演一樣可以跑…」放在「全域與用戶級」小节下，内容属于项目级，移到 `:23` 之后。

N3. `commands.md` §2 标签补全：`[SKIP]`（`install-claude-md.sh:112`、`install-dot-mcp.sh:106`，空模板）；`install-skill-pkg.sh:126` 缺 `SKILL.md` 的目录以 `[WARN]` 报、计入 `invalid=`，而 `commands.md:56` 把 `[INVALID]` 写成只表示「源 JSON 不合法」；`[WARN]` 也会来自缺 python3（`install-claude-project.sh` 的 JSON 校验）。

N4. `SKILL.md:53` 的 `.gitignore` 预检漏了 agents/skills/支持包的备份目录（`<P>/.claude/agents.backup-*`、`skills.backup-*`、`open_supports.backup-*`，见 `commands.md:65-68`）。建议把 `*.bak.*` 那一串改为 `*.bak.*`、`*.backup-*`、`.claude-project-backup-*`、`settings.local*.json`。

N5. 繁体用语：没有误用的简体字。命中的 4 处都是脚本或 README 原文引用：`SKILL.md:68` `## 手动安装与恢复`、`## MCP 服务器`，`commands.md:43` `复制完成。`，`commands.md:48` `配置安装完成。`。保留原文，建议在后面加「（原文）」，避免日后被当成错字改掉。大陆用语与 `dot_claude/README.md` 的用词不一致，建议统一：
- `項目外副作用`（`SKILL.md:55`、`commands.md:79`）、`項目級參數`（`commands.md:19`）→ `專案外副作用`、`專案級參數`。台湾用法里「項目」是 item，读起来有歧义，优先改这一项。
- `插件` → `外掛`（`SKILL.md:29,58,59,68`，`commands.md:23,79`；README 用「外掛」）
- `用戶級` → `使用者層級`（`SKILL.md:13,45`，`commands.md:25,32`）
- `克隆` → `clone 到`（`commands.md:31`）；`回滾` → `復原`（`SKILL.md:59`，`commands.md:79`）
- `模板` → `範本`（README 用「範本」；可选）

N6. `description`（`SKILL.md:3`）后半句「會話中預演並確認，寫入由使用者執行給出的一條命令完成」读起来拗口；而且设计 §3.1 的全局/Codex 触发词（「裝 gstack」「同步全域設定」「裝 Codex 規則」）没有出现在 description 或 when_to_use 里。建议：
- description new：`…整包或其中單一維度。會話中只做預演；寫入改給一條命令由使用者執行。全域工具、個人用戶級與 Codex 配置也只給命令。`
- when_to_use 追加：`「裝 gstack」「同步個人 skills」「裝 Codex 規則」時也適用。`

N7. `SKILL.md:44`「更新 → 整包加 `-F`」：`-F` 会整份覆盖目标的 `settings.json`（先备份），使用者本地加的 permissions 或插件要从备份手动合回。确认问题里应写明这一点。

N8. catalog 输出的 `REPO=` 是 `pwd -P` 解析后的物理路径。仓库在符号链接路径下时，用户按 `REPO=` 加 allowRead 没问题；按 shell rc 里的逻辑路径加，则未验证沙箱是否解析符号链接。仅记录，不需要改。

N9. 测试用 `env -u`，不是 POSIX，但 macOS、GNU、busybox 都支持，可以不改。

N10. catalog 的可移植性与健壮性已核对，没有问题：`printf -- '-'`、`find -maxdepth/-mindepth`、`awk '!seen[$0]++'`、`sed` 的 `[[:space:]]` 在 BSD 与 GNU 下都可用；dash 下实测正确；输出 13 行（上限 30）；所有路径 exit 0；技能路径与仓库路径含空格时都正确（实测 `home sp`）。`for flag in $(collect_flags …)` 靠分词，FLAG 不含空格（脚本也校验 FLAG 字符集，`install-claude-project.sh:143-146`），可以接受。
