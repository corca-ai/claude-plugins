#!/usr/bin/env bash
set -euo pipefail
# heartbeat.sh — PreToolUse catch-all hook (async)
# Sends periodic heartbeat status updates.
# Stub: real implementation in S6b migration.

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
