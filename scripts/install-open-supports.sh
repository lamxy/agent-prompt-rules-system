#!/bin/sh
# install-open-supports.sh - 安装 open_supports/ 下的支持包
#
# 功能：
#   按名称安装单个支持包，或按清单文件批量安装，分两种作用域：
#   - 项目级（-t）：把支持包复制到 <project>/.claude/open_supports/<ost>/，
#     生成 wrapper Skill（<project>/.claude/skills/<ost>_install/），再在复制后的
#     目录中运行支持包的 scripts_for_install/install.*。
#   - 全局（-g）：不复制支持包、不生成 wrapper Skill，直接在本仓库的
#     open_supports/<ost>/ 中运行安装脚本，由安装脚本写入用户级配置。
#     清单中出现项目级参数（{PROJECT_DIR}、--local、--location=local）时整份拒绝。
#
# 本脚本只安装支持包，不分发清单文件；把场景清单复制到项目或 ~/.claude/
# 由 install-claude-project.sh 负责，它复制后会调用本脚本。
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
用法：
  项目级：sh scripts/install-open-supports.sh -t <project_dir> [安装来源] [选项]
  全局：  sh scripts/install-open-supports.sh -g [安装来源] [选项]

作用域（必选，二选一）：
  -t, --target <project_dir>  项目级安装到该项目根目录（目录必须已存在）
  -g, --global                全局安装：不复制支持包、不生成 wrapper Skill，
                              在本仓库的支持包目录中运行安装脚本

安装来源（可选，二选一；都不给时读取默认清单）：
  -n, --name <支持包>         只安装这一个支持包；其后用 -- 分隔安装参数，
                              例如：-n acme/widget -- --location=local {PROJECT_DIR}
  -l, --list <清单文件>       按清单文件批量安装
                              默认清单：-t 时为 <project_dir>/.claude/open_supports_name_list.txt
                                        -g 时为 ~/.claude/open_supports_name_list.txt

其他选项（均可选）：
  -s, --source <root>         源 open_supports 根目录（默认：<repo>/open_supports）
  -F, --force                 仅项目级：用源支持包替换已复制的支持包与 wrapper Skill，
                              旧版先备份到 <project_dir>/.claude/open_supports.backup-<时间戳>/
  --no-skills                 仅项目级：运行安装脚本，但不生成 wrapper Skill
  --skills-only               仅项目级：复制支持包并生成 wrapper Skill，但不运行安装脚本
  --dry-run                   只打印计划操作，不复制、不写入、不运行安装脚本
  -h, --help                  显示此帮助信息

清单格式（每行一条）：
  <支持包> [安装参数...]
  - 支持包名称写 OwnerName/RepoName 或 ost_OwnerName_RepoName
  - 参数原样传给安装脚本；参数值不能含空格；只支持整行注释（# 开头）
  - 同一支持包可写多行（例如不同客户端），每行各运行一次安装脚本
  - 项目级：{PROJECT_DIR} 替换为项目绝对路径。安装脚本在复制后的支持包目录中运行，
    项目级安装必须用它传入项目目录
  - 全局：不得出现 {PROJECT_DIR}、--local、--location=local，否则整份清单被拒绝，
    不运行任何安装脚本

wrapper Skill（仅项目级）：
  记录该支持包的全部安装命令，供之后重新安装或更新。带生成标记的 Skill 按清单重新
  生成；删除标记行后视为手动维护，不再覆盖（-F 时先备份再覆盖）。用 -n 单独安装时
  只在 Skill 不存在时创建，不覆盖已有的 Skill。

示例：
  sh scripts/install-open-supports.sh -t ~/proj --dry-run
  sh scripts/install-open-supports.sh -t ~/proj -n colbymchenry/codegraph -- --target=claude --location=local {PROJECT_DIR}
  sh scripts/install-open-supports.sh -g --dry-run
  sh scripts/install-open-supports.sh -g -n garrytan/gstack
USAGE
}

fail_usage() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

TARGET=""
GLOBAL=0
SINGLE_NAME=""
SINGLE_ARGS=""
LIST_FILE=""
SOURCE_ROOT=""
FORCE=0
NO_SKILLS=0
SKILLS_ONLY=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -t|--target)
      [ "$#" -ge 2 ] || fail_usage '-t 需要一个值'
      TARGET="$2"
      shift 2
      ;;
    --target=*)
      TARGET="${1#--target=}"
      shift
      ;;
    -g|--global)
      GLOBAL=1
      shift
      ;;
    -n|--name)
      [ "$#" -ge 2 ] || fail_usage '-n 需要一个值'
      SINGLE_NAME="$2"
      shift 2
      ;;
    --name=*)
      SINGLE_NAME="${1#--name=}"
      shift
      ;;
    -l|--list)
      [ "$#" -ge 2 ] || fail_usage '-l 需要一个值'
      LIST_FILE="$2"
      shift 2
      ;;
    --list=*)
      LIST_FILE="${1#--list=}"
      shift
      ;;
    -s|--source)
      [ "$#" -ge 2 ] || fail_usage '-s 需要一个值'
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
    --)
      # Everything after -- belongs to the single package given with -n.
      shift
      [ -n "$SINGLE_NAME" ] || fail_usage '-- 之后的安装参数只能与 -n 一起使用'
      for arg do
        case "$arg" in
          *[[:space:]]*) fail_usage "安装参数不能含空格：$arg" ;;
        esac
      done
      SINGLE_ARGS="$*"
      break
      ;;
    *)
      fail_usage "未知选项：$1"
      ;;
  esac
done

if [ "$GLOBAL" -eq 1 ] && [ -n "$TARGET" ]; then
  fail_usage '-t 与 -g 不可同时使用'
fi
if [ "$GLOBAL" -eq 0 ] && [ -z "$TARGET" ]; then
  fail_usage '必须指定作用域：-t <project_dir>（项目级）或 -g（全局）'
fi
if [ -n "$SINGLE_NAME" ] && [ -n "$LIST_FILE" ]; then
  fail_usage '-n 与 -l 不可同时使用'
fi
if [ "$NO_SKILLS" -eq 1 ] && [ "$SKILLS_ONLY" -eq 1 ]; then
  fail_usage '--no-skills 和 --skills-only 不可同时使用'
fi
if [ "$GLOBAL" -eq 1 ]; then
  [ "$FORCE" -eq 0 ] || fail_usage '-F 只用于项目级：全局安装不复制支持包'
  [ "$SKILLS_ONLY" -eq 0 ] || fail_usage '--skills-only 只用于项目级：全局安装不生成 wrapper Skill'
  # Global installs never vendor packages or write wrapper Skills.
  NO_SKILLS=1
fi

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$REPO_ROOT/open_supports"
fi

if [ "$GLOBAL" -eq 1 ]; then
  ABS_TARGET=""
  [ -n "$LIST_FILE" ] || LIST_FILE="$HOME/.claude/open_supports_name_list.txt"
else
  if [ ! -d "$TARGET" ]; then
    printf '错误：目标目录不存在：%s\n' "$TARGET" >&2
    exit 1
  fi
  ABS_TARGET="$(cd "$TARGET" && pwd -P)"
  [ -n "$LIST_FILE" ] || LIST_FILE="$TARGET/.claude/open_supports_name_list.txt"
fi

if [ ! -d "$SOURCE_ROOT" ]; then
  printf '错误：open_supports 根目录不存在：%s\n' "$SOURCE_ROOT" >&2
  exit 1
fi

if [ -z "$SINGLE_NAME" ] && [ ! -f "$LIST_FILE" ]; then
  printf '错误：列表文件不存在：%s\n' "$LIST_FILE" >&2
  exit 1
fi

TOTAL=0
VENDORED=0
REUSED=0
STALE=0
SKILL_GENERATED=0
SKILL_REUSED=0
SCRIPT_OK=0
MISSING=0
NO_SCRIPT=0
FAILED=0
CONFLICT=0
REJECTED=0

BACKUP_DIR=""
# Packages already vendored / given a wrapper Skill in this run (space separated).
SEEN_PACKAGES=" "
SEEN_SKILLS=" "

TAB="$(printf '\t')"
GENERATED_MARKER='<!-- generated by scripts/install-open-supports.sh; delete this line to keep manual edits -->'

ENTRIES_FILE="$(mktemp "${TMPDIR:-/tmp}/open-supports-entries.XXXXXX")"
trap 'rm -f "$ENTRIES_FILE"' EXIT HUP INT TERM

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

# Moves an existing path into this run's backup directory instead of deleting it.
backup_path() {
  path="$1"
  rel="$2"

  if [ -z "$BACKUP_DIR" ]; then
    base_path="$ABS_TARGET/.claude/open_supports.backup-$(date +%Y%m%d-%H%M%S)"
    BACKUP_DIR="$base_path"
    counter=1
    while [ -e "$BACKUP_DIR" ]; do
      BACKUP_DIR="${base_path}.${counter}"
      counter=$((counter + 1))
    done
  fi

  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$path" "$BACKUP_DIR/$rel"
  printf '[BACKUP] %s -> %s\n' "$path" "$BACKUP_DIR/$rel"
}

copy_support_package() {
  src="$1"
  dest="$2"
  ost_name="$3"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] vendor %s -> %s\n' "$src" "$dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] || [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      backup_path "$dest" "packages/$ost_name"
      cp -R "$src" "$dest"
      printf '[FORCE] 已用源支持包替换：%s\n' "$dest"
      VENDORED=$((VENDORED + 1))
      return 0
    fi

    if [ -L "$dest" ]; then
      printf '[CONFLICT] 支持包路径是一个符号链接：%s\n' "$dest" >&2
      CONFLICT=$((CONFLICT + 1))
      return 1
    fi

    if [ ! -d "$dest" ]; then
      printf '[CONFLICT] 支持包路径不是目录：%s\n' "$dest" >&2
      CONFLICT=$((CONFLICT + 1))
      return 1
    fi

    printf '[REUSED] 复用已有支持包：%s\n' "$dest"
    REUSED=$((REUSED + 1))
    # Only files from the source count: install scripts and users may add files
    # to the vendored copy ("Only in <dest>"), which is not staleness.
    if diff -rq "$src" "$dest" 2>/dev/null | grep -v -F "Only in $dest" | grep . >/dev/null; then
      printf '[STALE] 已有支持包与源不一致，仍使用已有版本；用 -F 更新（旧版会先备份）：%s\n' "$dest" >&2
      STALE=$((STALE + 1))
    fi
    return 0
  fi

  cp -R "$src" "$dest"
  printf '[VENDORED] 已安装支持包：%s\n' "$dest"
  VENDORED=$((VENDORED + 1))
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

runner_for_script() {
  case "$1" in
    *.sh) printf 'sh\n' ;;
    *.py) printf 'python3\n' ;;
    *.js) printf 'node\n' ;;
    *) printf '\n' ;;
  esac
}

# Renders manifest args for the wrapper Skill: {PROJECT_DIR} becomes the
# project root at the time the Skill is used, so the Skill survives a moved
# checkout; other args are quoted only when they contain shell-special chars.
render_skill_args() {
  rendered=""
  for arg in $1; do
    case "$arg" in
      *'{PROJECT_DIR}'*)
        while :; do
          case "$arg" in
            *'{PROJECT_DIR}'*)
              arg="${arg%%\{PROJECT_DIR\}*}\${PROJECT_ROOT}${arg#*\{PROJECT_DIR\}}"
              ;;
            *)
              break
              ;;
          esac
        done
        arg="\"$arg\""
        ;;
      *[!A-Za-z0-9_./=,:@+-]*)
        arg="'$arg'"
        ;;
    esac
    rendered="$rendered $arg"
  done
  printf '%s\n' "$rendered"
}

write_wrapper_skill() {
  ost_name="$1"
  dest_file="$2"
  src_dir="$3"
  slug="$(skill_slug "${ost_name}_install")"

  rel_script=""
  runner=""
  if rel_script="$(find_install_script "$src_dir")"; then
    runner="$(runner_for_script "$rel_script")"
  fi

  {
    printf -- '---\nname: %s\n' "$slug"
    printf 'description: Install, reinstall, or update %s using this project'"'"'s vendored open_supports package.\n---\n\n' "$ost_name"
    printf '%s\n\n' "$GENERATED_MARKER"
    printf '# %s Open Supports Wrapper\n\n' "$ost_name"
    printf 'Use this project-local vendored support package before taking action:\n\n'
    printf '1. Read `.claude/open_supports/%s/repo_readme_summary.md`.\n' "$ost_name"
    printf '2. Read `.claude/open_supports/%s/skill_for_setup/README.md` if it exists.\n' "$ost_name"
    printf '3. Read `.claude/open_supports/%s/skill_for_setup/%s_install/SKILL.md` if it exists.\n' "$ost_name" "$ost_name"
    printf '4. Read every file under `.claude/open_supports/%s/.ost-refs/` if that directory exists and has files.\n\n' "$ost_name"

    if [ -z "$rel_script" ] || [ -z "$runner" ]; then
      printf 'This package has no recognised `scripts_for_install/install.*`; follow the package documentation.\n'
    else
      printf 'Reinstall or update with the same arguments this project was set up with. Run from the project root:\n\n'
      printf '```sh\nPROJECT_ROOT="$(pwd)"\n'
      awk -F "$TAB" -v name="$ost_name" '$1 == name { print $3 }' "$ENTRIES_FILE" | while IFS= read -r entry_args; do
        printf '(cd .claude/open_supports/%s && %s %s%s)\n' "$ost_name" "$runner" "$rel_script" "$(render_skill_args "$entry_args")"
      done
      printf '```\n\n'
      printf 'Each line is one recorded install command (from `.claude/open_supports_name_list.txt` or a single install). Run only the lines the user asked for, and ask before running commands that change user-level configuration.\n'
    fi
  } > "$dest_file"
}

generate_wrapper_skill() {
  ost_name="$1"
  src_dir="$2"
  dest_dir="$TARGET/.claude/skills/${ost_name}_install"
  dest_file="$dest_dir/SKILL.md"

  if [ "$NO_SKILLS" -eq 1 ]; then
    return 0
  fi

  case "$SEEN_SKILLS" in
    *" $ost_name "*) return 0 ;;
  esac
  SEEN_SKILLS="$SEEN_SKILLS$ost_name "

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] generate wrapper Skill: %s\n' "$dest_file"
    return 0
  fi

  if [ -L "$dest_dir" ] || { [ -e "$dest_dir" ] && [ ! -d "$dest_dir" ]; }; then
    if [ "$FORCE" -ne 1 ]; then
      printf '[CONFLICT] wrapper Skill 路径不是普通目录：%s\n' "$dest_dir" >&2
      CONFLICT=$((CONFLICT + 1))
      return 1
    fi
    backup_path "$dest_dir" "skills/${ost_name}_install"
  elif [ -d "$dest_dir" ]; then
    if [ -n "$SINGLE_NAME" ] && [ "$FORCE" -ne 1 ]; then
      # A single install knows only one command; keep the Skill built from the list.
      printf '[REUSED] 单独安装不覆盖已有的 wrapper Skill：%s\n' "$dest_dir"
      SKILL_REUSED=$((SKILL_REUSED + 1))
      return 0
    elif grep -F -x "$GENERATED_MARKER" "$dest_file" >/dev/null 2>&1; then
      : # Generated earlier: regenerate so it matches the current list.
    elif [ "$FORCE" -eq 1 ]; then
      backup_path "$dest_dir" "skills/${ost_name}_install"
    else
      printf '[REUSED] 保留手动维护的 wrapper Skill：%s\n' "$dest_dir"
      SKILL_REUSED=$((SKILL_REUSED + 1))
      return 0
    fi
  fi

  mkdir -p "$dest_dir"
  write_wrapper_skill "$ost_name" "$dest_file" "$src_dir"
  printf '[SKILL] %s\n' "$dest_file"
  SKILL_GENERATED=$((SKILL_GENERATED + 1))
}

run_install_script() {
  pkg_dir="$1"
  rel_script="$2"
  args="$3"

  if [ "$SKILLS_ONLY" -eq 1 ]; then
    return 0
  fi

  # Version 1 manifests do not support quoted args or arg values containing spaces.
  set -- $args

  # Scripts run inside the vendored package directory, so a default target of
  # "." would point there. {PROJECT_DIR} lets a manifest name the real project;
  # it is replaced after splitting, so project paths with spaces still work.
  for arg do
    shift
    while :; do
      case "$arg" in
        *'{PROJECT_DIR}'*)
          arg="${arg%%\{PROJECT_DIR\}*}${ABS_TARGET}${arg#*\{PROJECT_DIR\}}"
          ;;
        *)
          break
          ;;
      esac
    done
    set -- "$@" "$arg"
  done

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] run %s/%s %s\n' "$pkg_dir" "$rel_script" "$*"
    return 0
  fi

  runner="$(runner_for_script "$rel_script")"
  if [ -n "$runner" ]; then
    (cd "$pkg_dir" && "$runner" "$rel_script" "$@")
  elif [ -x "$pkg_dir/$rel_script" ]; then
    (cd "$pkg_dir" && "./$rel_script" "$@")
  else
    return 1
  fi
}

process_entry() {
  ost_name="$1"
  support_name="$2"
  args="$3"

  TOTAL=$((TOTAL + 1))

  if [ "$ost_name" = "-" ]; then
    printf '[MISSING] 无效的支持包名称：%s\n' "$support_name" >&2
    MISSING=$((MISSING + 1))
    return 0
  fi

  src_dir="$SOURCE_ROOT/$ost_name"
  vendored_dir="$TARGET/.claude/open_supports/$ost_name"

  if [ "$GLOBAL" -eq 1 ]; then
    printf '\n==> [GLOBAL] %s %s\n' "$ost_name" "$args"
  else
    printf '\n==> %s %s\n' "$ost_name" "$args"
  fi

  if [ ! -d "$src_dir" ]; then
    printf '[MISSING] 源支持包不存在：%s\n' "$src_dir" >&2
    MISSING=$((MISSING + 1))
    return 0
  fi

  # Global installs run the script from the repository copy; nothing is vendored.
  if [ "$GLOBAL" -eq 1 ]; then
    vendored_dir="$src_dir"
  else
    # A package listed on several lines is vendored once per run.
    case "$SEEN_PACKAGES" in
      *" $ost_name "*)
        ;;
      *)
        SEEN_PACKAGES="$SEEN_PACKAGES$ost_name "
        if ! copy_support_package "$src_dir" "$vendored_dir" "$ost_name"; then
          return 0
        fi
        ;;
    esac

    if ! generate_wrapper_skill "$ost_name" "$src_dir"; then
      return 0
    fi
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
    printf '[FAILED] 安装脚本执行失败：%s\n' "$ost_name" >&2
    FAILED=$((FAILED + 1))
  fi
}

set -f

# Records one parsed entry. Global installs reject project-level arguments up
# front; project installs only warn about user-level ones.
add_entry() {
  support_name="$1"
  args="$2"
  ost_name="$(support_to_ost "$support_name")" || ost_name="-"

  for arg in $args; do
    if [ "$GLOBAL" -eq 1 ]; then
      case "$arg" in
        *'{PROJECT_DIR}'*|--local|--location=local)
          printf '[REJECTED] 全局清单不能含项目级参数 %s：%s %s\n' "$arg" "$support_name" "$args" >&2
          REJECTED=$((REJECTED + 1))
          return 0
          ;;
      esac
    else
      case "$arg" in
        --global|--location=global)
          printf '[WARN] %s 带有用户级参数 %s，建议改放全局清单并用 -g 安装\n' "$support_name" "$arg" >&2
          ;;
      esac
    fi
  done

  printf '%s\t%s\t%s\n' "$ost_name" "$support_name" "$args" >> "$ENTRIES_FILE"
}

if [ "$GLOBAL" -eq 1 ]; then
  printf '[GLOBAL] 用户级安装：不复制支持包、不写入任何项目目录；安装脚本会修改 ~ 下的用户配置\n'
fi

# Pass 1: parse every entry first, so a package's wrapper Skill can record
# every line for that package and a rejected global list installs nothing.
# The list is read on fd 3 in both passes so install scripts keep the
# caller's stdin and cannot consume list lines.
if [ -n "$SINGLE_NAME" ]; then
  add_entry "$SINGLE_NAME" "$SINGLE_ARGS"
else
  while IFS= read -r raw_line <&3 || [ -n "$raw_line" ]; do
    line="$(trim_line "$raw_line")"
    case "$line" in
      ''|\#*)
        continue
        ;;
    esac

    set -- $line
    support_name="$1"
    shift || true
    add_entry "$support_name" "$*"
  done 3< "$LIST_FILE"
fi

if [ "$REJECTED" -gt 0 ]; then
  printf '\n错误：%d 个条目含项目级参数，整份清单未安装。项目级条目请放进项目清单并用 -t 安装。\n' "$REJECTED" >&2
  exit 1
fi

# Pass 2: vendor, generate wrapper Skills, and run install scripts.
while IFS="$TAB" read -r ost_name support_name args <&3; do
  process_entry "$ost_name" "$support_name" "$args"
done 3< "$ENTRIES_FILE"

if [ "$GLOBAL" -eq 1 ]; then
  MODE_NAME=global
else
  MODE_NAME=project
fi

printf '\n完成。mode=%s total=%d vendored=%d reused=%d stale=%d skill_generated=%d skill_reused=%d script_ok=%d missing=%d no_script=%d failed=%d conflict=%d\n' \
  "$MODE_NAME" "$TOTAL" "$VENDORED" "$REUSED" "$STALE" "$SKILL_GENERATED" "$SKILL_REUSED" "$SCRIPT_OK" "$MISSING" "$NO_SCRIPT" "$FAILED" "$CONFLICT"

if [ -n "$BACKUP_DIR" ]; then
  printf '被替换的内容已备份到：%s\n' "$BACKUP_DIR"
fi

if [ "$MISSING" -gt 0 ] || [ "$NO_SCRIPT" -gt 0 ] || [ "$FAILED" -gt 0 ] || [ "$CONFLICT" -gt 0 ]; then
  exit 1
fi
