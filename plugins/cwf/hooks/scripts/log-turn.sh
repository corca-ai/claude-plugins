#!/usr/bin/env bash
set -euo pipefail
# log-turn.sh — Stop/SessionEnd hook (async)
# Logs conversation turns to markdown session files.
# Stub: real implementation in S6a migration.

HOOK_GROUP="log"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
