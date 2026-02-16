#!/usr/bin/env bash
# redact-session-logs.sh: sanitize existing Codex session log artifacts in place.
# Default target directory: resolve_cwf_session_logs_dir output
# (prefers ./.cwf/sessions, falls back to legacy ./.cwf/projects/sessions).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDACTOR_SCRIPT="$SCRIPT_DIR/redact-sensitive.pl"
JSON_REDACTOR_SCRIPT="$SCRIPT_DIR/redact-jsonl.sh"
RESOLVER_SCRIPT="$SCRIPT_DIR/../cwf-artifact-paths.sh"

if [ ! -f "$RESOLVER_SCRIPT" ]; then
  echo "Missing resolver script: $RESOLVER_SCRIPT" >&2
  exit 1
fi

# shellcheck source=../cwf-artifact-paths.sh
# shellcheck disable=SC1090,SC1091
source "$RESOLVER_SCRIPT"

DEFAULT_CWD="$(pwd)"
DEFAULT_TARGET_DIR="$(resolve_cwf_session_logs_dir "$DEFAULT_CWD")"
TARGET_DIR="${1:-$DEFAULT_TARGET_DIR}"

if [ ! -f "$REDACTOR_SCRIPT" ]; then
  echo "Missing redactor script: $REDACTOR_SCRIPT" >&2
  exit 1
fi

if [ ! -x "$JSON_REDACTOR_SCRIPT" ]; then
  echo "Missing JSONL redactor script: $JSON_REDACTOR_SCRIPT" >&2
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory not found: $TARGET_DIR" >&2
  exit 1
fi

if ! command -v perl >/dev/null 2>&1; then
  echo "perl is required for markdown redaction." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for JSONL redaction." >&2
  exit 1
fi

count=0
while IFS= read -r file; do
  if [[ "$file" == *.jsonl ]]; then
    "$JSON_REDACTOR_SCRIPT" "$file"
  else
    perl -i "$REDACTOR_SCRIPT" "$file"
  fi
  count=$((count + 1))
done < <(find "$TARGET_DIR" -type f \( -name "*.md" -o -name "*.jsonl" \) | sort)

echo "Redacted ${count} files under $TARGET_DIR"
