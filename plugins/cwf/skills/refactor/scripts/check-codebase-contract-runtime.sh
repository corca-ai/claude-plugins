#!/usr/bin/env bash
set -euo pipefail

# check-codebase-contract-runtime.sh
# End-to-end runtime check for codebase-contract bootstrap behavior used by
# `cwf:refactor --codebase`.
#
# Verifies:
# - create path (status=created)
# - idempotent re-run (status=existing)
# - force update (status=updated)
# - fallback degradation (status=fallback, exit 0)
# - required contract keys exist for codebase scan parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap-codebase-contract.sh"

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_cmd bash
require_cmd jq
[[ -f "$BOOTSTRAP_SCRIPT" ]] || fail "bootstrap script not found: $BOOTSTRAP_SCRIPT"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-codebase-contract-check.XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

contract_path="$tmp_root/codebase-contract.json"

created_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
created_status="$(printf '%s' "$created_json" | jq -r '.status')"
[[ "$created_status" == "created" ]] || fail "expected created, got: $created_status"
[[ -f "$contract_path" ]] || fail "contract file not created: $contract_path"

jq -e '
  .version == 1 and
  (.scope.include_globs | type == "array") and
  (.scope.exclude_globs | type == "array") and
  (.scope.include_extensions | type == "array") and
  (.checks.large_file_lines.warn_at | type == "number") and
  (.checks.large_file_lines.error_at | type == "number") and
  (.checks.todo_markers.patterns | type == "array") and
  (.checks.shell_strict_mode.exclude_globs | type == "array") and
  (.deep_review.enabled | type == "boolean") and
  (.deep_review.fixed_experts | type == "array") and
  (.deep_review.context_experts | type == "array") and
  (.deep_review.context_expert_count | type == "number") and
  (.reporting.top_findings_limit | type == "number")
' "$contract_path" >/dev/null || fail "contract schema keys missing or invalid"

existing_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
existing_status="$(printf '%s' "$existing_json" | jq -r '.status')"
[[ "$existing_status" == "existing" ]] || fail "expected existing, got: $existing_status"

updated_json="$(bash "$BOOTSTRAP_SCRIPT" --json --force --contract "$contract_path")"
updated_status="$(printf '%s' "$updated_json" | jq -r '.status')"
[[ "$updated_status" == "updated" ]] || fail "expected updated, got: $updated_status"

set +e
fallback_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "/dev/null/codebase-contract.json" 2>/dev/null)"
fallback_rc=$?
set -e
[[ "$fallback_rc" -eq 0 ]] || fail "fallback execution returned non-zero: $fallback_rc"

fallback_status="$(printf '%s' "$fallback_json" | jq -r '.status')"
[[ "$fallback_status" == "fallback" ]] || fail "expected fallback, got: $fallback_status"

fallback_warning="$(printf '%s' "$fallback_json" | jq -r '.warning // empty')"
[[ -n "$fallback_warning" ]] || fail "expected fallback warning metadata"

echo "CHECK_OK: codebase-contract runtime behavior verified"
