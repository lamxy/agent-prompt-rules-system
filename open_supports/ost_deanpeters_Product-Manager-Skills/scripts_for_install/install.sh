#!/bin/sh
# =============================================================================
# install.sh - Product Manager Skills 安装助手
# 仓库：https://github.com/deanpeters/Product-Manager-Skills
#
# 用法：
#   ./install.sh [选项] [目标项目目录]
#
# 选项：
#   --client=codex-zip       下载最新 pm-skills-codex.zip 到项目（默认）
#   --client=codex-cli       通过 npx Skills CLI 全局安装指定 skill
#   --client=claude-code     输出官方 Claude Code 插件命令
#   --client=claude-desktop  输出官方 Claude Desktop/Web ZIP 上传步骤
#   --project-dir=PATH       codex-zip 的项目/仓库根目录（默认：.）
#   TARGET_DIR               codex-zip 模式中 --project-dir 的位置参数别名
#   --skill=NAME             codex-cli 使用的 skill 名称
#   --location=local         在支持时使用项目级安装（默认）
#   --location=global        在支持时使用全局安装；codex-cli 必须使用
#   --verify-only            不安装，只在可行时运行验证检查
#   --help                   显示帮助
#
# 示例：
#   ./install.sh --client=codex-zip --project-dir=/path/to/project
#   ./install.sh --client=codex-cli --skill=prd-development --location=global
#   ./install.sh --client=claude-code
# =============================================================================
# 安装模式：双模。官方 Skills CLI 路径为全局安装；本封装的 Codex ZIP 路径写入显式项目目录。

set -eu

REPO="deanpeters/Product-Manager-Skills"
REPO_URL="https://github.com/deanpeters/Product-Manager-Skills"
CODEX_ZIP_URL="https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-codex.zip"
STARTER_PACK_URL="https://github.com/deanpeters/Product-Manager-Skills/releases/latest/download/pm-skills-starter-pack.zip"

CLIENT="codex-zip"
PROJECT_DIR="."
SKILL=""
LOCATION="local"
VERIFY_ONLY="no"
TMP_DIR=""
PROJECT_DIR_SET="no"

usage() {
  sed -n '/^# 用法：/,/^# ====/p' "$0" | sed 's/^# \?//'
  exit 0
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --client=*) CLIENT="${1#--client=}" ;;
    --project-dir=*) PROJECT_DIR="${1#--project-dir=}"; PROJECT_DIR_SET="yes" ;;
    --skill=*) SKILL="${1#--skill=}" ;;
    --location=local) LOCATION="local" ;;
    --location=global|--global) LOCATION="global" ;;
    --verify-only) VERIFY_ONLY="yes" ;;
    --help|-h) usage ;;
    -*)
      printf '错误：未知选项“%s”\n' "$1" >&2
      printf '运行“%s --help”查看用法。\n' "$0" >&2
      exit 1
      ;;
    *)
      if [ "$PROJECT_DIR_SET" = "yes" ]; then
        printf '错误：只能指定一个 TARGET_DIR 或 --project-dir\n' >&2
        exit 1
      fi
      PROJECT_DIR="$1"
      PROJECT_DIR_SET="yes"
      ;;
  esac
  shift
done

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT HUP INT TERM

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
      printf '错误：不支持的平台“%s”。本脚本支持 macOS、Linux 和 WSL。\n' "$_uname" >&2
      printf 'Windows 用户请参考官方 README/文档：\n  %s\n' "$REPO_URL" >&2
      exit 1
      ;;
  esac
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '错误：找不到必需命令：%s\n' "$1" >&2
    exit 1
  fi
}

abs_project_dir() {
  if [ ! -d "$PROJECT_DIR" ]; then
    printf '错误：目标项目目录不存在：%s\n' "$PROJECT_DIR" >&2
    exit 1
  fi

  CDPATH= cd -- "$PROJECT_DIR" && pwd
}

find_extracted_skills_dir() {
  found="$(find "$TMP_DIR/extract" -type d -path '*/.agents/skills' -print 2>/dev/null | sed -n '1p')"
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi

  found="$(find "$TMP_DIR/extract" -type d -path '*/skills' -print 2>/dev/null | sed -n '1p')"
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi

  return 1
}

find_extracted_agents_md() {
  find "$TMP_DIR/extract" -type f -name AGENTS.md -print 2>/dev/null | sed -n '1p'
}

copy_codex_agents_md() {
  project_root="$1"
  agents_src="$2"
  agents_dst="$project_root/AGENTS.md"

  if [ ! -f "$agents_src" ]; then
    printf 'Codex ZIP 中未找到 AGENTS.md；已跳过 AGENTS.md 设置。\n'
    return 0
  fi

  if [ ! -f "$agents_dst" ]; then
    cp "$agents_src" "$agents_dst"
    printf '已从官方 Codex ZIP 创建 AGENTS.md。\n'
    return 0
  fi

  if grep -F "Product Manager Skills" "$agents_dst" >/dev/null 2>&1; then
    printf 'AGENTS.md 已引用 Product Manager Skills；保持不变。\n'
    return 0
  fi

  cat >>"$agents_dst" <<'EOF'

## Product Manager Skills

Product Manager Skills 已安装在 `.agents/skills/` 下。请让 Codex 使用指定 skill，例如：

```text
使用 jobs-to-be-done skill 分析这个客户问题。
```
EOF
  printf '已向现有 AGENTS.md 追加 Product Manager Skills 说明。\n'
}

install_codex_zip() {
  require_cmd curl
  require_cmd unzip

  project_root="$(abs_project_dir)"
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pm-skills-codex.XXXXXX")"
  mkdir -p "$TMP_DIR/extract"

  printf '正在从 %s 下载最新 Codex ZIP\n' "$CODEX_ZIP_URL"
  curl -fsSL "$CODEX_ZIP_URL" -o "$TMP_DIR/pm-skills-codex.zip"
  unzip -q "$TMP_DIR/pm-skills-codex.zip" -d "$TMP_DIR/extract"

  skills_src="$(find_extracted_skills_dir || true)"
  if [ -z "$skills_src" ]; then
    printf '错误：下载的 ZIP 不包含可识别的 skills 目录。\n' >&2
    exit 1
  fi

  skills_dst="$project_root/.agents/skills"
  mkdir -p "$skills_dst"

  copied=0
  for skill_dir in "$skills_src"/*; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$skills_dst/$skill_name"
    cp -R "$skill_dir/." "$skills_dst/$skill_name/"
    copied=$((copied + 1))
  done

  agents_src="$(find_extracted_agents_md || true)"
  copy_codex_agents_md "$project_root" "$agents_src"

  printf '已在 %s 下安装或更新 %s 个 Product Manager skill 文件夹\n' "$skills_dst" "$copied"
}

verify_codex_zip() {
  project_root="$(abs_project_dir)"
  skills_dst="$project_root/.agents/skills"

  if [ ! -d "$skills_dst" ]; then
    printf '验证失败：未找到 skills 目录：%s\n' "$skills_dst" >&2
    return 1
  fi

  count="$(find "$skills_dst" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | sed 's/[ ]//g')"
  if [ "$count" -gt 0 ]; then
    printf '验证通过：在 %s 下找到 %s 个 SKILL.md 文件\n' "$skills_dst" "$count"
  else
    printf '验证失败：在 %s 下未找到 SKILL.md 文件\n' "$skills_dst" >&2
    return 1
  fi

  if [ -f "$project_root/AGENTS.md" ]; then
    printf 'Verification passed: AGENTS.md exists at %s\n' "$project_root/AGENTS.md"
  else
    printf 'Verification warning: AGENTS.md not found at %s\n' "$project_root/AGENTS.md" >&2
  fi
}

install_codex_cli() {
  if [ "$LOCATION" != "global" ]; then
    printf 'Error: --client=codex-cli follows the official Skills CLI Codex command, which uses --location=global.\n' >&2
    printf 'Run again with:\n  %s --client=codex-cli --skill=<skill-name> --location=global\n' "$0" >&2
    exit 1
  fi

  require_cmd npx

  if [ -z "$SKILL" ]; then
    printf 'Error: --client=codex-cli requires --skill=<skill-name>.\n' >&2
    printf 'Discover skills with:\n  npx skills add %s --list\n' "$REPO" >&2
    exit 1
  fi

  printf 'Installing Product Manager skill with Skills CLI: %s\n' "$SKILL"
  npx skills add "$REPO" --skill "$SKILL" -a codex -g
}

verify_codex_cli() {
  if [ "$LOCATION" != "global" ]; then
    printf 'Error: --client=codex-cli verification follows the official global Skills CLI path.\n' >&2
    printf 'Run again with --location=global.\n' >&2
    return 1
  fi

  require_cmd npx

  printf 'Listing Codex skills with Skills CLI...\n'
  if [ -n "$SKILL" ]; then
    if npx skills list -a codex 2>/dev/null | grep -F "$SKILL" >/dev/null 2>&1; then
      printf 'Verification passed: %s is listed for Codex.\n' "$SKILL"
      return 0
    fi
    printf 'Verification failed: %s was not found in npx skills list -a codex.\n' "$SKILL" >&2
    return 1
  fi

  npx skills list -a codex
}

print_claude_code_steps() {
  printf 'Official Claude Code install path is run inside Claude Code:\n'
  printf '  /plugin marketplace add %s\n' "$REPO"
  printf '  /plugin install jobs-to-be-done@pm-skills\n'
  printf '  /reload-plugins\n'
  printf '\n'
  printf 'Other documented examples:\n'
  printf '  /plugin install user-story@pm-skills\n'
  printf '  /plugin install prd-development@pm-skills\n'
  printf '  /plugin install product-strategy-session@pm-skills\n'
}

print_claude_desktop_steps() {
  printf 'Official Claude Desktop/Web install path:\n'
  printf '  1. Download the starter pack: %s\n' "$STARTER_PACK_URL"
  printf '  2. Unzip the pack locally.\n'
  printf '  3. In Claude, open Settings -> Capabilities -> Skills.\n'
  printf '  4. Upload the individual skill ZIPs inside the pack, not the outer pack ZIP.\n'
}

print_next_steps() {
  printf '\nNext prompt to verify behavior:\n'
  printf '  Use the jobs-to-be-done skill to analyze this customer problem.\n'
}

main() {
  if [ "$CLIENT" = "codex-zip" ] && [ "$LOCATION" = "local" ]; then
    PROJECT_DIR="$(abs_project_dir)"
  fi
  detect_platform
  printf 'Platform: %s\n' "$PLATFORM"
  printf 'Client: %s\n' "$CLIENT"
  printf '\n'

  case "$CLIENT" in
    codex-zip)
      if [ "$LOCATION" != "local" ]; then
        printf 'Error: --client=codex-zip supports only --location=local. Use --project-dir to choose the target repo.\n' >&2
        exit 1
      fi
      if [ "$VERIFY_ONLY" = "yes" ]; then
        verify_codex_zip
      else
        install_codex_zip
        verify_codex_zip
        print_next_steps
      fi
      ;;
    codex-cli)
      if [ "$VERIFY_ONLY" = "yes" ]; then
        verify_codex_cli
      else
        install_codex_cli
        verify_codex_cli
        print_next_steps
      fi
      ;;
    claude-code)
      print_claude_code_steps
      ;;
    claude-desktop|claude-web)
      print_claude_desktop_steps
      ;;
    *)
      printf 'Error: unknown --client value "%s".\n' "$CLIENT" >&2
      printf 'Supported clients: codex-zip, codex-cli, claude-code, claude-desktop.\n' >&2
      exit 1
      ;;
  esac
}

main
