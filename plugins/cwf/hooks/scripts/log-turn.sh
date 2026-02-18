#!/usr/bin/env bash
set -euo pipefail
# log-turn.sh — Stop/SessionEnd hook (async)
# Logs conversation turns to markdown session files.
# Idempotent — safe to call multiple times per turn.
# SessionEnd passes "session_end" arg to trigger auto-commit.

HOOK_GROUP="log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"
# shellcheck source=plugins/cwf/hooks/scripts/text-format.sh
source "$SCRIPT_DIR/text-format.sh"
# shellcheck source=plugins/cwf/hooks/scripts/env-loader.sh
source "$SCRIPT_DIR/env-loader.sh"

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
REDACTOR_SCRIPT="${PLUGIN_ROOT}/scripts/codex/redact-sensitive.pl"
LIVE_RESOLVER_SCRIPT="${PLUGIN_ROOT}/scripts/cwf-live-state.sh"
RESOLVER_SCRIPT="${PLUGIN_ROOT}/scripts/cwf-artifact-paths.sh"
CAN_REDACT="false"
if command -v perl >/dev/null 2>&1 && [ -f "$REDACTOR_SCRIPT" ]; then
    CAN_REDACT="true"
fi

if [ -f "$RESOLVER_SCRIPT" ]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$RESOLVER_SCRIPT"
fi

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

HOOK_TYPE="${1:-stop}"

# ── Read hook input ──────────────────────────────────────────────────────────
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

if [ -z "$CWD" ]; then
    CWD="$(pwd)"
fi

# ── Wait for transcript flush (async hook may race with file writes) ─────────
sleep 0.3

# ── Load config (env -> shell profiles) ─────────────────────────────────────
cwf_env_load_vars \
  CWF_SESSION_LOG_DIR \
  CWF_SESSION_LOG_ENABLED \
  CWF_SESSION_LOG_TRUNCATE \
  CWF_SESSION_LOG_AUTO_COMMIT
cwf_env_load_vars CWF_ARTIFACT_ROOT

ENABLED="${CWF_SESSION_LOG_ENABLED:-true}"
if [ "$ENABLED" != "true" ]; then
    exit 0
fi

ARTIFACT_ROOT_RAW="${CWF_ARTIFACT_ROOT:-.cwf}"
if [[ "$ARTIFACT_ROOT_RAW" == /* ]]; then
    ARTIFACT_ROOT="$ARTIFACT_ROOT_RAW"
else
    ARTIFACT_ROOT="${CWD}/${ARTIFACT_ROOT_RAW}"
fi

DEFAULT_LOG_DIR="${ARTIFACT_ROOT}/projects/sessions"
if declare -F resolve_cwf_session_logs_dir >/dev/null 2>&1; then
    DEFAULT_LOG_DIR="$(resolve_cwf_session_logs_dir "$CWD")"
else
    DEFAULT_LOG_DIR="${ARTIFACT_ROOT}/sessions"
    LEGACY_LOG_DIR="${ARTIFACT_ROOT}/projects/sessions"
    if [ ! -d "$DEFAULT_LOG_DIR" ] && [ -d "$LEGACY_LOG_DIR" ]; then
        DEFAULT_LOG_DIR="$LEGACY_LOG_DIR"
    fi
fi
LOG_DIR="${CWF_SESSION_LOG_DIR:-$DEFAULT_LOG_DIR}"
TRUNCATE_THRESHOLD="${CWF_SESSION_LOG_TRUNCATE:-10}"
AUTO_COMMIT="${CWF_SESSION_LOG_AUTO_COMMIT:-false}"

# ── Timezone helpers (transcript timestamps are UTC) ─────────────────────────
LOCAL_TZ=$(date +%Z)

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

# ── Session hash & state ─────────────────────────────────────────────────────
HASH=$(echo -n "$SESSION_ID" | shasum -a 256 | cut -c1-8)
STATE_DIR="/tmp/cwf-session-log-${HASH}"
mkdir -p "$STATE_DIR"

# ── Atomic lock (prevent race between Stop and SessionEnd) ────────────────────
LOCK_DIR="${STATE_DIR}/lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # Another instance is running — exit silently
    exit 0
fi
TEMP_ENTRIES=$(mktemp)
trap 'rm -f "$TEMP_ENTRIES"; rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# ── Resolve output file path ────────────────────────────────────────────────
# Filename format: {yymmdd}-{hhmm}-{hash}.claude.md
# Session start time is used for {hhmm}, cached in state for consistency
OUT_FILE_STATE="${STATE_DIR}/out_file"
mkdir -p "$LOG_DIR"

if [ -f "$OUT_FILE_STATE" ]; then
    OUT_FILE=$(cat "$OUT_FILE_STATE")
else
    # Check for existing file with this hash (handles process restart)
    EXISTING=""
    for f in "$LOG_DIR"/*-"${HASH}.claude.md" "$LOG_DIR"/*-"${HASH}.md"; do
        if [ -f "$f" ]; then
            EXISTING="$f"
            break
        fi
    done

    if [ -n "$EXISTING" ]; then
        OUT_FILE="$EXISTING"
    else
        # Compute start time from first transcript entry
        START_TIME=""
        FIRST_TS=$(jq -rs '[.[] | select(.timestamp) | .timestamp // empty] | first // empty' < "$TRANSCRIPT_PATH" 2>/dev/null || true)
        if [ -n "${FIRST_TS:-}" ]; then
            START_TIME=$(utc_to_local "$FIRST_TS" "%H%M")
        fi
        [ -z "${START_TIME:-}" ] && START_TIME=$(date +%H%M)
        DATE_STR=$(date +%y%m%d)
        OUT_FILE="${LOG_DIR}/${DATE_STR}-${START_TIME}-${HASH}.claude.md"
    fi
    echo "$OUT_FILE" > "$OUT_FILE_STATE"
fi

if [ -f "$OUT_FILE" ]; then
    link_log_into_live_session "$OUT_FILE" || true
fi

# ── Detect team membership ──────────────────────────────────────────────────
# Strategy:
#   1. Check cached state (subsequent invocations)
#   2. Read transcript first line for teamName/agentName (teammates have these)
#   3. Fallback: check team configs for leadSessionId match (leader detection)
TEAM_NAME=""
TEAM_ROLE=""
TEAM_INFO_FILE="${STATE_DIR}/team_info"
if [ -f "$TEAM_INFO_FILE" ]; then
    TEAM_NAME=$(head -1 "$TEAM_INFO_FILE")
    TEAM_ROLE=$(sed -n '2p' "$TEAM_INFO_FILE")
else
    # Transcript entries have teamName and agentName fields
    TEAM_NAME=$(head -1 "$TRANSCRIPT_PATH" | jq -r '.teamName // empty' 2>/dev/null || true)
    if [ -n "${TEAM_NAME:-}" ]; then
        TEAM_ROLE=$(head -1 "$TRANSCRIPT_PATH" | jq -r '.agentName // "member"' 2>/dev/null || true)
    else
        # Leader's transcript has teamName=null; match via leadSessionId in configs
        if [ -d "$HOME/.claude/teams" ]; then
            for config in "$HOME/.claude/teams"/*/config.json; do
                [ -f "$config" ] || continue
                LEAD_SID=$(jq -r '.leadSessionId // empty' "$config" 2>/dev/null || true)
                if [ "${LEAD_SID:-}" = "$SESSION_ID" ]; then
                    TEAM_NAME=$(jq -r '.name // empty' "$config" 2>/dev/null || true)
                    TEAM_ROLE="leader"
                    break
                fi
            done
        fi
    fi
    # Cache for subsequent invocations
    if [ -n "${TEAM_NAME:-}" ]; then
        printf '%s\n%s\n' "$TEAM_NAME" "$TEAM_ROLE" > "$TEAM_INFO_FILE"
    fi
fi

# ── Incremental offset ───────────────────────────────────────────────────────
OFFSET_FILE="${STATE_DIR}/offset"
LAST_OFFSET=0
if [ -f "$OFFSET_FILE" ]; then
    LAST_OFFSET=$(cat "$OFFSET_FILE")
fi

TOTAL_LINES=$(wc -l < "$TRANSCRIPT_PATH" | tr -d ' ')

if [ "$TOTAL_LINES" -lt "$LAST_OFFSET" ]; then
    # Transcript was truncated (e.g., user rewound with Esc+Esc)
    # Re-read everything; we'll skip already-logged turns and only log new ones
    REWOUND=true
    LAST_OFFSET=0
elif [ "$TOTAL_LINES" -eq "$LAST_OFFSET" ]; then
    # No new lines — but SessionEnd still needs to auto-commit the existing log
    if [ "$HOOK_TYPE" = "session_end" ] && [ "$AUTO_COMMIT" = "true" ]; then
        if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            if git -C "$CWD" diff --cached --quiet 2>/dev/null; then
                # Collect ALL session log .md files (untracked + modified)
                SESSION_FILES=$(git -C "$CWD" ls-files --others --modified -- "$LOG_DIR/*.md" 2>/dev/null)
                if [ -n "$SESSION_FILES" ]; then
                    echo "$SESSION_FILES" | xargs -I{} git -C "$CWD" add -- "{}" 2>/dev/null
                    FILE_COUNT=$(echo "$SESSION_FILES" | wc -l | tr -d ' ')
                    if [ "$FILE_COUNT" -eq 1 ]; then
                        COMMIT_MSG="prompt-log: $(basename "$OUT_FILE" .md)"
                    else
                        COMMIT_MSG="prompt-log: ${FILE_COUNT} sessions ($(basename "$OUT_FILE" .md))"
                    fi
                    git -C "$CWD" commit --no-verify -m "$COMMIT_MSG" 2>/dev/null || true
                fi
            fi
        fi
    fi
    exit 0
fi

# ── Read new JSONL entries (use temp file to avoid bash null-byte stripping) ──
tail -n +"$((LAST_OFFSET + 1))" "$TRANSCRIPT_PATH" > "$TEMP_ENTRIES"

# ── Parse turns with jq ──────────────────────────────────────────────────────
# Group entries into turns: user message → assistant messages until next user
TURNS_JSON=$(jq -s '
  # Filter to user/assistant entries only (skip snapshots, etc.)
  [ .[] | select(.type == "user" or .type == "assistant") ] |

  # Group into turns
  reduce .[] as $e (
    {turns: [], cur: null};
    if $e.type == "user" and ($e.isMeta | not) and
       ($e.message.content |
         (type == "string" and length > 0) or
         (type == "array" and any(
           type == "string" or .type == "text" or .type == "image"
         ))
       )
    then
      # New user turn — flush previous
      {
        turns: (if .cur then .turns + [.cur] else .turns end),
        cur: {user: $e, assistants: []}
      }
    elif $e.type == "assistant" and .cur then
      # Add assistant entry to current turn
      .cur.assistants += [$e] | .
    else . end
  ) |
  # Flush final turn
  if .cur then .turns + [.cur] else .turns end
' < "$TEMP_ENTRIES" 2>/dev/null || echo '[]')

TURN_COUNT=$(echo "$TURNS_JSON" | jq 'length')
if [ "$TURN_COUNT" -eq 0 ]; then
    # Update offset even if no turns (skip meta/snapshot entries)
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
    # Persist turn number so next invocation doesn't restart from Turn 1
    TURN_NUM_FILE="${STATE_DIR}/turn_num"
    TURN_START=1
    if [ -f "$TURN_NUM_FILE" ]; then
        TURN_START=$(cat "$TURN_NUM_FILE")
    fi
    echo "$TURN_START" > "$TURN_NUM_FILE"
    exit 0
fi

# ── Determine turn numbering ─────────────────────────────────────────────────
TURN_NUM_FILE="${STATE_DIR}/turn_num"
TURN_START=1
if [ -f "$TURN_NUM_FILE" ]; then
    TURN_START=$(cat "$TURN_NUM_FILE")
fi

# ── Write session header if first write ───────────────────────────────────────
if [ ! -f "$OUT_FILE" ]; then
    # Extract metadata from first assistant entry
    MODEL=$(jq -rs '[.[] | select(.type == "assistant") | .message.model // empty] | first // empty' < "$TEMP_ENTRIES")
    [ -z "$MODEL" ] && MODEL="unknown"

    BRANCH=$(jq -rs '[.[] | select(.gitBranch) | .gitBranch // empty] | first // empty' < "$TEMP_ENTRIES")
    [ -z "$BRANCH" ] && BRANCH="unknown"

    VERSION=$(jq -rs '[.[] | select(.version) | .version // empty] | first // empty' < "$TEMP_ENTRIES")
    [ -z "$VERSION" ] && VERSION="unknown"

    FIRST_TS=$(jq -rs '[.[] | select(.timestamp) | .timestamp // empty] | first // empty' < "$TEMP_ENTRIES")
    if [ -n "$FIRST_TS" ]; then
        STARTED=$(utc_to_local "$FIRST_TS" "%Y-%m-%d %H:%M:%S")
        [ -z "$STARTED" ] && STARTED="$FIRST_TS"
    else
        STARTED=$(date "+%Y-%m-%d %H:%M:%S")
    fi

    {
        echo "# Session: ${HASH}"
        echo "Model: ${MODEL} | Branch: ${BRANCH}"
        [ -n "$TEAM_NAME" ] && echo "Team: ${TEAM_NAME} (${TEAM_ROLE})"
        echo "Recorded by: ${USER:-unknown}@$(hostname 2>/dev/null || echo unknown)"
        echo "CWD: ${CWD}"
        echo "Started: ${STARTED} ${LOCAL_TZ} | Claude Code v${VERSION}"
    } > "$OUT_FILE"
fi

if [ -f "$OUT_FILE" ]; then
    link_log_into_live_session "$OUT_FILE" || true
fi

# ── Handle rewind: mark and skip already-logged turns ────────────────────────
FIRST_TURN_IDX=0
if [ "${REWOUND:-}" = "true" ]; then
    if [ -f "$OUT_FILE" ]; then
        REWIND_TS=$(date "+%H:%M:%S")
        {
            echo ""
            echo "---"
            echo "## ⟲ Rewind [${REWIND_TS}] (after Turn $((TURN_START - 1)))"
        } >> "$OUT_FILE"
    fi
    # Skip already-logged turns; at minimum, log the last turn (the new one)
    ALREADY_LOGGED=$((TURN_START - 1))
    if [ "$ALREADY_LOGGED" -ge "$TURN_COUNT" ]; then
        FIRST_TURN_IDX=$((TURN_COUNT - 1))
    else
        FIRST_TURN_IDX="$ALREADY_LOGGED"
    fi
    # Keep TURN_START unchanged — new turns continue the sequence
fi

# ── Format and append each turn ───────────────────────────────────────────────
TURN_IDX=$FIRST_TURN_IDX
while [ "$TURN_IDX" -lt "$TURN_COUNT" ]; do
    TURN=$(echo "$TURNS_JSON" | jq ".[$TURN_IDX]")
    CURRENT_TURN_NUM=$((TURN_START + TURN_IDX - FIRST_TURN_IDX))

    # ── Timestamps ────────────────────────────────────────────────────────
    USER_TS=$(echo "$TURN" | jq -r '.user.timestamp // empty')
    LAST_ASSISTANT_TS=$(echo "$TURN" | jq -r '.assistants[-1].timestamp // empty')

    USER_TIME=$(utc_to_local "$USER_TS")
    ASSISTANT_TIME=$(utc_to_local "$LAST_ASSISTANT_TS")

    # Duration
    DURATION_STR=""
    if [ -n "$USER_TS" ] && [ -n "$LAST_ASSISTANT_TS" ]; then
        USER_EPOCH=$(utc_to_epoch "$USER_TS")
        ASSISTANT_EPOCH=$(utc_to_epoch "$LAST_ASSISTANT_TS")
        if [ -n "$USER_EPOCH" ] && [ -n "$ASSISTANT_EPOCH" ]; then
            DURATION=$((ASSISTANT_EPOCH - USER_EPOCH))
            if [ "$DURATION" -ge 0 ]; then
                DURATION_STR=" (${DURATION}s)"
            fi
        fi
    fi

    # ── Token usage ───────────────────────────────────────────────────────
    TOKEN_STR=""
    INPUT_TOKENS=$(echo "$TURN" | jq '[.assistants[].message.usage.input_tokens // 0] | add')
    OUTPUT_TOKENS=$(echo "$TURN" | jq '[.assistants[].message.usage.output_tokens // 0] | add')
    if [ "$INPUT_TOKENS" != "null" ] && [ "$INPUT_TOKENS" != "0" ]; then
        TOKEN_STR=" | Tokens: ${INPUT_TOKENS}↑ ${OUTPUT_TOKENS}↓"
    fi

    # ── Turn header ───────────────────────────────────────────────────────
    TIME_RANGE=""
    if [ -n "$USER_TIME" ] && [ -n "$ASSISTANT_TIME" ]; then
        TIME_RANGE=" [${USER_TIME} → ${ASSISTANT_TIME}]"
    elif [ -n "$USER_TIME" ]; then
        TIME_RANGE=" [${USER_TIME}]"
    fi

    {
        echo ""
        echo "---"
        echo "## Turn ${CURRENT_TURN_NUM}${TIME_RANGE}${DURATION_STR}${TOKEN_STR}"
    } >> "$OUT_FILE"

    # ── User content ──────────────────────────────────────────────────────
    USER_CONTENT=$(echo "$TURN" | jq -r '
      .user.message.content |
      if type == "string" then .
      elif type == "array" then
        [ .[] |
          if type == "string" then .
          elif .type == "text" then .text
          elif .type == "image" then "[Image]"
          else empty end
        ] | join("\n")
      else "" end
    ')
    USER_CONTENT=$(redact_sensitive_text "$USER_CONTENT")

    {
        echo ""
        echo "### User"
        echo "$USER_CONTENT"
    } >> "$OUT_FILE"

    # ── Assistant content ─────────────────────────────────────────────────
    ASSISTANT_TEXT=$(echo "$TURN" | jq -r '
      [.assistants[].message.content[] |
        select(.type == "text") | .text
      ] | join("\n")
      # Strip leading/trailing blank lines
      | gsub("^[\\s\\n]+"; "") | gsub("[\\s\\n]+$"; "")
    ')
    ASSISTANT_TEXT=$(redact_sensitive_text "$ASSISTANT_TEXT")

    if [ -n "$ASSISTANT_TEXT" ]; then
        ASSISTANT_TEXT=$(normalize_multiline_text "$ASSISTANT_TEXT")
        LINE_COUNT=$(text_line_count "$ASSISTANT_TEXT")

        {
            echo ""
            echo "### Assistant${LINE_COUNT:+ (${LINE_COUNT} lines$([ "$LINE_COUNT" -gt "$TRUNCATE_THRESHOLD" ] && echo " → truncated"))}"
        } >> "$OUT_FILE"

        if [ "$LINE_COUNT" -gt "$TRUNCATE_THRESHOLD" ]; then
            OMITTED=$((LINE_COUNT - TRUNCATE_THRESHOLD))
            MARKER="...(${OMITTED} lines truncated)..."
            truncate_middle_lines "$ASSISTANT_TEXT" "$TRUNCATE_THRESHOLD" "$MARKER" >> "$OUT_FILE"
        else
            printf '%s\n' "$ASSISTANT_TEXT" >> "$OUT_FILE"
        fi
    fi

    # ── Tool calls ────────────────────────────────────────────────────────
    TOOLS_JSON=$(echo "$TURN" | jq -c '
      [.assistants[].message.content[] |
        select(.type == "tool_use") |
        {name, input}
      ]
    ')

    TOOL_COUNT=$(echo "$TOOLS_JSON" | jq 'length')
    if [ "$TOOL_COUNT" -gt 0 ]; then
        echo "" >> "$OUT_FILE"
        echo "### Tools" >> "$OUT_FILE"

        TOOL_IDX=0
        while [ "$TOOL_IDX" -lt "$TOOL_COUNT" ]; do
            TOOL=$(echo "$TOOLS_JSON" | jq ".[$TOOL_IDX]")
            TOOL_NAME=$(echo "$TOOL" | jq -r '.name')

            TOOL_SUMMARY=$(echo "$TOOL" | jq -r --arg name "$TOOL_NAME" '
              if $name == "Read" then
                "Read `\(.input.file_path // "?")`"
              elif $name == "Bash" then
                "Bash `\(.input.command // "?" | .[0:80])`"
              elif $name == "Edit" then
                "Edit `\(.input.file_path // "?")`"
              elif $name == "Write" then
                "Write `\(.input.file_path // "?")`"
              elif $name == "Task" then
                "Task[\(.input.subagent_type // "?")] \"\(.input.description // "?")\""
              elif $name == "Grep" then
                "Grep `\(.input.pattern // "?")` \(.input.path // "")"
              elif $name == "Glob" then
                "Glob `\(.input.pattern // "?")`"
              elif $name == "Skill" then
                "Skill `\(.input.skill // "?")`"
              elif $name == "AskUserQuestion" then
                "AskUserQuestion \"\(
                  .input.questions[0].question // .input.questions[0].header // "?" | .[0:60]
                )\" [\(
                  .input.questions[0].options // [] | map(.label) | join(", ") | .[0:80]
                )]"
              elif $name == "EnterPlanMode" then
                "EnterPlanMode"
              elif $name == "ExitPlanMode" then
                "ExitPlanMode"
              elif $name == "WebFetch" then
                "WebFetch `\(.input.url // "?" | .[0:60])`"
              elif $name == "WebSearch" then
                "WebSearch `\(.input.query // "?" | .[0:60])`"
              elif $name == "TaskCreate" then
                "TaskCreate \"\(.input.subject // "?")\""
              elif $name == "TaskUpdate" then
                "TaskUpdate #\(.input.taskId // "?") → \(.input.status // "?")"
              elif $name == "NotebookEdit" then
                "NotebookEdit `\(.input.notebook_path // "?")`"
              else
                $name
              end
            ')
            TOOL_SUMMARY=$(redact_sensitive_text "$TOOL_SUMMARY")

            TOOL_NUM=$((TOOL_IDX + 1))
            echo "${TOOL_NUM}. ${TOOL_SUMMARY}" >> "$OUT_FILE"
            TOOL_IDX=$((TOOL_IDX + 1))
        done
    fi

    # ── AskUserQuestion answers (from tool_results in user content) ────
    ASK_ANSWERS=$(echo "$TURN" | jq -r '
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
    ' 2>/dev/null || true)
    ASK_ANSWERS=$(redact_sensitive_text "$ASK_ANSWERS")
    if [ -n "$ASK_ANSWERS" ]; then
        {
            echo ""
            echo "### User Answers"
            echo "$ASK_ANSWERS"
        } >> "$OUT_FILE"
        persist_decision_journal_entry "$CURRENT_TURN_NUM" "$TURN" "$LAST_ASSISTANT_TS"
    fi

    TURN_IDX=$((TURN_IDX + 1))
done

# ── Update state ──────────────────────────────────────────────────────────────
echo "$TOTAL_LINES" > "$OFFSET_FILE"
echo "$((TURN_START + TURN_COUNT - FIRST_TURN_IDX))" > "$TURN_NUM_FILE"

# ── Auto-commit session log on SessionEnd ────────────────────────────────────
if [ "$HOOK_TYPE" = "session_end" ] && [ "$AUTO_COMMIT" = "true" ] && [ -f "$OUT_FILE" ]; then
    if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # Only proceed if no pre-existing staged changes (don't interfere)
        if git -C "$CWD" diff --cached --quiet 2>/dev/null; then
            # Collect ALL session log .md files (untracked + modified)
            # This ensures sub-agent session logs (from team runs) are included
            SESSION_FILES=$(git -C "$CWD" ls-files --others --modified -- "$LOG_DIR/*.md" 2>/dev/null)
            if [ -n "$SESSION_FILES" ]; then
                echo "$SESSION_FILES" | xargs -I{} git -C "$CWD" add -- "{}" 2>/dev/null
                FILE_COUNT=$(echo "$SESSION_FILES" | wc -l | tr -d ' ')
                if [ "$FILE_COUNT" -eq 1 ]; then
                    COMMIT_MSG="prompt-log: $(basename "$OUT_FILE" .md)"
                else
                    COMMIT_MSG="prompt-log: ${FILE_COUNT} sessions ($(basename "$OUT_FILE" .md))"
                fi
                git -C "$CWD" commit --no-verify -m "$COMMIT_MSG" 2>/dev/null || true
            fi
        fi
    fi
fi

exit 0
