#!/usr/bin/env bash
set -euo pipefail

# check-docs-contract-runtime.sh
# End-to-end runtime check for docs-contract bootstrap behavior used by
# `cwf:refactor --docs`.
#
# Verifies:
# - create path (`status=created`)
# - idempotent re-run (`status=existing`)
# - force update (`status=updated`)
# - fallback degradation (`status=fallback`, exit 0)
# - required contract keys exist for docs-flow parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap-docs-contract.sh"

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

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-docs-contract-check.XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

contract_path="$tmp_root/docs-contract.yaml"

created_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
created_status="$(printf '%s' "$created_json" | jq -r '.status')"
[[ "$created_status" == "created" ]] || fail "expected created, got: $created_status"
[[ -f "$contract_path" ]] || fail "contract file not created: $contract_path"

for required_key in \
  'entry_docs:' \
  'inventory:' \
  'checks:' \
  'portability_baseline: true' \
  'entry_docs_review: true' \
  'project_context_review:' \
  'inventory_alignment:' \
  'locale_mirror_alignment:' \
  'plugin_manifest_glob:'; do
  grep -Fq "$required_key" "$contract_path" || fail "missing contract key: $required_key"
done

existing_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
existing_status="$(printf '%s' "$existing_json" | jq -r '.status')"
[[ "$existing_status" == "existing" ]] || fail "expected existing, got: $existing_status"

updated_json="$(bash "$BOOTSTRAP_SCRIPT" --json --force --contract "$contract_path")"
updated_status="$(printf '%s' "$updated_json" | jq -r '.status')"
[[ "$updated_status" == "updated" ]] || fail "expected updated, got: $updated_status"

set +e
fallback_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "/dev/null/docs-contract.yaml" 2>/dev/null)"
fallback_rc=$?
set -e
[[ "$fallback_rc" -eq 0 ]] || fail "fallback execution returned non-zero: $fallback_rc"

fallback_status="$(printf '%s' "$fallback_json" | jq -r '.status')"
[[ "$fallback_status" == "fallback" ]] || fail "expected fallback, got: $fallback_status"

fallback_warning="$(printf '%s' "$fallback_json" | jq -r '.warning // empty')"
[[ -n "$fallback_warning" ]] || fail "expected fallback warning metadata"

echo "CHECK_OK: docs-contract runtime behavior verified"
