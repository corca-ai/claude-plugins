#!/usr/bin/env bash
set -euo pipefail

# dogfood.sh — Sync CWF plugin source to local Claude Code cache.
#
# Removes old standalone corca-plugins entries and installs CWF
# as if it were a marketplace-installed plugin. Run this after
# modifying CWF source to reflect changes in the next session.
#
# Usage:
#   bash scripts/dogfood.sh          # from repo root
#   bash scripts/dogfood.sh --clean  # also remove .bak local skills

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CWF_SOURCE="$REPO_ROOT/plugins/cwf"
INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"
CACHE_BASE="$HOME/.claude/plugins/cache/corca-plugins"

# Read CWF version from plugin.json
CWF_VERSION=$(python3 -c "import json; print(json.load(open('$CWF_SOURCE/.claude-plugin/plugin.json'))['version'])")
CWF_CACHE="$CACHE_BASE/cwf/$CWF_VERSION"

echo "=== CWF Dogfood Sync ==="
echo "Source:  $CWF_SOURCE"
echo "Version: $CWF_VERSION"
echo "Cache:   $CWF_CACHE"
echo ""

# --- Step 1: Remove old standalone corca-plugins from installed_plugins.json ---
STANDALONE_PLUGINS=(
    "clarify@corca-plugins"
    "retro@corca-plugins"
    "refactor@corca-plugins"
    "gather-context@corca-plugins"
    "attention-hook@corca-plugins"
    "smart-read@corca-plugins"
    "prompt-logger@corca-plugins"
    "markdown-guard@corca-plugins"
    "plan-and-lessons@corca-plugins"
)

if [ -f "$INSTALLED_JSON" ]; then
    echo "Removing standalone plugin entries..."
    TEMP_JSON=$(mktemp)
    python3 << PYEOF
import json

standalone = [
    "clarify@corca-plugins", "retro@corca-plugins", "refactor@corca-plugins",
    "gather-context@corca-plugins", "attention-hook@corca-plugins",
    "smart-read@corca-plugins", "prompt-logger@corca-plugins",
    "markdown-guard@corca-plugins", "plan-and-lessons@corca-plugins"
]

with open("$INSTALLED_JSON") as f:
    data = json.load(f)

removed = []
for key in list(data.get("plugins", {}).keys()):
    if key in standalone:
        del data["plugins"][key]
        removed.append(key)

with open("$TEMP_JSON", "w") as f:
    json.dump(data, f, indent=4)

for r in removed:
    print(f"  Removed: {r}")
if not removed:
    print("  (none to remove)")
PYEOF
    mv "$TEMP_JSON" "$INSTALLED_JSON"
fi

# --- Step 2: Remove old standalone cache directories ---
echo ""
echo "Cleaning standalone caches..."
for plugin in clarify retro refactor gather-context attention-hook smart-read prompt-logger markdown-guard plan-and-lessons; do
    if [ -d "$CACHE_BASE/$plugin" ]; then
        rm -rf "$CACHE_BASE/$plugin"
        echo "  Removed: $CACHE_BASE/$plugin"
    fi
done

# --- Step 3: Create/update CWF cache ---
echo ""
echo "Syncing CWF to cache..."
mkdir -p "$CWF_CACHE"
rsync -a --delete "$CWF_SOURCE/" "$CWF_CACHE/"
echo "  Synced: $(find "$CWF_CACHE" -type f | wc -l) files"

# --- Step 4: Register CWF in installed_plugins.json ---
echo ""
echo "Registering cwf@corca-plugins..."
python3 -c "
import json
from datetime import datetime, timezone

with open('$INSTALLED_JSON') as f:
    data = json.load(f)

now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')
data['plugins']['cwf@corca-plugins'] = [{
    'scope': 'user',
    'installPath': '$CWF_CACHE',
    'version': '$CWF_VERSION',
    'installedAt': now,
    'lastUpdated': now,
    'gitCommitSha': '$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "local")'
}]

with open('$INSTALLED_JSON', 'w') as f:
    json.dump(data, f, indent=4)

print('  Registered: cwf@corca-plugins v$CWF_VERSION')
"

# --- Step 5: Optional cleanup ---
if [[ "${1:-}" == "--clean" ]]; then
    echo ""
    echo "Cleaning .bak local skills..."
    for bak in "$REPO_ROOT/.claude/skills/"*.bak; do
        if [ -d "$bak" ]; then
            rm -rf "$bak"
            echo "  Removed: $(basename "$bak")"
        fi
    done
fi

echo ""
echo "Done. Restart Claude Code to pick up changes."
echo ""
echo "CWF skills available after restart:"
for skill_dir in "$CWF_CACHE/skills"/*/; do
    if [ -f "$skill_dir/SKILL.md" ]; then
        echo "  cwf:$(basename "$skill_dir")"
    fi
done
