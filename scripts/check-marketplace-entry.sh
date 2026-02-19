#!/usr/bin/env bash
set -euo pipefail

# check-marketplace-entry.sh — verify that a plugin entry exists in marketplace metadata.
#
# Usage:
#   check-marketplace-entry.sh --source <path-or-url> --plugin <name> [--alias <name>] [--json]
#   check-marketplace-entry.sh <path-or-url> <name> [alias...]
#
# Exit codes:
#   0 = FOUND
#   1 = usage/dependency error
#   2 = LOOKUP_FAILED (network/file/HTTP access issue)
#   3 = INVALID_MARKETPLACE (JSON/schema shape issue)
#   4 = MISSING_ENTRY

usage() {
  cat <<'USAGE'
check-marketplace-entry.sh — verify marketplace plugin entry presence

Usage:
  check-marketplace-entry.sh --source <path-or-url> --plugin <name> [--alias <name>] [--json]
  check-marketplace-entry.sh <path-or-url> <name> [alias...]

Options:
  --source <value>  Marketplace source path, repository root, or HTTP(S) URL
  --plugin <name>   Primary plugin name to verify (required)
  --alias <name>    Additional accepted plugin alias (repeatable)
  --json            Print machine-readable JSON result
  -h, --help        Show this message
USAGE
}

SOURCE=""
PLUGIN=""
JSON_OUTPUT="false"
declare -a ALIASES=()
declare -a POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --source requires a value." >&2
        exit 1
      fi
      SOURCE="$2"
      shift 2
      ;;
    --plugin)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --plugin requires a value." >&2
        exit 1
      fi
      PLUGIN="$2"
      shift 2
      ;;
    --alias)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --alias requires a value." >&2
        exit 1
      fi
      ALIASES+=("$2")
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
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$SOURCE" ]] && [[ "${#POSITIONAL[@]}" -gt 0 ]]; then
  SOURCE="${POSITIONAL[0]}"
fi
if [[ -z "$PLUGIN" ]] && [[ "${#POSITIONAL[@]}" -gt 1 ]]; then
  PLUGIN="${POSITIONAL[1]}"
fi
if [[ "${#POSITIONAL[@]}" -gt 2 ]]; then
  for alias in "${POSITIONAL[@]:2}"; do
    ALIASES+=("$alias")
  done
fi

if [[ -z "$SOURCE" ]] || [[ -z "$PLUGIN" ]]; then
  usage >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  exit 1
fi

TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/marketplace-entry-XXXXXX.json")"
# shellcheck disable=SC2317
cleanup() {
  rm -f "$TMP_FILE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

SOURCE_PATH=""
SOURCE_KIND=""

resolve_local_marketplace_path() {
  local source_value="$1"

  if [[ -f "$source_value" ]]; then
    SOURCE_PATH="$source_value"
    return 0
  fi

  if [[ -d "$source_value" ]]; then
    if [[ -f "$source_value/.claude-plugin/marketplace.json" ]]; then
      SOURCE_PATH="$source_value/.claude-plugin/marketplace.json"
      return 0
    fi
    if [[ -f "$source_value/marketplace.json" ]]; then
      SOURCE_PATH="$source_value/marketplace.json"
      return 0
    fi
  fi

  return 1
}

print_result() {
  local status="$1"
  local code="$2"
  local message="$3"
  local resolved_source="$4"
  local candidates_json="$5"

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq -n \
      --arg status "$status" \
      --arg message "$message" \
      --arg source "$resolved_source" \
      --arg plugin "$PLUGIN" \
      --argjson aliases "$candidates_json" \
      --argjson exit_code "$code" \
      '{status:$status, exit_code:$exit_code, source:$source, plugin:$plugin, candidates:$aliases, message:$message}'
  else
    echo "status=$status"
    echo "source=$resolved_source"
    echo "plugin=$PLUGIN"
    echo "message=$message"
  fi
}

if [[ "$SOURCE" =~ ^https?:// ]]; then
  SOURCE_KIND="url"
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for URL source." >&2
    exit 1
  fi
  set +e
  HTTP_CODE="$(curl -sS -L --connect-timeout 10 --max-time 45 -o "$TMP_FILE" -w "%{http_code}" "$SOURCE")"
  CURL_EXIT=$?
  set -e
  if [[ "$CURL_EXIT" -ne 0 ]]; then
    print_result "LOOKUP_FAILED" 2 "Failed to fetch marketplace URL (curl exit: $CURL_EXIT)." "$SOURCE" "[]"
    exit 2
  fi
  if [[ ! "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
    print_result "LOOKUP_FAILED" 2 "Marketplace URL responded with HTTP $HTTP_CODE." "$SOURCE" "[]"
    exit 2
  fi
else
  SOURCE_KIND="local"
  if ! resolve_local_marketplace_path "$SOURCE"; then
    print_result "LOOKUP_FAILED" 2 "Marketplace file not found from source path." "$SOURCE" "[]"
    exit 2
  fi
  cp "$SOURCE_PATH" "$TMP_FILE"
fi

if ! jq -e '.plugins and (.plugins | type == "array")' "$TMP_FILE" >/dev/null 2>&1; then
  if [[ "$SOURCE_KIND" == "local" ]]; then
    print_result "INVALID_MARKETPLACE" 3 "Marketplace JSON missing required plugins[] array." "$SOURCE_PATH" "[]"
  else
    print_result "INVALID_MARKETPLACE" 3 "Marketplace JSON missing required plugins[] array." "$SOURCE" "[]"
  fi
  exit 3
fi

declare -a CANDIDATES=()

add_candidate() {
  local raw="$1"
  local normalized
  local existing

  normalized="$(echo "$raw" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$normalized" ]]; then
    return
  fi

  for existing in "${CANDIDATES[@]}"; do
    if [[ "$existing" == "$normalized" ]]; then
      return
    fi
  done

  CANDIDATES+=("$normalized")
}

add_candidate "$PLUGIN"
if [[ "${#ALIASES[@]}" -gt 0 ]]; then
  for alias in "${ALIASES[@]}"; do
    add_candidate "$alias"
  done
fi

CANDIDATES_JSON="$(printf '%s\n' "${CANDIDATES[@]}" | jq -R . | jq -s .)"

set +e
jq -e --argjson candidates "$CANDIDATES_JSON" '
  any(.plugins[]?;
    (.name // "" | ascii_downcase) as $name |
    (.source // "" | ascii_downcase) as $source |
    any($candidates[];
      . == $name
      or $source == ("./plugins/" + .)
      or $source == ("plugins/" + .)
      or ($source | endswith("/plugins/" + .))
      or ($source | endswith("/" + .))
    )
  )
' "$TMP_FILE" >/dev/null 2>&1
MATCH_EXIT=$?
set -e

if [[ "$MATCH_EXIT" -eq 0 ]]; then
  if [[ "$SOURCE_KIND" == "local" ]]; then
    print_result "FOUND" 0 "Marketplace entry found." "$SOURCE_PATH" "$CANDIDATES_JSON"
  else
    print_result "FOUND" 0 "Marketplace entry found." "$SOURCE" "$CANDIDATES_JSON"
  fi
  exit 0
fi

if [[ "$SOURCE_KIND" == "local" ]]; then
  print_result "MISSING_ENTRY" 4 "Marketplace entry not found for requested plugin/aliases." "$SOURCE_PATH" "$CANDIDATES_JSON"
else
  print_result "MISSING_ENTRY" 4 "Marketplace entry not found for requested plugin/aliases." "$SOURCE" "$CANDIDATES_JSON"
fi
exit 4
