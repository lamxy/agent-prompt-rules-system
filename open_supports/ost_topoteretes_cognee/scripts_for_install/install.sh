#!/bin/sh
# =============================================================================
# install.sh - Cognee installation helper
# Repository: https://github.com/topoteretes/cognee
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --location=local       Install or update into a project virtualenv (default)
#   --location=global      Install or update with pip --user using the selected Python
#   --venv-dir=PATH        Virtualenv path for --location=local (default: .venv)
#   --extras=LIST          Optional Cognee extras, comma-separated
#                          Examples: ollama, postgres, neo4j, docs, anthropic
#   --manager=auto         Prefer uv when available, otherwise pip (default)
#   --manager=uv           Require uv for package installation
#   --manager=pip          Use python -m pip
#   --dry-run              Print the planned actions without installing
#   --help                 Show this help
#
# Examples:
#   ./install.sh
#   ./install.sh --extras=ollama
#   ./install.sh --extras=postgres,neo4j,aws
#   ./install.sh --location=global --manager=pip
# =============================================================================

set -eu

LOCATION="local"
VENV_DIR=".venv"
EXTRAS=""
MANAGER="auto"
DRY_RUN="no"

for arg in "$@"; do
  case "$arg" in
    --location=local) LOCATION="local" ;;
    --location=global) LOCATION="global" ;;
    --venv-dir=*) VENV_DIR="${arg#--venv-dir=}" ;;
    --extras=*) EXTRAS="${arg#--extras=}" ;;
    --manager=auto) MANAGER="auto" ;;
    --manager=uv) MANAGER="uv" ;;
    --manager=pip) MANAGER="pip" ;;
    --dry-run) DRY_RUN="yes" ;;
    --help|-h)
      sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      printf 'Error: unknown option "%s"\nRun "%s --help" for usage.\n' "$arg" "$0" >&2
      exit 1
      ;;
  esac
done

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
      printf 'Error: unsupported platform "%s". This script supports macOS, Linux, and WSL.\n' "$_uname" >&2
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
    printf 'Error: Python was not found. Cognee requires Python 3.10 through 3.14.\n' >&2
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
    printf 'Error: Cognee requires Python 3.10 through 3.14; found %s at %s.\n' "$_ver" "$PYTHON" >&2
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
