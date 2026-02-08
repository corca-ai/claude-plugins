#!/usr/bin/env bash
set -euo pipefail
# smart-read.sh — PreToolUse hook for Read
# Checks file size before allowing full reads to prevent context waste.
# Stub: real implementation in S6a migration.

HOOK_GROUP="read"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
