#!/bin/sh
# =============================================================================
# install.sh - Skills For Real Engineers（mattpocock/skills）安装助手
# 仓库：https://github.com/mattpocock/skills
#
# 用法：
#   ./install.sh [--client=客户端] [--global | --local] [选项] [项目目录]
#
# 安装作用域（D 类双模式，默认值与官方一致）：
#   claude-code  默认用户级（claude plugin install 默认 --scope user）；
#                --local 改为项目级 --scope project，在子 Shell 中 cd 到项目目录执行
#   codex        仅用户级（~/.codex），不接受项目目录
#   copilot      仅用户级（~/.copilot），不接受项目目录
#   gemini       默认用户级（~/.gemini/skills/）；
#                --local 改为 --scope workspace，在子 Shell 中 cd 到项目目录执行
#   npx          默认项目级（官方 npx skills add 不带 -g），写入项目目录下该 agent 的项目级 skills 目录（因 agent 而异，如 cursor→.agents/skills/）；
#                项目目录默认 .，脚本先验证并在 ( cd 项目目录 && npx ... ) 中执行；
#                --global 改为 -g 全局安装，此时不得再给项目目录
#
# 选项：
#   --client=NAME     claude-code（默认）、codex、copilot、gemini、npx
#   --agent=NAME      npx 客户端的目标 agent（如 cursor、opencode、windsurf）；
#                     省略时由 skills CLI 交互选择
#   --yes             npx 客户端非交互安装（传给 skills CLI 的 -y，安装全部 skills，
#                     含 setup-matt-pocock-skills）；省略时保持官方交互选择
#   --global          显式用户级 / 全局安装
#   --local           显式项目级安装（仅 claude-code、gemini、npx 支持）
#   项目目录          项目级安装的目标目录（必须已存在；默认 .）
#   --verify-only     不安装，只运行验证
#   --dry-run         只打印将执行的命令，不实际执行
#   --help, -h        显示本帮助
#
# 示例：
#   ./install.sh                                         # Claude Code 插件，用户级
#   ./install.sh --client=claude-code --local /work/app  # Claude Code 插件，项目级
#   ./install.sh --client=codex
#   ./install.sh --client=gemini
#   ./install.sh --client=npx --agent=cursor /work/app   # 写入 /work/app/.agents/skills/（cursor）
#   ./install.sh --client=npx --agent=cursor --global    # 写入 ~/ 下全局目录
#   ./install.sh --client=npx --agent=cursor --yes /work/app  # 非交互，适合 CI / 容器
#   ./install.sh --client=npx --agent=cursor --dry-run /work/app
#
# 注意：
#   - 每个 agent 只选一种安装方式（插件或 npx），否则每个 skill 会出现两次。
#   - npx 安装询问 skills 时必须勾选 setup-matt-pocock-skills。
#   - npx 安装需要 git（skills CLI 通过 git clone 获取仓库）。
#   - 安装后在每个仓库的 agent 中运行一次 /setup-matt-pocock-skills。
#   - 本脚本不提供卸载；卸载见 claude plugin uninstall、npx skills remove 等官方命令。
# =============================================================================

set -eu

REPO="mattpocock/skills"
REPO_GIT_URL="https://github.com/mattpocock/skills.git"
PLUGIN_NAME="mattpocock-skills"
CLAUDE_PLUGIN_REF="mattpocock-skills@claude-plugins-official"
MARKETPLACE_PLUGIN_REF="mattpocock-skills@mattpocock"

CLIENT="claude-code"
AGENT=""
SCOPE=""
SCOPE_SET="no"
TARGET_DIR=""
TARGET_SET="no"
YES="no"
VERIFY_ONLY="no"
DRY_RUN="no"
ABS_TARGET_DIR=""

die() {
  printf '错误：%s\n' "$1" >&2
  exit 1
}

set_scope() {
  if [ "$SCOPE_SET" = "yes" ] && [ "$SCOPE" != "$1" ]; then
    die '不能同时指定 --global 和 --local。'
  fi
  SCOPE="$1"
  SCOPE_SET="yes"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --client=*) CLIENT="${1#--client=}" ;;
    --agent=*) AGENT="${1#--agent=}" ;;
    --global) set_scope global ;;
    --local) set_scope local ;;
    --yes) YES="yes" ;;
    --verify-only) VERIFY_ONLY="yes" ;;
    --dry-run) DRY_RUN="yes" ;;
    --help|-h) sed -n '/^# 用法：/,/^# ====/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)
      printf '错误：未知选项 "%s"。运行 "%s --help" 查看用法。\n' "$1" "$0" >&2
      exit 1
      ;;
    *)
      [ "$TARGET_SET" = "no" ] || die '只能指定一个项目目录。'
      TARGET_DIR="$1"
      TARGET_SET="yes"
      ;;
  esac
  shift
done

# --- 按客户端确定官方默认作用域，并校验组合 ---
case "$CLIENT" in
  claude-code|gemini)
    [ "$SCOPE_SET" = "yes" ] || SCOPE="global"
    if [ "$SCOPE" = "global" ] && [ "$TARGET_SET" = "yes" ]; then
      die "--client=$CLIENT 默认用户级安装，不接受项目目录；项目级请显式加 --local。"
    fi
    ;;
  codex|copilot)
    [ "$SCOPE" != "local" ] || die "--client=$CLIENT 官方仅支持用户级插件安装，不支持 --local。"
    [ "$TARGET_SET" = "no" ] || die "--client=$CLIENT 为用户级安装，不接受项目目录。"
    SCOPE="global"
    ;;
  npx)
    [ "$SCOPE_SET" = "yes" ] || SCOPE="local"
    if [ "$SCOPE" = "global" ] && [ "$TARGET_SET" = "yes" ]; then
      die '--global 模式写入用户级目录，不接受项目目录。'
    fi
    ;;
  *)
    die "未知客户端 \"$CLIENT\"。支持：claude-code、codex、copilot、gemini、npx。"
    ;;
esac

if [ -n "$AGENT" ] && [ "$CLIENT" != "npx" ]; then
  die '--agent 仅用于 --client=npx。'
fi

if [ "$YES" = "yes" ] && [ "$CLIENT" != "npx" ]; then
  die '--yes 仅用于 --client=npx。'
fi

if [ "$SCOPE" = "local" ]; then
  [ "$TARGET_SET" = "yes" ] || TARGET_DIR="."
  [ -d "$TARGET_DIR" ] || die "项目目录不存在：$TARGET_DIR"
  ABS_TARGET_DIR="$(CDPATH= cd -- "$TARGET_DIR" && pwd -P)"
fi

# =============================================================================
# 通用工具
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
      printf '错误：不支持的平台 "%s"。本脚本支持 macOS、Linux 和 WSL。\n' "$_uname" >&2
      printf 'Windows 用户可在 PowerShell 中直接运行官方命令，例如：\n' >&2
      printf '  claude plugin install %s\n' "$CLAUDE_PLUGIN_REF" >&2
      printf '  npx skills@latest add %s -a <agent>\n' "$REPO" >&2
      exit 1
      ;;
  esac
}

require_cmd() {
  [ "$DRY_RUN" = "yes" ] && return 0
  command -v "$1" >/dev/null 2>&1 || die "找不到必需命令：$1"
}

# 打印并执行命令（全局分支）
run() {
  printf '+ %s\n' "$*"
  [ "$DRY_RUN" = "yes" ] && return 0
  "$@"
}

# 在子 Shell 中 cd 到已验证的项目目录后执行（项目分支，不改变调用端 CWD）
run_in_target() {
  printf '+ (cd %s && %s)\n' "$ABS_TARGET_DIR" "$*"
  [ "$DRY_RUN" = "yes" ] && return 0
  ( cd "$ABS_TARGET_DIR" && "$@" )
}

print_scope() {
  if [ "$SCOPE" = "local" ]; then
    printf '作用域：项目级（目标目录：%s）\n' "$ABS_TARGET_DIR"
  else
    printf '作用域：用户级 / 全局\n'
  fi
}

# =============================================================================
# Claude Code
# =============================================================================
claude_installed() {
  if [ "$SCOPE" = "local" ]; then
    ( cd "$ABS_TARGET_DIR" && claude plugin list 2>/dev/null ) | grep -F "$PLUGIN_NAME" >/dev/null 2>&1
  else
    claude plugin list 2>/dev/null | grep -F "$PLUGIN_NAME" >/dev/null 2>&1
  fi
}

install_claude() {
  require_cmd claude
  if [ "$DRY_RUN" = "no" ] && claude_installed; then
    printf 'ℹ %s 已安装；Claude Code 插件默认自动更新，无需重复安装。\n' "$PLUGIN_NAME"
    return 0
  fi
  if [ "$SCOPE" = "local" ]; then
    run_in_target claude plugin install "$CLAUDE_PLUGIN_REF" --scope project
  else
    run claude plugin install "$CLAUDE_PLUGIN_REF"
  fi
}

verify_claude() {
  require_cmd claude
  if [ "$SCOPE" = "local" ]; then
    run_in_target claude plugin list
  else
    run claude plugin list
  fi
  [ "$DRY_RUN" = "yes" ] && return 0
  if claude_installed; then
    printf '验证通过：claude plugin list 中找到 %s。\n' "$PLUGIN_NAME"
  else
    printf '验证失败：claude plugin list 中未找到 %s。\n' "$PLUGIN_NAME" >&2
    return 1
  fi
}

# =============================================================================
# Codex
# =============================================================================
install_codex() {
  require_cmd codex
  run codex plugin marketplace add "$REPO" || printf '提示：marketplace 可能已添加，继续安装插件。\n'
  run codex plugin add "$MARKETPLACE_PLUGIN_REF"
}

verify_codex() {
  require_cmd codex
  run codex plugin list
  [ "$DRY_RUN" = "yes" ] && return 0
  if codex plugin list 2>/dev/null | grep -F "$PLUGIN_NAME" >/dev/null 2>&1; then
    printf '验证通过：codex plugin list 中找到 %s。\n' "$PLUGIN_NAME"
  else
    printf '验证失败：codex plugin list 中未找到 %s。\n' "$PLUGIN_NAME" >&2
    return 1
  fi
}

# =============================================================================
# GitHub Copilot CLI
# =============================================================================
install_copilot() {
  require_cmd copilot
  run copilot plugin marketplace add "$REPO" || printf '提示：marketplace 可能已添加，继续安装插件。\n'
  run copilot plugin install "$MARKETPLACE_PLUGIN_REF"
  printf '\n如需自动更新，请手动在 ~/.copilot/settings.json 中合并以下配置（脚本不自动改写 JSON）：\n'
  printf '%s\n' '{' \
    '  "extraKnownMarketplaces": {' \
    '    "mattpocock": { "source": { "source": "github", "repo": "mattpocock/skills" }, "autoUpdate": true }' \
    '  }' \
    '}'
  printf 'VS Code 用户可改用命令 "Chat: Install Plugin From Source"，输入 https://github.com/%s\n' "$REPO"
}

verify_copilot() {
  printf '官方未提供 Copilot 专门验证命令；请在 Copilot 中输入 /grill-me 确认 skill 可用。\n'
}

# =============================================================================
# Gemini CLI（重新运行即为更新）
# =============================================================================
install_gemini() {
  require_cmd gemini
  for _path in skills/engineering skills/productivity; do
    if [ "$SCOPE" = "local" ]; then
      run_in_target gemini skills install "$REPO_GIT_URL" --path "$_path" --scope workspace
    else
      run gemini skills install "$REPO_GIT_URL" --path "$_path"
    fi
  done
}

verify_gemini() {
  printf '官方未提供 Gemini 专门验证命令；请在 Gemini CLI 中输入 /grill-me 确认 skill 可用。\n'
}

# =============================================================================
# npx skills（skills.sh，可编辑文件，需手动更新）
# =============================================================================
npx_add() {
  [ -z "$AGENT" ] || set -- "$@" -a "$AGENT"
  [ "$YES" = "no" ] || set -- "$@" -y
  "$@"
}

install_npx() {
  require_cmd npx
  require_cmd git
  printf '提示：安装器询问选择哪些 skills 时，请务必包含 setup-matt-pocock-skills。\n'
  if [ "$SCOPE" = "local" ]; then
    npx_add run_in_target npx skills@latest add "$REPO"
  else
    npx_add run npx skills@latest add "$REPO" -g
  fi
}

verify_npx() {
  require_cmd npx
  if [ "$SCOPE" = "local" ]; then
    _list="$(run_in_target npx skills@latest list 2>&1)" || { printf '%s\n' "$_list"; return 1; }
  else
    _list="$(run npx skills@latest list -g 2>&1)" || { printf '%s\n' "$_list"; return 1; }
  fi
  printf '%s\n' "$_list"
  [ "$DRY_RUN" = "no" ] || return 0
  if printf '%s\n' "$_list" | grep -F "setup-matt-pocock-skills" >/dev/null 2>&1; then
    printf '验证通过：skills list 中找到 setup-matt-pocock-skills。\n'
    return 0
  fi
  printf '验证失败：skills list 中未找到 setup-matt-pocock-skills。\n' >&2
  return 1
}

# =============================================================================
# 安装后提示
# =============================================================================
print_next_steps() {
  printf '\n✓ 完成。\n\n下一步：\n'
  printf '  1. 重启或重新打开对应 agent。\n'
  if [ "$SCOPE" = "local" ]; then
    printf '  2. 在 %s 中打开 agent，运行一次：/setup-matt-pocock-skills\n' "$ABS_TARGET_DIR"
  else
    printf '  2. 在每个要使用的仓库中打开 agent，各运行一次：/setup-matt-pocock-skills\n'
  fi
  printf '  3. 试用：/grill-with-docs I want to add CSV export to the reports page\n'
  case "$CLIENT" in
    npx) printf '\n更新：npx skills@latest update（新增 skill 需重新运行本脚本）\n' ;;
    gemini) printf '\n更新：重新运行本脚本即可（官方：Re-run both commands to update）\n' ;;
    *) printf '\n更新：插件默认自动更新。\n' ;;
  esac
}

# =============================================================================
# 主流程
# =============================================================================
main() {
  detect_platform
  printf '平台：%s\n客户端：%s\n' "$PLATFORM" "$CLIENT"
  print_scope
  [ "$DRY_RUN" = "no" ] || printf '模式：dry-run（只打印命令）\n'
  printf '\n'

  case "$CLIENT" in
    claude-code) _fn="claude" ;;
    *) _fn="$CLIENT" ;;
  esac

  if [ "$VERIFY_ONLY" = "yes" ]; then
    "verify_$_fn"
    exit $?
  fi

  "install_$_fn"
  printf '\n'
  "verify_$_fn" || printf '提示：验证未通过，请重启 agent 后用 --verify-only 再次检查。\n' >&2
  print_next_steps
}

main
