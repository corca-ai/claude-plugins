#!/bin/bash
# Blocks the built-in WebSearch tool and redirects to /gather-context --search.
# Activates automatically when the gather-context plugin is installed.

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Built-in WebSearch is disabled. Use /gather-context --search instead: Skill(skill: \"gather-context\", args: \"--search <query>\"). For code search: args: \"--search code <query>\"."}}
EOF
