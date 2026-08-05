#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OPEN_SUPPORTS_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)
STATE_DIR=${OST_WORKFLOW_STATE_DIR:-"$OPEN_SUPPORTS_ROOT/.ost-workflow-state"}

usage() {
  cat <<'EOF'
Usage:
  state.sh init OWNER/REPO
  state.sh show OWNER/REPO
  state.sh set-stage OWNER/REPO STAGE STATUS
  state.sh block OWNER/REPO STAGE REASON QUESTION [SUGGESTED_DEFAULT]
  state.sh answer OWNER/REPO ANSWER
  state.sh scope-contract OWNER/REPO CLASSIFICATION OFFICIAL_DEFAULT TARGET_DIRECTORY_REQUIREMENT EXECUTION_MECHANISM EVIDENCE
  state.sh contract OWNER/REPO STAGE PACKAGE_DIR STAGE_SKILL_PATH REQUIRED_INPUTS ALLOWED_OUTPUTS
  state.sh agent-run OWNER/REPO STAGE STATUS SUMMARY
  state.sh inline-run OWNER/REPO STAGE STATUS SUMMARY FALLBACK_REASON
  state.sh offer-usage-examples OWNER/REPO MATCHED_CRITERIA
  state.sh usage-examples OWNER/REPO DECISION MATCHED_CRITERIA [RESULT]
  state.sh test-result OWNER/REPO RESULT COMMAND EXIT_CODE SUMMARY
  state.sh complete OWNER/REPO
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

need_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required for workflow state JSON operations"
}

now_utc() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

state_name_for() {
  printf '%s' "$1" | tr '/' '_'
}

state_file_for() {
  printf '%s/%s.json' "$STATE_DIR" "$(state_name_for "$1")"
}

require_owner_repo() {
  case "${1:-}" in
    */*) ;;
    *) die "owner/repo is required" ;;
  esac
}

valid_stage() {
  case "$1" in
    repo_readme_summary|install_script|skill_for_setup|optional_usage_examples|optional_test_install) return 0 ;;
    *) return 1 ;;
  esac
}

valid_stage_status() {
  case "$1" in
    pending|in_progress|done|blocked|waiting_user|skipped|failed) return 0 ;;
    *) return 1 ;;
  esac
}

valid_usage_examples_decision() {
  case "$1" in
    accepted|declined|not_applicable) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_state_exists() {
  [ -f "$state_file" ] || die "state file not found: $state_file"
}

cleanup_lock() {
  [ -n "${lock_dir:-}" ] && [ -d "$lock_dir" ] && rmdir "$lock_dir" 2>/dev/null || true
}

acquire_lock() {
  lock_dir="${state_file}.lock"
  i=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    i=$((i + 1))
    [ "$i" -le 50 ] || die "could not acquire state lock: $lock_dir"
    sleep 1
  done
  trap 'cleanup_lock' EXIT HUP INT TERM
}

release_lock() {
  cleanup_lock
  lock_dir=
  trap - EXIT HUP INT TERM
}

write_jq() {
  filter=$1
  shift
  tmp="${state_file}.tmp.$$"
  acquire_lock
  if jq "$@" "$filter" "$state_file" > "$tmp"; then
    mv "$tmp" "$state_file"
    release_lock
  else
    rm -f "$tmp"
    release_lock
    exit 1
  fi
}

cmd_init() {
  require_owner_repo "$1"
  owner_repo=$1
  state_name=$(state_name_for "$owner_repo")
  state_file=$(state_file_for "$owner_repo")
  mkdir -p "$STATE_DIR"
  acquire_lock
  if [ -e "$state_file" ]; then
    release_lock
    die "state file already exists: $state_file"
  fi
  now=$(now_utc)

  tmp="${state_file}.tmp.$$"
  jq -n \
    --arg owner_repo "$owner_repo" \
    --arg package_dir "ost_$state_name" \
    --arg now "$now" \
    '{
      owner_repo: $owner_repo,
      package_dir: $package_dir,
      workflow_status: "in_progress",
      current_stage: "repo_readme_summary",
      stages: {
        repo_readme_summary: "pending",
        install_script: "pending",
        skill_for_setup: "pending",
        optional_usage_examples: "pending",
        optional_test_install: "pending"
      },
      clarifications: [],
      installation_scope: {
        classification: null,
        official_default: null,
        target_directory_requirement: null,
        execution_mechanism: null,
        evidence: []
      },
      usage_examples: {
        offered: false,
        decision: "pending",
        matched_criteria: [],
        result: null
      },
      test_install: {
        offered: false,
        decision: "pending",
        script_command: null,
        verify_commands: [],
        result: null
      },
      execution: {
        mode: "subagent_preferred",
        fallback: "inline",
        current_agent_stage: null,
        dispatch_contracts: [],
        inline_runs: [],
        agent_runs: []
      },
      updated_at: $now
    }' > "$tmp"
  mv "$tmp" "$state_file"
  release_lock
  printf '%s\n' "$state_file"
}

cmd_show() {
  require_owner_repo "$1"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  jq '.' "$state_file"
}

cmd_set_stage() {
  require_owner_repo "$1"
  stage=$2
  status=$3
  valid_stage "$stage" || die "unknown stage: $stage"
  valid_stage_status "$status" || die "unknown stage status: $status"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .stages[$stage] = $status
    | .current_stage = $stage
    | .workflow_status = (if ($status == "blocked" or $status == "failed") then "blocked" else "in_progress" end)
    | .execution.current_agent_stage = (if $status == "in_progress" then $stage else .execution.current_agent_stage end)
    | .updated_at = $now
  ' --arg stage "$stage" --arg status "$status" --arg now "$now"
}

cmd_block() {
  require_owner_repo "$1"
  stage=$2
  reason=$3
  question=$4
  suggested_default=${5:-""}
  valid_stage "$stage" || die "unknown stage: $stage"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .stages[$stage] = "blocked"
    | .current_stage = $stage
    | .workflow_status = "blocked"
    | .clarifications += [{
        stage: $stage,
        reason: $reason,
        question: $question,
        suggested_default: (if $suggested_default == "" then null else $suggested_default end),
        status: "open",
        created_at: $now
      }]
    | .updated_at = $now
  ' \
    --arg stage "$stage" \
    --arg reason "$reason" \
    --arg question "$question" \
    --arg suggested_default "$suggested_default" \
    --arg now "$now"
}

cmd_answer() {
  require_owner_repo "$1"
  answer=$2
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    (.clarifications | to_entries | map(select(.value.status == "open")) | last | .key) as $idx
    | if $idx == null then
        error("no open clarification")
      else
        (.clarifications[$idx].stage) as $stage
        | .clarifications[$idx].status = "answered"
        | .clarifications[$idx].answer = $answer
        | .clarifications[$idx].answered_at = $now
        | .workflow_status = "in_progress"
        | .current_stage = $stage
        | .stages[$stage] = "in_progress"
        | .updated_at = $now
      end
  ' --arg answer "$answer" --arg now "$now"
}

cmd_scope_contract() {
  require_owner_repo "$1"
  classification=$2
  official_default=$3
  target_directory_requirement=$4
  execution_mechanism=$5
  evidence=$6
  case "$classification" in
    A|B|C|D) ;;
    *) die "installation scope classification must be A, B, C, or D" ;;
  esac
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .installation_scope = {
      classification: $classification,
      official_default: $official_default,
      target_directory_requirement: $target_directory_requirement,
      execution_mechanism: $execution_mechanism,
      evidence: (if $evidence == "" then [] else [$evidence] end)
    }
    | .updated_at = $now
  ' \
    --arg classification "$classification" \
    --arg official_default "$official_default" \
    --arg target_directory_requirement "$target_directory_requirement" \
    --arg execution_mechanism "$execution_mechanism" \
    --arg evidence "$evidence" \
    --arg now "$now"
}

cmd_agent_run() {
  require_owner_repo "$1"
  stage=$2
  status=$3
  summary=$4
  valid_stage "$stage" || die "unknown stage: $stage"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .execution.current_agent_stage = $stage
    | .execution.agent_runs += [{
        stage: $stage,
        executor: "subagent",
        fallback_reason: null,
        status: $status,
        summary: $summary,
        recorded_at: $now
      }]
    | .updated_at = $now
  ' --arg stage "$stage" --arg status "$status" --arg summary "$summary" --arg now "$now"
}

cmd_contract() {
  require_owner_repo "$1"
  stage=$2
  package_dir=$3
  stage_skill_path=$4
  required_inputs=$5
  allowed_outputs=$6
  valid_stage "$stage" || die "unknown stage: $stage"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .execution.dispatch_contracts += [{
      stage: $stage,
      executor: "subagent",
      package_dir: $package_dir,
      stage_skill_path: $stage_skill_path,
      required_inputs: (
        if $required_inputs == "" then []
        else ($required_inputs | split(",") | map(gsub("^ +| +$"; "")))
        end
      ),
      allowed_outputs: (
        if $allowed_outputs == "" then []
        else ($allowed_outputs | split(",") | map(gsub("^ +| +$"; "")))
        end
      ),
      context_hygiene: {
        do_not_return: [
          "long official docs excerpts",
          "full README",
          "full generated files",
          "step-by-step private reasoning"
        ]
      },
      recorded_at: $now
    }]
    | .updated_at = $now
  ' \
    --arg stage "$stage" \
    --arg package_dir "$package_dir" \
    --arg stage_skill_path "$stage_skill_path" \
    --arg required_inputs "$required_inputs" \
    --arg allowed_outputs "$allowed_outputs" \
    --arg now "$now"
}

cmd_inline_run() {
  require_owner_repo "$1"
  stage=$2
  status=$3
  summary=$4
  fallback_reason=$5
  valid_stage "$stage" || die "unknown stage: $stage"
  [ -n "$fallback_reason" ] || die "fallback reason is required"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .execution.inline_runs += [{
      stage: $stage,
      executor: "fallback_inline",
      fallback_reason: $fallback_reason,
      status: $status,
      summary: $summary,
      recorded_at: $now
    }]
    | .updated_at = $now
  ' \
    --arg stage "$stage" \
    --arg status "$status" \
    --arg summary "$summary" \
    --arg fallback_reason "$fallback_reason" \
    --arg now "$now"
}

cmd_offer_usage_examples() {
  require_owner_repo "$1"
  criteria=$2
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .usage_examples.offered = true
    | .usage_examples.decision = "pending"
    | .usage_examples.matched_criteria = (if $criteria == "" then [] else [$criteria] end)
    | .usage_examples.result = "pending"
    | .stages.optional_usage_examples = "waiting_user"
    | .current_stage = "optional_usage_examples"
    | .workflow_status = "blocked"
    | .updated_at = $now
  ' --arg criteria "$criteria" --arg now "$now"
}

cmd_usage_examples() {
  require_owner_repo "$1"
  decision=$2
  criteria=$3
  result=${4:-}
  has_result=false
  [ "$#" -eq 4 ] && has_result=true
  valid_usage_examples_decision "$decision" || die "usage examples decision must be accepted, declined, or not_applicable"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  case "$decision" in
    accepted)
      if [ "$has_result" = false ] || [ "$result" = "" ] || [ "$result" = "pending" ]; then
        result=pending
        stage_status=in_progress
      else
        case "$result" in
          generated|done) stage_status=done ;;
          skipped) die "usage examples result 'skipped' is invalid for accepted decision; omit result, use pending, generated, or done" ;;
          *) die "usage examples result '$result' is invalid for accepted decision; omit result, use pending, generated, or done" ;;
        esac
      fi
      ;;
    declined|not_applicable)
      if [ "$has_result" = false ] || [ "$result" = "" ] || [ "$result" = "skipped" ]; then
        result=skipped
        stage_status=skipped
      else
        case "$result" in
          pending|generated|done) die "usage examples result '$result' is invalid for $decision decision; omit result or use skipped" ;;
          *) die "usage examples result '$result' is invalid for $decision decision; omit result or use skipped" ;;
        esac
      fi
      ;;
  esac

  write_jq '
    .usage_examples.offered = (if $decision == "not_applicable" then false else true end)
    | .usage_examples.decision = $decision
    | .usage_examples.matched_criteria = (
        if $decision == "not_applicable" or $criteria == "" then [] else [$criteria] end
      )
    | .usage_examples.result = $result
    | .stages.optional_usage_examples = $stage_status
    | .current_stage = "optional_usage_examples"
    | .workflow_status = "in_progress"
    | .updated_at = $now
  ' \
    --arg decision "$decision" \
    --arg criteria "$criteria" \
    --arg result "$result" \
    --arg stage_status "$stage_status" \
    --arg now "$now"
}

cmd_test_result() {
  require_owner_repo "$1"
  result=$2
  command=$3
  exit_code=$4
  summary=$5
  case "$result" in
    passed|failed|skipped) ;;
    *) die "test result must be passed, failed, or skipped" ;;
  esac
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .current_stage = "optional_test_install"
    | .stages.optional_test_install = (
        if $result == "passed" then "done"
        elif $result == "skipped" then "skipped"
        else "failed"
        end
      )
    | .workflow_status = (
        if $result == "failed" then "blocked"
        else "in_progress"
        end
      )
    | .test_install.offered = true
    | .test_install.decision = (if $result == "skipped" then "declined" else "accepted" end)
    | .test_install.result = $result
    | .test_install.updated_at = $now
    | .test_install.last_command = {
        command: $command,
        exit_code: $exit_code,
        summary: $summary,
        recorded_at: $now
      }
    | if $result == "failed" then
        .test_install.failure = {
          command: $command,
          exit_code: $exit_code,
          output_summary: $summary,
          recorded_at: $now
        }
      else
        .
      end
    | .updated_at = $now
  ' \
    --arg result "$result" \
    --arg command "$command" \
    --arg exit_code "$exit_code" \
    --arg summary "$summary" \
    --arg now "$now"
}

cmd_complete() {
  require_owner_repo "$1"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  for stage in repo_readme_summary install_script skill_for_setup; do
    status=$(jq -r --arg stage "$stage" '(.stages // {}) as $st | if ($st | has($stage)) then $st[$stage] else "__missing__" end' "$state_file")
    [ "$status" = "done" ] || die "$stage must be done before complete; current status: $status"
  done

  optional_usage_examples=$(jq -r 'if .stages | has("optional_usage_examples") then .stages.optional_usage_examples else "__missing__" end' "$state_file")
  case "$optional_usage_examples" in
    __missing__|done|skipped) ;;
    *) die "optional_usage_examples must be done or skipped before complete; current status: $optional_usage_examples" ;;
  esac

  optional_test_install=$(jq -r '(.stages // {}) as $st | if ($st | has("optional_test_install")) then $st.optional_test_install else "__missing__" end' "$state_file")
  test_result=$(jq -r '.test_install.result // "__missing__"' "$state_file")
  case "$optional_test_install" in
    skipped) ;;
    done)
      [ "$test_result" = "passed" ] || die "optional_test_install is done but test_install.result must be passed before complete; current result: $test_result"
      ;;
    *)
      die "optional_test_install must be skipped or done with test_install.result passed before complete; current status: $optional_test_install, result: $test_result"
      ;;
  esac

  scope_complete=$(jq -r '
    (.installation_scope // {}) as $scope
    | if (
        ($scope.classification | IN("A", "B", "C", "D"))
        and (($scope.official_default // "") != "")
        and (($scope.target_directory_requirement // "") != "")
        and (($scope.execution_mechanism // "") != "")
        and (($scope.evidence // []) | length > 0)
      ) then "yes" else "no" end
  ' "$state_file")
  [ "$scope_complete" = "yes" ] || die "installation_scope must record classification, official default, target-directory requirement, execution mechanism, and official evidence before complete"

  write_jq '
    .stages.optional_usage_examples //= "skipped"
    | .usage_examples //= {
        offered: false,
        decision: "not_applicable",
        matched_criteria: [],
        result: null
      }
    | .workflow_status = "done"
    | .updated_at = $now
  ' --arg now "$now"
}

need_jq

cmd=${1:-}
[ -n "$cmd" ] || { usage >&2; exit 2; }
shift || true

case "$cmd" in
  init)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    cmd_init "$1"
    ;;
  show)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    cmd_show "$1"
    ;;
  set-stage)
    [ "$#" -eq 3 ] || { usage >&2; exit 2; }
    cmd_set_stage "$1" "$2" "$3"
    ;;
  block)
    [ "$#" -eq 4 ] || [ "$#" -eq 5 ] || { usage >&2; exit 2; }
    cmd_block "$@"
    ;;
  answer)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    cmd_answer "$1" "$2"
    ;;
  scope-contract)
    [ "$#" -eq 6 ] || { usage >&2; exit 2; }
    cmd_scope_contract "$1" "$2" "$3" "$4" "$5" "$6"
    ;;
  contract)
    [ "$#" -eq 6 ] || { usage >&2; exit 2; }
    cmd_contract "$1" "$2" "$3" "$4" "$5" "$6"
    ;;
  agent-run)
    [ "$#" -eq 4 ] || { usage >&2; exit 2; }
    cmd_agent_run "$1" "$2" "$3" "$4"
    ;;
  inline-run)
    [ "$#" -eq 5 ] || { usage >&2; exit 2; }
    cmd_inline_run "$1" "$2" "$3" "$4" "$5"
    ;;
  offer-usage-examples)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    cmd_offer_usage_examples "$1" "$2"
    ;;
  usage-examples)
    [ "$#" -eq 3 ] || [ "$#" -eq 4 ] || { usage >&2; exit 2; }
    cmd_usage_examples "$@"
    ;;
  test-result)
    [ "$#" -eq 5 ] || { usage >&2; exit 2; }
    cmd_test_result "$1" "$2" "$3" "$4" "$5"
    ;;
  complete)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    cmd_complete "$1"
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
