#!/usr/bin/env bash
# sync-session-logs.sh: Export Codex session JSONL into persistent markdown logs.
#
# Usage examples:
#   plugins/cwf/scripts/codex/sync-session-logs.sh
#   plugins/cwf/scripts/codex/sync-session-logs.sh --session-id <id>
#   plugins/cwf/scripts/codex/sync-session-logs.sh --jsonl <path>
#
# By default this script:
# - Finds the latest Codex session for the current cwd
# - Writes markdown to resolve_cwf_session_logs_dir output (prefers ./.cwf/sessions,
#   falls back to legacy ./.cwf/projects/sessions when needed) as *.codex.md
# - Does not copy raw JSONL (use --raw to enable)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDACTOR_SCRIPT="$SCRIPT_DIR/redact-sensitive.pl"
JSON_REDACTOR_SCRIPT="$SCRIPT_DIR/redact-jsonl.sh"
RESOLVER_SCRIPT="$SCRIPT_DIR/../cwf-artifact-paths.sh"
LIVE_RESOLVER_SCRIPT="$SCRIPT_DIR/../cwf-live-state.sh"

if [ ! -f "$RESOLVER_SCRIPT" ]; then
  echo "Missing resolver script: $RESOLVER_SCRIPT" >&2
  exit 1
fi

# shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
source "$RESOLVER_SCRIPT"

DEFAULT_CWD="$(pwd)"
DEFAULT_OUT_DIR="$(resolve_cwf_session_logs_dir "$DEFAULT_CWD")"
CODEX_SESSIONS_DIR="${CODEX_SESSIONS_DIR:-$HOME/.codex/sessions}"
TRUNCATE_THRESHOLD="${CODEX_SESSION_LOG_TRUNCATE:-20}"

SESSION_ID=""
JSONL_PATH=""
CWD_FILTER="$DEFAULT_CWD"
OUT_DIR="$DEFAULT_OUT_DIR"
COPY_RAW=false
SINCE_EPOCH=""
QUIET=false
APPEND_MODE="${CODEX_SESSION_LOG_APPEND:-true}"

STATE_FILE=""
STATE_ENABLED=false
STATE_OFFSET=0
STATE_JSONL_PATH=""
STATE_OUT_FILE=""
STATE_LAST_MTIME=0

EMITTED_TURNS=0
HAS_TURN=false
TURN_USER_TEXT=""
TURN_USER_TS=""
TURN_ASSISTANT_TEXT=""
TURN_ASSISTANT_LAST_TS=""
TURN_TOOLS=""
LAST_TURN_FINGERPRINT=""

usage() {
  cat <<'USAGE'
Export Codex session JSONL into markdown logs.

Usage:
  sync-session-logs.sh [options]

Options:
  --session-id <id>    Export a specific session id
  --jsonl <path>       Export a specific JSONL file directly
  --cwd <path>         Prefer sessions whose session_meta.cwd matches path (default: $PWD)
  --since-epoch <sec>  Prefer sessions modified at/after this epoch seconds value
  --out-dir <path>     Output directory (default: CWF_SESSION_LOG_DIR/.cwf/sessions with legacy fallback)
  --raw                Copy raw JSONL into out-dir/raw
  --no-raw             Backward-compatible alias for default behavior (no raw copy)
  --quiet              Suppress informational output
  --append             Incremental append sync when possible (default)
  --no-append          Disable incremental append and always rebuild
  -h, --help           Show help
USAGE
}

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
  local alias_link=""

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

  # Compatibility alias for readers that still expect one session-log.md file.
  alias_link="${session_dir}/session-log.md"
  if [ ! -e "$alias_link" ] || [ -L "$alias_link" ]; then
    ln -sfn "session-logs/$(basename "$log_file")" "$alias_link"
  fi
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
  STATE_JSONL_PATH="$(jq -r '.jsonl_path // ""' "$f" 2>/dev/null || echo "")"
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
  {
    echo "# Session: ${HASH}"
    echo "Engine: codex | Model: ${MODEL}"
    echo "Recorded by: ${USER:-unknown}@$(hostname 2>/dev/null || echo unknown)"
    echo "CWD: ${SESSION_CWD}"
    echo "Started: ${STARTED_LOCAL} | Codex CLI v${CLI_VERSION}"
    echo "Session ID: ${SESSION_ID}"
  } > "$OUT_FILE"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --session-id)
      SESSION_ID="${2:-}"
      shift 2
      ;;
    --jsonl)
      JSONL_PATH="${2:-}"
      shift 2
      ;;
    --cwd)
      CWD_FILTER="${2:-}"
      shift 2
      ;;
    --since-epoch)
      SINCE_EPOCH="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --raw)
      COPY_RAW=true
      shift
      ;;
    --no-raw)
      COPY_RAW=false
      shift
      ;;
    --quiet)
      QUIET=true
      shift
      ;;
    --append)
      APPEND_MODE=true
      shift
      ;;
    --no-append)
      APPEND_MODE=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ ! -d "$CODEX_SESSIONS_DIR" ]; then
  log "Codex sessions directory not found: $CODEX_SESSIONS_DIR"
  exit 0
fi

if [ -z "$JSONL_PATH" ]; then
  if [ -n "$SESSION_ID" ]; then
    JSONL_PATH=$(find_session_by_id "$SESSION_ID")
  else
    JSONL_PATH=$(find_latest_session_for_cwd "$CWD_FILTER" "$SINCE_EPOCH" || true)
    if [ -z "$JSONL_PATH" ]; then
      if [ -n "$SINCE_EPOCH" ]; then
        log "No cwd-matched Codex session updated since epoch: $SINCE_EPOCH"
      else
        JSONL_PATH=$(find "$CODEX_SESSIONS_DIR" -type f -name '*.jsonl' -print0 2>/dev/null | xargs -0 ls -1t 2>/dev/null | head -n1 || true)
      fi
    fi
  fi
fi

if [ -z "$JSONL_PATH" ] || [ ! -f "$JSONL_PATH" ]; then
  log "No Codex session JSONL found to export."
  exit 0
fi

SESSION_ID_META=$(jq -r 'select(.type == "session_meta") | .payload.id // empty' "$JSONL_PATH" 2>/dev/null | head -n1)
if [ -n "$SESSION_ID_META" ]; then
  SESSION_ID="$SESSION_ID_META"
fi

if [ -z "$SESSION_ID" ]; then
  SESSION_ID=$(basename "$JSONL_PATH" | sed -E 's/^.*-([0-9a-f-]{36})\.jsonl$/\1/' )
fi

if [ -z "$SESSION_ID" ]; then
  log "Failed to determine session id from: $JSONL_PATH"
  exit 1
fi

HASH=$(echo -n "$SESSION_ID" | shasum -a 256 | cut -c1-8)

SESSION_STARTED_UTC=$(jq -r 'select(.type == "session_meta") | .payload.timestamp // empty' "$JSONL_PATH" 2>/dev/null | head -n1)
MODEL=$(jq -r 'select(.type == "turn_context") | .payload.model // empty' "$JSONL_PATH" 2>/dev/null | head -n1)
SESSION_CWD=$(jq -r 'select(.type == "session_meta") | .payload.cwd // empty' "$JSONL_PATH" 2>/dev/null | head -n1)
CLI_VERSION=$(jq -r 'select(.type == "session_meta") | .payload.cli_version // empty' "$JSONL_PATH" 2>/dev/null | head -n1)

[ -z "$MODEL" ] && MODEL="unknown"
[ -z "$SESSION_CWD" ] && SESSION_CWD="$CWD_FILTER"
[ -z "$CLI_VERSION" ] && CLI_VERSION="unknown"

STARTED_LOCAL=$(utc_to_local "$SESSION_STARTED_UTC" "%Y-%m-%d %H:%M:%S")
DATE_STR=$(utc_to_local "$SESSION_STARTED_UTC" "%y%m%d")
START_HHMM=$(utc_to_local "$SESSION_STARTED_UTC" "%H%M")

[ -z "$STARTED_LOCAL" ] && STARTED_LOCAL="$(date "+%Y-%m-%d %H:%M:%S")"
[ -z "$DATE_STR" ] && DATE_STR="$(date +%y%m%d)"
[ -z "$START_HHMM" ] && START_HHMM="$(date +%H%M)"

mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${DATE_STR}-${START_HHMM}-${HASH}.codex.md"

CURRENT_SIZE="$(wc -c < "$JSONL_PATH" | tr -d ' ')"
CURRENT_MTIME="$(file_mtime_epoch "$JSONL_PATH")"
SOURCE_JSONL="$JSONL_PATH"
CHUNK_FILE=""
EVENTS_FILE="$(mktemp)"
trap 'rm -f "$EVENTS_FILE" "$CHUNK_FILE"' EXIT

APPEND_MODE="$(normalize_bool "$APPEND_MODE")"
STATE_FILE="$OUT_DIR/.sync-state/${HASH}.json"
STATE_ENABLED=false
REBUILD_MODE=true

reset_turn_state
EMITTED_TURNS=0
LAST_TURN_FINGERPRINT=""
TURN_NUM=0
STATE_OFFSET=0

if [ "$APPEND_MODE" = "true" ] && command -v jq >/dev/null 2>&1; then
  STATE_ENABLED=true
  if load_sync_state "$STATE_FILE"; then
    if [ "$STATE_JSONL_PATH" = "$JSONL_PATH" ] && [ "$STATE_OUT_FILE" = "$OUT_FILE" ] && \
      [ "$STATE_OFFSET" -ge 0 ] && [ "$STATE_OFFSET" -le "$CURRENT_SIZE" ] && [ -f "$OUT_FILE" ]; then
      REBUILD_MODE=false
    else
      reset_turn_state
      EMITTED_TURNS=0
      LAST_TURN_FINGERPRINT=""
      STATE_OFFSET=0
    fi
  fi
fi

if [ "$REBUILD_MODE" = "true" ]; then
  write_session_header
else
  if [ "$STATE_OFFSET" -ge "$CURRENT_SIZE" ]; then
    reset_turn_state
    if [ "$STATE_ENABLED" = "true" ]; then
      save_sync_state "$STATE_FILE" "$CURRENT_SIZE" "$JSONL_PATH" "$OUT_FILE" "$CURRENT_MTIME"
    fi
    if [ "$COPY_RAW" = "true" ]; then
      RAW_DIR="$OUT_DIR/raw"
      RAW_FILE="$RAW_DIR/$(basename "$JSONL_PATH")"
      mkdir -p "$RAW_DIR"
      cp "$JSONL_PATH" "$RAW_FILE"
      redact_file_in_place "$RAW_FILE"
    fi
    link_log_into_live_session "$OUT_FILE" || true
    log "Codex session exported: $OUT_FILE"
    exit 0
  fi

  CHUNK_FILE="$(mktemp)"
  tail -c "+$((STATE_OFFSET + 1))" "$JSONL_PATH" > "$CHUNK_FILE"
  SOURCE_JSONL="$CHUNK_FILE"
fi

if ! build_events_from_source "$SOURCE_JSONL"; then
  if [ "$REBUILD_MODE" != "true" ]; then
    log "Incremental parse failed; falling back to full rebuild."
    REBUILD_MODE=true
    STATE_OFFSET=0
    SOURCE_JSONL="$JSONL_PATH"
    reset_turn_state
    EMITTED_TURNS=0
    LAST_TURN_FINGERPRINT=""
    write_session_header
    build_events_from_source "$SOURCE_JSONL"
  else
    exit 1
  fi
fi

flush_turn() {
  if [ "$HAS_TURN" != "true" ]; then
    return
  fi

  local fingerprint
  fingerprint=$(printf '%s\n%s\n%s\n' "$TURN_USER_TEXT" "$TURN_ASSISTANT_TEXT" "$TURN_TOOLS" | shasum -a 256 | cut -d' ' -f1)
  if [ -n "$LAST_TURN_FINGERPRINT" ] && [ "$LAST_TURN_FINGERPRINT" = "$fingerprint" ]; then
    return
  fi

  LAST_TURN_FINGERPRINT="$fingerprint"

  local user_time assistant_time time_range
  local display_turn
  user_time=$(utc_to_local "$TURN_USER_TS" "%H:%M:%S")
  assistant_time=$(utc_to_local "$TURN_ASSISTANT_LAST_TS" "%H:%M:%S")
  display_turn=$((EMITTED_TURNS + 1))
  time_range=""

  if [ -n "$user_time" ] && [ -n "$assistant_time" ]; then
    time_range=" [${user_time} -> ${assistant_time}]"
  elif [ -n "$user_time" ]; then
    time_range=" [${user_time}]"
  fi

  {
    echo ""
    echo "---"
    echo "## Turn ${display_turn}${time_range}"
    echo ""
    echo "### User"
    echo "$TURN_USER_TEXT"
  } >> "$OUT_FILE"

  if [ -n "$TURN_ASSISTANT_TEXT" ]; then
    local line_count
    line_count=$(printf '%s\n' "$TURN_ASSISTANT_TEXT" | wc -l | tr -d ' ')
    {
      echo ""
      echo "### Assistant (${line_count} lines$([ "$line_count" -gt "$TRUNCATE_THRESHOLD" ] && echo " -> truncated"))"
    } >> "$OUT_FILE"

    if [ "$line_count" -gt "$TRUNCATE_THRESHOLD" ]; then
      local half omitted
      half=$((TRUNCATE_THRESHOLD / 2))
      omitted=$((line_count - TRUNCATE_THRESHOLD))
      {
        printf '%s\n' "$TURN_ASSISTANT_TEXT" | head -n "$half"
        echo ""
        echo "...(${omitted} lines truncated)..."
        echo ""
        printf '%s\n' "$TURN_ASSISTANT_TEXT" | tail -n "$half"
      } >> "$OUT_FILE"
    else
      printf '%s\n' "$TURN_ASSISTANT_TEXT" >> "$OUT_FILE"
    fi
  fi

  if [ -n "$TURN_TOOLS" ]; then
    echo "" >> "$OUT_FILE"
    echo "### Tools" >> "$OUT_FILE"
    local idx=1
    while IFS= read -r tool_line; do
      [ -n "$tool_line" ] || continue
      echo "${idx}. ${tool_line}" >> "$OUT_FILE"
      idx=$((idx + 1))
    done <<< "$TURN_TOOLS"
  fi

  EMITTED_TURNS=$((EMITTED_TURNS + 1))
}

while IFS= read -r event; do
  kind=$(echo "$event" | jq -r '.kind')

  if [ "$kind" = "message" ]; then
    role=$(echo "$event" | jq -r '.role')
    msg_ts=$(echo "$event" | jq -r '.ts // empty')
    msg_text=$(echo "$event" | jq -r '.text // "" | gsub("\\\\n"; "\n")')

    if [ "$role" = "user" ]; then
      if [ "$HAS_TURN" = "true" ]; then
        flush_turn
      fi

      TURN_NUM=$((TURN_NUM + 1))
      HAS_TURN=true
      TURN_USER_TEXT="$msg_text"
      TURN_USER_TS="$msg_ts"
      TURN_ASSISTANT_TEXT=""
      TURN_ASSISTANT_LAST_TS=""
      TURN_TOOLS=""
    else
      if [ "$HAS_TURN" = "true" ]; then
        if [ -n "$TURN_ASSISTANT_TEXT" ]; then
          TURN_ASSISTANT_TEXT="${TURN_ASSISTANT_TEXT}"$'\n\n'"${msg_text}"
        else
          TURN_ASSISTANT_TEXT="$msg_text"
        fi
        TURN_ASSISTANT_LAST_TS="$msg_ts"
      fi
    fi
  elif [ "$kind" = "tool" ]; then
    if [ "$HAS_TURN" = "true" ]; then
      tool_name=$(echo "$event" | jq -r '.name // "tool"')
      tool_args=$(echo "$event" | jq -r '.arguments // ""')
      tool_summary=$(summarize_tool "$tool_name" "$tool_args")
      if [ -n "$TURN_TOOLS" ]; then
        TURN_TOOLS="${TURN_TOOLS}"$'\n'"${tool_summary}"
      else
        TURN_TOOLS="$tool_summary"
      fi
    fi
  fi
done < "$EVENTS_FILE"

if [ "$HAS_TURN" = "true" ]; then
  flush_turn
  reset_turn_state
fi

redact_file_in_place "$OUT_FILE"

if [ "$STATE_ENABLED" = "true" ]; then
  save_sync_state "$STATE_FILE" "$CURRENT_SIZE" "$JSONL_PATH" "$OUT_FILE" "$CURRENT_MTIME"
fi

if [ "$COPY_RAW" = "true" ]; then
  RAW_DIR="$OUT_DIR/raw"
  RAW_FILE="$RAW_DIR/$(basename "$JSONL_PATH")"
  mkdir -p "$RAW_DIR"
  cp "$JSONL_PATH" "$RAW_FILE"
  redact_file_in_place "$RAW_FILE"
fi

link_log_into_live_session "$OUT_FILE" || true

log "Codex session exported: $OUT_FILE"
exit 0
