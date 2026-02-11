#!/usr/bin/env bash
# Exa code context search — called by the gather-context skill
# Usage: code-search.sh [--tokens NUM] "<query>"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../hooks/scripts/env-loader.sh
source "$SCRIPT_DIR/../../../hooks/scripts/env-loader.sh"

# --- Parse arguments ---
TOKENS_NUM=5000
QUERY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tokens)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "Error: --tokens requires a numeric value." >&2; exit 1
      fi
      TOKENS_NUM="$2"; shift 2 ;;
    *)  QUERY="$1"; shift ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "Error: No query provided." >&2
  echo "Usage: code-search.sh [--tokens NUM] \"<query>\"" >&2
  exit 1
fi

# --- Load API key: shell env -> shell profiles -> legacy ~/.claude/.env ---
cwf_env_load_vars EXA_API_KEY

if [ -z "${EXA_API_KEY:-}" ]; then
  cat >&2 <<'MSG'
Error: EXA_API_KEY is not set.

Get your API key: https://dashboard.exa.ai/api-keys

Then add to your shell profile (~/.zshrc or ~/.bashrc):
  export EXA_API_KEY="your-key-here"

Legacy fallback is also supported:
  ~/.claude/.env
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
  PAYLOAD=$(jq -n --arg q "$QUERY" --argjson t "$TOKENS_NUM" '{query: $q, tokensNum: $t}')
else
  PAYLOAD=$(python3 -c "
import json, sys
print(json.dumps({'query': sys.argv[1], 'tokensNum': int(sys.argv[2])}))
" "$QUERY" "$TOKENS_NUM")
fi

# --- Execute API call ---
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT INT TERM

set +e
HTTP_CODE=$(curl -s --max-time 30 --connect-timeout 10 \
  -X POST "https://api.exa.ai/context" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $EXA_API_KEY" \
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
  echo "Error: API key is invalid. Check your EXA_API_KEY." >&2
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
  echo "## Code Context: $QUERY"
  echo
  echo "*Source: Exa Code Context API (GitHub, Stack Overflow, docs)*"
  echo
  jq -r '.response // "No results"' "$TMPFILE"
else
  python3 - "$TMPFILE" "$QUERY" <<'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except (json.JSONDecodeError, FileNotFoundError) as e:
    print(f"Error parsing response: {e}", file=sys.stderr)
    sys.exit(1)
print(f"## Code Context: {sys.argv[2]}")
print()
print("*Source: Exa Code Context API (GitHub, Stack Overflow, docs)*")
print()
print(data.get("response", "No results"))
PYEOF
fi
