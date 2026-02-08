#!/usr/bin/env bash
# update-all.sh: Update the CWF plugin to the latest version.
# Usage: bash scripts/update-all.sh

set -euo pipefail

MARKETPLACE="corca-plugins"
PLUGIN="cwf"
SETTINGS_FILE="${HOME}/.claude/settings.json"

# --- helpers ---------------------------------------------------------------

# Check if cwf plugin is installed in settings.json
is_cwf_installed() {
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    return 1
  fi

  local target="${PLUGIN}@${MARKETPLACE}"

  if command -v jq &>/dev/null; then
    jq -e --arg t "$target" '.enabledPlugins // {} | has($t)' "$SETTINGS_FILE" >/dev/null 2>&1
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
data = json.load(open('${SETTINGS_FILE}'))
sys.exit(0 if '${target}' in data.get('enabledPlugins', {}) else 1)
"
  else
    grep -q "\"${target}\"" "$SETTINGS_FILE" 2>/dev/null
  fi
}

# --- main ------------------------------------------------------------------

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Error: $SETTINGS_FILE not found." >&2
  exit 1
fi

# Warn if not on main branch (marketplace update pulls from default branch)
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [[ -n "$current_branch" && "$current_branch" != "main" && "$current_branch" != "master" ]]; then
  echo "WARNING: Current branch is '$current_branch', not main."
  echo "  Marketplace update pulls from the default branch -- local changes on this branch won't be reflected."
  echo "  Merge to main first, or press Enter to continue anyway."
  if [[ -t 0 ]]; then
    read -r
  else
    echo "  (non-interactive shell -- continuing automatically)"
  fi
fi

echo "==> Updating marketplace: ${MARKETPLACE}"
claude plugin marketplace update "$MARKETPLACE"
echo ""

if ! is_cwf_installed; then
  echo "CWF plugin is not installed."
  echo "Run: bash scripts/install.sh"
  exit 0
fi

echo "==> Updating ${PLUGIN}@${MARKETPLACE}"
if claude plugin install "${PLUGIN}@${MARKETPLACE}"; then
  echo ""
  echo "==> Success. Restart Claude Code for changes to take effect."
else
  echo ""
  echo "==> Update failed." >&2
  exit 1
fi
