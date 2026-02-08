#!/usr/bin/env bash
set -euo pipefail
# enter-plan-mode.sh — PreToolUse hook for EnterPlanMode
# Injects Plan & Lessons Protocol path into assistant context when EnterPlanMode is triggered.

HOOK_GROUP="plan_protocol"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROTOCOL_PATH="${PLUGIN_ROOT}/references/plan-protocol.md"

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"READ and FOLLOW the Plan & Lessons Protocol at: ${PROTOCOL_PATH}"}}
EOF
