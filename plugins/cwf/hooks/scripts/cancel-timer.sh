#!/usr/bin/env bash
set -euo pipefail
# cancel-timer.sh — PostToolUse hook for AskUserQuestion/EnterPlanMode/ExitPlanMode
# Cancels attention timer when user responds.
# Stub: real implementation in S6b migration.

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
