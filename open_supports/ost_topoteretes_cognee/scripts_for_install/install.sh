#!/bin/sh
# =============================================================================
# install.sh - Cognee 安装助手
# 仓库：https://github.com/topoteretes/cognee
#
# 用法：
#   ./install.sh [选项] [目标项目目录]
#
# 选项：
#   --location=local       安装或更新到项目虚拟环境（默认）
#   --location=global      使用所选 Python 的 pip --user 安装或更新
#   --venv-dir=PATH        --location=local 的虚拟环境路径（默认：.venv）
#   TARGET_DIR             本地项目根目录；默认虚拟环境为 TARGET_DIR/.venv
#   --extras=LIST          可选 Cognee extras，逗号分隔
#                          示例：ollama、postgres、neo4j、docs、anthropic
#   --manager=auto         优先使用可用的 uv，否则使用 pip（默认）
#   --manager=uv           要求使用 uv 安装包
#   --manager=pip          使用 python -m pip
#   --dry-run              只输出计划操作，不安装
#   --help                 显示帮助
#
# 示例：
#   ./install.sh
#   ./install.sh --extras=ollama
#   ./install.sh --extras=postgres,neo4j,aws
#   ./install.sh --location=global --manager=pip
# =============================================================================
# 安装模式：双模。本地封装使用显式虚拟环境路径；全局模式使用当前用户的 Python 环境。

set -eu

LOCATION="local"
VENV_DIR=".venv"
EXTRAS=""
MANAGER="auto"
DRY_RUN="no"
TARGET_DIR="."
TARGET_DIR_SET="no"
VENV_DIR_SET="no"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --location=local|--local) LOCATION="local" ;;
    --location=global|--global) LOCATION="global" ;;
    --venv-dir=*) VENV_DIR="${1#--venv-dir=}"; VENV_DIR_SET="yes" ;;
    --extras=*) EXTRAS="${1#--extras=}" ;;
    --manager=auto) MANAGER="auto" ;;
    --manager=uv) MANAGER="uv" ;;
    --manager=pip) MANAGER="pip" ;;
    --dry-run) DRY_RUN="yes" ;;
    --help|-h)
      sed -n '/^# 用法：/,/^# ====/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      printf '错误：未知选项“%s”\n运行“%s --help”查看用法。\n' "$1" "$0" >&2
      exit 1
      ;;
    *)
      if [ "$TARGET_DIR_SET" = "yes" ]; then
        printf '错误：只能指定一个 TARGET_DIR\n' >&2
        exit 1
      fi
      TARGET_DIR="$1"
      TARGET_DIR_SET="yes"
      ;;
  esac
  shift
done

if [ "$LOCATION" = "local" ]; then
  [ -d "$TARGET_DIR" ] || {
    printf '错误：目标项目目录不存在：%s\n' "$TARGET_DIR" >&2
    exit 1
  }
  TARGET_DIR="$(CDPATH= cd -- "$TARGET_DIR" && pwd)"
  if [ "$VENV_DIR_SET" = "no" ]; then
    VENV_DIR="$TARGET_DIR/.venv"
  fi
fi

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
      printf 'Windows users can use PowerShell directly:\n' >&2
      printf '  uv venv\n  .\\.venv\\Scripts\\Activate.ps1\n  uv pip install cognee\n' >&2
      exit 1
      ;;
  esac
}

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    PYTHON="$(command -v python3)"
  elif command -v python >/dev/null 2>&1; then
    PYTHON="$(command -v python)"
  else
    printf '错误：未找到 Python。Cognee 需要 Python 3.10 至 3.14。\n' >&2
    exit 1
  fi
}

check_python_version() {
  if ! "$PYTHON" - <<'PY'
import sys
raise SystemExit(0 if (3, 10) <= sys.version_info[:2] < (3, 15) else 1)
PY
  then
    _ver="$("$PYTHON" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null || printf 'unknown')"
    printf '错误：Cognee 需要 Python 3.10 至 3.14；在 %s 找到 %s。\n' "$PYTHON" "$_ver" >&2
    exit 1
  fi
}

validate_options() {
  case "$LOCATION" in
    local|global) ;;
    *)
      printf 'Error: invalid location "%s".\n' "$LOCATION" >&2
      exit 1
      ;;
  esac

  case "$MANAGER" in
    auto|uv|pip) ;;
    *)
      printf 'Error: invalid manager "%s".\n' "$MANAGER" >&2
      exit 1
      ;;
  esac

  case "$EXTRAS" in
    *[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_,-]*)
      printf 'Error: extras may only contain letters, numbers, underscore, hyphen, and comma.\n' >&2
      exit 1
      ;;
  esac

  case "$VENV_DIR" in
    "") printf 'Error: --venv-dir cannot be empty.\n' >&2; exit 1 ;;
  esac
}

choose_manager() {
  if [ "$MANAGER" = "uv" ]; then
    if ! command -v uv >/dev/null 2>&1; then
      printf 'Error: --manager=uv was requested, but uv was not found in PATH.\n' >&2
      printf 'Install uv first or rerun with --manager=pip.\n' >&2
      exit 1
    fi
    PKG_MANAGER="uv"
    return
  fi

  if [ "$MANAGER" = "pip" ]; then
    PKG_MANAGER="pip"
    return
  fi

  if command -v uv >/dev/null 2>&1; then
    PKG_MANAGER="uv"
  else
    PKG_MANAGER="pip"
  fi
}

build_package_spec() {
  if [ -n "$EXTRAS" ]; then
    PACKAGE_SPEC="cognee[$EXTRAS]"
  else
    PACKAGE_SPEC="cognee"
  fi
}

local_python() {
  printf '%s/bin/python' "$VENV_DIR"
}

local_cli() {
  printf '%s/bin/cognee-cli' "$VENV_DIR"
}

print_summary() {
  printf '=== Cognee install/update summary ===\n'
  printf 'Platform: %s\n' "$PLATFORM"
  printf 'Python: %s\n' "$PYTHON"
  printf 'Location: %s\n' "$LOCATION"
  if [ "$LOCATION" = "local" ]; then
    printf 'Virtualenv: %s\n' "$VENV_DIR"
  fi
  printf 'Package: %s\n' "$PACKAGE_SPEC"
  printf 'Installer: %s\n' "$PKG_MANAGER"
  printf 'Configuration files: this script will not create or modify .env, Docker, Claude, or Agent configuration.\n'
  printf '\n'
}

ensure_local_venv() {
  if [ -x "$(local_python)" ]; then
    printf '%s\n' "-> Reusing existing virtualenv at $VENV_DIR"
    return
  fi

  printf '%s\n' "-> Creating virtualenv at $VENV_DIR"
  if [ "$PKG_MANAGER" = "uv" ]; then
    uv venv "$VENV_DIR" --python "$PYTHON"
  else
    "$PYTHON" -m venv "$VENV_DIR"
  fi
}

install_local() {
  ensure_local_venv
  VENV_PY="$(local_python)"

  if "$VENV_PY" -c 'import cognee' >/dev/null 2>&1; then
    _installed="$("$VENV_PY" -c 'import cognee; print(getattr(cognee, "__version__", "installed"))' 2>/dev/null || printf 'installed')"
    printf '%s\n' "-> Cognee is already present in $VENV_DIR ($_installed); updating with the package manager."
  else
    printf '%s\n' "-> Installing Cognee into $VENV_DIR"
  fi

  if [ "$PKG_MANAGER" = "uv" ]; then
    uv pip install --python "$VENV_PY" --upgrade "$PACKAGE_SPEC"
  else
    "$VENV_PY" -m pip install --upgrade pip
    "$VENV_PY" -m pip install --upgrade "$PACKAGE_SPEC"
  fi
}

install_global() {
  if "$PYTHON" -c 'import cognee' >/dev/null 2>&1; then
    _installed="$("$PYTHON" -c 'import cognee; print(getattr(cognee, "__version__", "installed"))' 2>/dev/null || printf 'installed')"
    printf '%s\n' "-> Cognee is already available to $PYTHON ($_installed); updating with pip --user."
  else
    printf '%s\n' '-> Installing Cognee for the current user with pip --user.'
  fi

  if [ "$PKG_MANAGER" = "uv" ]; then
    printf '%s\n' '-> Global installs use pip --user to avoid modifying system Python.'
  fi
  "$PYTHON" -m pip install --user --upgrade "$PACKAGE_SPEC"
}

verify_install() {
  if [ "$LOCATION" = "local" ]; then
    VERIFY_PY="$(local_python)"
    VERIFY_CLI="$(local_cli)"
  else
    VERIFY_PY="$PYTHON"
    VERIFY_CLI="cognee-cli"
  fi

  printf '\n=== Verification ===\n'
  "$VERIFY_PY" -c 'import cognee; print("Cognee import OK:", cognee.__file__)'

  if [ "$LOCATION" = "local" ]; then
    if [ -x "$VERIFY_CLI" ]; then
      printf 'Cognee CLI OK: %s\n' "$VERIFY_CLI"
    else
      printf 'Warning: %s was not found. Try reopening the shell or reinstalling with pip.\n' "$VERIFY_CLI" >&2
    fi
  elif command -v "$VERIFY_CLI" >/dev/null 2>&1; then
    printf 'Cognee CLI OK: %s\n' "$(command -v "$VERIFY_CLI")"
  else
    printf 'Warning: cognee-cli is not on PATH. Ensure your user base bin directory is on PATH.\n' >&2
  fi

  printf '\nNext steps:\n'
  if [ "$LOCATION" = "local" ]; then
    printf '  . %s/bin/activate\n' "$VENV_DIR"
  fi
  printf '  export LLM_API_KEY="YOUR_OPENAI_API_KEY"\n'
  printf '  cognee-cli remember "Cognee turns documents into AI memory."\n'
  printf '  cognee-cli recall "What does Cognee do?"\n'
  printf '\nFor the local UI, start Docker first, then run: cognee-cli -ui\n'
}

main() {
  detect_platform
  find_python
  check_python_version
  validate_options
  choose_manager
  build_package_spec
  print_summary

  if [ "$DRY_RUN" = "yes" ]; then
    printf 'Dry run only; no changes were made.\n'
    exit 0
  fi

  if [ "$LOCATION" = "local" ]; then
    install_local
  else
    install_global
  fi

  verify_install
}

main
