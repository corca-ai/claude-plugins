#!/usr/bin/env bash
set -euo pipefail

# check-update-latest-consistency.sh
# Enforces update latest-version oracle consistency contracts for CWF.
#
# Modes:
# - contract : static lint for update skill fail-closed semantics
# - top-level: runtime verification against authoritative marketplace metadata
#
# Exit codes:
#   0 = PASS
#   1 = usage/dependency error
#   2 = UNVERIFIED (fail-closed)
#   3 = FAIL (consistency violation)

usage() {
  cat <<'USAGE'
check-update-latest-consistency.sh — validate CWF update latest-version consistency

Usage:
  check-update-latest-consistency.sh [options]

Options:
  --mode <contract|top-level>
                         Validation mode (default: contract)
  --skill-file <path>    SKILL.md path for contract mode
                         (default: plugins/cwf/skills/update/SKILL.md)
  --scope <user|project|local>
                         Target scope for top-level mode (default: user)
  --claude-bin <path>    Claude executable (default: CLAUDE_BIN env or claude)
  --plugin-name <name>   Plugin short name in marketplace JSON (default: cwf)
  --plugin-id-prefix <prefix>
                         Prefix used in `claude plugin list --json` IDs (default: cwf@)
  --marketplace-source <path-or-url>
                         Authoritative marketplace source
                         (default: https://raw.githubusercontent.com/corca-ai/claude-plugins/main/.claude-plugin/marketplace.json)
  --cache-root <path>    Additional cache root to search (repeatable)
  --json                 Emit JSON summary
  -h, --help             Show this help

Examples:
  check-update-latest-consistency.sh --mode contract
  check-update-latest-consistency.sh --mode top-level --scope user --json
USAGE
}

MODE="contract"
SKILL_FILE=""
SCOPE="user"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
PLUGIN_NAME="cwf"
PLUGIN_ID_PREFIX="cwf@"
MARKETPLACE_SOURCE="https://raw.githubusercontent.com/corca-ai/claude-plugins/main/.claude-plugin/marketplace.json"
JSON_OUTPUT="false"

declare -a EXTRA_CACHE_ROOTS=()

tmp_files=()
# shellcheck disable=SC2317
cleanup() {
  local f=""
  for f in "${tmp_files[@]}"; do
    rm -f "$f" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: missing required command: $1" >&2
    exit 1
  fi
}

emit_result() {
  local status="$1"
  local verdict="$2"
  local reason="$3"
  local current_version="$4"
  local authoritative_latest="$5"
  local cache_latest="$6"
  local scope="$7"

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq -n \
      --arg mode "$MODE" \
      --arg status "$status" \
      --arg verdict "$verdict" \
      --arg reason "$reason" \
      --arg scope "$scope" \
      --arg current_version "$current_version" \
      --arg authoritative_latest "$authoritative_latest" \
      --arg cache_latest "$cache_latest" \
      '{mode:$mode,status:$status,verdict:$verdict,reason:$reason,scope:$scope,current_version:$current_version,authoritative_latest:$authoritative_latest,cache_latest:$cache_latest}'
  else
    echo "mode=$MODE"
    echo "status=$status"
    echo "verdict=$verdict"
    echo "reason=$reason"
    echo "scope=$scope"
    echo "current_version=$current_version"
    echo "authoritative_latest=$authoritative_latest"
    echo "cache_latest=$cache_latest"
  fi
}

version_cmp() {
  local a="$1"
  local b="$2"
  if [[ "$a" == "$b" ]]; then
    printf '0\n'
    return 0
  fi

  local first=""
  first="$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -n1)"
  if [[ "$first" == "$a" ]]; then
    printf -- '-1\n'
  else
    printf '1\n'
  fi
}

resolve_marketplace_file() {
  local source="$1"
  local out_file="$2"

  if [[ "$source" =~ ^https?:// ]]; then
    require_cmd curl
    set +e
    local http_code
    http_code="$(curl -sS -L --connect-timeout 10 --max-time 45 -o "$out_file" -w "%{http_code}" "$source")"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      return 2
    fi
    if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
      return 2
    fi
    return 0
  fi

  if [[ -f "$source" ]]; then
    cp "$source" "$out_file"
    return 0
  fi
  if [[ -f "$source/.claude-plugin/marketplace.json" ]]; then
    cp "$source/.claude-plugin/marketplace.json" "$out_file"
    return 0
  fi
  if [[ -f "$source/marketplace.json" ]]; then
    cp "$source/marketplace.json" "$out_file"
    return 0
  fi

  return 2
}

run_contract_mode() {
  local skill_file="$SKILL_FILE"
  local missing=0

  [[ -n "$skill_file" ]] || skill_file="plugins/cwf/skills/update/SKILL.md"
  if [[ ! -f "$skill_file" ]]; then
    emit_result "FAIL" "FAIL" "SKILL_FILE_NOT_FOUND" "" "" "" "$SCOPE"
    exit 3
  fi

  if ! grep -Fq "Apply Update to Selected Scope (No Confirmation Prompt)" "$skill_file"; then
    echo "contract missing: no-confirmation apply section" >&2
    missing=1
  fi
  if ! grep -Fq "Changelog Summary (Opt-In)" "$skill_file"; then
    echo "contract missing: changelog opt-in section" >&2
    missing=1
  fi
  if ! grep -Fq "Auto-apply when newer version exists" "$skill_file"; then
    echo "contract missing: auto-apply rule" >&2
    missing=1
  fi
  if ! grep -Fqi "authoritative" "$skill_file"; then
    echo "contract missing: authoritative source requirement" >&2
    missing=1
  fi
  if ! grep -Fq "UNVERIFIED" "$skill_file"; then
    echo "contract missing: UNVERIFIED fail-closed state" >&2
    missing=1
  fi
  if ! grep -Eqi "top-level|top level" "$skill_file"; then
    echo "contract missing: top-level verification requirement" >&2
    missing=1
  fi
  if ! grep -Fq "check-update-latest-consistency.sh" "$skill_file"; then
    echo "contract missing: update consistency checker integration" >&2
    missing=1
  fi

  if [[ "$missing" -ne 0 ]]; then
    emit_result "FAIL" "FAIL" "CONTRACT_MISSING_REQUIRED_CLAUSES" "" "" "" "$SCOPE"
    exit 3
  fi

  emit_result "PASS" "CONTRACT_OK" "CONTRACT_VALID" "" "" "" "$SCOPE"
  exit 0
}

run_top_level_mode() {
  require_cmd jq

  case "$SCOPE" in
    user|project|local) ;;
    *)
      echo "Error: unsupported --scope: $SCOPE" >&2
      exit 1
      ;;
  esac

  if [[ "$CLAUDE_BIN" == */* ]]; then
    if [[ ! -x "$CLAUDE_BIN" ]]; then
      emit_result "UNVERIFIED" "UNVERIFIED" "CLAUDE_BIN_NOT_EXECUTABLE" "" "" "" "$SCOPE"
      exit 2
    fi
  else
    if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
      emit_result "UNVERIFIED" "UNVERIFIED" "CLAUDE_BIN_NOT_FOUND" "" "" "" "$SCOPE"
      exit 2
    fi
  fi

  local plugin_list_json=""
  local plugin_list_err
  plugin_list_err="$(mktemp "${TMPDIR:-/tmp}/cwf-update-list-err.XXXXXX")"
  tmp_files+=("$plugin_list_err")

  set +e
  plugin_list_json="$("$CLAUDE_BIN" plugin list --json 2>"$plugin_list_err")"
  local list_rc=$?
  set -e
  if [[ "$list_rc" -ne 0 ]]; then
    emit_result "UNVERIFIED" "UNVERIFIED" "PLUGIN_LIST_FAILED" "" "" "" "$SCOPE"
    exit 2
  fi

  local current_install_path=""
  current_install_path="$(
    printf '%s' "$plugin_list_json" \
      | jq -r --arg scope "$SCOPE" --arg prefix "$PLUGIN_ID_PREFIX" \
        '[.[] | select(.id | startswith($prefix)) | select(.scope == $scope) | .installPath] | first // empty'
  )"

  if [[ -z "$current_install_path" ]]; then
    emit_result "FAIL" "FAIL" "SCOPE_INSTALL_NOT_FOUND" "" "" "" "$SCOPE"
    exit 3
  fi

  local current_plugin_json="$current_install_path/.claude-plugin/plugin.json"
  if [[ ! -f "$current_plugin_json" ]]; then
    emit_result "FAIL" "FAIL" "CURRENT_PLUGIN_JSON_NOT_FOUND" "" "" "" "$SCOPE"
    exit 3
  fi

  local current_version=""
  current_version="$(jq -r '.version // empty' "$current_plugin_json")"
  if [[ -z "$current_version" ]]; then
    emit_result "FAIL" "FAIL" "CURRENT_VERSION_MISSING" "" "" "" "$SCOPE"
    exit 3
  fi

  local marketplace_update_out=""
  set +e
  marketplace_update_out="$("$CLAUDE_BIN" plugin marketplace update corca-plugins 2>&1)"
  local market_rc=$?
  set -e
  if [[ "$market_rc" -ne 0 ]]; then
    emit_result "UNVERIFIED" "UNVERIFIED" "MARKETPLACE_UPDATE_FAILED" "$current_version" "" "" "$SCOPE"
    exit 2
  fi
  if printf '%s\n' "$marketplace_update_out" | grep -Eiq 'nested|not available|unavailable|blocked|permission denied'; then
    emit_result "UNVERIFIED" "UNVERIFIED" "MARKETPLACE_UPDATE_NON_TOP_LEVEL" "$current_version" "" "" "$SCOPE"
    exit 2
  fi

  local marketplace_file
  marketplace_file="$(mktemp "${TMPDIR:-/tmp}/cwf-update-marketplace.XXXXXX.json")"
  tmp_files+=("$marketplace_file")
  if ! resolve_marketplace_file "$MARKETPLACE_SOURCE" "$marketplace_file"; then
    emit_result "UNVERIFIED" "UNVERIFIED" "AUTHORITATIVE_SOURCE_FETCH_FAILED" "$current_version" "" "" "$SCOPE"
    exit 2
  fi

  if ! jq -e '.plugins and (.plugins | type == "array")' "$marketplace_file" >/dev/null 2>&1; then
    emit_result "UNVERIFIED" "UNVERIFIED" "AUTHORITATIVE_SOURCE_INVALID" "$current_version" "" "" "$SCOPE"
    exit 2
  fi

  local authoritative_latest=""
  authoritative_latest="$(jq -r --arg name "$PLUGIN_NAME" '.plugins[]? | select((.name // "") == $name) | .version // empty' "$marketplace_file" | head -n1)"
  if [[ -z "$authoritative_latest" ]]; then
    emit_result "UNVERIFIED" "UNVERIFIED" "AUTHORITATIVE_VERSION_MISSING" "$current_version" "" "" "$SCOPE"
    exit 2
  fi

  local extra_cache_roots_raw="${CWF_UPDATE_CACHE_ROOTS:-}"
  local -a cache_roots=()
  local -a env_extra_cache_roots=()
  if [[ -n "$extra_cache_roots_raw" ]]; then
    IFS=':' read -r -a env_extra_cache_roots <<< "$extra_cache_roots_raw"
  fi
  cache_roots=(
    "${CLAUDE_HOME:-$HOME/.claude}/plugins/cache"
    "$HOME/.claude/plugins/cache"
    "${XDG_CACHE_HOME:-$HOME/.cache}/claude/plugins/cache"
    "/usr/local/share/claude/plugins/cache"
  )

  local root=""
  for root in "${env_extra_cache_roots[@]}"; do
    [[ -n "$root" ]] || continue
    cache_roots+=("$root")
  done
  for root in "${EXTRA_CACHE_ROOTS[@]}"; do
    [[ -n "$root" ]] || continue
    cache_roots+=("$root")
  done

  local latest_plugin_json=""
  local candidate=""
  local best_candidate=""
  local best_version=""
  local candidate_base=""
  local candidate_version=""
  local cmp=""
  for root in "${cache_roots[@]}"; do
    [[ -d "$root" ]] || continue
    best_candidate=""
    best_version=""
    while IFS= read -r candidate; do
      candidate_base="${candidate%/.claude-plugin/plugin.json}"
      candidate_version="${candidate_base##*/}"
      [[ -n "$candidate_version" ]] || continue
      if [[ -z "$best_candidate" ]]; then
        best_candidate="$candidate"
        best_version="$candidate_version"
        continue
      fi
      cmp="$(version_cmp "$candidate_version" "$best_version")"
      if [[ "$cmp" == "1" ]]; then
        best_candidate="$candidate"
        best_version="$candidate_version"
      fi
    done < <(find "$root" -type f -path "*/$PLUGIN_NAME/*/.claude-plugin/plugin.json" 2>/dev/null)
    if [[ -n "$best_candidate" ]]; then
      latest_plugin_json="$best_candidate"
      break
    fi
  done

  if [[ -z "$latest_plugin_json" ]]; then
    emit_result "UNVERIFIED" "UNVERIFIED" "CACHE_SNAPSHOT_NOT_FOUND" "$current_version" "$authoritative_latest" "" "$SCOPE"
    exit 2
  fi

  local cache_latest=""
  cache_latest="$(jq -r '.version // empty' "$latest_plugin_json")"
  if [[ -z "$cache_latest" ]]; then
    emit_result "FAIL" "FAIL" "CACHE_VERSION_MISSING" "$current_version" "$authoritative_latest" "" "$SCOPE"
    exit 3
  fi

  if [[ "$cache_latest" != "$authoritative_latest" ]]; then
    emit_result "FAIL" "FAIL" "CACHE_AUTHORITATIVE_MISMATCH" "$current_version" "$authoritative_latest" "$cache_latest" "$SCOPE"
    exit 3
  fi

  local cmp=""
  cmp="$(version_cmp "$current_version" "$authoritative_latest")"
  case "$cmp" in
    0)
      emit_result "PASS" "UP_TO_DATE" "TOP_LEVEL_VERIFIED" "$current_version" "$authoritative_latest" "$cache_latest" "$SCOPE"
      exit 0
      ;;
    -1)
      emit_result "PASS" "OUTDATED" "TOP_LEVEL_VERIFIED" "$current_version" "$authoritative_latest" "$cache_latest" "$SCOPE"
      exit 0
      ;;
    1)
      emit_result "FAIL" "FAIL" "CURRENT_VERSION_AHEAD_OF_AUTHORITATIVE" "$current_version" "$authoritative_latest" "$cache_latest" "$SCOPE"
      exit 3
      ;;
    *)
      emit_result "FAIL" "FAIL" "VERSION_COMPARE_FAILED" "$current_version" "$authoritative_latest" "$cache_latest" "$SCOPE"
      exit 3
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --skill-file)
      SKILL_FILE="${2:-}"
      shift 2
      ;;
    --scope)
      SCOPE="${2:-}"
      shift 2
      ;;
    --claude-bin)
      CLAUDE_BIN="${2:-}"
      shift 2
      ;;
    --plugin-name)
      PLUGIN_NAME="${2:-}"
      shift 2
      ;;
    --plugin-id-prefix)
      PLUGIN_ID_PREFIX="${2:-}"
      shift 2
      ;;
    --marketplace-source)
      MARKETPLACE_SOURCE="${2:-}"
      shift 2
      ;;
    --cache-root)
      EXTRA_CACHE_ROOTS+=("${2:-}")
      shift 2
      ;;
    --json)
      JSON_OUTPUT="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$MODE" in
  contract)
    run_contract_mode
    ;;
  top-level)
    run_top_level_mode
    ;;
  *)
    echo "Error: unsupported --mode: $MODE" >&2
    exit 1
    ;;
esac
