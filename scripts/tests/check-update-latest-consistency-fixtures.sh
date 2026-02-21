#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHECK_SCRIPT="$REPO_ROOT/plugins/cwf/scripts/check-update-latest-consistency.sh"

PASS=0
FAIL=0

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "  expected: $expected"
    echo "  actual  : $actual"
  fi
}

assert_contains() {
  local name="$1"
  local value="$2"
  local needle="$3"
  if printf '%s' "$value" | grep -Fq "$needle"; then
    pass "$name"
  else
    fail "$name"
    echo "  missing: $needle"
  fi
}

json_field() {
  local file_path="$1"
  local key="$2"
  jq -r "$key" "$file_path"
}

run_capture() {
  local output_file="$1"
  shift
  set +e
  "$@" >"$output_file" 2>"$output_file.err"
  local rc=$?
  set -e
  echo "$rc"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_CLAUDE="$TMP_DIR/mock-claude.sh"
MARKETPLACE_JSON="$TMP_DIR/marketplace.json"
CACHE_ROOT="$TMP_DIR/cache"
INSTALL_ROOT="$TMP_DIR/install-user"

mkdir -p "$INSTALL_ROOT/.claude-plugin"
mkdir -p "$CACHE_ROOT/corca-plugins/cwf/0.8.7/.claude-plugin"

cat > "$MOCK_CLAUDE" <<'EOF_MOCK'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ge 3 && "$1" == "plugin" && "$2" == "list" && "$3" == "--json" ]]; then
  install_path="${MOCK_INSTALL_PATH:-}"
  scope="${MOCK_SCOPE:-user}"
  version="${MOCK_CURRENT_VERSION:-0.8.2}"
  cat <<JSON
[
  {
    "id": "cwf@corca-plugins",
    "scope": "$scope",
    "installPath": "$install_path",
    "version": "$version"
  }
]
JSON
  exit 0
fi

if [[ "$#" -ge 4 && "$1" == "plugin" && "$2" == "marketplace" && "$3" == "update" ]]; then
  rc="${MOCK_MARKETPLACE_UPDATE_RC:-0}"
  if [[ "$rc" -eq 0 ]]; then
    echo "marketplace update ok"
    exit 0
  fi
  echo "marketplace update failed" >&2
  exit "$rc"
fi

echo "unsupported mock invocation: $*" >&2
exit 9
EOF_MOCK
chmod +x "$MOCK_CLAUDE"

cat > "$MARKETPLACE_JSON" <<'EOF_MARKETPLACE'
{
  "plugins": [
    {
      "name": "cwf",
      "version": "0.8.7"
    }
  ]
}
EOF_MARKETPLACE

cat > "$INSTALL_ROOT/.claude-plugin/plugin.json" <<'EOF_PLUGIN'
{
  "name": "cwf",
  "version": "0.8.2"
}
EOF_PLUGIN

cat > "$CACHE_ROOT/corca-plugins/cwf/0.8.7/.claude-plugin/plugin.json" <<'EOF_CACHE'
{
  "name": "cwf",
  "version": "0.8.7"
}
EOF_CACHE

# Case A: contract mode passes on current SKILL
out_a="$TMP_DIR/out-contract-pass.txt"
rc="$(run_capture "$out_a" bash "$CHECK_SCRIPT" --mode contract --json)"
assert_eq "contract mode pass rc" "0" "$rc"
assert_eq "contract mode verdict" "CONTRACT_OK" "$(json_field "$out_a" '.verdict')"

# Case B: contract mode fails when UNVERIFIED clause missing
BAD_SKILL="$TMP_DIR/bad-update-skill.md"
sed '/UNVERIFIED/d' "$REPO_ROOT/plugins/cwf/skills/update/SKILL.md" > "$BAD_SKILL"
out_b="$TMP_DIR/out-contract-fail.txt"
rc="$(run_capture "$out_b" bash "$CHECK_SCRIPT" --mode contract --skill-file "$BAD_SKILL" --json)"
assert_eq "contract mode missing clause rc" "3" "$rc"
assert_eq "contract mode missing clause reason" "CONTRACT_MISSING_REQUIRED_CLAUSES" "$(json_field "$out_b" '.reason')"

# Case C: top-level mode pass with OUTDATED verdict
out_c="$TMP_DIR/out-top-level-pass.txt"
rc="$(run_capture "$out_c" env HOME="$TMP_DIR/home" CLAUDE_HOME="$TMP_DIR/home/.claude" XDG_CACHE_HOME="$TMP_DIR/home/.cache" MOCK_INSTALL_PATH="$INSTALL_ROOT" MOCK_SCOPE="user" MOCK_CURRENT_VERSION="0.8.2" MOCK_MARKETPLACE_UPDATE_RC=0 bash "$CHECK_SCRIPT" --mode top-level --scope user --claude-bin "$MOCK_CLAUDE" --marketplace-source "$MARKETPLACE_JSON" --cache-root "$CACHE_ROOT" --json)"
assert_eq "top-level mode pass rc" "0" "$rc"
assert_eq "top-level mode outdated verdict" "OUTDATED" "$(json_field "$out_c" '.verdict')"

# Case D: top-level mode UNVERIFIED when marketplace update fails
out_d="$TMP_DIR/out-top-level-unverified.txt"
rc="$(run_capture "$out_d" env HOME="$TMP_DIR/home" CLAUDE_HOME="$TMP_DIR/home/.claude" XDG_CACHE_HOME="$TMP_DIR/home/.cache" MOCK_INSTALL_PATH="$INSTALL_ROOT" MOCK_SCOPE="user" MOCK_CURRENT_VERSION="0.8.2" MOCK_MARKETPLACE_UPDATE_RC=7 bash "$CHECK_SCRIPT" --mode top-level --scope user --claude-bin "$MOCK_CLAUDE" --marketplace-source "$MARKETPLACE_JSON" --cache-root "$CACHE_ROOT" --json)"
assert_eq "top-level mode unverified rc" "2" "$rc"
assert_eq "top-level mode unverified reason" "MARKETPLACE_UPDATE_FAILED" "$(json_field "$out_d" '.reason')"

# Case E: top-level mode FAIL on cache/authoritative mismatch
cat > "$CACHE_ROOT/corca-plugins/cwf/0.8.7/.claude-plugin/plugin.json" <<'EOF_CACHE_STALE'
{
  "name": "cwf",
  "version": "0.8.2"
}
EOF_CACHE_STALE

out_e="$TMP_DIR/out-top-level-fail.txt"
rc="$(run_capture "$out_e" env HOME="$TMP_DIR/home" CLAUDE_HOME="$TMP_DIR/home/.claude" XDG_CACHE_HOME="$TMP_DIR/home/.cache" MOCK_INSTALL_PATH="$INSTALL_ROOT" MOCK_SCOPE="user" MOCK_CURRENT_VERSION="0.8.2" MOCK_MARKETPLACE_UPDATE_RC=0 bash "$CHECK_SCRIPT" --mode top-level --scope user --claude-bin "$MOCK_CLAUDE" --marketplace-source "$MARKETPLACE_JSON" --cache-root "$CACHE_ROOT" --json)"
assert_eq "top-level mode mismatch rc" "3" "$rc"
assert_eq "top-level mode mismatch reason" "CACHE_AUTHORITATIVE_MISMATCH" "$(json_field "$out_e" '.reason')"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
