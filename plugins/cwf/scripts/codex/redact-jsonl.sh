#!/usr/bin/env bash
# redact-jsonl.sh: redact sensitive strings inside JSONL records while preserving JSON validity.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEXT_REDACTOR="$SCRIPT_DIR/redact-sensitive.pl"

if [ "$#" -ne 1 ]; then
  echo "Usage: redact-jsonl.sh <file.jsonl>" >&2
  exit 1
fi

target_file="$1"
if [ ! -f "$target_file" ]; then
  echo "File not found: $target_file" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required." >&2
  exit 1
fi

tmp_file="$(mktemp)"
jq_err_file="$(mktemp)"
trap 'rm -f "$tmp_file" "$jq_err_file"' EXIT

if jq -c '
  def redact_string:
    gsub("tvly-[A-Za-z0-9._-]{8,}"; "tvly-REDACTED")
    | gsub("xox[baprs]-[A-Za-z0-9-]{8,}"; "xoxb-REDACTED")
    | gsub("sk-[A-Za-z0-9]{20,}"; "sk-REDACTED")
    | gsub("TAVILY_API_KEY\\s*=\\s*\"[^\"]*\""; "TAVILY_API_KEY=\"REDACTED\"")
    | gsub("EXA_API_KEY\\s*=\\s*\"[^\"]*\""; "EXA_API_KEY=\"REDACTED\"")
    | gsub("SLACK_BOT_TOKEN\\s*=\\s*\"[^\"]*\""; "SLACK_BOT_TOKEN=\"REDACTED\"")
    | gsub("OPENAI_API_KEY\\s*=\\s*\"[^\"]*\""; "OPENAI_API_KEY=\"REDACTED\"")
    | gsub("ANTHROPIC_API_KEY\\s*=\\s*\"[^\"]*\""; "ANTHROPIC_API_KEY=\"REDACTED\"")
    | gsub("GEMINI_API_KEY\\s*=\\s*\"[^\"]*\""; "GEMINI_API_KEY=\"REDACTED\"")
    | gsub("GOOGLE_API_KEY\\s*=\\s*\"[^\"]*\""; "GOOGLE_API_KEY=\"REDACTED\"")
    | gsub("GITHUB_TOKEN\\s*=\\s*\"[^\"]*\""; "GITHUB_TOKEN=\"REDACTED\"")
    | gsub("GH_TOKEN\\s*=\\s*\"[^\"]*\""; "GH_TOKEN=\"REDACTED\"")
    | gsub("AWS_ACCESS_KEY_ID\\s*=\\s*\"[^\"]*\""; "AWS_ACCESS_KEY_ID=\"REDACTED\"")
    | gsub("AWS_SECRET_ACCESS_KEY\\s*=\\s*\"[^\"]*\""; "AWS_SECRET_ACCESS_KEY=\"REDACTED\"")
    | gsub("Authorization:\\s*Bearer\\s+[A-Za-z0-9._-]{10,}"; "Authorization: Bearer REDACTED");

  def redact:
    if type == "string" then
      redact_string
    elif type == "array" then
      map(redact)
    elif type == "object" then
      with_entries(.value |= redact)
    else
      .
    end;

  redact
' "$target_file" > "$tmp_file" 2>"$jq_err_file"; then
  mv "$tmp_file" "$target_file"
else
  if command -v perl >/dev/null 2>&1 && [ -f "$TEXT_REDACTOR" ]; then
    perl -i "$TEXT_REDACTOR" "$target_file"
    echo "Warning: jq parse failed for $target_file; used text redaction fallback." >&2
  else
    cat "$jq_err_file" >&2
    echo "Failed to redact $target_file with jq, and perl fallback is unavailable." >&2
    exit 1
  fi
fi
