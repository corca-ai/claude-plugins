#!/usr/bin/env bash
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

# shellcheck source=env-loader.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-loader.sh"

# Load config from process env / shell profiles
slack_load_config() {
    cwf_env_load_vars \
        SLACK_BOT_TOKEN \
        SLACK_CHANNEL_ID \
        SLACK_WEBHOOK_URL \
        CWF_ATTENTION_USER_ID \
        CWF_ATTENTION_USER_HANDLE \
        CWF_ATTENTION_PARENT_MENTION \
        CWF_ATTENTION_REPLY_BROADCAST \
        CWF_ATTENTION_DELAY \
        CWF_ATTENTION_TRUNCATE \
        CWF_ATTENTION_HEARTBEAT_USER_IDLE \
        CWF_ATTENTION_HEARTBEAT_INTERVAL
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

slack_normalize_bool() {
    local value="${1:-false}"
    local normalized
    normalized=$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')
    case "$normalized" in
        true|1|yes|on) echo "true" ;;
        false|0|no|off) echo "false" ;;
        *) echo "false" ;;
    esac
}

# Build mention text for parent notifications.
# Priority:
#   1) CWF_ATTENTION_PARENT_MENTION (raw, e.g. "<@U123...>" or "@name")
#   2) CWF_ATTENTION_USER_ID (auto-wrapped as "<@...>")
#   3) CWF_ATTENTION_USER_HANDLE (auto-prefixed as "@...")
slack_attention_parent_mention() {
    if [ -n "${CWF_ATTENTION_PARENT_MENTION:-}" ]; then
        echo "${CWF_ATTENTION_PARENT_MENTION}"
        return
    fi

    if [ -n "${CWF_ATTENTION_USER_ID:-}" ]; then
        echo "<@${CWF_ATTENTION_USER_ID}>"
        return
    fi

    if [ -n "${CWF_ATTENTION_USER_HANDLE:-}" ]; then
        if [[ "${CWF_ATTENTION_USER_HANDLE}" == @* ]]; then
            echo "${CWF_ATTENTION_USER_HANDLE}"
        else
            echo "@${CWF_ATTENTION_USER_HANDLE}"
        fi
        return
    fi

    echo ""
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
            local broadcast
            broadcast=$(slack_normalize_bool "${CWF_ATTENTION_REPLY_BROADCAST:-false}")
            payload+=", \"thread_ts\": \"${thread_ts}\", \"reply_broadcast\": ${broadcast}"
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

    # 1. Load config
    slack_load_config

    # 2. Check variables
    echo ""
    echo "--- Configuration ---"
    if [ -n "${SLACK_BOT_TOKEN:-}" ]; then
        echo "$pass SLACK_BOT_TOKEN: set (${#SLACK_BOT_TOKEN} chars)"
    else
        echo "$fail SLACK_BOT_TOKEN: not set"
        echo "  Set it in ~/.zshrc or ~/.bashrc"
        has_error=1
    fi

    if [ -n "${SLACK_CHANNEL_ID:-}" ]; then
        echo "$pass SLACK_CHANNEL_ID: $SLACK_CHANNEL_ID"
    else
        echo "$fail SLACK_CHANNEL_ID: not set"
        echo "  Set it in ~/.zshrc or ~/.bashrc"
        has_error=1
    fi

    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        echo "  SLACK_WEBHOOK_URL: set (fallback)"
    fi

    [ "$has_error" -eq 1 ] && return 1

    # 3. Check token validity
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

    # 4. Check channel access
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
