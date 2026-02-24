#!/usr/bin/env bash
set -euo pipefail
# sync-session-logs-lib.sh: helper functions for sync-session-logs.sh.

log() {
  if [ "$QUIET" != "true" ]; then
    echo "$*"
  fi
}

can_redact() {
  [ -f "$REDACTOR_SCRIPT" ] && command -v perl >/dev/null 2>&1
}

can_redact_jsonl() {
  [ -x "$JSON_REDACTOR_SCRIPT" ] && command -v jq >/dev/null 2>&1
}

redact_file_in_place() {
  local target_file="$1"
  [ -f "$target_file" ] || return 0

  if [[ "$target_file" == *.jsonl ]]; then
    if can_redact_jsonl; then
      "$JSON_REDACTOR_SCRIPT" "$target_file"
    else
      log "Warning: redaction skipped for $target_file (missing jq or $JSON_REDACTOR_SCRIPT)"
    fi
  elif can_redact; then
    perl -i "$REDACTOR_SCRIPT" "$target_file"
  else
    log "Warning: redaction skipped for $target_file (missing perl or $REDACTOR_SCRIPT)"
  fi
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
  local live_state_file=""
  local live_dir=""

  if [ ! -f "$LIVE_RESOLVER_SCRIPT" ]; then
    return 1
  fi

  project_root=$(git -C "$base_dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$base_dir")
  live_state_file=$(bash "$LIVE_RESOLVER_SCRIPT" resolve "$project_root" 2>/dev/null || true)
  if [ -z "$live_state_file" ] || [ ! -f "$live_state_file" ]; then
    return 1
  fi

  live_dir=$(extract_live_dir_value "$live_state_file")
  if [ -z "$live_dir" ]; then
    return 1
  fi

  if [[ "$live_dir" == /* ]]; then
    printf '%s\n' "$live_dir"
  else
    printf '%s\n' "$project_root/$live_dir"
  fi
}

link_log_into_live_session() {
  local log_file="$1"
  local session_dir=""
  local links_dir=""
  local log_link=""

  [ -f "$log_file" ] || return 0

  session_dir=$(resolve_live_session_dir "$CWD_FILTER" 2>/dev/null || true)
  if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
    return 0
  fi

  links_dir="${session_dir}/session-logs"
  mkdir -p "$links_dir"

  log_link="${links_dir}/$(basename "$log_file")"
  if [ -e "$log_link" ] && [ ! -L "$log_link" ]; then
    return 0
  fi
  ln -sfn "$log_file" "$log_link"
}

utc_to_epoch() {
  local ts="$1"
  local ts_short
  ts_short=$(echo "$ts" | cut -c1-19)
  TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$ts_short" "+%s" 2>/dev/null || \
  date -d "${ts_short}Z" "+%s" 2>/dev/null || \
  echo ""
}

utc_to_local() {
  local ts="$1"
  local fmt="${2:-%Y-%m-%d %H:%M:%S}"
  local epoch
  epoch=$(utc_to_epoch "$ts")
  if [ -n "$epoch" ]; then
    date -r "$epoch" "+$fmt" 2>/dev/null || \
    date -d "@$epoch" "+$fmt" 2>/dev/null || \
    echo ""
  else
    echo ""
  fi
}

find_session_by_id() {
  local sid="$1"
  find "$CODEX_SESSIONS_DIR" -type f -name "*${sid}.jsonl" 2>/dev/null | head -n1
}

file_mtime_epoch() {
  local path="$1"
  stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null || echo "0"
}

normalize_bool() {
  local v="${1:-}"
  case "$v" in
    1|true|TRUE|yes|YES|on|ON) echo "true" ;;
    0|false|FALSE|no|NO|off|OFF) echo "false" ;;
    *) echo "false" ;;
  esac
}

reset_turn_state() {
  HAS_TURN=false
  TURN_USER_TEXT=""
  TURN_USER_TS=""
  TURN_ASSISTANT_TEXT=""
  TURN_ASSISTANT_LAST_TS=""
  TURN_TOOLS=""
}

load_sync_state() {
  local f="$1"
  [ -f "$f" ] || return 1
  command -v jq >/dev/null 2>&1 || return 1

  local version
  version="$(jq -r '.version // 0' "$f" 2>/dev/null || echo "0")"
  [ "$version" = "1" ] || return 1

  STATE_OFFSET="$(jq -r '.offset // 0' "$f" 2>/dev/null || echo "0")"
  # shellcheck disable=SC2034
  STATE_JSONL_PATH="$(jq -r '.jsonl_path // ""' "$f" 2>/dev/null || echo "")"
  # shellcheck disable=SC2034
  STATE_OUT_FILE="$(jq -r '.out_file // ""' "$f" 2>/dev/null || echo "")"
  STATE_LAST_MTIME="$(jq -r '.last_mtime // 0' "$f" 2>/dev/null || echo "0")"

  EMITTED_TURNS="$(jq -r '.emitted_turns // 0' "$f" 2>/dev/null || echo "0")"
  HAS_TURN="$(normalize_bool "$(jq -r '.has_turn // false' "$f" 2>/dev/null || echo "false")")"
  TURN_USER_TEXT="$(jq -r '.turn_user_text // ""' "$f" 2>/dev/null || echo "")"
  TURN_USER_TS="$(jq -r '.turn_user_ts // ""' "$f" 2>/dev/null || echo "")"
  TURN_ASSISTANT_TEXT="$(jq -r '.turn_assistant_text // ""' "$f" 2>/dev/null || echo "")"
  TURN_ASSISTANT_LAST_TS="$(jq -r '.turn_assistant_last_ts // ""' "$f" 2>/dev/null || echo "")"
  TURN_TOOLS="$(jq -r '.turn_tools // ""' "$f" 2>/dev/null || echo "")"
  LAST_TURN_FINGERPRINT="$(jq -r '.last_turn_fingerprint // ""' "$f" 2>/dev/null || echo "")"

  [ -n "$STATE_OFFSET" ] || STATE_OFFSET=0
  [ -n "$STATE_LAST_MTIME" ] || STATE_LAST_MTIME=0
  [ -n "$EMITTED_TURNS" ] || EMITTED_TURNS=0
  return 0
}

save_sync_state() {
  local f="$1"
  local offset="$2"
  local jsonl_path="$3"
  local out_file="$4"
  local last_mtime="$5"
  mkdir -p "$(dirname "$f")"
  jq -n \
    --argjson version 1 \
    --argjson offset "$offset" \
    --arg jsonl_path "$jsonl_path" \
    --arg out_file "$out_file" \
    --argjson last_mtime "$last_mtime" \
    --argjson emitted_turns "$EMITTED_TURNS" \
    --arg has_turn "$HAS_TURN" \
    --arg turn_user_text "$TURN_USER_TEXT" \
    --arg turn_user_ts "$TURN_USER_TS" \
    --arg turn_assistant_text "$TURN_ASSISTANT_TEXT" \
    --arg turn_assistant_last_ts "$TURN_ASSISTANT_LAST_TS" \
    --arg turn_tools "$TURN_TOOLS" \
    --arg last_turn_fingerprint "$LAST_TURN_FINGERPRINT" \
    '{
      version: $version,
      offset: $offset,
      jsonl_path: $jsonl_path,
      out_file: $out_file,
      last_mtime: $last_mtime,
      emitted_turns: $emitted_turns,
      has_turn: ($has_turn == "true"),
      turn_user_text: $turn_user_text,
      turn_user_ts: $turn_user_ts,
      turn_assistant_text: $turn_assistant_text,
      turn_assistant_last_ts: $turn_assistant_last_ts,
      turn_tools: $turn_tools,
      last_turn_fingerprint: $last_turn_fingerprint
    }' > "$f"
}

find_latest_session_for_cwd() {
  local target_cwd="$1"
  local min_epoch="${2:-}"
  local f
  local file_epoch
  local session_cwd

  while IFS= read -r f; do
    [ -f "$f" ] || continue
    if [ -n "$min_epoch" ]; then
      file_epoch=$(file_mtime_epoch "$f")
      if [ -n "$file_epoch" ] && [ "$file_epoch" -lt "$min_epoch" ]; then
        continue
      fi
    fi

    session_cwd=$(jq -r 'select(.type == "session_meta") | .payload.cwd // empty' "$f" 2>/dev/null | head -n1)
    if [ -n "$session_cwd" ] && [ "$session_cwd" = "$target_cwd" ]; then
      echo "$f"
      return 0
    fi
  done < <(find "$CODEX_SESSIONS_DIR" -type f -name '*.jsonl' -print0 2>/dev/null | xargs -0 ls -1t 2>/dev/null || true)

  return 1
}

summarize_tool() {
  local name="$1"
  local arguments="$2"
  local summary="$name"

  case "$name" in
    exec_command)
      local cmd
      cmd=$(echo "$arguments" | jq -r '.cmd // empty' 2>/dev/null || true)
      if [ -n "$cmd" ]; then
        cmd=$(echo "$cmd" | tr '\n' ' ' | cut -c1-120)
        summary="exec_command: $cmd"
      fi
      ;;
    spawn_agent)
      local message
      message=$(echo "$arguments" | jq -r '.message // empty' 2>/dev/null || true)
      if [ -n "$message" ]; then
        message=$(echo "$message" | tr '\n' ' ' | cut -c1-120)
        summary="spawn_agent: $message"
      fi
      ;;
    send_input)
      local message
      message=$(echo "$arguments" | jq -r '.message // empty' 2>/dev/null || true)
      if [ -n "$message" ]; then
        message=$(echo "$message" | tr '\n' ' ' | cut -c1-120)
        summary="send_input: $message"
      fi
      ;;
    wait)
      summary="wait"
      ;;
    *)
      summary="$name"
      ;;
  esac

  echo "$summary"
}

build_events_from_source() {
  local source_jsonl="$1"
  local has_event_messages=""

  has_event_messages=$(
    jq -r 'select(.type == "event_msg" and (.payload.type == "user_message" or .payload.type == "agent_message")) | 1' \
      "$source_jsonl" 2>/dev/null | head -n1 || true
  )

  if [ -n "$has_event_messages" ]; then
    jq -c '
      if .type == "event_msg" and (.payload.type == "user_message" or .payload.type == "agent_message") then
        {
          kind: "message",
          role: (if .payload.type == "user_message" then "user" else "assistant" end),
          ts: (.timestamp // ""),
          text: (.payload.message // "")
        }
      elif .type == "response_item" and (.payload.type == "function_call" or .payload.type == "custom_tool_call") then
        {
          kind: "tool",
          ts: (.timestamp // ""),
          name: (.payload.name // "tool"),
          arguments: (.payload.arguments // "")
        }
      else
        empty
      end
    ' "$source_jsonl" > "$EVENTS_FILE"
    return 0
  fi

  log "No event_msg user/assistant messages detected; falling back to response_item.message."
  jq -c '
    def message_text:
      if (.payload.content | type) == "array" then
        (.payload.content
          | map(
              if .type == "input_text" then (.text // "")
              elif .type == "output_text" then (.text // "")
              elif (.text? != null) then (.text // "")
              elif (.input_text? != null) then (.input_text // "")
              elif (.output_text? != null) then (.output_text // "")
              else ""
              end
            )
          | join("\n")
        )
      else
        ""
      end;
    if .type == "response_item" and .payload.type == "message" and (.payload.role == "user" or .payload.role == "assistant") then
      {
        kind: "message",
        role: .payload.role,
        ts: (.timestamp // ""),
        text: message_text
      }
    elif .type == "response_item" and (.payload.type == "function_call" or .payload.type == "custom_tool_call") then
      {
        kind: "tool",
        ts: (.timestamp // ""),
        name: (.payload.name // "tool"),
        arguments: (.payload.arguments // "")
      }
    else
      empty
    end
  ' "$source_jsonl" > "$EVENTS_FILE"
}

write_session_header() {
  local target_file
  target_file="${OUT_WRITE_FILE:-$OUT_FILE}"
  # shellcheck disable=SC2153
  {
    echo "# Session: ${HASH}"
    echo "Engine: codex | Model: ${MODEL}"
    echo "Recorded by: ${USER:-unknown}@$(hostname 2>/dev/null || echo unknown)"
    echo "CWD: ${SESSION_CWD}"
    echo "Started: ${STARTED_LOCAL} | Codex CLI v${CLI_VERSION}"
    echo "Session ID: ${SESSION_ID}"
  } > "$target_file"
}
