#!/usr/bin/env bash
set -euo pipefail
# attention.sh — Notification hook for idle_prompt (async)
# Sends Slack notification when Claude is idle.
# Includes task context: user request, Claude response, questions, and todo status.
#
# v2.0: Uses slack-send.sh for Web API threading support.
# When a thread exists (created by track-user-input.sh), sends as thread reply.
# Falls back to standalone message or webhook if no thread/bot token.
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

# Source shared Slack utility
# shellcheck source=slack-send.sh
source "$SCRIPT_DIR/slack-send.sh"
# shellcheck source=text-format.sh
source "$SCRIPT_DIR/text-format.sh"

# === CONFIGURATION ===
slack_load_config
ATTENTION_TRUNCATE_LINES="${CWF_ATTENTION_TRUNCATE:-10}"
if ! [[ "$ATTENTION_TRUNCATE_LINES" =~ ^[0-9]+$ ]] || [ "$ATTENTION_TRUNCATE_LINES" -le 0 ]; then
    ATTENTION_TRUNCATE_LINES=10
fi

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
    append_section() {
        local title="$1"
        local body="$2"
        if [ -z "$body" ]; then
            return
        fi

        if [ -n "$MESSAGE" ]; then
            MESSAGE+=$'\n\n'
        fi
        MESSAGE+="${title}"$'\n'"${body}"
    }

    if [ -n "$LAST_HUMAN_TEXT" ]; then
        TRUNCATED_REQUEST=$(normalize_and_truncate_text "$LAST_HUMAN_TEXT" "$ATTENTION_TRUNCATE_LINES")
        append_section ":memo: Request:" "$TRUNCATED_REQUEST"
    fi

    if [ -n "$LAST_ASSISTANT_TEXT" ]; then
        TRUNCATED_RESPONSE=$(normalize_and_truncate_text "$LAST_ASSISTANT_TEXT" "$ATTENTION_TRUNCATE_LINES")
        append_section ":robot_face: Response:" "$TRUNCATED_RESPONSE"
    fi

    if [ -n "$ASK_QUESTION" ]; then
        TRUNCATED_QUESTION=$(normalize_and_truncate_text "$ASK_QUESTION" "$ATTENTION_TRUNCATE_LINES")
        append_section ":question: Waiting for answer:" "$TRUNCATED_QUESTION"
    fi

    if [ -n "$TODO_STATUS" ]; then
        TODO_TEXT=$(normalize_and_truncate_text "$TODO_STATUS")
        if [ -n "$TODO_TEXT" ]; then
            if [ -n "$MESSAGE" ]; then
                MESSAGE+=$'\n\n'
            fi
            MESSAGE+="$TODO_TEXT"
        fi
    fi

    if [ -z "$MESSAGE" ]; then
        MESSAGE="Claude is waiting for your input"
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
    # Fallback: no session_id available
    ESCAPED_TITLE=$(slack_escape_json "$TITLE")
    ESCAPED_MESSAGE=$(slack_escape_json "$MESSAGE")

    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -s -X POST "${SLACK_WEBHOOK_URL}" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"*$ESCAPED_TITLE*\\n$ESCAPED_MESSAGE\"}" \
            > /dev/null 2>&1
    fi
fi

exit 0
