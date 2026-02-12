#!/usr/bin/env bash
set -euo pipefail

# check-links.sh — Check for broken links in Markdown documentation
# Usage: check-links.sh [--local] [--json] [--file PATH] [-h|--help]
#   --local      Skip external URLs; only check internal file refs and anchors
#   --json       Output machine-readable JSON format
#   --file PATH  Check a single file instead of all .md files
#   -h|--help    Show this usage message
# Exit 0 = no broken links, Exit 1 = broken links found

usage() {
  sed -n '3,10p' "$0" | sed 's/^# \?//'
  exit 0
}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOCAL_ONLY=false
JSON_OUTPUT=false
SINGLE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --local)
      LOCAL_ONLY=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --file)
      SINGLE_FILE="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
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

# Dependency check
if ! command -v lychee &>/dev/null; then
  echo "Error: lychee is not installed." >&2
  echo "Install via: cargo install lychee" >&2
  echo "  or: brew install lychee" >&2
  echo "  or: https://github.com/lycheeverse/lychee#installation" >&2
  exit 1
fi

cd "$REPO_ROOT"

# Build lychee arguments
LYCHEE_ARGS=("--config" ".lychee.toml")

if [[ "$LOCAL_ONLY" == "true" ]]; then
  LYCHEE_ARGS+=("--offline")
fi

if [[ "$JSON_OUTPUT" == "true" ]]; then
  LYCHEE_ARGS+=("--format" "json")
fi

# Target: single file or all .md files
if [[ -n "$SINGLE_FILE" ]]; then
  LYCHEE_ARGS+=("$SINGLE_FILE")
else
  LYCHEE_ARGS+=("**/*.md")
fi

echo -e "${GREEN}Running link check...${NC}" >&2
if [[ "$LOCAL_ONLY" == "true" ]]; then
  echo -e "${YELLOW}Mode: local only (skipping external URLs)${NC}" >&2
fi

# Run lychee — exit code 0 = no broken links, non-zero = broken links found
if lychee "${LYCHEE_ARGS[@]}"; then
  echo -e "${GREEN}All links are valid.${NC}" >&2
  exit 0
else
  EXIT_CODE=$?
  echo -e "${RED}Broken links detected.${NC}" >&2
  exit "$EXIT_CODE"
fi
