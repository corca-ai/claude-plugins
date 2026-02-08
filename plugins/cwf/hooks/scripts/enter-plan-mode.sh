#!/usr/bin/env bash
set -euo pipefail
# enter-plan-mode.sh — PreToolUse hook for EnterPlanMode
# Injects Plan & Lessons Protocol into assistant context.
# Stub: real implementation in S6a migration.

HOOK_GROUP="plan_protocol"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
