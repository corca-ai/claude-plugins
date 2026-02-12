#!/usr/bin/env bash
set -euo pipefail

# check-schemas.sh — Validate project config files against JSON Schemas
# Usage: check-schemas.sh [--json] [-h|--help]
#   --json    Output machine-readable JSON (structured per-file pass/fail)
#   -h|--help Show this usage message
# Exit 0 = all valid, Exit 1 = any validation failure or missing dependency

usage() {
  sed -n '3,8p' "$0" | sed 's/^# \?//'
  exit 0
}

JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Colors (disabled for non-TTY output and JSON mode)
if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# Find repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCHEMA_DIR="${REPO_ROOT}/scripts/schemas"

# --- Dependency checks ---

# yq: must be mikefarah/Go variant
if ! command -v yq &>/dev/null; then
  echo "Error: yq is not installed." >&2
  echo "Install: brew install yq  (or)  go install github.com/mikefarah/yq/v4@latest" >&2
  exit 1
fi

if ! yq --version 2>&1 | grep -qE 'mikefarah|version v4'; then
  echo "Error: yq must be the mikefarah/Go variant (v4+)." >&2
  echo "Install: brew install yq  (or)  go install github.com/mikefarah/yq/v4@latest" >&2
  exit 1
fi

# npx
if ! command -v npx &>/dev/null; then
  echo "Error: npx is not installed." >&2
  echo "Install: install Node.js (https://nodejs.org/) which includes npx" >&2
  exit 1
fi

# --- Temp file management ---

TMPFILES=()

cleanup() {
  for f in "${TMPFILES[@]}"; do
    rm -f "$f" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

# --- Validation targets ---
# Format: "schema_file:data_file[:converter]"
# converter is optional; "yq" means convert YAML to JSON first

targets=(
  "cwf-state.schema.json:cwf-state.yaml:yq"
  "plugin.schema.json:plugins/cwf/.claude-plugin/plugin.json"
  "hooks.schema.json:plugins/cwf/hooks/hooks.json"
)

# --- Validate a single target ---
# Args: target_spec ("schema:data[:converter]")
# Returns: 0 on pass, 1 on fail

validate_target() {
  local spec="$1"
  local schema data converter
  schema="${spec%%:*}"
  local rest="${spec#*:}"
  data="${rest%%:*}"
  converter="${rest#*:}"
  # If no converter field, converter == data (no colon separator found)
  if [[ "$converter" == "$data" ]]; then
    converter=""
  fi

  local schema_path="${SCHEMA_DIR}/${schema}"
  local data_path="${REPO_ROOT}/${data}"
  local validate_path="$data_path"

  # Check files exist
  if [[ ! -f "$schema_path" ]]; then
    echo "Error: Schema file not found: ${schema_path}" >&2
    return 1
  fi
  if [[ ! -f "$data_path" ]]; then
    echo "Error: Data file not found: ${data_path}" >&2
    return 1
  fi

  # Convert YAML to JSON if needed
  if [[ "$converter" == "yq" ]]; then
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/check-schemas-XXXXXX.json")
    TMPFILES+=("$tmpfile")
    if ! yq -o json "$data_path" > "$tmpfile"; then
      echo "Error: yq conversion failed for ${data}" >&2
      return 1
    fi
    validate_path="$tmpfile"
  fi

  # Validate with ajv-cli
  local output
  if output=$(npx ajv-cli@5 validate -s "$schema_path" -d "$validate_path" --spec=draft2020 --all-errors 2>&1); then
    return 0
  else
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      echo "$output" >&2
    fi
    return 1
  fi
}

# --- Run all validations ---

failed=0
pass_count=0
fail_count=0
json_results=""

for pair in "${targets[@]}"; do
  # Extract the human-readable data file name
  local_rest="${pair#*:}"
  data_file="${local_rest%%:*}"

  if validate_target "$pair"; then
    pass_count=$((pass_count + 1))
    if [[ "$JSON_OUTPUT" == "true" ]]; then
      entry=$(printf '{"file":"%s","status":"PASS"}' "$data_file")
      if [[ -n "$json_results" ]]; then json_results="$json_results,"; fi
      json_results="$json_results$entry"
    else
      echo -e "  ${GREEN}PASS${NC}  ${data_file}"
    fi
  else
    failed=1
    fail_count=$((fail_count + 1))
    if [[ "$JSON_OUTPUT" == "true" ]]; then
      entry=$(printf '{"file":"%s","status":"FAIL"}' "$data_file")
      if [[ -n "$json_results" ]]; then json_results="$json_results,"; fi
      json_results="$json_results$entry"
    else
      echo -e "  ${RED}FAIL${NC}  ${data_file}"
    fi
  fi
done

# --- Summary ---

total=${#targets[@]}

if [[ "$JSON_OUTPUT" == "true" ]]; then
  printf '{"results":[%s],"summary":{"total":%d,"pass":%d,"fail":%d}}\n' \
    "$json_results" "$total" "$pass_count" "$fail_count"
else
  echo "---"
  if [[ "$failed" -eq 0 ]]; then
    echo -e "${GREEN}All ${total} schema validations passed.${NC}"
  else
    echo -e "${RED}${fail_count}/${total} schema validations failed.${NC}"
  fi
fi

exit "$failed"
