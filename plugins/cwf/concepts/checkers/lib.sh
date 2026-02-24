#!/usr/bin/env bash
set -euo pipefail

# Shared helper for concept checker scripts.
# Exit codes:
#   0  pass
#   1  fail
#   2  usage error
#   10 warn-only (non-blocking)

concept_check() {
  if [[ $# -lt 4 ]]; then
    echo "[FAIL] concept_check usage: <id> <title> <doc> <required...>" >&2
    return 2
  fi

  local concept_id="$1"
  local title="$2"
  local doc_path="$3"
  shift 3
  local required_headers=("$@")
  local recommended_header="## Examples"

  local fail_count=0
  local warn_count=0

  echo "Concept checker: ${concept_id}"

  if [[ ! -f "$doc_path" ]]; then
    echo "[FAIL] missing concept document: $doc_path"
    return 1
  fi

  if grep -Fxq "# $title" "$doc_path"; then
    echo "[PASS] title header present: # $title"
  else
    echo "[FAIL] missing exact title header: # $title"
    fail_count=$((fail_count + 1))
  fi

  for header in "${required_headers[@]}"; do
    if grep -Fxq "$header" "$doc_path"; then
      echo "[PASS] required section present: $header"
    else
      echo "[FAIL] missing required section: $header"
      fail_count=$((fail_count + 1))
    fi
  done

  if grep -Fxq "$recommended_header" "$doc_path"; then
    echo "[PASS] recommended section present: $recommended_header"
  else
    echo "[WARN] recommended section missing: $recommended_header"
    warn_count=$((warn_count + 1))
  fi

  if [[ "$fail_count" -gt 0 ]]; then
    echo "[FAIL] concept check failed: id=$concept_id fail_count=$fail_count"
    return 1
  fi

  if [[ "$warn_count" -gt 0 ]]; then
    echo "[WARN] concept check completed with warnings: id=$concept_id warn_count=$warn_count"
    return 10
  fi

  echo "[PASS] concept check passed: id=$concept_id"
  return 0
}
