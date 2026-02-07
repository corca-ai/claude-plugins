#!/bin/bash
# Tavily URL content extraction — called by the gather-context skill
# Usage: extract.sh "<url>" [--query "<relevance_query>"]
set -euo pipefail

# --- Parse arguments ---
URL=""
EXTRACT_QUERY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "Error: --query requires a value." >&2; exit 1
      fi
      EXTRACT_QUERY="$2"; shift 2 ;;
    *)  URL="$1"; shift ;;
  esac
done

if [ -z "$URL" ]; then
  echo "Error: No URL provided." >&2
  echo "Usage: extract.sh \"<url>\" [--query \"<relevance_query>\"]" >&2
  exit 1
fi

# --- Validate URL ---
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Error: Invalid URL. Must start with http:// or https://" >&2
  echo "Did you mean: /gather-context --search $URL?" >&2
  exit 1
fi

# --- Load API key: shell env → ~/.claude/.env → shell profiles ---
[ -z "${TAVILY_API_KEY:-}" ] && [ -f ~/.claude/.env ] && source ~/.claude/.env 2>/dev/null
[ -z "${TAVILY_API_KEY:-}" ] && eval "$(grep -sh '^export TAVILY_API_KEY=' ~/.zshenv ~/.zshrc ~/.bashrc ~/.bash_profile ~/.profile 2>/dev/null | head -1)"

if [ -z "${TAVILY_API_KEY:-}" ]; then
  cat >&2 <<'MSG'
Error: TAVILY_API_KEY is not set.

Get your API key: https://app.tavily.com/home

Then add to your shell profile:
  export TAVILY_API_KEY="your-key-here"
MSG
  exit 1
fi

# --- Detect JSON builder ---
if command -v jq &>/dev/null; then
  JSON_TOOL="jq"
else
  JSON_TOOL="python3"
fi

# --- Build payload ---
if [ "$JSON_TOOL" = "jq" ]; then
  PAYLOAD=$(jq -n --arg u "$URL" '{urls: [$u], extract_depth: "basic", format: "markdown"}')
  [ -n "$EXTRACT_QUERY" ] && PAYLOAD=$(echo "$PAYLOAD" | jq --arg q "$EXTRACT_QUERY" '. + {query: $q}')
else
  PAYLOAD=$(python3 -c "
import json, sys
p = {'urls': [sys.argv[1]], 'extract_depth': 'basic', 'format': 'markdown'}
if sys.argv[2]: p['query'] = sys.argv[2]
print(json.dumps(p))
" "$URL" "$EXTRACT_QUERY")
fi

# --- Execute API call ---
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT INT TERM

set +e
HTTP_CODE=$(curl -s --max-time 30 --connect-timeout 10 \
  -X POST "https://api.tavily.com/extract" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -d "$PAYLOAD" \
  -o "$TMPFILE" -w "%{http_code}")
CURL_EXIT=$?
set -e

# --- Check errors ---
if [ "$CURL_EXIT" -ne 0 ] || [ "$HTTP_CODE" = "000" ]; then
  echo "Error: Connection failed. Check your network." >&2
  exit 1
fi

if [ "$HTTP_CODE" = "401" ]; then
  echo "Error: API key is invalid. Check your TAVILY_API_KEY." >&2
  exit 1
elif [ "$HTTP_CODE" = "429" ]; then
  echo "Error: Rate limit exceeded. Please wait and retry." >&2
  exit 1
elif [ "$HTTP_CODE" != "200" ]; then
  echo "Error: Request failed (HTTP $HTTP_CODE)." >&2
  exit 1
fi

# --- Parse and format ---
if [ "$JSON_TOOL" = "jq" ]; then
  CONTENT=$(jq -r '.results[0].raw_content // empty' "$TMPFILE")
  if [ -n "$CONTENT" ]; then
    echo "## Extracted: $URL"
    echo
    echo "$CONTENT"
  else
    FAILED=$(jq -r '.failed_results // empty' "$TMPFILE")
    echo "Error: Extraction failed." >&2
    [ -n "$FAILED" ] && echo "Details: $FAILED" >&2
    exit 1
  fi
else
  python3 - "$TMPFILE" "$URL" <<'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except (json.JSONDecodeError, FileNotFoundError) as e:
    print(f"Error parsing response: {e}", file=sys.stderr)
    sys.exit(1)
results = data.get("results", [])
if results:
    print(f"## Extracted: {sys.argv[2]}")
    print()
    print(results[0].get("raw_content", "No content"))
else:
    failed = data.get("failed_results", [])
    msg = "Extraction failed"
    if failed:
        msg += f": {failed}"
    print(msg, file=sys.stderr)
    sys.exit(1)
PYEOF
fi
