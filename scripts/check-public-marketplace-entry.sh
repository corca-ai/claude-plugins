#!/usr/bin/env bash
set -euo pipefail

# check-public-marketplace-entry.sh — verify plugin entry in public GitHub marketplace file.
#
# Exit codes:
#   same as scripts/check-marketplace-entry.sh

usage() {
  cat <<'USAGE'
check-public-marketplace-entry.sh — check plugin entry in public GitHub marketplace JSON

Usage:
  check-public-marketplace-entry.sh [options]

Options:
  --repo <owner/name>   GitHub repository (default: corca-ai/claude-plugins)
  --ref <git-ref>       Branch or tag name (default: main)
  --plugin <name>       Plugin name to verify (default: cwf)
  --alias <name>        Additional alias accepted by entry checker (repeatable)
  --json                Print JSON output from checker
  -h, --help            Show this message
USAGE
}

REPO="corca-ai/claude-plugins"
REF="main"
PLUGIN="cwf"
JSON_OUTPUT="false"
declare -a ALIASES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    --plugin)
      PLUGIN="${2:-}"
      shift 2
      ;;
    --alias)
      ALIASES+=("${2:-}")
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

if [[ -z "$REPO" ]] || [[ -z "$REF" ]] || [[ -z "$PLUGIN" ]]; then
  echo "Error: repo/ref/plugin must not be empty." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTRY_CHECKER="$SCRIPT_DIR/check-marketplace-entry.sh"
if [[ ! -x "$ENTRY_CHECKER" ]]; then
  echo "Error: checker not found or not executable: $ENTRY_CHECKER" >&2
  exit 1
fi

URL="https://raw.githubusercontent.com/${REPO}/${REF}/.claude-plugin/marketplace.json"

declare -a CHECK_ARGS=(--source "$URL" --plugin "$PLUGIN")
if [[ "${#ALIASES[@]}" -gt 0 ]]; then
  for alias in "${ALIASES[@]}"; do
    CHECK_ARGS+=(--alias "$alias")
  done
fi
if [[ "$JSON_OUTPUT" == "true" ]]; then
  CHECK_ARGS+=(--json)
fi

bash "$ENTRY_CHECKER" "${CHECK_ARGS[@]}"
