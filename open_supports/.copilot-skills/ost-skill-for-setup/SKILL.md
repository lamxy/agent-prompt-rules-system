---
name: ost-skill-for-setup
description: 'Write skill_for_setup/SKILL.md and skill_for_setup/README.md for any open-source library in the open_supports/ system. Use after scripts_for_install/ is complete. Implements the script-first pattern: primary path runs the install script; fallback follows repo_readme_summary.md Part 2.'
argument-hint: 'GitHub owner/repo of the target library, e.g. colbymchenry/codegraph'
---

# 编写 open_supports 安装技能（skill_for_setup）

## When to Use

- `scripts_for_install/install.*` 已完成后，为支持包编写 AI 可执行的安装技能
- 更新现有技能（官方安装方式有重大变动时）

## Pre-read

1. 该支持包的 `repo_readme_summary.md` — 确认安装方式和平台限制
2. `scripts_for_install/install.*` 的实际内容 — 了解脚本支持的 flag 和排除的平台
3. `.ost-refs/` 目录（如存在）

## 设计原则：脚本优先 + 轻量兜底

| 路径 | 触发条件 | 执行方式 |
|------|---------|---------|
| **主路径** | 脚本存在且平台支持 | 运行 `scripts_for_install/install.*` |
| **兜底路径** | 平台不受脚本支持、脚本报错、用户要手动控制 | 按 `repo_readme_summary.md` 第 2 部分逐步执行 |

优势：安装逻辑只在脚本中维护一份，技能轻薄；兜底路径覆盖脚本不适用的场景（如 Windows）。

## [库特定] 替换清单

| 占位符 | 说明 |
|--------|------|
| skill `name` frontmatter | `ost-{GithubName}-{RepoName}-install`（全小写，连字符分隔） |
| `{LibraryName}` | 库名，如 `CodeGraph` |
| `{owner}/{repo}` | GitHub 路径 |
| `install.*` 扩展名 | 与实际脚本语言一致（`.sh` / `.js` / `.py`） |
| 脚本 flag 示例 | 与 `install.*` 实际支持的 flag 一致 |
| 主路径平台说明 | 脚本实际支持的平台 |
| 兜底路径触发条件 | 脚本实际排除的场景 |
| 验证命令 | 库安装后的验证命令 |
| 安装完成后提示 | 用户安装后需手动执行的下一步 |
| Troubleshooting 表 | 按库的实际常见问题填写 |

## SKILL.md 模板

```markdown
---
name: ost-{GithubName}-{RepoName}-install
description: '帮助用户安装并配置 {LibraryName}。主路径：运行支持包内的一键脚本；脚本不可用时回退到 repo_readme_summary.md。范围：[包含的步骤] 不含 [排除的步骤]。'
argument-hint: '[可传参数说明]'
---

# {LibraryName} 安装（skill_for_setup）

> 参考：[`repo_readme_summary.md`](../../repo_readme_summary.md)  
> 脚本：[`scripts_for_install/install.*`](../../scripts_for_install/install.sh)  
> 官方仓库：[{owner}/{repo}](https://github.com/{owner}/{repo})

## When to Use

[安装 / 配置 / 升级该库的触发描述]

## Pre-read

1. [`../../repo_readme_summary.md`](../../repo_readme_summary.md) — 安装方式和注意事项
2. [`../../.ost-refs/`](../../.ost-refs/) 目录（如存在）— 本地约定

## Pre-checks

从对话上下文中确认：

| 信息 | 默认值 | 说明 |
|------|--------|------|
| 操作系统 | — | 影响走主路径还是兜底路径 |
| [其他需要确认的信息] | [默认值] | [说明] |

## Procedure

### 主路径：运行一键脚本（[脚本支持的平台]）

从支持包根目录（本 SKILL.md 向上两级）执行：

​```sh
sh scripts_for_install/install.* [flags]
​```

常用示例：

​```sh
[按库实际支持的 flag 填写示例]
​```

### 兜底路径：参考 repo_readme_summary.md

遇到以下情况时，转为按 `repo_readme_summary.md` **第 2 部分（安装与更新）** 逐步执行：

- [触发条件1，如：用户平台为 Windows]
- [触发条件2，如：脚本执行报错]

将安装命令发给用户确认后逐条运行。

### 验证

​```sh
[验证命令]
​```

---

## 安装完成后告知用户

```
[下一步提示，如需用户手动执行的操作]
```

---

## Troubleshooting

| 现象 | 原因 | 处理 |
|------|------|------|
| [常见问题] | [原因] | [处理方式] |
```

## README.md 模板

```markdown
# {LibraryName} 安装 Skill — 使用说明

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "[安装意图示例]" |
| 明确指定 Skill | `/ost-{GithubName}-{RepoName}-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|---------|
| Claude Code | ✅ 优先支持 |
| Codex CLI | ✅ 优先支持 |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| [按脚本实际支持的 flag 填写] | | |

## 范围说明

- ✅ 包含：[此技能包含的操作]
- ❌ 不含：[明确排除的操作及用户应如何自行完成]
```

## Quality Checklist

- [ ] skill `name` 符合规范：全小写，连字符分隔，无下划线
- [ ] 主路径的脚本扩展名与实际文件一致（`.sh` / `.js` / `.py`）
- [ ] 兜底路径明确列出了触发条件
- [ ] 兜底路径指向 `repo_readme_summary.md` 第 2 部分（而非重复安装命令）
- [ ] 验证命令来自官方文档或 `repo_readme_summary.md`
- [ ] README.md 中 `/ost-...` 触发词与 `name` frontmatter 一致
- [ ] 范围说明中"不含"部分已填写（避免用户误以为包含）
