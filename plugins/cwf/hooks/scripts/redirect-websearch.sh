#!/usr/bin/env bash
set -euo pipefail
# redirect-websearch.sh — PreToolUse hook for WebSearch
# Blocks built-in WebSearch and redirects to cwf:gather --search.

HOOK_GROUP="websearch_redirect"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Built-in WebSearch is disabled. Use cwf:gather --search instead: Skill(skill: \"cwf:gather\", args: \"--search <query>\"). For code search: args: \"--search code <query>\"."}}
EOF
