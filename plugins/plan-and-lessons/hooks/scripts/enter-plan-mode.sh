#!/usr/bin/env bash
set -euo pipefail
# Injects Plan & Lessons Protocol path into assistant context when EnterPlanMode is triggered.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROTOCOL_PATH="${PLUGIN_ROOT}/protocol.md"

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"READ and FOLLOW the Plan & Lessons Protocol at: ${PROTOCOL_PATH}"}}
EOF
