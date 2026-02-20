#!/usr/bin/env bash
set -euo pipefail

# check-setup-contract-runtime.sh
# End-to-end runtime check for setup-contract bootstrap behavior used by
# `cwf:setup` setup-contract phase.
#
# Verifies:
# - create path (status=created)
# - idempotent re-run (status=existing)
# - force update (status=updated)
# - fallback degradation (status=fallback, non-zero exit)
# - required contract keys exist for setup-flow parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap-setup-contract.sh"

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_cmd bash
require_cmd jq
require_cmd git
[[ -f "$BOOTSTRAP_SCRIPT" ]] || fail "bootstrap script not found: $BOOTSTRAP_SCRIPT"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-setup-contract-check.XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

contract_path="$tmp_root/setup-contract.yaml"

created_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
created_status="$(printf '%s' "$created_json" | jq -r '.status')"
[[ "$created_status" == "created" ]] || fail "expected created, got: $created_status"
[[ -f "$contract_path" ]] || fail "contract file not created: $contract_path"

for required_key in \
  'policy:' \
  'hook_extensions:' \
  '  pre_push:' \
  '    path: ""' \
  '    required: false' \
  'core_tools:' \
  'repo_tools:' \
  'core_tools_required: true' \
  'repo_tools_opt_in: true' \
  'hook_index_coverage_mode:' \
  'install_hint:' \
  'reason:'; do
  grep -Fq "$required_key" "$contract_path" || fail "missing contract key: $required_key"
done

existing_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract "$contract_path")"
existing_status="$(printf '%s' "$existing_json" | jq -r '.status')"
[[ "$existing_status" == "existing" ]] || fail "expected existing, got: $existing_status"

updated_json="$(bash "$BOOTSTRAP_SCRIPT" --json --force --contract "$contract_path")"
updated_status="$(printf '%s' "$updated_json" | jq -r '.status')"
[[ "$updated_status" == "updated" ]] || fail "expected updated, got: $updated_status"

set +e
fallback_json="$(bash "$BOOTSTRAP_SCRIPT" --json --contract '/dev/null/setup-contract.yaml' 2>/dev/null)"
fallback_rc=$?
set -e
[[ "$fallback_rc" -ne 0 ]] || fail "fallback execution unexpectedly returned success"

fallback_status="$(printf '%s' "$fallback_json" | jq -r '.status')"
[[ "$fallback_status" == "fallback" ]] || fail "expected fallback, got: $fallback_status"

fallback_warning="$(printf '%s' "$fallback_json" | jq -r '.warning // empty')"
[[ -n "$fallback_warning" ]] || fail "expected fallback warning metadata"

# External-repo detectability regression:
# The bootstrap must discover repo_tools from generic host-repo scripts,
# not only CWF-internal paths.
external_repo="$tmp_root/external-repo"
mkdir -p "$external_repo/scripts"
git -C "$external_repo" init -q
cat > "$external_repo/scripts/check.sh" <<'EOF_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
yq '.policy' .cwf/setup-contract.yaml >/dev/null
EOF_SCRIPT
chmod +x "$external_repo/scripts/check.sh"
git -C "$external_repo" add scripts/check.sh

external_contract="$tmp_root/external-setup-contract.yaml"
external_json="$(
  cd "$external_repo" \
    && bash "$BOOTSTRAP_SCRIPT" --json --contract "$external_contract"
)"
external_status="$(printf '%s' "$external_json" | jq -r '.status')"
[[ "$external_status" == "created" ]] || fail "expected external created, got: $external_status"
grep -Fq 'name: "yq"' "$external_contract" || fail "expected yq in external repo_tools suggestions"

echo "CHECK_OK: setup-contract runtime behavior verified"
