#!/bin/bash
# Track user prompt submissions and create Slack thread parent
# Triggered by UserPromptSubmit hook (async)
#
# On first prompt in a session:
#   - Creates a Slack parent message with hostname, cwd, and prompt text
#   - Saves the message ts for threading subsequent notifications
# On every prompt:
#   - Records the timestamp of last user interaction (for heartbeat idle detection)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/slack-send.sh"

# Load config
slack_load_config

# Read hook input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

HASH=$(slack_session_hash "$SESSION_ID")

# Record user interaction timestamp (used by heartbeat.sh)
date +%s > "$(slack_state_file "$HASH" "last-user-ts")"

# Cancel any running timer (user responded via new prompt instead of PostToolUse)
TIMER_FILE=$(slack_state_file "$HASH" "timer.pid")
if [ -f "$TIMER_FILE" ]; then
    kill $(cat "$TIMER_FILE") 2>/dev/null
    rm -f "$TIMER_FILE"
    rm -f "$(slack_state_file "$HASH" "input.json")"
fi

# If no thread exists yet, create parent message with first prompt
# Use mkdir as atomic lock to prevent race between concurrent async instances
LOCK_DIR="/tmp/claude-attention-${HASH}-thread-lock"
if mkdir "$LOCK_DIR" 2>/dev/null; then
    trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

    THREAD_TS=$(slack_get_thread_ts "$HASH")
    if [ -z "$THREAD_TS" ]; then
        HOSTNAME_STR=$(hostname)
        CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
        [ -z "$CWD" ] && CWD="$PWD"

        # Truncate prompt for display (max 500 chars)
        DISPLAY_PROMPT="$PROMPT"
        if [ ${#DISPLAY_PROMPT} -gt 500 ]; then
            DISPLAY_PROMPT="${DISPLAY_PROMPT:0:500}..."
        fi

        MESSAGE=":large_green_circle: Claude Code @ ${HOSTNAME_STR} | ${CWD}"$'\n'":memo: ${DISPLAY_PROMPT}"

        slack_send "$HASH" "$MESSAGE" ""
    fi

    rmdir "$LOCK_DIR" 2>/dev/null
fi

exit 0
