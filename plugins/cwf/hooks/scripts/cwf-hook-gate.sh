# cwf-hook-gate.sh — shared gate for all cwf hook scripts
# SOURCED (not executed) by hook scripts. Do NOT add set -euo pipefail.
#
# Usage in hook scripts:
#   HOOK_GROUP="attention"   # set before sourcing
#   source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"
#
# Gate logic:
#   1. Source ~/.claude/cwf-hooks-enabled.sh if it exists
#   2. Check HOOK_{GROUP}_ENABLED flag (uppercased)
#   3. Exit calling script with 0 if explicitly disabled (value = "false")
#   4. Default: enabled (hooks work without cwf:setup)

_CWF_HOOKS_CONFIG="$HOME/.claude/cwf-hooks-enabled.sh"

if [ -f "$_CWF_HOOKS_CONFIG" ]; then
    # shellcheck source=/dev/null
    . "$_CWF_HOOKS_CONFIG"
fi

# Build the env var name: HOOK_{GROUP}_ENABLED (uppercased)
# Bash 3.2 compatible — no nameref ${!var}, use printenv instead
_CWF_FLAG_NAME="HOOK_$(echo "$HOOK_GROUP" | tr '[:lower:]' '[:upper:]')_ENABLED"
_CWF_FLAG_VALUE=$(printenv "$_CWF_FLAG_NAME" 2>/dev/null || true)

if [ "$_CWF_FLAG_VALUE" = "false" ]; then
    exit 0
fi

# Clean up temporary variables
unset _CWF_HOOKS_CONFIG _CWF_FLAG_NAME _CWF_FLAG_VALUE
