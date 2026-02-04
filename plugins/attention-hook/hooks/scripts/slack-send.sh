#!/bin/bash
# Shared Slack API utility for attention-hook
# Supports: Web API (chat.postMessage with threading) and Webhook (fallback, no threading)
#
# Usage: source this file in other scripts
#   source "$SCRIPT_DIR/slack-send.sh"
#   slack_load_config
#   HASH=$(slack_session_hash "$SESSION_ID")
#   slack_send "$HASH" "Hello" ""       # parent message
#   slack_send "$HASH" "Reply" "true"   # thread reply
#
# Diagnose: run directly to check Slack configuration
#   ./slack-send.sh --diagnose

# Load config from ~/.claude/.env
slack_load_config() {
    local env_file="$HOME/.claude/.env"
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
    fi
}

# Generate session-scoped hash (first 12 chars of SHA-256)
slack_session_hash() {
    local session_id="$1"
    echo -n "$session_id" | shasum -a 256 | cut -c1-12
}

# Get state file path for a session
slack_state_file() {
    local hash="$1"
    local name="$2"
    echo "/tmp/claude-attention-${hash}-${name}"
}

# Read thread_ts for a session
slack_get_thread_ts() {
    local hash="$1"
    local file
    file=$(slack_state_file "$hash" "thread-ts")
    if [ -f "$file" ]; then
        cat "$file"
    fi
}

# Save thread_ts for a session
slack_save_thread_ts() {
    local hash="$1"
    local ts="$2"
    echo "$ts" > "$(slack_state_file "$hash" "thread-ts")"
}

# Escape special characters for JSON string
slack_escape_json() {
    local text="$1"
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    text="${text//$'\t'/\\t}"
    echo "$text"
}

# Send message to Slack
# Usage: slack_send <hash> <text> [is_thread_reply]
#   hash:            session hash for state file lookup
#   text:            message text (plain or mrkdwn)
#   is_thread_reply: if non-empty, send as thread reply using saved thread_ts
#
# Prefers Web API (SLACK_BOT_TOKEN + SLACK_CHANNEL_ID) for threading support.
# Falls back to Webhook (SLACK_WEBHOOK_URL) with no threading.
slack_send() {
    local hash="$1"
    local text="$2"
    local is_reply="${3:-}"

    local escaped_text
    escaped_text=$(slack_escape_json "$text")

    # Prefer Web API if bot token and channel are configured
    if [ -n "${SLACK_BOT_TOKEN:-}" ] && [ -n "${SLACK_CHANNEL_ID:-}" ]; then
        local thread_ts=""
        if [ -n "$is_reply" ]; then
            thread_ts=$(slack_get_thread_ts "$hash")
        fi

        local payload="{\"channel\": \"${SLACK_CHANNEL_ID}\", \"text\": \"${escaped_text}\""
        if [ -n "$thread_ts" ]; then
            payload+=", \"thread_ts\": \"${thread_ts}\", \"reply_broadcast\": true"
        fi
        payload+="}"

        local response
        response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
            -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$payload" 2>/dev/null)

        # Save ts from parent messages for future threading
        if [ -z "$is_reply" ] && [ -n "$response" ]; then
            local ts ok
            ok=$(echo "$response" | jq -r '.ok // empty' 2>/dev/null)
            ts=$(echo "$response" | jq -r '.ts // empty' 2>/dev/null)
            if [ -n "$ts" ]; then
                slack_save_thread_ts "$hash" "$ts"
            fi
            # Debug log for thread-ts save
            local debug_log="/tmp/claude-attention-${hash}-debug.log"
            echo "$(date): slack_send parent: ok=$ok ts=$ts saved=$([ -n "$ts" ] && echo "yes" || echo "no")" >> "$debug_log"
        fi

        return 0
    fi

    # Fallback: Webhook (no threading support)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -s -X POST "${SLACK_WEBHOOK_URL}" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"${escaped_text}\"}" \
            > /dev/null 2>&1
        return 0
    fi

    return 1
}

# Diagnose Slack configuration
# Run: ./slack-send.sh --diagnose
slack_diagnose() {
    local pass="✓"
    local fail="✗"
    local has_error=0

    echo "=== attention-hook Slack diagnostics ==="
    echo ""

    # 1. Check env file
    local env_file="$HOME/.claude/.env"
    if [ -f "$env_file" ]; then
        echo "$pass ~/.claude/.env found"
    else
        echo "$fail ~/.claude/.env not found"
        echo "  Create it with SLACK_BOT_TOKEN and SLACK_CHANNEL_ID"
        return 1
    fi

    # 2. Load config
    slack_load_config

    # 3. Check variables
    echo ""
    echo "--- Configuration ---"
    if [ -n "${SLACK_BOT_TOKEN:-}" ]; then
        echo "$pass SLACK_BOT_TOKEN: set (${#SLACK_BOT_TOKEN} chars)"
    else
        echo "$fail SLACK_BOT_TOKEN: not set"
        has_error=1
    fi

    if [ -n "${SLACK_CHANNEL_ID:-}" ]; then
        echo "$pass SLACK_CHANNEL_ID: $SLACK_CHANNEL_ID"
    else
        echo "$fail SLACK_CHANNEL_ID: not set"
        has_error=1
    fi

    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        echo "  SLACK_WEBHOOK_URL: set (fallback)"
    fi

    [ "$has_error" -eq 1 ] && return 1

    # 4. Check token validity
    echo ""
    echo "--- Token check (auth.test) ---"
    local auth_response
    auth_response=$(curl -s "https://slack.com/api/auth.test" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" 2>/dev/null)

    local auth_ok
    auth_ok=$(echo "$auth_response" | jq -r '.ok' 2>/dev/null)

    if [ "$auth_ok" = "true" ]; then
        local team user
        team=$(echo "$auth_response" | jq -r '.team' 2>/dev/null)
        user=$(echo "$auth_response" | jq -r '.user' 2>/dev/null)
        echo "$pass Token valid — team: $team, bot: $user"
    else
        local auth_err
        auth_err=$(echo "$auth_response" | jq -r '.error' 2>/dev/null)
        echo "$fail Token invalid — error: $auth_err"
        return 1
    fi

    # 5. Check channel access
    echo ""
    echo "--- Channel check ---"
    local ch_response
    ch_response=$(curl -s "https://slack.com/api/conversations.info?channel=${SLACK_CHANNEL_ID}" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" 2>/dev/null)

    local ch_ok
    ch_ok=$(echo "$ch_response" | jq -r '.ok' 2>/dev/null)

    if [ "$ch_ok" = "true" ]; then
        echo "$pass Channel accessible"
    else
        local ch_err
        ch_err=$(echo "$ch_response" | jq -r '.error' 2>/dev/null)
        if [ "$ch_err" = "channel_not_found" ]; then
            echo "$fail Channel not found — check SLACK_CHANNEL_ID"
            echo "  For DM: open a DM with the bot in Slack, click bot name, copy Channel ID (starts with D)"
            echo "  For channels: ensure bot is invited with /invite @BotName"
            echo "  Note: do NOT use your self-DM channel ID"
        elif [ "$ch_err" = "missing_scope" ]; then
            local needed
            needed=$(echo "$ch_response" | jq -r '.needed' 2>/dev/null)
            echo "$fail Missing scope: $needed (needed for channel info check, but may not block sending)"
        else
            echo "$fail Channel error: $ch_err"
        fi
    fi

    # 6. Test message
    echo ""
    echo "--- Send test message ---"
    local test_response
    test_response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"channel\": \"${SLACK_CHANNEL_ID}\", \"text\": \":wrench: attention-hook diagnose: test message\"}" 2>/dev/null)

    local test_ok
    test_ok=$(echo "$test_response" | jq -r '.ok' 2>/dev/null)

    if [ "$test_ok" = "true" ]; then
        echo "$pass Test message sent — check Slack!"
    else
        local test_err
        test_err=$(echo "$test_response" | jq -r '.error' 2>/dev/null)
        echo "$fail Send failed — error: $test_err"
        if [ "$test_err" = "channel_not_found" ]; then
            echo "  Bot token is valid but cannot access this channel."
            echo "  If using DM: add im:write scope and use bot's DM channel ID"
        elif [ "$test_err" = "not_in_channel" ]; then
            echo "  Bot is not in this channel. Run: /invite @BotName"
        fi
        return 1
    fi

    echo ""
    echo "=== All checks passed ==="
    return 0
}

# Run diagnose when executed directly with --diagnose
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ "${1:-}" == "--diagnose" ]]; then
    slack_diagnose
fi
