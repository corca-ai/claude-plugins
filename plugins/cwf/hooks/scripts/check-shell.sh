#!/usr/bin/env bash
set -euo pipefail
# check-shell.sh — PostToolUse hook for Write|Edit
# Validates shell scripts using shellcheck after write/edit operations.
# NEW hook (not migrated — fresh implementation in S6b).

HOOK_GROUP="lint_shell"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
