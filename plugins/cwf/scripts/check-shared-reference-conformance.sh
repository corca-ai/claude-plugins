#!/usr/bin/env bash
set -euo pipefail

# check-shared-reference-conformance.sh — verify shared output-persistence reference usage.
#
# Ensures composing skills reference the shared contract in agent-patterns and
# keeps inline Output Persistence duplication under a bounded threshold.
#
# Usage:
#   check-shared-reference-conformance.sh [--strict]

usage() {
  cat <<'USAGE'
check-shared-reference-conformance.sh — shared reference conformance check

Usage:
  check-shared-reference-conformance.sh [--strict]

Options:
  --strict   Exit non-zero on conformance violations
  -h, --help Show this message
USAGE
}

STRICT="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REFERENCE_FILE="plugins/cwf/references/agent-patterns.md"
ANCHOR_TOKEN="sub-agent-output-persistence-contract"
DUPLICATION_THRESHOLD="${CWF_OUTPUT_PERSISTENCE_INLINE_MAX:-24}"
REFERENCE_HEADING="## Sub-agent Output Persistence Contract"
TARGET_SKILLS=(
  "plugins/cwf/skills/plan/SKILL.md"
  "plugins/cwf/skills/clarify/SKILL.md"
  "plugins/cwf/skills/retro/SKILL.md"
  "plugins/cwf/skills/refactor/SKILL.md"
  "plugins/cwf/skills/review/SKILL.md"
)

if [[ ! "$DUPLICATION_THRESHOLD" =~ ^[0-9]+$ ]]; then
  DUPLICATION_THRESHOLD=20
fi

FAIL_COUNT=0
report_fail() {
  local msg="$1"
  echo "[FAIL] $msg"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

report_pass() {
  local msg="$1"
  echo "[PASS] $msg"
}

echo "Shared reference conformance check"

if [[ ! -f "$REFERENCE_FILE" ]]; then
  report_fail "missing reference file: $REFERENCE_FILE"
else
  if grep -qF "$REFERENCE_HEADING" "$REFERENCE_FILE"; then
    report_pass "reference anchor exists in $REFERENCE_FILE"
  else
    report_fail "missing shared reference heading in $REFERENCE_FILE"
  fi
fi

for skill in "${TARGET_SKILLS[@]}"; do
  if [[ ! -f "$skill" ]]; then
    report_fail "missing skill file: $skill"
    continue
  fi

  if grep -qi "$ANCHOR_TOKEN" "$skill"; then
    report_pass "shared contract reference present: $skill"
  else
    report_fail "shared contract reference missing: $skill"
  fi
done

INLINE_COUNT="$(rg -n "Output Persistence" "${TARGET_SKILLS[@]}" | wc -l | tr -d ' ')"
echo "Inline Output Persistence markers: $INLINE_COUNT (threshold=$DUPLICATION_THRESHOLD)"
if [[ "$INLINE_COUNT" -gt "$DUPLICATION_THRESHOLD" ]]; then
  report_fail "inline Output Persistence markers exceed threshold"
else
  report_pass "inline Output Persistence markers are within threshold"
fi

if [[ "$FAIL_COUNT" -gt 0 && "$STRICT" == "true" ]]; then
  exit 1
fi

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 0
fi

echo "[PASS] shared-reference conformance aligned"
exit 0
