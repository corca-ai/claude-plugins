#!/usr/bin/env bash
set -euo pipefail

# check-portability-contract.sh
# Unified gate runner for portable/authoring contract profiles.

CONTRACT_SELECTOR="auto"
CONTEXT="manual"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACT_JSON_TMP=""

usage() {
  cat <<'USAGE'
check-portability-contract.sh — run contract-driven gate checks

Usage:
  check-portability-contract.sh [options]

Options:
  --contract <auto|portable|authoring|path>
                          Contract selector (default: auto=portable baseline)
  --context <manual|hook|post-run>
                          Execution context filter (default: manual)
  -h, --help              Show this help
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

cleanup() {
  if [[ -n "$CONTRACT_JSON_TMP" && -f "$CONTRACT_JSON_TMP" ]]; then
    rm -f "$CONTRACT_JSON_TMP"
  fi
}

resolve_profile_contract_path() {
  local profile="$1"
  local yaml_path="$PLUGIN_ROOT/contracts/${profile}-contract.yaml"
  local json_path="$PLUGIN_ROOT/contracts/${profile}-contract.json"

  if [[ -f "$yaml_path" ]]; then
    echo "$yaml_path"
  elif [[ -f "$json_path" ]]; then
    echo "$json_path"
  else
    echo "$yaml_path"
  fi
}

resolve_contract_path() {
  local selector="$1"
  case "$selector" in
    auto)
      resolve_profile_contract_path "portable"
      ;;
    portable)
      resolve_profile_contract_path "portable"
      ;;
    authoring)
      resolve_profile_contract_path "authoring"
      ;;
    *)
      if [[ "$selector" == /* ]]; then
        echo "$selector"
      elif [[ -f "$REPO_ROOT/$selector" ]]; then
        echo "$REPO_ROOT/$selector"
      elif [[ -f "$PLUGIN_ROOT/$selector" ]]; then
        echo "$PLUGIN_ROOT/$selector"
      else
        echo "$selector"
      fi
      ;;
  esac
}

context_enabled() {
  local check_json="$1"
  local context="$2"
  jq -e --arg context "$context" '
    if (.contexts | type) == "array" then
      any(.contexts[]; . == $context)
    else
      true
    end
  ' <<<"$check_json" >/dev/null
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract)
      CONTRACT_SELECTOR="${2-}"
      [[ -n "$CONTRACT_SELECTOR" ]] || fail "--contract requires a value"
      shift 2
      ;;
    --context)
      CONTEXT="${2-}"
      [[ -n "$CONTEXT" ]] || fail "--context requires a value"
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

case "$CONTEXT" in
  manual|hook|post-run) ;;
  *) fail "invalid --context value: $CONTEXT" ;;
esac

require_cmd jq
require_cmd yq

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONTRACT_PATH="$(resolve_contract_path "$CONTRACT_SELECTOR")"
[[ -f "$CONTRACT_PATH" ]] || fail "contract file not found: $CONTRACT_PATH"

CONTRACT_JSON_TMP="$(mktemp)"
trap cleanup EXIT

if ! yq -o=json '.' "$CONTRACT_PATH" >"$CONTRACT_JSON_TMP" 2>/dev/null; then
  fail "invalid contract format: expected YAML/JSON object"
fi

if ! jq -e '.version and (.checks | type == "array")' "$CONTRACT_JSON_TMP" >/dev/null; then
  fail "invalid contract schema: expected version + checks[]"
fi

check_count="$(jq '.checks | length' "$CONTRACT_JSON_TMP")"
run_count=0
pass_count=0
warn_count=0
fail_count=0

for ((i=0; i<check_count; i++)); do
  check_json="$(jq -c ".checks[$i]" "$CONTRACT_JSON_TMP")"
  check_id="$(jq -r '.id // "unnamed"' <<<"$check_json")"
  check_mode="$(jq -r '.mode // "fail"' <<<"$check_json")"
  check_cmd="$(jq -r '.command // empty' <<<"$check_json")"

  if [[ -z "$check_cmd" ]]; then
    warn "[$check_id] empty command; skipping"
    warn_count=$((warn_count + 1))
    continue
  fi

  if ! context_enabled "$check_json" "$CONTEXT"; then
    continue
  fi

  run_count=$((run_count + 1))
  echo "[gate:$check_id] $check_cmd"

  set +e
  CWF_PLUGIN_ROOT="$PLUGIN_ROOT" CWF_HOST_REPO_ROOT="$REPO_ROOT" bash -lc "cd \"$REPO_ROOT\" && $check_cmd"
  rc=$?
  set -e

  if [[ "$rc" -eq 0 ]]; then
    pass_count=$((pass_count + 1))
    continue
  fi

  case "$check_mode" in
    off)
      warn "[$check_id] command failed but mode=off; ignoring"
      ;;
    warn)
      warn "[$check_id] command failed (mode=warn, rc=$rc)"
      warn_count=$((warn_count + 1))
      ;;
    *)
      echo "CHECK_FAIL: [$check_id] command failed (mode=fail, rc=$rc)" >&2
      fail_count=$((fail_count + 1))
      ;;
  esac
done

echo "Contract: $CONTRACT_PATH"
echo "Context : $CONTEXT"
echo "Summary : run=$run_count pass=$pass_count warn=$warn_count fail=$fail_count"

if [[ "$fail_count" -gt 0 ]]; then
  fail "unified gate failed"
fi

echo "CHECK_OK: unified gate passed"
