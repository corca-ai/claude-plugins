#!/bin/bash
# Tavily web search — called by the web-search skill
# Usage: search.sh [--topic news|finance] [--time-range day|week|month|year] [--deep] "<query>"
set -euo pipefail

# --- Parse arguments ---
TOPIC=""
TIME_RANGE=""
SEARCH_DEPTH="basic"
QUERY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic)      TOPIC="$2"; shift 2 ;;
    --time-range) TIME_RANGE="$2"; shift 2 ;;
    --deep)       SEARCH_DEPTH="advanced"; shift ;;
    *)            QUERY="$1"; shift ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "Error: No query provided." >&2
  echo "Usage: search.sh [--topic news|finance] [--time-range day|week|month|year] [--deep] \"<query>\"" >&2
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
  PAYLOAD=$(jq -n --arg q "$QUERY" '{query: $q, search_depth: "basic", max_results: 5, include_answer: true}')
  [ -n "$TOPIC" ] && PAYLOAD=$(echo "$PAYLOAD" | jq --arg t "$TOPIC" '. + {topic: $t}')
  [ -n "$TIME_RANGE" ] && PAYLOAD=$(echo "$PAYLOAD" | jq --arg tr "$TIME_RANGE" '. + {time_range: $tr}')
  if [ "$SEARCH_DEPTH" = "advanced" ]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq '. + {search_depth: "advanced", include_raw_content: "markdown"}')
  fi
else
  PAYLOAD=$(python3 -c "
import json, sys
p = {'query': sys.argv[1], 'search_depth': 'basic', 'max_results': 5, 'include_answer': True}
if sys.argv[2]: p['topic'] = sys.argv[2]
if sys.argv[3]: p['time_range'] = sys.argv[3]
if sys.argv[4] == 'advanced':
    p['search_depth'] = 'advanced'
    p['include_raw_content'] = 'markdown'
print(json.dumps(p))
" "$QUERY" "$TOPIC" "$TIME_RANGE" "$SEARCH_DEPTH")
fi

# --- Execute API call ---
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT INT TERM

HTTP_CODE=$(curl -s --max-time 30 --connect-timeout 10 \
  -X POST "https://api.tavily.com/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -d "$PAYLOAD" \
  -o "$TMPFILE" -w "%{http_code}")
CURL_EXIT=$?

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
  ANSWER=$(jq -r '.answer // empty' "$TMPFILE")

  echo "## Search Results: $QUERY"
  echo
  [ -n "$ANSWER" ] && echo "$ANSWER" && echo
  jq -r '[.results[] | {t: (.title // "Untitled"), c: (.content // ""), u: (.url // "")}] | to_entries[] | "### \(.key + 1). \(.value.t)\n\(.value.c)\n- URL: \(.value.u)\n"' "$TMPFILE"
  echo "---"
  echo "Sources:"
  jq -r '.results[] | "- [\(.title // "Untitled")](\(.url // ""))"' "$TMPFILE"
else
  python3 - "$TMPFILE" "$QUERY" <<'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except (json.JSONDecodeError, FileNotFoundError) as e:
    print(f"Error parsing response: {e}", file=sys.stderr)
    sys.exit(1)
print(f"## Search Results: {sys.argv[2]}")
print()
answer = data.get("answer")
if answer:
    print(answer + "\n")
for i, r in enumerate(data.get("results", []), 1):
    print(f"### {i}. {r.get('title', 'Untitled')}")
    print(r.get("content", ""))
    print(f"- URL: {r.get('url', '')}\n")
print("---")
print("Sources:")
for r in data.get("results", []):
    print(f"- [{r.get('title', 'Untitled')}]({r.get('url', '')})")
PYEOF
fi
