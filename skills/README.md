# Skills

本目录存放按项目/场景分组的技能包。每个技能包是一个以 `skills-<FLAG>` 命名的目录，其中 `<FLAG>` 为自定义标识（如 `frontend-dev`、`experiment`），包含该场景下所需的 skill 子目录集合。

## 目录结构

```
skills/
  skills-frontend-dev/   # 前端开发场景技能包（FLAG=frontend-dev）
    my-skill-a/
    my-skill-b/
  skills-NAME-FLAG/      # 命名模板，复制后重命名
```

## 使用方式

通过 `scripts/install-skill-pkg.sh` 将指定技能包中的技能拷贝到目标项目的技能目录：

```sh
# 基本用法（同名目录提示手动处理，其他直接拷贝）
sh scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills

# 强制覆盖（删除同名目录后重新拷贝）
sh scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills -F

# 指定技能包来源目录（默认为本仓库 skills/ 目录）
sh scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills -s /custom/skills/root
```

## 新增技能包

1. 在 `skills/` 下新建 `skills-<FLAG>/` 目录
2. 在其中放置各 skill 子目录（每个 skill 含 `SKILL.md` 等文件）
3. 用 `-f <FLAG>` 参数安装到目标项目
