#!/usr/bin/env bash
set -euo pipefail
# exit-plan-mode.sh — PreToolUse hook for ExitPlanMode
# Validates that the plan file contains a Deferred Actions section,
# then checks for unchecked items. Always emits observable output.
#
# Three outcomes (never silent):
#   1. DENY  — Deferred Actions section missing → block ExitPlanMode
#   2. WARN  — unchecked items found → allow with mandatory action list
#   3. PASS  — section present, all items checked → allow with confirmation
#
# Solves the recurring pattern where "Deferred Actions" in plan.md
# are ignored when transitioning from plan mode to implementation.
# See: S12 lessons, S13.5-A lessons, S13.5-B3 lessons.

HOOK_GROUP="plan_protocol"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

# Find the active plan file in ~/.claude/plans/
PLANS_DIR="$HOME/.claude/plans"
if [ ! -d "$PLANS_DIR" ]; then
    # No plans directory — unusual but not blockable
    cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"exit-plan-mode hook: No ~/.claude/plans/ directory found. Ensure your plan includes a Deferred Actions section."}}
EOF
    exit 0
fi

# Most recently modified .md file is the active plan
PLAN_FILE=$(find "$PLANS_DIR" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null | head -1)
if [ -z "${PLAN_FILE:-}" ] || [ ! -f "$PLAN_FILE" ]; then
    cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"exit-plan-mode hook: No plan file found in ~/.claude/plans/. Ensure your plan includes a Deferred Actions section."}}
EOF
    exit 0
fi

# Scan the plan file for Deferred Actions section and unchecked items
SECTION_FOUND=false
DEFERRED=""
CHECKED_COUNT=0
IN_SECTION=false

while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+(Deferred[[:space:]]Actions|Post-Approval[[:space:]]Actions) ]]; then
        SECTION_FOUND=true
        IN_SECTION=true
        continue
    fi
    if $IN_SECTION; then
        # Next section header ends the deferred section
        if [[ "$line" =~ ^## ]]; then
            break
        fi
        # Collect unchecked items (- [ ] ...)
        if [[ "$line" =~ ^-[[:space:]]\[[[:space:]]\] ]]; then
            if [ -n "$DEFERRED" ]; then
                DEFERRED="${DEFERRED}"$'\n'"${line}"
            else
                DEFERRED="${line}"
            fi
        fi
        # Count checked items (- [x] ...)
        if [[ "$line" =~ ^-[[:space:]]\[[xX]\] ]]; then
            CHECKED_COUNT=$((CHECKED_COUNT + 1))
        fi
    fi
done < "$PLAN_FILE"

# --- Outcome 1: Section missing → DENY ---
if [ "$SECTION_FOUND" = false ]; then
    REASON="Plan file is missing a '## Deferred Actions' section. The Plan & Lessons Protocol requires this section. Add it to your plan (even if empty: '- [x] None') before exiting plan mode. Plan file: ${PLAN_FILE}"
    jq -n --arg reason "$REASON" \
        '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$reason}}'
    exit 0
fi

# --- Outcome 2: Unchecked items found → ALLOW with mandatory context ---
if [ -n "$DEFERRED" ]; then
    UNCHECKED_COUNT=$(echo "$DEFERRED" | wc -l | tr -d ' ')
    CONTEXT="exit-plan-mode hook: ${UNCHECKED_COUNT} unchecked deferred action(s) found. Execute these BEFORE starting implementation:

${DEFERRED}

Handle these items NOW, before any implementation work."
    jq -n --arg ctx "$CONTEXT" \
        '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":$ctx}}'
    exit 0
fi

# --- Outcome 3: Section present, all checked → ALLOW with confirmation ---
CONTEXT="exit-plan-mode hook: Deferred Actions validated — ${CHECKED_COUNT} item(s), all checked."
jq -n --arg ctx "$CONTEXT" \
    '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":$ctx}}'
