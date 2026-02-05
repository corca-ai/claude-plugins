#!/usr/bin/env bash
# check-consistency.sh: Validate plugin consistency for deployment.
# Checks plugin.json, marketplace.json, READMEs, and AI_NATIVE_PRODUCT_TEAM.md.
#
# Usage: check-consistency.sh <plugin-name> [--new]
# Output: JSON report with gaps array

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

PLUGIN_NAME="${1:-}"
IS_NEW=false
if [[ "${2:-}" == "--new" ]]; then
  IS_NEW=true
fi

if [[ -z "$PLUGIN_NAME" ]]; then
  echo '{"error": "Usage: check-consistency.sh <plugin-name> [--new]"}' >&2
  exit 1
fi

PLUGIN_DIR="$REPO_ROOT/plugins/$PLUGIN_NAME"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
README_EN="$REPO_ROOT/README.md"
README_KO="$REPO_ROOT/README.ko.md"
AI_NATIVE_EN="$REPO_ROOT/AI_NATIVE_PRODUCT_TEAM.md"

gaps=()

# --- 1. Plugin directory exists ---
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "{\"error\": \"Plugin directory not found: plugins/$PLUGIN_NAME/\"}"
  exit 1
fi

# --- 2. plugin.json exists and has version ---
plugin_json_version=""
if [[ -f "$PLUGIN_JSON" ]]; then
  if command -v jq &>/dev/null; then
    plugin_json_version=$(jq -r '.version // empty' "$PLUGIN_JSON")
  else
    plugin_json_version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$PLUGIN_JSON" | head -1)
  fi
  if [[ -z "$plugin_json_version" ]]; then
    gaps+=("plugin.json exists but has no version field")
  fi
else
  gaps+=("plugin.json not found at .claude-plugin/plugin.json")
fi

# --- 3. marketplace.json entry ---
marketplace_version=""
in_marketplace=false
if command -v jq &>/dev/null; then
  marketplace_entry=$(jq -r --arg name "$PLUGIN_NAME" '.plugins[] | select(.name == $name)' "$MARKETPLACE_JSON" 2>/dev/null || true)
  if [[ -n "$marketplace_entry" ]]; then
    in_marketplace=true
    marketplace_version=$(echo "$marketplace_entry" | jq -r '.version // empty' 2>/dev/null || true)
  fi
else
  if grep -q "\"name\": \"$PLUGIN_NAME\"" "$MARKETPLACE_JSON" 2>/dev/null; then
    in_marketplace=true
  fi
fi

# Detect new vs modified
detected_new=false
if [[ "$in_marketplace" == "false" ]]; then
  detected_new=true
fi

if [[ "$detected_new" == "true" && "$IS_NEW" == "false" ]]; then
  gaps+=("Plugin not found in marketplace.json — use --new flag or add entry")
fi

# Version match check (only for existing plugins)
version_match=false
if [[ "$in_marketplace" == "true" && -n "$plugin_json_version" ]]; then
  if [[ -n "$marketplace_version" && "$marketplace_version" != "$plugin_json_version" ]]; then
    gaps+=("marketplace.json version ($marketplace_version) does not match plugin.json ($plugin_json_version)")
  elif [[ -n "$marketplace_version" && "$marketplace_version" == "$plugin_json_version" ]]; then
    version_match=true
  fi
fi

# --- 4. README checks ---
readme_en_mentioned=false
if grep -qi "$PLUGIN_NAME" "$README_EN" 2>/dev/null; then
  readme_en_mentioned=true
else
  gaps+=("README.md does not mention $PLUGIN_NAME")
fi

readme_ko_mentioned=false
if grep -qi "$PLUGIN_NAME" "$README_KO" 2>/dev/null; then
  readme_ko_mentioned=true
else
  gaps+=("README.ko.md does not mention $PLUGIN_NAME")
fi

# --- 5. AI_NATIVE_PRODUCT_TEAM.md check (new plugins only) ---
ai_native_mentioned=false
if [[ "$detected_new" == "true" || "$IS_NEW" == "true" ]]; then
  if grep -qi "$PLUGIN_NAME" "$AI_NATIVE_EN" 2>/dev/null; then
    ai_native_mentioned=true
  fi
fi

# --- 6. Skill/Hook structure checks ---
has_skill=false
has_hooks=false
skill_md=""
hooks_json=""

if [[ -f "$PLUGIN_DIR/skills/$PLUGIN_NAME/SKILL.md" ]]; then
  has_skill=true
  skill_md="plugins/$PLUGIN_NAME/skills/$PLUGIN_NAME/SKILL.md"
fi

if [[ -f "$PLUGIN_DIR/hooks/hooks.json" ]]; then
  has_hooks=true
  hooks_json="plugins/$PLUGIN_NAME/hooks/hooks.json"
fi

if [[ "$has_skill" == "false" && "$has_hooks" == "false" ]]; then
  gaps+=("No SKILL.md or hooks.json found — plugin has no entry point")
fi

# --- 6b. SKILL.md size check (skill-type plugins) ---
skill_md_words=0
skill_md_severity="ok"
if [[ "$has_skill" == "true" && -n "$skill_md" ]]; then
  skill_md_full="$REPO_ROOT/$skill_md"
  if [[ -f "$skill_md_full" ]]; then
    skill_md_words=$(wc -w < "$skill_md_full" | tr -d ' ')
    if [[ "$skill_md_words" -gt 5000 ]]; then
      skill_md_severity="error"
      gaps+=("skill_md_large: SKILL.md is ${skill_md_words} words (>5000) — consider running /refactor-skill $PLUGIN_NAME")
    elif [[ "$skill_md_words" -gt 3000 ]]; then
      skill_md_severity="warning"
      gaps+=("skill_md_large: SKILL.md is ${skill_md_words} words (>3000) — consider running /refactor-skill $PLUGIN_NAME")
    fi
  fi
fi

# --- 7. Plugin type detection ---
plugin_type="unknown"
if [[ "$has_skill" == "true" && "$has_hooks" == "true" ]]; then
  plugin_type="hybrid"
elif [[ "$has_skill" == "true" ]]; then
  plugin_type="skill"
elif [[ "$has_hooks" == "true" ]]; then
  plugin_type="hook"
fi

# --- Output JSON ---
# Helper: output "value" or null for optional strings
json_str() { if [[ -n "$1" ]]; then echo "\"$1\""; else echo "null"; fi; }

gaps_json="["
for i in "${!gaps[@]}"; do
  if [[ $i -gt 0 ]]; then
    gaps_json+=","
  fi
  escaped="${gaps[$i]//\"/\\\"}"
  gaps_json+="\"$escaped\""
done
gaps_json+="]"

cat <<EOF
{
  "plugin_name": "$PLUGIN_NAME",
  "plugin_dir": "plugins/$PLUGIN_NAME/",
  "plugin_json_version": $(json_str "$plugin_json_version"),
  "marketplace_version": $(json_str "$marketplace_version"),
  "in_marketplace": $in_marketplace,
  "detected_new": $detected_new,
  "version_match": $version_match,
  "readme_en_mentioned": $readme_en_mentioned,
  "readme_ko_mentioned": $readme_ko_mentioned,
  "ai_native_mentioned": $ai_native_mentioned,
  "plugin_type": "$plugin_type",
  "has_skill": $has_skill,
  "has_hooks": $has_hooks,
  "skill_md": $(json_str "$skill_md"),
  "skill_md_words": $skill_md_words,
  "skill_md_severity": "$skill_md_severity",
  "hooks_json": $(json_str "$hooks_json"),
  "gap_count": ${#gaps[@]},
  "gaps": $gaps_json
}
EOF
