#!/bin/bash
# Blocks the built-in WebSearch tool and redirects to /web-search skill.
# Activates automatically when the web-search plugin is installed.

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Built-in WebSearch is disabled. Use the /web-search skill instead: Skill(skill: \"web-search\", args: \"<query>\"). For code search: args: \"code <query>\". For URL extraction: args: \"extract <url>\"."}}
EOF
