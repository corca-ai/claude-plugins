#!/bin/bash
# Claude Code notification script (improved version)
# Sends notification only after 60 seconds of inactivity (idle_prompt)
# Includes task context: user request, Claude response, and todo status

# Usage: Add this file to ~/.claude/hooks, and add the following to your .claude/settings.json
# {
#   "hooks": {
#     "Notification": [
#       {
#         "matcher": "idle_prompt",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "~/.claude/hooks/attention.sh"
#           }
#         ]
#       }
#     ]
#   }
# }

# === CONFIGURATION ===
# Load webhook URLs from ~/.claude/.env if it exists
ENV_FILE="$HOME/.claude/.env"
if [ -f "$ENV_FILE" ]; then
    # Source the .env file (supports KEY="value" format)
    set -a
    source "$ENV_FILE"
    set +a
fi

# Use environment variables (can be set in ~/.claude/.env or shell environment)
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"

# === READ HOOK INPUT ===
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# === HELPER FUNCTIONS ===
# Truncate text to first 3 lines + ... + last 3 lines
truncate_text() {
    local text="$1"
    local line_count=$(echo "$text" | wc -l)

    if [ "$line_count" -le 6 ]; then
        echo "$text"
    else
        local first=$(echo "$text" | head -n 3)
        local last=$(echo "$text" | tail -n 3)
        echo "$first"
        echo "..."
        echo "$last"
    fi
}

# Extract text content from message (handles both string and array content)
extract_content() {
    local json="$1"
    local msg_type="$2"

    # Human messages have content directly, assistant messages have .message.content
    if [ "$msg_type" = "human" ]; then
        echo "$json" | jq -r '
            if .message.content | type == "string" then
                .message.content
            elif .message.content | type == "array" then
                [.message.content[] | select(type == "string" or .type == "text") | if type == "string" then . else .text end] | join("\n")
            else
                ""
            end
        '
    else
        echo "$json" | jq -r '
            if .message.content | type == "string" then
                .message.content
            elif .message.content | type == "array" then
                [.message.content[] | select(.type == "text") | .text] | join("\n")
            else
                ""
            end
        '
    fi
}

# Parse todo status from transcript
parse_todos() {
    local transcript="$1"

    # Find the last TodoWrite tool result
    local todo_json=$(jq -s '
        [.[] | select(.type == "assistant") |
         .message.content[]? |
         select(.type == "tool_use" and .name == "TodoWrite") |
         .input.todos] |
        last // []
    ' "$transcript" 2>/dev/null)

    if [ -z "$todo_json" ] || [ "$todo_json" = "null" ] || [ "$todo_json" = "[]" ]; then
        echo ""
        return
    fi

    local completed=$(echo "$todo_json" | jq '[.[] | select(.status == "completed")] | length')
    local in_progress=$(echo "$todo_json" | jq '[.[] | select(.status == "in_progress")] | length')
    local pending=$(echo "$todo_json" | jq '[.[] | select(.status == "pending")] | length')
    local total=$((completed + in_progress + pending))

    if [ "$total" -gt 0 ]; then
        echo ":white_check_mark: Todo: $completed/$total done"
        if [ "$in_progress" -gt 0 ]; then
            echo "  (in progress: $in_progress, pending: $pending)"
        fi
    fi
}

# === BUILD NOTIFICATION ===
HOSTNAME=$(hostname)
TITLE="Claude Code @ $HOSTNAME"

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Get last user message with string content (real human input, not tool results)
    LAST_HUMAN_TEXT=$(jq -rs '[.[] | select(.type == "user" and (.message.content | type == "string"))] | last | .message.content // ""' "$TRANSCRIPT_PATH" 2>/dev/null)

    # Get last assistant message with text content
    LAST_ASSISTANT_TEXT=$(jq -rs '[.[] | select(.type == "assistant")] | last | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] | join("\n") else . // "" end' "$TRANSCRIPT_PATH" 2>/dev/null)

    # Get todo status
    TODO_STATUS=$(parse_todos "$TRANSCRIPT_PATH")

    # Build message
    MESSAGE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"$'\n'

    if [ -n "$LAST_HUMAN_TEXT" ]; then
        TRUNCATED_REQUEST=$(truncate_text "$LAST_HUMAN_TEXT")
        MESSAGE+=$'\n'":memo: Request:"$'\n'"$TRUNCATED_REQUEST"$'\n'
    fi

    if [ -n "$LAST_ASSISTANT_TEXT" ]; then
        TRUNCATED_RESPONSE=$(truncate_text "$LAST_ASSISTANT_TEXT")
        MESSAGE+=$'\n'":robot_face: Response:"$'\n'"$TRUNCATED_RESPONSE"$'\n'
    fi

    if [ -n "$TODO_STATUS" ]; then
        MESSAGE+=$'\n'"$TODO_STATUS"
    fi
else
    MESSAGE="Claude is waiting for your input"
fi

# === SEND NOTIFICATIONS ===
# Escape special characters for JSON
escape_json() {
    local text="$1"
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    text="${text//$'\t'/\\t}"
    echo "$text"
}

ESCAPED_TITLE=$(escape_json "$TITLE")
ESCAPED_MESSAGE=$(escape_json "$MESSAGE")

# Send to Slack
if [ -n "$SLACK_WEBHOOK" ]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"*$ESCAPED_TITLE*\\n$ESCAPED_MESSAGE\"}" \
        > /dev/null 2>&1
fi

# Send to Discord
if [ -n "$DISCORD_WEBHOOK" ]; then
    curl -s -X POST "$DISCORD_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"**$ESCAPED_TITLE**\\n$ESCAPED_MESSAGE\"}" \
        > /dev/null 2>&1
fi

exit 0
