#!/usr/bin/env bash
set -euo pipefail
# heartbeat.sh — PreToolUse catch-all hook (async)
# Periodic heartbeat status checker.
# Triggered by PreToolUse:* (async) - runs on every tool call, exits fast if no heartbeat needed.
#
# Fast path (< 10ms): check timestamps, exit if no heartbeat warranted
# Slow path (rare): parse transcript for todo status, send threaded status update

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input (minimal parsing for fast path)
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# Source shared utilities
# shellcheck source=slack-send.sh
source "$SCRIPT_DIR/slack-send.sh"
# shellcheck source=text-format.sh
source "$SCRIPT_DIR/text-format.sh"
slack_load_config
ATTENTION_TRUNCATE_LINES="${CLAUDE_CORCA_ATTENTION_TRUNCATE:-10}"
if ! [[ "$ATTENTION_TRUNCATE_LINES" =~ ^[0-9]+$ ]] || [ "$ATTENTION_TRUNCATE_LINES" -le 0 ]; then
    ATTENTION_TRUNCATE_LINES=10
fi

HASH=$(slack_session_hash "$SESSION_ID")

# --- FAST PATH: Quick checks before expensive operations ---

# Check 1: Is there a thread to reply to?
THREAD_TS=$(slack_get_thread_ts "$HASH")
if [ -z "$THREAD_TS" ]; then
    exit 0
fi

# Check 2: Has user been idle long enough?
IDLE_THRESHOLD="${CLAUDE_CORCA_ATTENTION_HEARTBEAT_USER_IDLE:-${CLAUDE_ATTENTION_HEARTBEAT_USER_IDLE:-300}}"
LAST_USER_FILE=$(slack_state_file "$HASH" "last-user-ts")
if [ ! -f "$LAST_USER_FILE" ]; then
    exit 0
fi

LAST_USER_TS=$(cat "$LAST_USER_FILE")
NOW=$(date +%s)
IDLE_SECONDS=$((NOW - LAST_USER_TS))
if [ "$IDLE_SECONDS" -lt "$IDLE_THRESHOLD" ]; then
    exit 0
fi

# Check 3: Has enough time passed since last heartbeat?
HEARTBEAT_INTERVAL="${CLAUDE_CORCA_ATTENTION_HEARTBEAT_INTERVAL:-${CLAUDE_ATTENTION_HEARTBEAT_INTERVAL:-300}}"
HEARTBEAT_FILE=$(slack_state_file "$HASH" "heartbeat-ts")
if [ -f "$HEARTBEAT_FILE" ]; then
    LAST_HEARTBEAT=$(cat "$HEARTBEAT_FILE")
    HEARTBEAT_AGE=$((NOW - LAST_HEARTBEAT))
    if [ "$HEARTBEAT_AGE" -lt "$HEARTBEAT_INTERVAL" ]; then
        exit 0
    fi
fi

# --- SLOW PATH: Send heartbeat ---

# Write heartbeat timestamp immediately (prevent duplicate sends from concurrent tool calls)
echo "$NOW" > "$HEARTBEAT_FILE"

# Parse transcript for todo status
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
TODO_STATUS=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    PARSE_SCRIPT="$SCRIPT_DIR/parse-transcript.sh"
    if [ -x "$PARSE_SCRIPT" ]; then
        eval "$("$PARSE_SCRIPT" "$TRANSCRIPT_PATH")" || true
        TODO_STATUS="${PARSED_TODO_STATUS:-}"
    fi
fi

# Build heartbeat message
IDLE_MIN=$((IDLE_SECONDS / 60))
MESSAGE=":heartbeat: Status (${IDLE_MIN}m idle)"
if [ -n "$TODO_STATUS" ]; then
    TODO_TEXT=$(normalize_and_truncate_text "$TODO_STATUS" "$ATTENTION_TRUNCATE_LINES")
    if [ -n "$TODO_TEXT" ]; then
        MESSAGE+=$'\n'"$TODO_TEXT"
    fi
fi

slack_send "$HASH" "$MESSAGE" "true"

exit 0
