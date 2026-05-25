# 搜索工具极简规约

环境已安装 rg（ripgrep）和 ast-grep（sg），优先使用，不用内置回退。

## 工具选择

| 场景 | 工具 |
|------|------|
| 文本/正则/字符串/TODO 搜索 | rg |
| 语法结构查询（函数签名、调用链、Hook 模式等） | sg（ast-grep） |

语法上下文敏感时优先 sg，避免文本搜索的误匹配噪音。

## Token 节省原则（必须遵守）

- 先定位再读取：`rg -l "pattern"` 找到文件后再读内容，不直接 dump 全量结果
- 限制输出行数：PowerShell 用 `| Select-Object -First 20`；WSL/Linux 用 `| head -n 20`
- 排除噪音：`rg --max-columns 120 --glob '!*.lock'`（根据项目类型按需扩展）
- ast-grep 使用紧凑格式：`sg scan --pattern '...' --lang <lang> --format compact`
- 优先 `rg -c "pattern"` 做密度预判，再决定是否展开全量结果

## 新增工具规则

- 新工具直接追加本文件的工具选择表格与 Token 节省原则
- 若单工具规约超过 20 行，单独拆出 `env-<toolname>-min.md`，本文件保留一行引用
