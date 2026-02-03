#!/usr/bin/env bash
# Update the corca-plugins marketplace and reinstall all installed plugins.
# Usage: bash scripts/update-all.sh

set -euo pipefail

MARKETPLACE="corca-plugins"
SETTINGS_FILE="${HOME}/.claude/settings.json"

# --- helpers ---------------------------------------------------------------

# Extract plugin names that end with @corca-plugins from settings.json
extract_plugins() {
  if command -v jq &>/dev/null; then
    jq -r '.enabledPlugins // {} | keys[] | select(endswith("@'"${MARKETPLACE}"'")) | split("@")[0]' "$SETTINGS_FILE"
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
data = json.load(open('${SETTINGS_FILE}'))
for key in data.get('enabledPlugins', {}):
    if key.endswith('@${MARKETPLACE}'):
        print(key.split('@')[0])
"
  else
    grep -oP '"([^"]+)@'"${MARKETPLACE}"'"' "$SETTINGS_FILE" | tr -d '"' | sed 's/@'"${MARKETPLACE}"'//'
  fi
}

# --- main ------------------------------------------------------------------

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Error: $SETTINGS_FILE not found." >&2
  exit 1
fi

echo "==> Updating marketplace: ${MARKETPLACE}"
claude plugin marketplace update "$MARKETPLACE"
echo ""

plugins=$(extract_plugins | sort)

if [[ -z "$plugins" ]]; then
  echo "No ${MARKETPLACE} plugins found in ${SETTINGS_FILE}."
  exit 0
fi

count=$(echo "$plugins" | wc -l)
echo "==> Found ${count} installed plugin(s). Updating..."
echo ""

success=0
fail=0

for plugin in $plugins; do
  echo "--- ${plugin}@${MARKETPLACE}"
  if claude plugin install "${plugin}@${MARKETPLACE}"; then
    success=$((success + 1))
  else
    fail=$((fail + 1))
  fi
  echo ""
done

echo "==> Done. ${success} updated, ${fail} failed."
echo "Restart Claude Code for changes to take effect."
