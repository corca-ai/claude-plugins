#!/usr/bin/env bash
set -euo pipefail
# track-user-input.sh — UserPromptSubmit hook (async)
# Track user prompt submissions and create Slack thread parent.
#
# On first prompt in a session:
#   - Creates a Slack parent message with hostname, cwd, and prompt text
#   - Saves the message ts for threading subsequent notifications
# On every prompt:
#   - Records the timestamp of last user interaction (for heartbeat idle detection)

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=slack-send.sh
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
    kill "$(cat "$TIMER_FILE")" 2>/dev/null || true
    rm -f "$TIMER_FILE"
    rm -f "$(slack_state_file "$HASH" "input.json")"
fi

# If no thread exists yet, create parent message with first prompt
# Use mkdir as atomic lock to prevent race between concurrent async instances
LOCK_DIR="/tmp/claude-attention-${HASH}-thread-lock"
# Clean stale lock (older than 1 minute)
if [ -d "$LOCK_DIR" ]; then
    if [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
fi
if mkdir "$LOCK_DIR" 2>/dev/null; then
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT INT TERM

    THREAD_TS=$(slack_get_thread_ts "$HASH")
    if [ -z "$THREAD_TS" ]; then
        HOSTNAME_STR=$(hostname)
        CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
        if [ -z "$CWD" ]; then CWD="$PWD"; fi

        # Truncate prompt for display (max 500 chars)
        DISPLAY_PROMPT="$PROMPT"
        if [ ${#DISPLAY_PROMPT} -gt 500 ]; then
            DISPLAY_PROMPT="${DISPLAY_PROMPT:0:500}..."
        fi

        PARENT_MENTION=$(slack_attention_parent_mention)
        HEADER=":large_green_circle: Claude Code @ ${HOSTNAME_STR} | ${CWD}"
        if [ -n "$PARENT_MENTION" ]; then
            HEADER="${PARENT_MENTION} ${HEADER}"
        fi

        MESSAGE="${HEADER}"$'\n'":memo: ${DISPLAY_PROMPT}"

        slack_send "$HASH" "$MESSAGE" ""
    fi

fi

exit 0
