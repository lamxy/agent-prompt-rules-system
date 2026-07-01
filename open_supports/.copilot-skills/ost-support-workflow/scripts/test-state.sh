#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STATE_SH="$SCRIPT_DIR/state.sh"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ost-workflow-state-test.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

export OST_WORKFLOW_STATE_DIR="$TMP_DIR/state"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  _file=$1
  _filter=$2
  _expected=$3
  _actual=$(jq -r "$_filter" "$_file")
  [ "$_actual" = "$_expected" ] || fail "$_filter expected $_expected, got $_actual"
}

run_state() {
  sh "$STATE_SH" "$@"
}

assert_fails() {
  if run_state "$@" >/dev/null 2>&1; then
    fail "expected failure: state.sh $*"
  fi
}

mark_core_done() {
  _owner_repo=$1
  run_state set-stage "$_owner_repo" repo_readme_summary done
  run_state set-stage "$_owner_repo" install_script done
  run_state set-stage "$_owner_repo" skill_for_setup done
}

OWNER_REPO="ExampleOwner/example-repo"
STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_example-repo.json"

run_state init "$OWNER_REPO"
assert_fails init "$OWNER_REPO"

[ -f "$STATE_FILE" ] || fail "state file was not created"
assert_jq "$STATE_FILE" '.owner_repo' "$OWNER_REPO"
assert_jq "$STATE_FILE" '.package_dir' 'ost_ExampleOwner_example-repo'
assert_jq "$STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$STATE_FILE" '.current_stage' 'repo_readme_summary'
assert_jq "$STATE_FILE" '.stages.install_script' 'pending'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'pending'
assert_jq "$STATE_FILE" '.usage_examples.decision' 'pending'
assert_jq "$STATE_FILE" '.execution.mode' 'subagent_preferred'
assert_jq "$STATE_FILE" '.execution.dispatch_contracts | length' '0'
assert_jq "$STATE_FILE" '.execution.inline_runs | length' '0'

mark_core_done "$OWNER_REPO"

run_state set-stage "$OWNER_REPO" install_script in_progress
assert_jq "$STATE_FILE" '.current_stage' 'install_script'
assert_jq "$STATE_FILE" '.stages.install_script' 'in_progress'

run_state block "$OWNER_REPO" install_script "Missing default scope" "Use local by default?" "local"
assert_jq "$STATE_FILE" '.workflow_status' 'blocked'
assert_jq "$STATE_FILE" '.stages.install_script' 'blocked'
assert_jq "$STATE_FILE" '.clarifications[-1].status' 'open'
assert_jq "$STATE_FILE" '.clarifications[-1].question' 'Use local by default?'
assert_jq "$STATE_FILE" '.clarifications[-1].suggested_default' 'local'

run_state answer "$OWNER_REPO" "Yes, use local."
assert_jq "$STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$STATE_FILE" '.stages.install_script' 'in_progress'
assert_jq "$STATE_FILE" '.clarifications[-1].status' 'answered'
assert_jq "$STATE_FILE" '.clarifications[-1].answer' 'Yes, use local.'

run_state agent-run "$OWNER_REPO" install_script DONE "Created install.sh"
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].stage' 'install_script'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].status' 'DONE'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].summary' 'Created install.sh'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].executor' 'subagent'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].fallback_reason' 'null'

run_state contract "$OWNER_REPO" install_script "open_supports/ost_ExampleOwner_example-repo" "open_supports/.copilot-skills/ost-install-script/SKILL.md" "repo_readme_summary.md" "DONE,NEEDS_CLARIFICATION,FAILED"
assert_jq "$STATE_FILE" '.execution.dispatch_contracts[-1].stage' 'install_script'
assert_jq "$STATE_FILE" '.execution.dispatch_contracts[-1].executor' 'subagent'
assert_jq "$STATE_FILE" '.execution.dispatch_contracts[-1].package_dir' 'open_supports/ost_ExampleOwner_example-repo'
assert_jq "$STATE_FILE" '.execution.dispatch_contracts[-1].stage_skill_path' 'open_supports/.copilot-skills/ost-install-script/SKILL.md'
assert_jq "$STATE_FILE" '.execution.dispatch_contracts[-1].required_inputs[0]' 'repo_readme_summary.md'
assert_jq "$STATE_FILE" '.execution.dispatch_contracts[-1].allowed_outputs[0]' 'DONE'

run_state inline-run "$OWNER_REPO" skill_for_setup DONE "Updated setup skill" "tool_search found no usable subagent tool"
assert_jq "$STATE_FILE" '.execution.inline_runs[-1].stage' 'skill_for_setup'
assert_jq "$STATE_FILE" '.execution.inline_runs[-1].status' 'DONE'
assert_jq "$STATE_FILE" '.execution.inline_runs[-1].summary' 'Updated setup skill'
assert_jq "$STATE_FILE" '.execution.inline_runs[-1].executor' 'fallback_inline'
assert_jq "$STATE_FILE" '.execution.inline_runs[-1].fallback_reason' 'tool_search found no usable subagent tool'

run_state usage-examples "$OWNER_REPO" accepted "CLI, Agent integration" pending
assert_jq "$STATE_FILE" '.usage_examples.offered' 'true'
assert_jq "$STATE_FILE" '.usage_examples.decision' 'accepted'
assert_jq "$STATE_FILE" '.usage_examples.matched_criteria[0]' 'CLI, Agent integration'
assert_jq "$STATE_FILE" '.usage_examples.result' 'pending'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'in_progress'
assert_jq "$STATE_FILE" '.current_stage' 'optional_usage_examples'

ACCEPTED_DEFAULT_OWNER_REPO="ExampleOwner/accepted-default-usage-examples"
ACCEPTED_DEFAULT_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_accepted-default-usage-examples.json"
run_state init "$ACCEPTED_DEFAULT_OWNER_REPO"
run_state usage-examples "$ACCEPTED_DEFAULT_OWNER_REPO" accepted "CLI, Agent integration"
assert_jq "$ACCEPTED_DEFAULT_STATE_FILE" '.usage_examples.result' 'pending'
assert_jq "$ACCEPTED_DEFAULT_STATE_FILE" '.stages.optional_usage_examples' 'in_progress'

ACCEPTED_EMPTY_RESULT_OWNER_REPO="ExampleOwner/accepted-empty-result-usage-examples"
ACCEPTED_EMPTY_RESULT_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_accepted-empty-result-usage-examples.json"
run_state init "$ACCEPTED_EMPTY_RESULT_OWNER_REPO"
run_state usage-examples "$ACCEPTED_EMPTY_RESULT_OWNER_REPO" accepted "CLI, Agent integration" ""
assert_jq "$ACCEPTED_EMPTY_RESULT_STATE_FILE" '.usage_examples.result' 'pending'
assert_jq "$ACCEPTED_EMPTY_RESULT_STATE_FILE" '.stages.optional_usage_examples' 'in_progress'

INVALID_ACCEPTED_OWNER_REPO="ExampleOwner/invalid-accepted-usage-examples"
INVALID_ACCEPTED_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_invalid-accepted-usage-examples.json"
run_state init "$INVALID_ACCEPTED_OWNER_REPO"
assert_fails usage-examples "$INVALID_ACCEPTED_OWNER_REPO" accepted "CLI, Agent integration" skipped
assert_jq "$INVALID_ACCEPTED_STATE_FILE" '.usage_examples.decision' 'pending'
assert_jq "$INVALID_ACCEPTED_STATE_FILE" '.stages.optional_usage_examples' 'pending'

run_state agent-run "$OWNER_REPO" optional_usage_examples DONE "Created usage_examples.md"
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].stage' 'optional_usage_examples'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].status' 'DONE'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].summary' 'Created usage_examples.md'

run_state usage-examples "$OWNER_REPO" accepted "CLI, Agent integration" generated
assert_jq "$STATE_FILE" '.usage_examples.result' 'generated'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'done'

PENDING_USAGE_OWNER_REPO="ExampleOwner/pending-usage-examples"
PENDING_USAGE_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_pending-usage-examples.json"
run_state init "$PENDING_USAGE_OWNER_REPO"
mark_core_done "$PENDING_USAGE_OWNER_REPO"
run_state test-result "$PENDING_USAGE_OWNER_REPO" skipped "not run" "0" "declined"
assert_fails complete "$PENDING_USAGE_OWNER_REPO"
assert_jq "$PENDING_USAGE_STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$PENDING_USAGE_STATE_FILE" '.stages.optional_usage_examples' 'pending'

NA_OWNER_REPO="ExampleOwner/no-usage-examples"
NA_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_no-usage-examples.json"
run_state init "$NA_OWNER_REPO"
run_state usage-examples "$NA_OWNER_REPO" not_applicable "" skipped
assert_jq "$NA_STATE_FILE" '.usage_examples.offered' 'false'
assert_jq "$NA_STATE_FILE" '.usage_examples.decision' 'not_applicable'
assert_jq "$NA_STATE_FILE" '.usage_examples.matched_criteria | length' '0'
assert_jq "$NA_STATE_FILE" '.usage_examples.result' 'skipped'
assert_jq "$NA_STATE_FILE" '.stages.optional_usage_examples' 'skipped'

NA_DEFAULT_OWNER_REPO="ExampleOwner/no-usage-examples-default"
NA_DEFAULT_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_no-usage-examples-default.json"
run_state init "$NA_DEFAULT_OWNER_REPO"
run_state usage-examples "$NA_DEFAULT_OWNER_REPO" not_applicable ""
assert_jq "$NA_DEFAULT_STATE_FILE" '.usage_examples.offered' 'false'
assert_jq "$NA_DEFAULT_STATE_FILE" '.usage_examples.decision' 'not_applicable'
assert_jq "$NA_DEFAULT_STATE_FILE" '.usage_examples.matched_criteria | length' '0'
assert_jq "$NA_DEFAULT_STATE_FILE" '.usage_examples.result' 'skipped'
assert_jq "$NA_DEFAULT_STATE_FILE" '.stages.optional_usage_examples' 'skipped'

INVALID_NA_OWNER_REPO="ExampleOwner/invalid-na-usage-examples"
INVALID_NA_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_invalid-na-usage-examples.json"
run_state init "$INVALID_NA_OWNER_REPO"
assert_fails usage-examples "$INVALID_NA_OWNER_REPO" not_applicable "" pending
assert_jq "$INVALID_NA_STATE_FILE" '.usage_examples.decision' 'pending'
assert_jq "$INVALID_NA_STATE_FILE" '.stages.optional_usage_examples' 'pending'

DECLINED_OWNER_REPO="ExampleOwner/declined-usage-examples"
DECLINED_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_declined-usage-examples.json"
run_state init "$DECLINED_OWNER_REPO"
run_state usage-examples "$DECLINED_OWNER_REPO" declined "Only one criterion matched" skipped
assert_jq "$DECLINED_STATE_FILE" '.usage_examples.offered' 'true'
assert_jq "$DECLINED_STATE_FILE" '.usage_examples.decision' 'declined'
assert_jq "$DECLINED_STATE_FILE" '.usage_examples.matched_criteria[0]' 'Only one criterion matched'
assert_jq "$DECLINED_STATE_FILE" '.usage_examples.result' 'skipped'
assert_jq "$DECLINED_STATE_FILE" '.stages.optional_usage_examples' 'skipped'

DECLINED_DEFAULT_OWNER_REPO="ExampleOwner/declined-default-usage-examples"
DECLINED_DEFAULT_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_declined-default-usage-examples.json"
run_state init "$DECLINED_DEFAULT_OWNER_REPO"
run_state usage-examples "$DECLINED_DEFAULT_OWNER_REPO" declined "Only one criterion matched"
assert_jq "$DECLINED_DEFAULT_STATE_FILE" '.usage_examples.result' 'skipped'
assert_jq "$DECLINED_DEFAULT_STATE_FILE" '.stages.optional_usage_examples' 'skipped'

INVALID_DECLINED_OWNER_REPO="ExampleOwner/invalid-declined-usage-examples"
INVALID_DECLINED_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_invalid-declined-usage-examples.json"
run_state init "$INVALID_DECLINED_OWNER_REPO"
assert_fails usage-examples "$INVALID_DECLINED_OWNER_REPO" declined "Only one criterion matched" generated
assert_jq "$INVALID_DECLINED_STATE_FILE" '.usage_examples.decision' 'pending'
assert_jq "$INVALID_DECLINED_STATE_FILE" '.stages.optional_usage_examples' 'pending'

INCOMPLETE_CORE_OWNER_REPO="ExampleOwner/incomplete-core-complete"
INCOMPLETE_CORE_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_incomplete-core-complete.json"
run_state init "$INCOMPLETE_CORE_OWNER_REPO"
run_state usage-examples "$INCOMPLETE_CORE_OWNER_REPO" not_applicable "" skipped
run_state test-result "$INCOMPLETE_CORE_OWNER_REPO" skipped "not run" "0" "declined"
assert_fails complete "$INCOMPLETE_CORE_OWNER_REPO"
assert_jq "$INCOMPLETE_CORE_STATE_FILE" '.stages.repo_readme_summary' 'pending'
assert_jq "$INCOMPLETE_CORE_STATE_FILE" '.workflow_status' 'in_progress'

PENDING_TEST_OWNER_REPO="ExampleOwner/pending-test-complete"
PENDING_TEST_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_pending-test-complete.json"
run_state init "$PENDING_TEST_OWNER_REPO"
mark_core_done "$PENDING_TEST_OWNER_REPO"
run_state usage-examples "$PENDING_TEST_OWNER_REPO" not_applicable "" skipped
assert_fails complete "$PENDING_TEST_OWNER_REPO"
assert_jq "$PENDING_TEST_STATE_FILE" '.stages.optional_test_install' 'pending'
assert_jq "$PENDING_TEST_STATE_FILE" '.workflow_status' 'in_progress'

FAILED_TEST_OWNER_REPO="ExampleOwner/failed-test-complete"
FAILED_TEST_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_failed-test-complete.json"
run_state init "$FAILED_TEST_OWNER_REPO"
mark_core_done "$FAILED_TEST_OWNER_REPO"
run_state usage-examples "$FAILED_TEST_OWNER_REPO" not_applicable "" skipped
run_state test-result "$FAILED_TEST_OWNER_REPO" failed "sh install.sh" "1" "install failed"
assert_fails complete "$FAILED_TEST_OWNER_REPO"
assert_jq "$FAILED_TEST_STATE_FILE" '.stages.optional_test_install' 'failed'
assert_jq "$FAILED_TEST_STATE_FILE" '.workflow_status' 'blocked'

SKIPPED_TEST_OWNER_REPO="ExampleOwner/skipped-test-complete"
SKIPPED_TEST_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_skipped-test-complete.json"
run_state init "$SKIPPED_TEST_OWNER_REPO"
mark_core_done "$SKIPPED_TEST_OWNER_REPO"
run_state usage-examples "$SKIPPED_TEST_OWNER_REPO" not_applicable "" skipped
run_state test-result "$SKIPPED_TEST_OWNER_REPO" skipped "not run" "0" "declined"
assert_jq "$SKIPPED_TEST_STATE_FILE" '.test_install.offered' 'true'
assert_jq "$SKIPPED_TEST_STATE_FILE" '.test_install.decision' 'declined'
assert_jq "$SKIPPED_TEST_STATE_FILE" '.test_install.result' 'skipped'
assert_jq "$SKIPPED_TEST_STATE_FILE" '.stages.optional_test_install' 'skipped'
assert_jq "$SKIPPED_TEST_STATE_FILE" '.workflow_status' 'in_progress'
run_state complete "$SKIPPED_TEST_OWNER_REPO"
assert_jq "$SKIPPED_TEST_STATE_FILE" '.workflow_status' 'done'

OFFER_USAGE_OWNER_REPO="ExampleOwner/offer-usage-examples"
OFFER_USAGE_STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_offer-usage-examples.json"
run_state init "$OFFER_USAGE_OWNER_REPO"
run_state offer-usage-examples "$OFFER_USAGE_OWNER_REPO" "CLI, Agent integration"
assert_jq "$OFFER_USAGE_STATE_FILE" '.usage_examples.offered' 'true'
assert_jq "$OFFER_USAGE_STATE_FILE" '.usage_examples.decision' 'pending'
assert_jq "$OFFER_USAGE_STATE_FILE" '.usage_examples.matched_criteria[0]' 'CLI, Agent integration'
assert_jq "$OFFER_USAGE_STATE_FILE" '.usage_examples.result' 'pending'
assert_jq "$OFFER_USAGE_STATE_FILE" '.stages.optional_usage_examples' 'waiting_user'
assert_jq "$OFFER_USAGE_STATE_FILE" '.current_stage' 'optional_usage_examples'
assert_jq "$OFFER_USAGE_STATE_FILE" '.workflow_status' 'blocked'
run_state usage-examples "$OFFER_USAGE_OWNER_REPO" accepted "CLI, Agent integration"
assert_jq "$OFFER_USAGE_STATE_FILE" '.usage_examples.decision' 'accepted'
assert_jq "$OFFER_USAGE_STATE_FILE" '.stages.optional_usage_examples' 'in_progress'
assert_jq "$OFFER_USAGE_STATE_FILE" '.workflow_status' 'in_progress'

run_state test-result "$OWNER_REPO" failed "sh install.sh" "1" "network unavailable"
assert_jq "$STATE_FILE" '.workflow_status' 'blocked'
assert_jq "$STATE_FILE" '.stages.optional_test_install' 'failed'
assert_jq "$STATE_FILE" '.test_install.result' 'failed'
assert_jq "$STATE_FILE" '.test_install.failure.command' 'sh install.sh'

run_state test-result "$OWNER_REPO" passed "tool version" "0" "version printed"
assert_jq "$STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$STATE_FILE" '.stages.optional_test_install' 'done'
assert_jq "$STATE_FILE" '.test_install.result' 'passed'

mark_core_done "$OWNER_REPO"
run_state complete "$OWNER_REPO"
assert_jq "$STATE_FILE" '.workflow_status' 'done'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'done'

run_state show "$OWNER_REPO" >/dev/null

printf 'PASS: state.sh behavior\n'
