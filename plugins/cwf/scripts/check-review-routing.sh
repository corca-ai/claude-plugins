#!/usr/bin/env bash
set -euo pipefail

# check-review-routing.sh — deterministic validation for review external routing cutoff.
#
# Validates that review/SKILL.md contains the >1200 prompt-line cutoff contract,
# and prints expected routing outcomes for provided line counts.
#
# Usage:
#   check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 [--strict]

usage() {
  cat <<'USAGE'
check-review-routing.sh — deterministic validation for review routing cutoff

Usage:
  check-review-routing.sh [--line-count <n> ...] [--strict]

Options:
  --line-count <n>  Prompt line count sample to evaluate (repeatable)
  --strict          Exit non-zero when required contract markers are missing
  -h, --help        Show this message
USAGE
}

STRICT="false"
LINE_COUNTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --line-count)
      if [[ $# -lt 2 ]]; then
        echo "--line-count requires a value" >&2
        exit 2
      fi
      LINE_COUNTS+=("$2")
      shift 2
      ;;
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

if [[ ${#LINE_COUNTS[@]} -eq 0 ]]; then
  LINE_COUNTS=(1199 1200 1201)
fi

REVIEW_SKILL="plugins/cwf/skills/review/SKILL.md"
if [[ ! -f "$REVIEW_SKILL" ]]; then
  echo "[FAIL] missing file: $REVIEW_SKILL" >&2
  exit 1
fi

FAIL_COUNT=0
report_fail() {
  local msg="$1"
  echo "[FAIL] $msg"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "Review routing cutoff check"

awk_check() {
  local pattern="$1"
  local label="$2"
  if grep -q "$pattern" "$REVIEW_SKILL"; then
    echo "[PASS] $label"
  else
    report_fail "$label"
  fi
}

awk_check 'prompt_lines > 1200' 'cutoff comparison exists: prompt_lines > 1200'
awk_check 'external_cli_allowed=false' 'routing state exists: external_cli_allowed=false'
awk_check 'prompt_lines_gt_1200' 'cutoff reason token exists: prompt_lines_gt_1200'

for raw in "${LINE_COUNTS[@]}"; do
  if [[ ! "$raw" =~ ^[0-9]+$ ]]; then
    report_fail "invalid --line-count value: $raw"
    continue
  fi

  if [[ "$raw" -gt 1200 ]]; then
    echo "[PASS] line_count=$raw -> expected_route=task_fallback_only reason=prompt_lines_gt_1200"
  else
    echo "[PASS] line_count=$raw -> expected_route=external_cli_allowed"
  fi
done

if [[ "$FAIL_COUNT" -gt 0 && "$STRICT" == "true" ]]; then
  exit 1
fi

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 0
fi

echo "[PASS] review routing contract is aligned"
exit 0
