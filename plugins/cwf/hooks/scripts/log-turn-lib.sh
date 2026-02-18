#!/usr/bin/env bash
set -euo pipefail
# log-turn-lib.sh: shared helper functions for log-turn hook.

redact_sensitive_text() {
    local raw_text="${1-}"

    if [ "$CAN_REDACT" = "true" ]; then
        if printf '%s' "$raw_text" | perl "$REDACTOR_SCRIPT"; then
            return 0
        fi
    fi

    printf '%s' "$raw_text"
}

extract_live_dir_value() {
    local state_file="$1"
    awk '
        /^live:/ { in_live=1; next }
        in_live && /^[^[:space:]]/ { exit }
        in_live && /^[[:space:]]{2}dir:[[:space:]]*/ {
            sub(/^[[:space:]]{2}dir:[[:space:]]*/, "", $0)
            gsub(/^[\"\047]|[\"\047]$/, "", $0)
            print $0
            exit
        }
    ' "$state_file"
}

resolve_live_session_dir() {
    local base_dir="$1"
    local project_root=""
    local resolved_live_state=""
    local live_dir=""

    if [ ! -f "$LIVE_RESOLVER_SCRIPT" ]; then
        return 1
    fi

    project_root=$(git -C "$base_dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$base_dir")
    resolved_live_state=$(bash "$LIVE_RESOLVER_SCRIPT" resolve "$project_root" 2>/dev/null || true)
    if [ -z "$resolved_live_state" ] || [ ! -f "$resolved_live_state" ]; then
        return 1
    fi

    live_dir=$(extract_live_dir_value "$resolved_live_state")
    if [ -z "$live_dir" ]; then
        return 1
    fi

    if [[ "$live_dir" == /* ]]; then
        printf '%s\n' "$live_dir"
    else
        printf '%s\n' "$project_root/$live_dir"
    fi
}

normalize_single_line_text() {
    local raw_text="${1-}"
    local single_line=""
    single_line=$(printf '%s' "$raw_text" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')
    printf '%s' "$single_line"
}

extract_ask_question_from_turn() {
    local turn_json="$1"
    echo "$turn_json" | jq -r '
      [
        .assistants[].message.content[]? |
        select(.type == "tool_use" and .name == "AskUserQuestion") |
        (.input.questions[0].question // .input.questions[0].header // "")
      ] | last // empty
    ' 2>/dev/null || true
}

extract_ask_answer_from_turn() {
    local turn_json="$1"
    echo "$turn_json" | jq -r '
      [
        (
          .user.message.content |
          if type == "array" then . else [] end
        )[] |
        select(.type == "tool_result") |
        .content |
        if type == "string" then .
        elif type == "array" then
          ([.[] | select(type == "object" and .type == "text") | .text] | join(""))
        else "" end |
        select(test("User has answered|user.*answered"))
      ] | join("\n")
    ' 2>/dev/null || true
}

extract_answer_payload() {
    local raw_answer="$1"
    local parsed=""
    parsed="$(printf '%s' "$raw_answer" | sed -nE 's/.*[Ww]ith:[[:space:]]*(.+)$/\1/p' | head -n 1)"
    if [ -n "$parsed" ]; then
        printf '%s' "$parsed"
        return 0
    fi
    printf '%s' "$raw_answer"
}

persist_decision_journal_entry() {
    local turn_num="$1"
    local turn_json="$2"
    local turn_ts="$3"
    local raw_question=""
    local raw_answer=""
    local question=""
    local answer=""
    local decision_ts=""
    local state_version=""
    local decision_id=""
    local entry_json=""

    if [ ! -f "$LIVE_RESOLVER_SCRIPT" ]; then
        return 0
    fi
    if ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    raw_question="$(extract_ask_question_from_turn "$turn_json")"
    raw_answer="$(extract_ask_answer_from_turn "$turn_json")"
    if [ -z "$raw_answer" ]; then
        return 0
    fi

    raw_answer="$(extract_answer_payload "$raw_answer")"
    question="$(normalize_single_line_text "$(redact_sensitive_text "$raw_question")")"
    answer="$(normalize_single_line_text "$(redact_sensitive_text "$raw_answer")")"

    if [ -z "$question" ]; then
        question="AskUserQuestion response (question unavailable)"
    fi
    if [ -z "$answer" ]; then
        return 0
    fi

    decision_ts="$turn_ts"
    if [ -z "$decision_ts" ]; then
        decision_ts="$(date -u "+%Y-%m-%dT%H:%M:%SZ")"
    fi

    state_version="$(bash "$LIVE_RESOLVER_SCRIPT" get "$CWD" state_version 2>/dev/null || true)"
    if [ -z "$state_version" ]; then
        state_version="0"
    fi

    decision_id="askq-$(printf '%s' "${SESSION_ID}|${turn_num}|${question}|${answer}" | shasum -a 256 | cut -c1-16)"
    entry_json="$(jq -cn \
        --arg decision_id "$decision_id" \
        --arg ts "$decision_ts" \
        --arg session_id "$SESSION_ID" \
        --arg question "$question" \
        --arg answer "$answer" \
        --arg source_hook "log-turn" \
        --arg state_version "$state_version" \
        '{
          decision_id:$decision_id,
          ts:$ts,
          session_id:$session_id,
          question:$question,
          answer:$answer,
          source_hook:$source_hook,
          state_version:$state_version
        }')"

    if ! bash "$LIVE_RESOLVER_SCRIPT" journal-append "$CWD" "$entry_json" >/dev/null 2>&1; then
        echo "[log-turn] warning: failed to append decision_journal entry (${decision_id})" >&2
    fi
}

link_log_into_live_session() {
    local log_file="$1"
    local session_dir=""
    local links_dir=""
    local session_log_link=""
    local session_log_alias=""

    [ -f "$log_file" ] || return 0

    session_dir=$(resolve_live_session_dir "$CWD" 2>/dev/null || true)
    if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
        return 0
    fi

    links_dir="${session_dir}/session-logs"
    mkdir -p "$links_dir"

    session_log_link="${links_dir}/$(basename "$log_file")"
    if [ -e "$session_log_link" ] && [ ! -L "$session_log_link" ]; then
        return 0
    fi
    ln -sfn "$log_file" "$session_log_link"

    # Compatibility alias for readers that still expect a single session-log.md.
    session_log_alias="${session_dir}/session-log.md"
    if [ ! -e "$session_log_alias" ] || [ -L "$session_log_alias" ]; then
        ln -sfn "session-logs/$(basename "$log_file")" "$session_log_alias"
    fi
}

utc_to_epoch() {
    local ts_short
    ts_short=$(echo "$1" | cut -c1-19)
    TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$ts_short" "+%s" 2>/dev/null || \
    date -d "${ts_short}Z" "+%s" 2>/dev/null || \
    echo ""
}

utc_to_local() {
    local fmt="${2:-%H:%M:%S}"
    local epoch
    epoch=$(utc_to_epoch "$1")
    if [ -n "$epoch" ]; then
        date -r "$epoch" "+$fmt" 2>/dev/null || \
        date -d "@$epoch" "+$fmt" 2>/dev/null || \
        echo ""
    fi
}
