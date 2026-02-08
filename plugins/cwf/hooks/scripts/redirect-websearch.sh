#!/usr/bin/env bash
set -euo pipefail
# redirect-websearch.sh — PreToolUse hook for WebSearch
# Blocks built-in WebSearch and redirects to /gather-context --search.
# Stub: real implementation in S6a migration.

HOOK_GROUP="websearch_redirect"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
