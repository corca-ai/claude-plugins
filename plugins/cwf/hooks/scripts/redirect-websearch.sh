#!/usr/bin/env bash
set -euo pipefail
# redirect-websearch.sh — PreToolUse hook for WebSearch
# Blocks built-in WebSearch and redirects to cwf:gather --search.

# shellcheck disable=SC2034
HOOK_GROUP="websearch_redirect"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

reason='Built-in WebSearch is disabled. Use cwf:gather --search instead: '
reason+='Skill(skill: "cwf:gather", args: "--search <query>"). '
reason+='For code search: args: "--search code <query>".'

jq -nc \
  --arg reason "$reason" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
