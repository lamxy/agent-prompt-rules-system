# settings/

此目录收录按**作用域**和**项目场景**分类的 Claude Code settings 模板，通过 `scripts/install-settings.sh` 安装到目标路径。

---

## 作用域与优先级

Claude Code settings 按三个作用域分层，优先级从高到低：

```
local > project > user
```

| 作用域 | 说明 | 默认路径 |
|--------|------|---------|
| `user` | 用户级全局配置，适用于所有项目 | `~/.claude/settings.json` |
| `project` | 项目级共享配置，纳入版本控制，团队共用 | `<project>/.claude/settings.json` |
| `local` | 本地个人覆盖，不提交 Git，仅影响当前机器 | `<project>/.claude/settings.local.json` |

---

## 可用模板与场景

### 用户级（`-l user`）

| 文件 | 场景名 | 说明 |
|------|--------|------|
| `settings.user.json` | —（基础模板） | 用户级基础配置 |
| `settings.user-productivity.json` | `productivity` | 通用生产力增强，默认场景 |

### 项目级（`-l project`）

| 文件 | 场景名 | 说明 |
|------|--------|------|
| `settings.project-frontend-dev.json` | `frontend-dev` | 前端开发场景 |
| `settings.project-backend-dev.json` | `backend-dev` | 后端开发场景 |
| `settings.project-fullstack-dev.json` | `fullstack-dev` | 全栈开发场景 |
| `settings.project-product-collab.json` | `product-collab` | 产品协作场景 |
| `settings.project-release-ops.json` | `release-ops` | 发布运维场景 |
| `settings.project-xxx.json` | —（占位模板） | 新场景起点，复制后按需修改 |

### 本地级（`-l local`）

| 文件 | 场景名 | 说明 |
|------|--------|------|
| `settings.local.json` | —（基础模板） | 本地级基础配置 |
| `settings.local-frontend-dev.json` | `frontend-dev` | 前端开发本地覆盖 |
| `settings.local-backend-dev.json` | `backend-dev` | 后端开发本地覆盖 |
| `settings.local-experimental.json` | `experimental` | 实验性功能开关 |
| `settings.local-low-connectivity.json` | `low-connectivity` | 弱网/低连通性环境 |
| `settings.local-proxy.json` | —（代理模板） | 代理环境配置，详见 `settings.local-proxy.json.README` |

---

## 安装方式

使用 `install-settings.sh` 安装到目标路径：

```sh
sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

```sh
# 用户级默认（productivity）
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级前端场景
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude

# 本地弱网场景（融合到已有配置）
sh ./scripts/install-settings.sh -l local -s low-connectivity -m merge -p /path/to/project/.claude

# 使用自定义源文件
sh ./scripts/install-settings.sh -l project --src settings/settings.project-xxx.json -m overwrite -p /path/to/project/.claude
```

---

## 注意事项

- **`.json` 文件已存在时不会自动覆盖**（除非显式指定 `-m overwrite`），需手动合并以保证 JSON 结构合法。
- `settings.project-xxx.json` 是新场景的占位起点，不对应任何场景名，复制后按需修改场景标识。
- `settings.local-proxy.json` 配合代理环境使用，包含 `availableModels` 等代理相关字段，详见同目录的 `.README` 说明文件。
- 提交项目时，`settings.local*` 系列文件应加入 `.gitignore`，避免将本地个人配置纳入版本控制。
