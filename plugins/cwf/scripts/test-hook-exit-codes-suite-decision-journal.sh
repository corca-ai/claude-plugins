#!/usr/bin/env bash
set -euo pipefail
# test-hook-exit-codes-suite-decision-journal.sh
# Provides suite_decision_journal_e2e() for test-hook-exit-codes.sh.

suite_decision_journal_e2e() {
  local hook_log_turn=""
  local hook_compact=""
  local sandbox=""
  local transcript=""
  local input_json=""
  local journal_raw=""
  local journal_json=""
  local journal_count=""
  local required_key=""
  local context=""
  local session_id=""
  local required_keys=(decision_id ts session_id question answer source_hook state_version)

  hook_log_turn="$(require_hook_path "log-turn.sh")" || return
  hook_compact="$(require_hook_path "compact-context.sh")" || return

  sandbox="$(new_sandbox_repo)"
  session_id="session-test-$(date +%s%N)"
  mkdir -p "$sandbox/.cwf/projects/s1"

  cat > "$sandbox/.cwf/cwf-state.yaml" <<EOF_STATE
live:
  session_id: "${session_id}"
  dir: ".cwf/projects/s1"
  branch: "test-branch"
  phase: "impl"
  task: "Decision journal test"
  state_file: ".cwf/projects/s1/session-state.yaml"
  key_files: []
  dont_touch: []
  decisions: []
  decision_journal: []
  remaining_gates: []
  state_version: "1"
EOF_STATE

  cat > "$sandbox/.cwf/projects/s1/session-state.yaml" <<EOF_SESSION
live:
  session_id: "${session_id}"
  dir: ".cwf/projects/s1"
  branch: "test-branch"
  phase: "impl"
  task: "Decision journal test"
  key_files: []
  dont_touch: []
  decisions: []
  decision_journal: []
  remaining_gates: []
  state_version: "1"
EOF_SESSION

  transcript="$sandbox/transcript.jsonl"
  jq -nc '
    {
      type:"user",
      timestamp:"2026-02-17T10:00:00.000Z",
      message:{
        content:[
          {type:"text",text:"I choose Proceed"},
          {type:"tool_result",content:"User has answered your question with: Proceed"}
        ]
      }
    }' > "$transcript"
  jq -nc '
    {
      type:"assistant",
      timestamp:"2026-02-17T10:00:02.000Z",
      message:{
        model:"claude-test",
        content:[
          {
            type:"tool_use",
            name:"AskUserQuestion",
            input:{
              questions:[
                {
                  question:"Proceed with strict mode?",
                  header:"Strict mode",
                  options:[{label:"Proceed"},{label:"Cancel"}]
                }
              ]
            }
          }
        ],
        usage:{input_tokens:10,output_tokens:12}
      }
    }' >> "$transcript"

  input_json="$(jq -nc \
    --arg sid "$session_id" \
    --arg transcript "$transcript" \
    --arg cwd "$sandbox" \
    '{session_id:$sid,transcript_path:$transcript,cwd:$cwd}')"
  run_hook "$hook_log_turn" "$sandbox" "$input_json"
  assert_exit_code 0 "log-turn runs for decision journal persistence"

  journal_raw="$(bash "$REPO_ROOT/plugins/cwf/scripts/cwf-live-state.sh" list-get "$sandbox" decision_journal | tail -n 1)"
  if [[ -z "$journal_raw" ]]; then
    fail "decision_journal entry is persisted"
    return
  fi

  journal_json="$(printf '%s' "$journal_raw" | sed 's/\\"/"/g')"
  if ! printf '%s' "$journal_json" | jq -e . >/dev/null 2>&1; then
    fail "decision_journal entry is valid JSON"
    return
  fi
  pass "decision_journal entry is valid JSON"

  for required_key in "${required_keys[@]}"; do
    if [[ "$(printf '%s' "$journal_json" | jq -r --arg k "$required_key" '.[$k] // empty')" == "" ]]; then
      fail "decision_journal required key present: $required_key"
    else
      pass "decision_journal required key present: $required_key"
    fi
  done

  bash "$REPO_ROOT/plugins/cwf/scripts/cwf-live-state.sh" journal-append "$sandbox" "$journal_json" >/dev/null
  journal_count="$(
    bash "$REPO_ROOT/plugins/cwf/scripts/cwf-live-state.sh" list-get "$sandbox" decision_journal \
      | sed '/^$/d' \
      | wc -l \
      | tr -d ' '
  )"
  if [[ "$journal_count" == "1" ]]; then
    pass "decision_journal append is idempotent by decision_id"
  else
    fail "decision_journal append is idempotent by decision_id (count=$journal_count)"
  fi

  input_json="$(jq -nc --arg sid "$session_id" --arg cwd "$sandbox" '{session_id:$sid,cwd:$cwd}')"
  run_hook "$hook_compact" "$sandbox" "$input_json"
  assert_exit_code 0 "compact-context hook runs for recovery output"

  context="$(printf '%s' "$LAST_OUTPUT" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null || true)"
  if [[ "$context" == *"Decision journal"* && "$context" == *"Proceed with strict mode?"* && "$context" == *"Proceed"* ]]; then
    pass "compact recovery context includes decision_journal details"
  else
    fail "compact recovery context includes decision_journal details"
  fi
}
