---
name: ost-install-script
description: 'Write scripts_for_install/install.sh for any open-source library in the open_supports/ system. Use when adding a new support package that needs a one-click installation script. Produces a POSIX sh script with platform detection, flag-driven interface, and idempotent behavior.'
argument-hint: 'GitHub owner/repo of the target library, e.g. colbymchenry/codegraph'
---

# 编写 open_supports 一键安装脚本（install.sh）

## When to Use

- 为 `open_supports/` 新增支持包时，编写 `scripts_for_install/install.sh`
- 官方安装方式有变动时，更新现有脚本

## Pre-read

1. 目标库的**官方安装文档**（主要依据）
2. 该支持包的 `repo_readme_summary.md` — 确认平台要求和安装命令
3. `.ost-refs/` 目录（如存在）— 了解本地路径约定

## 设计决策（编写前确认）

| 决策点 | 默认值 | 说明 |
|--------|--------|------|
| 脚本语言 | POSIX sh | 库有 Node.js / Python 运行时时可改用对应语言 |
| 平台覆盖 | macOS、Linux、WSL | 不包含 Windows native；Windows 安装命令在报错提示中给出 |
| 驱动方式 | 纯 flag 驱动 | 无交互式提示 |
| location 默认 | `local`（项目级） | `global` 需用户显式指定 |
| 已安装时 | 提示版本 + 执行升级 | 升级命令见官方文档 |

## [库特定] 替换清单

编写前，确认以下占位符对应的实际值：

| 占位符 | 说明 | 示例 |
|--------|------|------|
| `{LibraryName}` | 库名 | `CodeGraph` |
| `{owner}/{repo}` | GitHub 路径 | `colbymchenry/codegraph` |
| `INSTALL_URL` | 官方 curl 脚本地址 | `https://raw.githubusercontent.com/.../install.sh` |
| `{binary}` | 安装后的命令名 | `codegraph` |
| `install_cli()` | 安装方式：curl / npm / pip 等 | 见官方文档 |
| `configure()` | 接入 / 配置命令（无则整块删除） | `codegraph install ...` |
| `upgrade_cmd` | 升级命令 | `codegraph upgrade` |
| Windows 提示 | detect_platform `*` 分支中填写 Windows 安装命令 | `irm ... \| iex` |

## 脚本骨架模板

```sh
#!/bin/sh
# =============================================================================
# install.sh — {LibraryName} 安装脚本
# 仓库：https://github.com/{owner}/{repo}
#
# 用法：
#   ./install.sh [OPTIONS]
#
# 选项：
#   --target=TARGETS     Agent 目标（如库支持，否则删除此 flag）
#   --location=local     项目级配置（默认）
#   --location=global    全局配置（需显式指定）
#   --help               显示帮助
# =============================================================================

set -eu

# --- [库特定] 安装源 ---
INSTALL_URL="..."           # 官方 curl 脚本 URL

# --- 默认值（按库实际支持的选项调整，无关 flag 可删除） ---
TARGET="auto"
LOCATION="local"

# --- flag 解析 ---
for arg in "$@"; do
  case "$arg" in
    --target=*)        TARGET="${arg#--target=}" ;;
    --location=local)  LOCATION="local" ;;
    --location=global) LOCATION="global" ;;
    --help|-h)         sed -n '/^# 用法/,/^# ===/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *)
      printf 'Error: 未知选项 "%s"\n运行 "%s --help" 查看用法\n' "$arg" "$0" >&2
      exit 1
      ;;
  esac
done

# =============================================================================
# 平台检测（通用，直接复用）
# =============================================================================
detect_platform() {
  _uname="$(uname -s 2>/dev/null || echo unknown)"
  case "$_uname" in
    Darwin) PLATFORM="macos" ;;
    Linux)
      if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        PLATFORM="wsl"
      else
        PLATFORM="linux"
      fi
      ;;
    *)
      printf 'Error: 不支持的平台 "%s"。本脚本支持 macOS、Linux 和 WSL。\n' "$_uname" >&2
      # [库特定] 若有 Windows native 安装命令，在此补充提示：
      # printf 'Windows 用户请在 PowerShell 中执行：\n  irm <url> | iex\n' >&2
      exit 1
      ;;
  esac
}

# =============================================================================
# PATH 修复（通用）
# curl | sh 安装后，新增的二进制在当前 session PATH 中可能不可见，
# 主动在常见路径搜索并临时扩展 PATH。
# =============================================================================
refresh_path() {
  for _dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin" "/opt/homebrew/bin"; do
    if [ -x "$_dir/{binary}" ]; then   # [库特定] 替换 {binary}
      export PATH="$_dir:$PATH"
      return 0
    fi
  done
}

# =============================================================================
# [库特定] CLI 安装
# =============================================================================
install_cli() {
  printf '→ 正在安装 {LibraryName} CLI...\n'
  curl -fsSL "$INSTALL_URL" | sh
  # 若通过 npm 安装，替换为：npm i -g {pkg-name}
  refresh_path
}

# =============================================================================
# [库特定] 接入 / 配置（若库无此步骤，整块删除）
# =============================================================================
configure() {
  printf '→ 配置 Agent（target=%s，location=%s）...\n' "$TARGET" "$LOCATION"
  # 替换为库的实际配置命令，例如：
  # {binary} install --target="$TARGET" --location="$LOCATION" --yes
}

# =============================================================================
# [库特定] 安装后提示
# =============================================================================
print_next_steps() {
  printf '\n✓ 安装完成。\n\n'
  # 按库的实际使用方式填写下一步提示
  printf '下一步：...\n'
}

# =============================================================================
# 主流程（通用骨架）
# =============================================================================
main() {
  detect_platform
  printf '平台：%s\n\n' "$PLATFORM"

  # 已安装检测
  if command -v {binary} >/dev/null 2>&1; then    # [库特定] {binary}
    _ver="$({binary} version 2>/dev/null || printf 'unknown')"
    printf 'ℹ {LibraryName} 已安装（%s），检查更新...\n\n' "$_ver"
    {binary} upgrade || true    # [库特定] 升级命令；|| true 防止"已是最新"时非零退出码中断脚本
    printf '\n提示：如需重新配置，重新运行本脚本。\n'
    exit 0
  fi

  # 首次安装
  printf '=== {LibraryName} 首次安装 ===\n'
  install_cli

  # CLI 可用性验证
  if ! command -v {binary} >/dev/null 2>&1; then    # [库特定] {binary}
    printf '\nError: 安装后仍找不到 {binary} 命令。\n' >&2
    printf '请重新打开终端后重试，或手动安装：npm i -g {pkg-name}\n' >&2
    exit 1
  fi

  configure
  print_next_steps
}

main
```

## Quality Checklist

- [ ] `set -eu` 已保留（出错立即退出，避免静默失败）
- [ ] `printf` 使用 `%s` 占位，不将变量拼入格式字符串
- [ ] 升级命令后有 `|| true`（防止"已是最新"时非零退出码中断脚本）
- [ ] `refresh_path` 中的 `{binary}` 已替换为实际命令名
- [ ] 无关的 flag 和函数块已删除（如库没有 configure 步骤）
- [ ] `--help` 有用法说明和示例
- [ ] `print_next_steps` 告知用户安装后该做什么
