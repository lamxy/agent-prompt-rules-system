# skills-frontend-dev

前端场景的自定义 skill 目前尚未编写。`install-skill-pkg.sh` 只复制含 `SKILL.md` 的子目录，本文件不会被安装。

## 外部 skills（不随本包安装）

[vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) 提供 React / Next.js 的性能与设计规则，按需在项目根目录安装：

```sh
cd /path/to/project
npx skills add vercel-labs/agent-skills
```

建议只勾选：

| skill | 用途 |
|-------|------|
| `react-best-practices` | 40+ 条 React / Next.js 性能规则，按影响排序 |
| `web-design-guidelines` | 按 100+ 条无障碍、性能与 UX 规则审查 UI 代码 |
| `composition-patterns` | 用复合组件与状态提升替代布尔 prop 泛滥 |

部署相关的 `vercel-*` skill 只在项目部署到 Vercel 时才需要。
