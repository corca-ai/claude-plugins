#!/usr/bin/env bash
set -euo pipefail

# check-portability-fixtures.sh
# Regression fixtures for repository-agnostic behavior.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP_BOOTSTRAP="$PLUGIN_ROOT/skills/setup/scripts/bootstrap-setup-contract.sh"
SETUP_HOOKS="$PLUGIN_ROOT/skills/setup/scripts/configure-git-hooks.sh"

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_cmd bash
require_cmd git
require_cmd jq

[[ -x "$SETUP_BOOTSTRAP" ]] || fail "bootstrap script missing: $SETUP_BOOTSTRAP"
[[ -x "$SETUP_HOOKS" ]] || fail "hook config script missing: $SETUP_HOOKS"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-portability-fixtures.XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

# Fixture A: host-minimal repo should keep index-coverage gate disabled in authoring-only mode.
host_repo="$tmp_root/host-minimal"
mkdir -p "$host_repo/scripts"
git -C "$host_repo" init -q
cat > "$host_repo/scripts/check.sh" <<'EOF_HOST'
#!/usr/bin/env bash
set -euo pipefail
yq '.policy' .cwf/setup-contract.yaml >/dev/null
EOF_HOST
chmod +x "$host_repo/scripts/check.sh"
git -C "$host_repo" add scripts/check.sh

host_contract="$tmp_root/host-setup-contract.yaml"
host_json="$(cd "$host_repo" && bash "$SETUP_BOOTSTRAP" --json --contract "$host_contract")"
host_status="$(printf '%s' "$host_json" | jq -r '.status')"
[[ "$host_status" == "created" ]] || fail "host fixture expected created status, got: $host_status"
grep -Fq 'name: "yq"' "$host_contract" || fail "host fixture should detect yq repo_tool"
grep -Fq 'hook_index_coverage_mode: "authoring-only"' "$host_contract" || fail "host fixture should include hook_index_coverage_mode"

(cd "$host_repo" && bash "$SETUP_HOOKS" --install pre-push --profile balanced >/dev/null)
set +e
(cd "$host_repo" && ./.githooks/pre-push > "$tmp_root/host-pre-push.out" 2>&1)
host_rc=$?
set -e
[[ "$host_rc" -eq 0 ]] || fail "host fixture pre-push should pass (got rc=$host_rc)"
grep -Fq 'index coverage checks skipped by policy (mode: authoring-only).' \
  "$tmp_root/host-pre-push.out" \
  || fail "host fixture should skip index coverage in authoring-only mode"

# Fixture B: authoring-like repo should execute index-coverage gate in authoring-only mode.
author_repo="$tmp_root/authoring-repo"
mkdir -p "$author_repo/plugins/cwf"
git -C "$author_repo" init -q
cat > "$author_repo/README.md" <<'EOF_AUTHOR_EN'
# Fixture Authoring Repo
EOF_AUTHOR_EN
cat > "$author_repo/README.ko.md" <<'EOF_AUTHOR_KO'
# 픽스처 Authoring Repo
EOF_AUTHOR_KO
cat > "$author_repo/AGENTS.md" <<'EOF_AUTHOR_AGENTS'
# AGENTS

fixture
EOF_AUTHOR_AGENTS
git -C "$author_repo" add README.md README.ko.md AGENTS.md

(cd "$author_repo" && bash "$SETUP_HOOKS" --install pre-push --profile balanced >/dev/null)
set +e
(cd "$author_repo" && ./.githooks/pre-push > "$tmp_root/author-pre-push.out" 2>&1)
author_rc=$?
set -e
[[ "$author_rc" -ne 0 ]] || fail "authoring fixture pre-push should fail on index-coverage gate"
grep -Fq 'index coverage checks (mode: authoring-only, blocking: true)...' \
  "$tmp_root/author-pre-push.out" \
  || fail "authoring fixture should run blocking index coverage checks"

echo "CHECK_OK: portability fixtures verified (host-minimal + authoring-repo)"
