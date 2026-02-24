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
# - fallback degradation (status=fallback, non-zero exit)
# - required contract keys exist for codebase scan parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap-codebase-contract.sh"
SCAN_SCRIPT="$SCRIPT_DIR/codebase-quick-scan.sh"

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_cmd bash
require_cmd jq
require_cmd python3
[[ -f "$BOOTSTRAP_SCRIPT" ]] || fail "bootstrap script not found: $BOOTSTRAP_SCRIPT"
[[ -f "$SCAN_SCRIPT" ]] || fail "scan script not found: $SCAN_SCRIPT"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-codebase-contract-check.XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

contract_path="$tmp_root/codebase-contract.yaml"

created_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
created_status="$(printf '%s' "$created_json" | jq -r '.status')"
[[ "$created_status" == "created" ]] || fail "expected created, got: $created_status"
[[ -f "$contract_path" ]] || fail "contract file not created: $contract_path"

python3 - "$contract_path" <<'PY' || fail "contract schema keys missing or invalid"
import json
import sys

try:
    import yaml
except Exception as exc:
    raise SystemExit(f"PyYAML not available: {exc}")

contract_path = sys.argv[1]

with open(contract_path, encoding="utf-8") as f:
    raw_text = f.read()

try:
    data = json.loads(raw_text)
except Exception:
    data = yaml.safe_load(raw_text)

if data is None:
    data = {}

def fail(msg):
    raise SystemExit(msg)

def is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)

if not isinstance(data, dict):
    fail("contract root must be an object/mapping")
if data.get("version") != 1:
    fail("version must be 1")

scope = data.get("scope")
if not isinstance(scope, dict):
    fail("scope must be an object")
if not isinstance(scope.get("include_globs"), list):
    fail("scope.include_globs must be an array")
if not isinstance(scope.get("exclude_globs"), list):
    fail("scope.exclude_globs must be an array")
if not isinstance(scope.get("include_extensions"), list):
    fail("scope.include_extensions must be an array")

checks = data.get("checks")
if not isinstance(checks, dict):
    fail("checks must be an object")

large_file_lines = checks.get("large_file_lines")
if not isinstance(large_file_lines, dict):
    fail("checks.large_file_lines must be an object")
if not is_number(large_file_lines.get("warn_at")):
    fail("checks.large_file_lines.warn_at must be a number")
if not is_number(large_file_lines.get("error_at")):
    fail("checks.large_file_lines.error_at must be a number")

todo_markers = checks.get("todo_markers")
if not isinstance(todo_markers, dict):
    fail("checks.todo_markers must be an object")
if not isinstance(todo_markers.get("patterns"), list):
    fail("checks.todo_markers.patterns must be an array")

shell_strict_mode = checks.get("shell_strict_mode")
if not isinstance(shell_strict_mode, dict):
    fail("checks.shell_strict_mode must be an object")
if not isinstance(shell_strict_mode.get("exclude_globs"), list):
    fail("checks.shell_strict_mode.exclude_globs must be an array")
if not isinstance(shell_strict_mode.get("require_contract_and_pragma"), bool):
    fail("checks.shell_strict_mode.require_contract_and_pragma must be a boolean")
if not isinstance(shell_strict_mode.get("pragma_prefix"), str):
    fail("checks.shell_strict_mode.pragma_prefix must be a string")
if not isinstance(shell_strict_mode.get("pragma_required_fields"), list):
    fail("checks.shell_strict_mode.pragma_required_fields must be an array")
if not isinstance(shell_strict_mode.get("file_overrides"), dict):
    fail("checks.shell_strict_mode.file_overrides must be an object")

deep_review = data.get("deep_review")
if not isinstance(deep_review, dict):
    fail("deep_review must be an object")
if not isinstance(deep_review.get("enabled"), bool):
    fail("deep_review.enabled must be a boolean")
if not isinstance(deep_review.get("fixed_experts"), list):
    fail("deep_review.fixed_experts must be an array")
if not isinstance(deep_review.get("context_experts"), list):
    fail("deep_review.context_experts must be an array")
if not is_number(deep_review.get("context_expert_count")):
    fail("deep_review.context_expert_count must be a number")

reporting = data.get("reporting")
if not isinstance(reporting, dict):
    fail("reporting must be an object")
if not is_number(reporting.get("top_findings_limit")):
    fail("reporting.top_findings_limit must be a number")
PY

scan_repo="$tmp_root/repo"
mkdir -p "$scan_repo"
cat > "$scan_repo/sample.py" <<'EOF'
print("ok")
EOF

scan_json="$(bash "$SCAN_SCRIPT" "$scan_repo" --contract "$contract_path")"
scan_contract_status="$(printf '%s' "$scan_json" | jq -r '.contract.status')"
[[ "$scan_contract_status" == "loaded" ]] || fail "expected scan contract.status=loaded, got: $scan_contract_status"

expected_contract_path="$(python3 - "$contract_path" <<'PY'
import os
import sys
print(os.path.abspath(sys.argv[1]))
PY
)"
scan_contract_path="$(printf '%s' "$scan_json" | jq -r '.contract.path')"
[[ "$scan_contract_path" == "$expected_contract_path" ]] || fail "unexpected scan contract.path: $scan_contract_path"

existing_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
existing_status="$(printf '%s' "$existing_json" | jq -r '.status')"
[[ "$existing_status" == "existing" ]] || fail "expected existing, got: $existing_status"

updated_json="$(bash "$BOOTSTRAP_SCRIPT" --json --force --contract "$contract_path")"
updated_status="$(printf '%s' "$updated_json" | jq -r '.status')"
[[ "$updated_status" == "updated" ]] || fail "expected updated, got: $updated_status"

set +e
fallback_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "/dev/null/codebase-contract.yaml" 2>/dev/null)"
fallback_rc=$?
set -e
[[ "$fallback_rc" -ne 0 ]] || fail "fallback execution unexpectedly returned success"

fallback_status="$(printf '%s' "$fallback_json" | jq -r '.status')"
[[ "$fallback_status" == "fallback" ]] || fail "expected fallback, got: $fallback_status"

fallback_warning="$(printf '%s' "$fallback_json" | jq -r '.warning // empty')"
[[ -n "$fallback_warning" ]] || fail "expected fallback warning metadata"

echo "CHECK_OK: codebase-contract runtime behavior verified"
