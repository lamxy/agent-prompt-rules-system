#!/bin/sh
# Validate local-install target handling without allowing installers to write.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MISSING_TARGET=/tmp/ost-missing-target

assert_missing_target_fails() {
  package=$1
  shift

  output=$(sh "$ROOT_DIR/open_supports/$package/scripts_for_install/install.sh" "$@" "$MISSING_TARGET" 2>&1) && {
    printf 'Expected %s to reject a missing target directory.\n' "$package" >&2
    return 1
  }

  printf '%s\n' "$output" | grep -F 'Target project directory does not exist' >/dev/null || {
    printf 'Expected missing-target error from %s, got:\n%s\n' "$package" "$output" >&2
    return 1
  }
}

assert_help_works() {
  package=$1
  sh "$ROOT_DIR/open_supports/$package/scripts_for_install/install.sh" --help >/dev/null
}

assert_missing_target_fails ost_open-gsd_gsd-core --claude --local
assert_missing_target_fails ost_colbymchenry_codegraph --location=local
assert_missing_target_fails ost_eyaltoledano_claude-task-master --local
assert_missing_target_fails ost_msitarzewski_agency-agents --tool=codex --dry-run
assert_missing_target_fails ost_deanpeters_Product-Manager-Skills --client=codex-zip
assert_missing_target_fails ost_phuryn_pm-skills --client=opencode --location=local --repo-dir=/tmp/unused
assert_missing_target_fails ost_topoteretes_cognee --location=local --dry-run
assert_missing_target_fails ost_garrytan_gstack --team=required
assert_missing_target_fails ost_Fission-AI_OpenSpec --init-project

for package in \
  ost_open-gsd_gsd-core \
  ost_colbymchenry_codegraph \
  ost_eyaltoledano_claude-task-master \
  ost_msitarzewski_agency-agents \
  ost_deanpeters_Product-Manager-Skills \
  ost_phuryn_pm-skills \
  ost_topoteretes_cognee \
  ost_garrytan_gstack \
  ost_Fission-AI_OpenSpec
do
  assert_help_works "$package"
done

printf 'All project-local installers reject a nonexistent target before installation.\n'
