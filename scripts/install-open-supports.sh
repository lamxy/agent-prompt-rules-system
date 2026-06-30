#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/install-open-supports.sh -t <target_project_dir> [options]

Options:
  -t, --target <target_project_dir>
                             Target project root directory
  -l, --list <list_file>     List file (default: <target>/.claude/open_supports_name_list.txt)
  -s, --source <source_root> Source open_supports root (default: <repo>/open_supports)
  -F, --force                Force overwrite vendored support packages and wrapper Skills
  --no-skills                Vendor packages and run install scripts, but do not generate wrapper Skills
  --skills-only              Vendor packages and generate wrapper Skills, but do not run install scripts
  --dry-run                  Print planned actions without copying or running scripts
  -h, --help                 Show this help message

Manifest format:
  <support-name> [install args...]

Support names:
  GithubName/RepoName        Example: colbymchenry/codegraph
  ost_GithubName_RepoName    Example: ost_colbymchenry_codegraph
USAGE
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

TARGET=""
LIST_FILE=""
SOURCE_ROOT=""
FORCE=0
NO_SKILLS=0
SKILLS_ONLY=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -t|--target)
      [ "$#" -ge 2 ] || fail_usage '-t requires a value'
      TARGET="$2"
      shift 2
      ;;
    --target=*)
      TARGET="${1#--target=}"
      shift
      ;;
    -l|--list)
      [ "$#" -ge 2 ] || fail_usage '-l requires a value'
      LIST_FILE="$2"
      shift 2
      ;;
    --list=*)
      LIST_FILE="${1#--list=}"
      shift
      ;;
    -s|--source)
      [ "$#" -ge 2 ] || fail_usage '-s requires a value'
      SOURCE_ROOT="$2"
      shift 2
      ;;
    --source=*)
      SOURCE_ROOT="${1#--source=}"
      shift
      ;;
    -F|--force)
      FORCE=1
      shift
      ;;
    --no-skills)
      NO_SKILLS=1
      shift
      ;;
    --skills-only)
      SKILLS_ONLY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail_usage "unknown option: $1"
      ;;
  esac
done

[ -n "$TARGET" ] || fail_usage '-t <target_project_dir> is required'

if [ "$NO_SKILLS" -eq 1 ] && [ "$SKILLS_ONLY" -eq 1 ]; then
  fail_usage '--no-skills and --skills-only are mutually exclusive'
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/open_supports"
fi

if [ -z "$LIST_FILE" ]; then
  LIST_FILE="$TARGET/.claude/open_supports_name_list.txt"
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: target directory does not exist: %s\n' "$TARGET" >&2
  exit 1
fi

if [ ! -d "$SOURCE_ROOT" ]; then
  printf 'Error: open_supports root not found: %s\n' "$SOURCE_ROOT" >&2
  exit 1
fi

if [ ! -f "$LIST_FILE" ]; then
  printf 'Error: list file not found: %s\n' "$LIST_FILE" >&2
  exit 1
fi

TOTAL=0
VENDORED=0
REUSED=0
SKILL_GENERATED=0
SKILL_REUSED=0
SCRIPT_OK=0
MISSING=0
NO_SCRIPT=0
FAILED=0
CONFLICT=0

trim_line() {
  printf '%s\n' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

support_to_ost() {
  name="$1"
  case "$name" in
    ost_*)
      ost_name="$name"
      ;;
    */*)
      ost_name="ost_$(printf '%s\n' "$name" | sed 's,/,_,g')"
      ;;
    *)
      return 1
      ;;
  esac

  case "$ost_name" in
    ost_[A-Za-z0-9._-]*)
      ;;
    *)
      return 1
      ;;
  esac

  case "$ost_name" in
    *..*|*[!A-Za-z0-9._-]*)
      return 1
      ;;
  esac

  printf '%s\n' "$ost_name"
}

skill_slug() {
  printf '%s\n' "$1" | sed 's/_/-/g'
}

copy_support_package() {
  src="$1"
  dest="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] vendor %s -> %s\n' "$src" "$dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] replacing support package symlink: %s\n' "$dest"
      rm -rf "$dest"
      cp -R "$src" "$dest"
      VENDORED=$((VENDORED + 1))
      return 0
    fi
    printf '[CONFLICT] support package path is a symlink: %s\n' "$dest" >&2
    CONFLICT=$((CONFLICT + 1))
    return 1
  fi

  if [ -d "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] replacing support package: %s\n' "$dest"
      rm -rf "$dest"
      cp -R "$src" "$dest"
      VENDORED=$((VENDORED + 1))
      return 0
    fi
    printf '[REUSED] support package: %s\n' "$dest"
    REUSED=$((REUSED + 1))
    return 0
  fi

  if [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] replacing support package file: %s\n' "$dest"
      rm -rf "$dest"
      cp -R "$src" "$dest"
      VENDORED=$((VENDORED + 1))
      return 0
    fi
    printf '[CONFLICT] support package path is not a directory: %s\n' "$dest" >&2
    CONFLICT=$((CONFLICT + 1))
    return 1
  fi

  cp -R "$src" "$dest"
  printf '[VENDORED] support package: %s\n' "$dest"
  VENDORED=$((VENDORED + 1))
}

generate_wrapper_skill() {
  ost_name="$1"
  target_dir="$2"
  dest_dir="$target_dir/.claude/skills/${ost_name}_install"
  dest_file="$dest_dir/SKILL.md"
  slug="$(skill_slug "${ost_name}_install")"

  if [ "$NO_SKILLS" -eq 1 ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] generate wrapper Skill: %s\n' "$dest_file"
    return 0
  fi

  if [ -L "$dest_dir" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] replacing wrapper Skill symlink: %s\n' "$dest_dir"
      rm -rf "$dest_dir"
    else
      printf '[CONFLICT] wrapper Skill path is a symlink: %s\n' "$dest_dir" >&2
      CONFLICT=$((CONFLICT + 1))
      return 1
    fi
  elif [ -d "$dest_dir" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] replacing wrapper Skill: %s\n' "$dest_dir"
      rm -rf "$dest_dir"
    else
      printf '[REUSED] wrapper Skill: %s\n' "$dest_dir"
      SKILL_REUSED=$((SKILL_REUSED + 1))
      return 0
    fi
  elif [ -e "$dest_dir" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] replacing wrapper Skill file: %s\n' "$dest_dir"
      rm -rf "$dest_dir"
    else
      printf '[CONFLICT] wrapper Skill path is not a directory: %s\n' "$dest_dir" >&2
      CONFLICT=$((CONFLICT + 1))
      return 1
    fi
  fi

  mkdir -p "$dest_dir"
  cat > "$dest_file" <<EOF_SKILL
---
name: $slug
description: Install or update ${ost_name} using this project's vendored open_supports package.
---

# ${ost_name} Open Supports Wrapper

Use this project-local vendored support package before taking action:

1. Read \`.claude/open_supports/${ost_name}/repo_readme_summary.md\`.
2. Read \`.claude/open_supports/${ost_name}/skill_for_setup/README.md\` if it exists.
3. Read \`.claude/open_supports/${ost_name}/skill_for_setup/${ost_name}_install/SKILL.md\` if it exists.
4. Read every file under \`.claude/open_supports/${ost_name}/.ost-refs/\` if that directory exists and has files.

Run the vendored install script from the vendored package directory:

\`\`\`sh
cd .claude/open_supports/${ost_name}
sh scripts_for_install/install.sh
\`\`\`

If the support package uses a non-sh installer, inspect \`.claude/open_supports/${ost_name}/scripts_for_install/\` and use the matching runtime described by the package documentation.
EOF_SKILL

  printf '[SKILL] %s\n' "$dest_file"
  SKILL_GENERATED=$((SKILL_GENERATED + 1))
}

find_install_script() {
  pkg_dir="$1"

  for rel in \
    scripts_for_install/install.sh \
    scripts_for_install/install.py \
    scripts_for_install/install.js
  do
    if [ -f "$pkg_dir/$rel" ]; then
      printf '%s\n' "$rel"
      return 0
    fi
  done

  set +f
  for abs in "$pkg_dir"/scripts_for_install/install.*; do
    [ -f "$abs" ] || continue
    printf 'scripts_for_install/%s\n' "$(basename "$abs")"
    set -f
    return 0
  done
  set -f

  return 1
}

run_install_script() {
  pkg_dir="$1"
  rel_script="$2"
  args="$3"

  if [ "$SKILLS_ONLY" -eq 1 ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] run %s/%s %s\n' "$pkg_dir" "$rel_script" "$args"
    return 0
  fi

  # Version 1 manifests do not support quoted args or arg values containing spaces.
  set -- $args
  case "$rel_script" in
    *.sh)
      (cd "$pkg_dir" && sh "$rel_script" "$@")
      ;;
    *.py)
      (cd "$pkg_dir" && python3 "$rel_script" "$@")
      ;;
    *.js)
      (cd "$pkg_dir" && node "$rel_script" "$@")
      ;;
    *)
      if [ -x "$pkg_dir/$rel_script" ]; then
        (cd "$pkg_dir" && "./$rel_script" "$@")
      else
        return 1
      fi
      ;;
  esac
}

process_entry() {
  support_name="$1"
  args="$2"

  TOTAL=$((TOTAL + 1))

  if ! ost_name="$(support_to_ost "$support_name")"; then
    printf '[MISSING] invalid support name: %s\n' "$support_name" >&2
    MISSING=$((MISSING + 1))
    return 0
  fi

  src_dir="$SOURCE_ROOT/$ost_name"
  vendored_dir="$TARGET/.claude/open_supports/$ost_name"

  printf '\n==> %s\n' "$ost_name"

  if [ ! -d "$src_dir" ]; then
    printf '[MISSING] source package not found: %s\n' "$src_dir" >&2
    MISSING=$((MISSING + 1))
    return 0
  fi

  if ! copy_support_package "$src_dir" "$vendored_dir"; then
    return 0
  fi

  if ! generate_wrapper_skill "$ost_name" "$TARGET"; then
    return 0
  fi

  if [ "$SKILLS_ONLY" -eq 1 ]; then
    return 0
  fi

  script_dir="$vendored_dir"
  if [ "$DRY_RUN" -eq 1 ]; then
    script_dir="$src_dir"
  fi

  if ! rel_script="$(find_install_script "$script_dir")"; then
    printf '[NO_SCRIPT] %s/scripts_for_install/install.*\n' "$script_dir" >&2
    NO_SCRIPT=$((NO_SCRIPT + 1))
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    run_install_script "$vendored_dir" "$rel_script" "$args"
    return 0
  fi

  if run_install_script "$vendored_dir" "$rel_script" "$args"; then
    printf '[SCRIPT_OK] %s\n' "$ost_name"
    SCRIPT_OK=$((SCRIPT_OK + 1))
  else
    printf '[FAILED] install script failed: %s\n' "$ost_name" >&2
    FAILED=$((FAILED + 1))
  fi
}

set -f

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  line="$(trim_line "$raw_line")"
  case "$line" in
    ''|\#*)
      continue
      ;;
  esac

  set -- $line
  support_name="$1"
  shift || true
  args="$*"

  process_entry "$support_name" "$args"
done < "$LIST_FILE"

printf '\nDone. total=%d vendored=%d reused=%d skill_generated=%d skill_reused=%d script_ok=%d missing=%d no_script=%d failed=%d conflict=%d\n' \
  "$TOTAL" "$VENDORED" "$REUSED" "$SKILL_GENERATED" "$SKILL_REUSED" "$SCRIPT_OK" "$MISSING" "$NO_SCRIPT" "$FAILED" "$CONFLICT"

if [ "$MISSING" -gt 0 ] || [ "$NO_SCRIPT" -gt 0 ] || [ "$FAILED" -gt 0 ] || [ "$CONFLICT" -gt 0 ]; then
  exit 1
fi
