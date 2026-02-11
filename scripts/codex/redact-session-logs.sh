#!/usr/bin/env bash
# redact-session-logs.sh: sanitize existing Codex session log artifacts in place.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDACTOR_SCRIPT="$SCRIPT_DIR/redact-sensitive.pl"
JSON_REDACTOR_SCRIPT="$SCRIPT_DIR/redact-jsonl.sh"
TARGET_DIR="${1:-prompt-logs/sessions-codex}"

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
