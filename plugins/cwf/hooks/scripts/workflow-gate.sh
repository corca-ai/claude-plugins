#!/usr/bin/env bash
set -euo pipefail
# workflow-gate.sh — UserPromptSubmit gate for active cwf:run workflows.
# Emits status warnings and blocks ship/push/commit intents while critical gates remain.

# shellcheck disable=SC2034
HOOK_GROUP="workflow_gate"
# shellcheck source=cwf-hook-gate.sh
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

INPUT="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIVE_STATE_SCRIPT="$PLUGIN_ROOT/scripts/cwf-live-state.sh"

if [[ ! -f "$LIVE_STATE_SCRIPT" ]]; then
  exit 0
fi

json_block() {
  local reason="$1"
  local reason_json
  reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  cat <<EOF
{"decision":"block","reason":${reason_json}}
EOF
  exit 1
}

json_allow() {
  local reason="$1"
  local reason_json
  reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  cat <<EOF
{"decision":"allow","reason":${reason_json}}
EOF
  exit 0
}

trim_ws() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_quotes() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

normalize_scalar() {
  local value="$1"
  value="${value%%#*}"
  value="$(trim_ws "$value")"
  value="$(strip_quotes "$value")"
  printf '%s' "$value"
}

extract_live_scalar() {
  local file_path="$1"
  local key="$2"

  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      pat = "^[[:space:]]{2}" key ":[[:space:]]*"
      if ($0 ~ pat) {
        sub(pat, "", $0)
        print $0
        exit
      }
    }
  ' "$file_path"
}

extract_live_list() {
  local file_path="$1"
  local key="$2"

  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      full = "^[[:space:]]{2}" key ":[[:space:]]*$"
      empty = "^[[:space:]]{2}" key ":[[:space:]]*\\[\\][[:space:]]*$"

      if ($0 ~ empty) {
        exit
      }
      if ($0 ~ full) {
        in_key=1
        next
      }
      if (in_key) {
        if ($0 ~ /^[[:space:]]{4}-[[:space:]]*/) {
          line=$0
          sub(/^[[:space:]]{4}-[[:space:]]*/, "", line)
          gsub(/^"/, "", line)
          gsub(/"$/, "", line)
          gsub(/^'\''/, "", line)
          gsub(/'\''$/, "", line)
          print line
          next
        }
        if ($0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:/ || $0 ~ /^[^[:space:]]/) {
          exit
        }
      }
    }
  ' "$file_path"
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
  printf '%s' "$prompt" | grep -Eiq '(^|[[:space:]])(cwf:ship|/ship|git[[:space:]]+push|git[[:space:]]+merge|gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+pr[[:space:]]+merge|커밋해|푸시해|배포해)([[:space:]]|$)'
}

PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"
CWD_FROM_INPUT="$(echo "$INPUT" | jq -r '.cwd // empty')"
BASE_DIR="$PWD"
if [[ -n "$CWD_FROM_INPUT" && -d "$CWD_FROM_INPUT" ]]; then
  BASE_DIR="$CWD_FROM_INPUT"
fi

LIVE_STATE_FILE="$(bash "$LIVE_STATE_SCRIPT" resolve "$BASE_DIR" 2>/dev/null || true)"
if [[ -z "$LIVE_STATE_FILE" || ! -f "$LIVE_STATE_FILE" ]]; then
  exit 0
fi

ACTIVE_PIPELINE="$(normalize_scalar "$(extract_live_scalar "$LIVE_STATE_FILE" "active_pipeline" || true)")"
if [[ -z "$ACTIVE_PIPELINE" ]]; then
  exit 0
fi

# Stale pipeline detection: if stored session_id differs from current, the
# pipeline belongs to a previous session and should be cleaned up.
STORED_SESSION_ID="$(normalize_scalar "$(extract_live_scalar "$LIVE_STATE_FILE" "session_id" || true)")"
if [[ -n "$SESSION_ID" && -n "$STORED_SESSION_ID" && "$SESSION_ID" != "$STORED_SESSION_ID" ]]; then
  json_allow "[WARNING] Stale pipeline detected: active_pipeline='${ACTIVE_PIPELINE}' belongs to session '${STORED_SESSION_ID}' but current session is '${SESSION_ID}'. Run: bash cwf-live-state.sh set . active_pipeline=\"\" to clean up."
fi

PHASE="$(normalize_scalar "$(extract_live_scalar "$LIVE_STATE_FILE" "phase" || true)")"
OVERRIDE_REASON="$(normalize_scalar "$(extract_live_scalar "$LIVE_STATE_FILE" "pipeline_override_reason" || true)")"
STATE_VERSION="$(normalize_scalar "$(extract_live_scalar "$LIVE_STATE_FILE" "state_version" || true)")"

mapfile -t REMAINING_GATES < <(extract_live_list "$LIVE_STATE_FILE" "remaining_gates" || true)

if [[ "${#REMAINING_GATES[@]}" -eq 0 ]]; then
  json_allow "[WARNING] Active pipeline '${ACTIVE_PIPELINE}' has no remaining_gates in live state. Run cleanup or reinitialize run-state before continuing."
fi

gate_chain="$(IFS=' -> '; echo "${REMAINING_GATES[*]}")"
status_msg="[PIPELINE] Active: ${ACTIVE_PIPELINE} (phase: ${PHASE:-unknown}, state_version: ${STATE_VERSION:-unset}). Remaining gates: ${gate_chain}. Do NOT skip gates. Use Skill tool to invoke next stage."

if list_contains "review-code" "${REMAINING_GATES[@]}" && prompt_requests_blocked_action "$PROMPT"; then
  if [[ -n "$OVERRIDE_REASON" && "$OVERRIDE_REASON" != "null" ]]; then
    json_allow "${status_msg} Override active: ${OVERRIDE_REASON}."
  fi
  json_block "${status_msg} BLOCKED action: ship/push/commit requested while review-code is still pending."
fi

json_allow "$status_msg"
