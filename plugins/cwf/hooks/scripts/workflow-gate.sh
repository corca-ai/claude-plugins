#!/usr/bin/env bash
set -euo pipefail
# workflow-gate.sh — UserPromptSubmit gate for active cwf:run workflows.
# Emits status warnings and blocks ship/push/commit intents while critical gates remain.

HOOK_GROUP="workflow_gate"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"

INPUT="$(cat)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIVE_STATE_SCRIPT="$PLUGIN_ROOT/scripts/cwf-live-state.sh"
ARTIFACT_PATHS_SCRIPT="$PLUGIN_ROOT/scripts/cwf-artifact-paths.sh"
BLOCKED_ACTION_REGEX='(^|[[:space:]])(cwf:ship|/ship|git[[:space:]]+push|git[[:space:]]+merge|'
BLOCKED_ACTION_REGEX+='gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+pr[[:space:]]+merge|'
BLOCKED_ACTION_REGEX+='커밋해|푸시해|배포해)([[:space:]]|$)'

json_block() {
  local reason="$1"
  local reason_json="$reason"
  if command -v jq >/dev/null 2>&1; then
    reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  else
    reason_json="${reason_json//\\/\\\\}"
    reason_json="${reason_json//\"/\\\"}"
    reason_json="${reason_json//$'\n'/ }"
    reason_json="\"$reason_json\""
  fi
  cat <<JSON
{"decision":"block","reason":${reason_json}}
JSON
  exit 1
}

json_allow() {
  local reason="$1"
  local reason_json="$reason"
  if command -v jq >/dev/null 2>&1; then
    reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  else
    reason_json="${reason_json//\\/\\\\}"
    reason_json="${reason_json//\"/\\\"}"
    reason_json="${reason_json//$'\n'/ }"
    reason_json="\"$reason_json\""
  fi
  cat <<JSON
{"decision":"allow","reason":${reason_json}}
JSON
  exit 0
}

extract_json_field() {
  local input_json="$1"
  local field="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input_json" | jq -r --arg key "$field" '.[$key] // empty'
    return
  fi

  # Best-effort fallback for dependency-degraded mode.
  printf '%s' "$input_json" \
    | sed -n "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" \
    | head -n 1
}

read_live_scalar() {
  local base_dir="$1"
  local key="$2"
  bash "$LIVE_STATE_SCRIPT" get "$base_dir" "$key"
}

read_live_list() {
  local base_dir="$1"
  local key="$2"
  bash "$LIVE_STATE_SCRIPT" list-get "$base_dir" "$key"
}

live_scalar_key_declared() {
  local key="$1"
  grep -Eq "^[[:space:]]{2}${key}:[[:space:]]*" "$LIVE_STATE_FILE"
}

live_list_is_inline_empty() {
  local key="$1"
  grep -Eq "^[[:space:]]{2}${key}:[[:space:]]*\\[[[:space:]]*\\][[:space:]]*$" "$LIVE_STATE_FILE"
}

live_list_block_has_lines() {
  local key="$1"
  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      if ($0 ~ "^[[:space:]]{2}" key ":[[:space:]]*$") {
        in_target=1
        next
      }
      if (!in_target) {
        next
      }
      if ($0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*/) {
        exit
      }
      if ($0 !~ /^[[:space:]]*$/) {
        print "1"
        exit
      }
    }
  ' "$LIVE_STATE_FILE" | grep -q '^1$'
}

read_live_scalar_or_block() {
  local base_dir="$1"
  local key="$2"
  local value=""
  if ! live_scalar_key_declared "$key"; then
    json_block "BLOCKED: workflow gate expected live.${key} in ${LIVE_STATE_FILE}, but key is missing or malformed."
  fi
  if ! value="$(read_live_scalar "$base_dir" "$key" 2>/dev/null)"; then
    json_block "BLOCKED: workflow gate could not parse live.${key} from ${LIVE_STATE_FILE}. Fix live-state parser/state before continuing."
  fi
  printf '%s' "$value"
}

read_live_list_or_block() {
  local base_dir="$1"
  local key="$2"
  local value=""
  if ! live_scalar_key_declared "$key"; then
    json_block "BLOCKED: workflow gate expected live.${key} in ${LIVE_STATE_FILE}, but key is missing or malformed."
  fi
  if ! value="$(read_live_list "$base_dir" "$key" 2>/dev/null)"; then
    json_block "BLOCKED: workflow gate could not parse live.${key} from ${LIVE_STATE_FILE}. Fix live-state parser/state before continuing."
  fi
  if [[ -z "$value" ]] && ! live_list_is_inline_empty "$key"; then
    if live_list_block_has_lines "$key"; then
      json_block "BLOCKED: workflow gate detected malformed live.${key} entries in ${LIVE_STATE_FILE}."
    fi
  fi
  printf '%s' "$value"
}

resolve_base_dir() {
  local input_json="$1"
  local cwd_from_input=""
  local base_dir="$PWD"

  cwd_from_input="$(printf '%s' "$input_json" | jq -r '.cwd // empty')"
  if [[ -n "$cwd_from_input" && -d "$cwd_from_input" ]]; then
    base_dir="$cwd_from_input"
  fi

  printf '%s' "$base_dir"
}

list_contains() {
  local needle="$1"
  shift
  local item=""
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

prompt_requests_blocked_action() {
  local prompt="$1"
  printf '%s' "$prompt" | grep -Eiq "$BLOCKED_ACTION_REGEX"
}

PROMPT="$(extract_json_field "$INPUT" "prompt")"
SESSION_ID="$(extract_json_field "$INPUT" "session_id")"
BLOCKED_REQUEST="false"
if prompt_requests_blocked_action "$PROMPT" || prompt_requests_blocked_action "$INPUT"; then
  BLOCKED_REQUEST="true"
fi

if ! command -v jq >/dev/null 2>&1; then
  if [[ "$BLOCKED_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate dependency missing (jq). Protected actions are denied until jq is available."
  fi
  json_allow "[WARNING] workflow gate dependency missing (jq). Non-protected prompts are allowed."
fi

if [[ ! -f "$LIVE_STATE_SCRIPT" ]]; then
  if [[ "$BLOCKED_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate dependency missing (${LIVE_STATE_SCRIPT}). Protected actions are denied."
  fi
  json_allow "[WARNING] workflow gate dependency missing (${LIVE_STATE_SCRIPT}). Non-protected prompts are allowed."
fi

BASE_DIR="$(resolve_base_dir "$INPUT")"

LIVE_STATE_FILE="$(bash "$LIVE_STATE_SCRIPT" resolve "$BASE_DIR" 2>/dev/null || true)"
if [[ -z "$LIVE_STATE_FILE" || ! -f "$LIVE_STATE_FILE" ]]; then
  STATE_FILE_PROBE=""
  if [[ -f "$ARTIFACT_PATHS_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$ARTIFACT_PATHS_SCRIPT"
    STATE_FILE_PROBE="$(resolve_cwf_state_file "$BASE_DIR" 2>/dev/null || true)"
  fi
  if [[ -z "$STATE_FILE_PROBE" ]]; then
    STATE_FILE_PROBE="$BASE_DIR/.cwf/cwf-state.yaml"
  fi
  if [[ "$BLOCKED_REQUEST" == "true" && -f "$STATE_FILE_PROBE" ]]; then
    json_block "BLOCKED: live state file is unavailable while protected action was requested. Resolve live-state before ship/push."
  fi
  json_allow "[WARNING] live state file unavailable; workflow gate skipped."
fi

ACTIVE_PIPELINE="$(read_live_scalar_or_block "$BASE_DIR" "active_pipeline")"
if [[ -z "$ACTIVE_PIPELINE" ]]; then
  json_allow "[WARNING] live.active_pipeline is empty; workflow gate treated this as no active pipeline."
fi

# Stale pipeline detection: if stored session_id differs from current, the
# pipeline belongs to a previous session and should be cleaned up.
STORED_SESSION_ID="$(read_live_scalar_or_block "$BASE_DIR" "session_id")"
if [[ -n "$SESSION_ID" && -n "$STORED_SESSION_ID" && "$SESSION_ID" != "$STORED_SESSION_ID" ]]; then
  stale_reason="[WARNING] Stale pipeline detected: active_pipeline='${ACTIVE_PIPELINE}' "
  stale_reason+="belongs to session '${STORED_SESSION_ID}' but current session is '${SESSION_ID}'. "
  stale_reason+="Run: bash ${LIVE_STATE_SCRIPT} set . active_pipeline=\"\" to clean up."
  json_allow "$stale_reason"
fi

PHASE="$(read_live_scalar_or_block "$BASE_DIR" "phase")"
OVERRIDE_REASON="$(read_live_scalar_or_block "$BASE_DIR" "pipeline_override_reason")"
STATE_VERSION="$(read_live_scalar_or_block "$BASE_DIR" "state_version")"

REMAINING_GATES_RAW="$(read_live_list_or_block "$BASE_DIR" "remaining_gates")"
REMAINING_GATES=()
if [[ -n "$REMAINING_GATES_RAW" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    REMAINING_GATES+=("$line")
  done <<< "$REMAINING_GATES_RAW"
fi

if [[ "${#REMAINING_GATES[@]}" -eq 0 ]]; then
  missing_gate_reason="[WARNING] Active pipeline '${ACTIVE_PIPELINE}' has no remaining_gates in live state. "
  missing_gate_reason+="Run cleanup or reinitialize run-state before continuing."
  json_allow "$missing_gate_reason"
fi

gate_chain="$(IFS=' -> '; echo "${REMAINING_GATES[*]}")"
status_msg="[PIPELINE] Active: ${ACTIVE_PIPELINE} (phase: ${PHASE:-unknown}, "
status_msg+="state_version: ${STATE_VERSION:-unset}). Remaining gates: ${gate_chain}. "
status_msg+="Do NOT skip gates. Use Skill tool to invoke next stage."

if list_contains "review-code" "${REMAINING_GATES[@]}" && [[ "$BLOCKED_REQUEST" == "true" ]]; then
  if [[ -n "$OVERRIDE_REASON" && "$OVERRIDE_REASON" != "null" ]]; then
    json_allow "${status_msg} Override active: ${OVERRIDE_REASON}."
  fi
  json_block "${status_msg} BLOCKED action: ship/push/commit requested while review-code is still pending."
fi

json_allow "$status_msg"
