#!/usr/bin/env bash
set -euo pipefail

# check-claim-test-mapping.sh
# Validate claim-to-test mapping contract.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACT_PATH="$PLUGIN_ROOT/contracts/claims.json"

usage() {
  cat <<'USAGE'
check-claim-test-mapping.sh — validate claim-to-test mapping

Usage:
  check-claim-test-mapping.sh [--contract <path>]

Options:
  --contract <path>  Claim mapping JSON path (default: plugins/cwf/contracts/claims.json)
  -h, --help         Show this help
USAGE
}

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

warn() {
  echo "CHECK_WARN: $*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract)
      CONTRACT_PATH="${2-}"
      [[ -n "$CONTRACT_PATH" ]] || fail "--contract requires a path"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

require_cmd jq

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ "$CONTRACT_PATH" != /* ]]; then
  if [[ -f "$REPO_ROOT/$CONTRACT_PATH" ]]; then
    CONTRACT_PATH="$REPO_ROOT/$CONTRACT_PATH"
  elif [[ -f "$PLUGIN_ROOT/$CONTRACT_PATH" ]]; then
    CONTRACT_PATH="$PLUGIN_ROOT/$CONTRACT_PATH"
  fi
fi

[[ -f "$CONTRACT_PATH" ]] || fail "contract file not found: $CONTRACT_PATH"

if ! jq -e '.version and (.claims | type == "array")' "$CONTRACT_PATH" >/dev/null; then
  fail "invalid contract schema: expected version + claims[]"
fi

claim_count="$(jq '.claims | length' "$CONTRACT_PATH")"
if [[ "$claim_count" -le 0 ]]; then
  fail "claims array must contain at least one claim"
fi

duplicate_ids="$(jq -r '.claims[].id // empty' "$CONTRACT_PATH" | sed '/^$/d' | sort | uniq -d)"
if [[ -n "$duplicate_ids" ]]; then
  fail "duplicate claim IDs detected: $(echo "$duplicate_ids" | tr '\n' ' ' | sed 's/[[:space:]]\+$//')"
fi

fail_count=0
warn_count=0

for ((i=0; i<claim_count; i++)); do
  claim_id="$(jq -r ".claims[$i].id // empty" "$CONTRACT_PATH")"
  audience="$(jq -r ".claims[$i].audience // empty" "$CONTRACT_PATH")"
  assertion="$(jq -r ".claims[$i].assertion // empty" "$CONTRACT_PATH")"

  if [[ -z "$claim_id" ]]; then
    echo "CHECK_FAIL: claims[$i] missing id" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  if [[ "$audience" != "user" && "$audience" != "agent" ]]; then
    echo "CHECK_FAIL: [$claim_id] audience must be user|agent" >&2
    fail_count=$((fail_count + 1))
  fi

  if [[ -z "$assertion" ]]; then
    echo "CHECK_FAIL: [$claim_id] assertion is empty" >&2
    fail_count=$((fail_count + 1))
  fi

  src_count="$(jq ".claims[$i].source_refs | if type==\"array\" then length else 0 end" "$CONTRACT_PATH")"
  if [[ "$src_count" -le 0 ]]; then
    echo "CHECK_FAIL: [$claim_id] source_refs must have at least one entry" >&2
    fail_count=$((fail_count + 1))
  else
    for ((s=0; s<src_count; s++)); do
      src_file="$(jq -r ".claims[$i].source_refs[$s].file // empty" "$CONTRACT_PATH")"
      src_selector="$(jq -r ".claims[$i].source_refs[$s].selector // empty" "$CONTRACT_PATH")"
      if [[ -z "$src_file" ]]; then
        echo "CHECK_FAIL: [$claim_id] source_refs[$s].file is empty" >&2
        fail_count=$((fail_count + 1))
        continue
      fi
      if [[ ! -f "$REPO_ROOT/$src_file" ]]; then
        echo "CHECK_FAIL: [$claim_id] source file not found: $src_file" >&2
        fail_count=$((fail_count + 1))
      fi
      if [[ -z "$src_selector" ]]; then
        echo "CHECK_WARN: [$claim_id] source selector missing for $src_file" >&2
        warn_count=$((warn_count + 1))
      fi
    done
  fi

  test_count="$(jq ".claims[$i].tests | if type==\"array\" then length else 0 end" "$CONTRACT_PATH")"
  if [[ "$test_count" -le 0 ]]; then
    echo "CHECK_FAIL: [$claim_id] tests must have at least one entry" >&2
    fail_count=$((fail_count + 1))
  else
    for ((t=0; t<test_count; t++)); do
      test_id="$(jq -r ".claims[$i].tests[$t].id // empty" "$CONTRACT_PATH")"
      test_path="$(jq -r ".claims[$i].tests[$t].path // empty" "$CONTRACT_PATH")"
      test_cmd="$(jq -r ".claims[$i].tests[$t].command // empty" "$CONTRACT_PATH")"

      if [[ -z "$test_id" || -z "$test_path" || -z "$test_cmd" ]]; then
        echo "CHECK_FAIL: [$claim_id] tests[$t] requires id/path/command" >&2
        fail_count=$((fail_count + 1))
        continue
      fi

      if [[ ! -f "$REPO_ROOT/$test_path" ]]; then
        echo "CHECK_FAIL: [$claim_id] test path not found: $test_path" >&2
        fail_count=$((fail_count + 1))
      fi

      if [[ "$test_cmd" != *"$test_path"* ]]; then
        warn "[$claim_id] test command does not include declared path: $test_id"
        warn_count=$((warn_count + 1))
      fi
    done
  fi
done

if [[ "$fail_count" -gt 0 ]]; then
  fail "claim-test mapping validation failed ($fail_count fail, $warn_count warn)"
fi

echo "CHECK_OK: claim-test mapping verified (claims=$claim_count, warnings=$warn_count)"
