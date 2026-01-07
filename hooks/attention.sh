#!/bin/bash
# Claude Code notification script
# Sends push notification when Claude needs your attention

# Usage: Add this file to ~/.claude/hooks, and add the following to your .claude/settings.json
# {
#   "hooks": {
#     "PreToolUse": [
#       {
#         "matcher": "AskUserQuestion",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "~/.claude/hooks/attention.sh question"
#           }
#         ]
#       }
#     ],
#     "Stop": [
#       {
#         "matcher": "",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "~/.claude/hooks/attention.sh done"
#           }
#         ]
#       }
#     ]
#   }
# }

EVENT_TYPE="${1:-notification}"

# === CONFIGURATION ===
# Option 1: Slack webhook
SLACK_WEBHOOK=""

# Option 2: Discord webhook
DISCORD_WEBHOOK=""

# === NOTIFICATION LOGIC ===
HOSTNAME=$(hostname)
TITLE="Claude Code @ $HOSTNAME"

case "$EVENT_TYPE" in
    question)
        MESSAGE="Claude has a question for you"
        ;;
    done)
        MESSAGE="Claude has finished the task"
        ;;
    *)
        MESSAGE="Claude needs your attention"
        ;;
esac

# Send to Slack
if [ -n "$SLACK_WEBHOOK" ]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"*$TITLE*\n$MESSAGE\"}" \
        > /dev/null 2>&1
fi

# Send to Discord
if [ -n "$DISCORD_WEBHOOK" ]; then
    curl -s -X POST "$DISCORD_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"**$TITLE**\n$MESSAGE\"}" \
        > /dev/null 2>&1
fi

exit 0