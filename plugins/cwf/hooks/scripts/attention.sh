#!/usr/bin/env bash
set -euo pipefail
# attention.sh — Notification hook for idle_prompt (async)
# Sends Slack notification when Claude is idle.
# Includes task context: user request, Claude response, questions, and todo status.
#
# v2.0: Uses slack-send.sh for Web API threading support.
# When a thread exists (created by track-user-input.sh), sends as thread reply.
# Falls back to standalone message or legacy webhook if no thread/bot token.
#
# === COMPATIBILITY WARNING ===
# This script relies on parse-transcript.sh to parse Claude Code's internal transcript format.
# The transcript structure is not a public API and may change between versions.
# If notifications stop working after a Claude Code update, the jq queries may need adjustment.

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === HELPER FUNCTIONS ===

# Truncate text to first N lines + ... + last N lines
truncate_text() {
    local text="$1"
    local line_count=$(echo "$text" | wc -l)

    if [ "$line_count" -le 10 ]; then
        echo "$text"
    else
        local first=$(echo "$text" | head -n 5)
        local last=$(echo "$text" | tail -n 5)
        echo "$first"
        echo ""
        echo "...(truncated)..."
        echo ""
        echo "$last"
    fi
}

# Escape special characters for JSON
escape_json() {
    local text="$1"
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    text="${text//$'\t'/\\t}"
    echo "$text"
}

# Source shared Slack utility
# shellcheck source=slack-send.sh
source "$SCRIPT_DIR/slack-send.sh"

# === CONFIGURATION ===
slack_load_config

# === READ HOOK INPUT ===
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Compute session hash for state files
HASH=""
if [ -n "$SESSION_ID" ]; then
    HASH=$(slack_session_hash "$SESSION_ID")
fi

# === DEBUG LOGGING ===
if [ -n "$HASH" ]; then
    DEBUG_LOG=$(slack_state_file "$HASH" "debug.log")
    THREAD_TS_FILE=$(slack_state_file "$HASH" "thread-ts")
    echo "$(date): attention.sh called (tool_name=${TOOL_NAME:-none}, hash=$HASH, thread-ts-exists=$([ -f "$THREAD_TS_FILE" ] && echo "yes:$(cat "$THREAD_TS_FILE")" || echo "no"))" >> "$DEBUG_LOG"
fi

# === BUILD NOTIFICATION ===
HOSTNAME=$(hostname)
TITLE="Claude Code @ $HOSTNAME"

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Use parse-transcript.sh to get parsed data
    PARSE_SCRIPT="$SCRIPT_DIR/parse-transcript.sh"

    if [ -x "$PARSE_SCRIPT" ]; then
        eval "$("$PARSE_SCRIPT" "$TRANSCRIPT_PATH")"
        LAST_HUMAN_TEXT="$PARSED_HUMAN_TEXT"
        LAST_ASSISTANT_TEXT="$PARSED_ASSISTANT_TEXT"
        ASK_QUESTION="$PARSED_ASK_QUESTION"
        TODO_STATUS="$PARSED_TODO_STATUS"
    else
        # Fallback: minimal parsing if parse-transcript.sh is not available
        LAST_HUMAN_TEXT=""
        LAST_ASSISTANT_TEXT=""
        ASK_QUESTION=""
        TODO_STATUS=""
    fi

    # Build message body (compact format for thread replies)
    MESSAGE=""

    if [ -n "$LAST_HUMAN_TEXT" ]; then
        TRUNCATED_REQUEST=$(truncate_text "$LAST_HUMAN_TEXT")
        MESSAGE+=":memo: Request:"$'\n'"$TRUNCATED_REQUEST"$'\n'
    fi

    if [ -n "$LAST_ASSISTANT_TEXT" ]; then
        TRUNCATED_RESPONSE=$(truncate_text "$LAST_ASSISTANT_TEXT")
        MESSAGE+=$'\n'":robot_face: Response:"$'\n'"$TRUNCATED_RESPONSE"$'\n'
    fi

    if [ -n "$ASK_QUESTION" ]; then
        TRUNCATED_QUESTION=$(truncate_text "$ASK_QUESTION")
        MESSAGE+=$'\n'":question: Waiting for answer:"$'\n'"$TRUNCATED_QUESTION"$'\n'
    fi

    if [ -n "$TODO_STATUS" ]; then
        MESSAGE+=$'\n'"$TODO_STATUS"
    fi

    # Detect plan mode from tool_name or transcript
    if [ "$TOOL_NAME" = "EnterPlanMode" ]; then
        MESSAGE=":clipboard: Requesting plan mode approval"$'\n\n'"$MESSAGE"
    elif [ "$TOOL_NAME" = "ExitPlanMode" ]; then
        # Try to extract plan content from transcript (last Write to a plans/ path)
        PLAN_CONTENT=""
        if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
            PLAN_FILE=$(jq -r '
                [.[] | select(.role == "assistant") | .content[]? |
                 select(.type == "tool_use" and .name == "Write") |
                 .input.file_path // empty |
                 select(test("plans/|plan\\.md"))] | last // empty
            ' "$TRANSCRIPT_PATH" 2>/dev/null) || true
            if [ -n "${PLAN_FILE:-}" ] && [ -f "$PLAN_FILE" ]; then
                PLAN_CONTENT=$(cat "$PLAN_FILE" 2>/dev/null) || true
            fi
        fi
        if [ -n "$PLAN_CONTENT" ]; then
            TRUNCATED_PLAN=$(truncate_text "$PLAN_CONTENT")
            MESSAGE=":clipboard: Plan ready for review"$'\n\n'"$TRUNCATED_PLAN"
        else
            MESSAGE=":clipboard: Plan ready for review"$'\n\n'"$MESSAGE"
        fi
    fi
else
    MESSAGE="Claude is waiting for your input"
fi

# === DEDUPLICATION ===
# Skip sending if message is identical to the last one
if [ -n "$HASH" ]; then
    CACHE_FILE=$(slack_state_file "$HASH" "last-hash")
else
    CACHE_FILE="/tmp/claude-attention-last-hash"
fi
MESSAGE_HASH=$(echo "$MESSAGE" | shasum -a 256 | cut -d' ' -f1)

if [ -f "$CACHE_FILE" ]; then
    LAST_HASH=$(cat "$CACHE_FILE" 2>/dev/null) || true
    if [ "${LAST_HASH:-}" = "$MESSAGE_HASH" ]; then
        # Same message as before, skip notification
        exit 0
    fi
fi

# Save current hash for next comparison
echo "$MESSAGE_HASH" > "$CACHE_FILE"

# === SEND NOTIFICATIONS ===
if [ -n "$HASH" ]; then
    THREAD_TS=$(slack_get_thread_ts "$HASH")
    # Retry once if thread-ts not found (parent creation may still be in progress)
    if [ -z "$THREAD_TS" ]; then
        sleep 2
        THREAD_TS=$(slack_get_thread_ts "$HASH")
    fi
    if [ -n "$THREAD_TS" ]; then
        # Thread reply: compact format (no title header)
        slack_send "$HASH" "$MESSAGE" "true"
    else
        # No thread yet: include title as standalone message
        slack_send "$HASH" "*${TITLE}*"$'\n'"$MESSAGE" ""
    fi
else
    # Legacy fallback: no session_id available
    ESCAPED_TITLE=$(escape_json "$TITLE")
    ESCAPED_MESSAGE=$(escape_json "$MESSAGE")

    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -s -X POST "${SLACK_WEBHOOK_URL}" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"*$ESCAPED_TITLE*\\n$ESCAPED_MESSAGE\"}" \
            > /dev/null 2>&1
    fi
fi

exit 0
