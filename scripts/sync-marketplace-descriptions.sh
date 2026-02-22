#!/usr/bin/env bash
set -euo pipefail

# sync-marketplace-descriptions.sh — keep marketplace and plugin descriptions aligned
#
# Source of truth: plugins/<name>/.claude-plugin/plugin.json -> .claude-plugin/marketplace.json
#
# Usage:
#   sync-marketplace-descriptions.sh [--check] [--plugin <name>]...
#
# Exit codes:
#   0 = aligned (or updated successfully)
#   1 = mismatch in --check mode, missing dependencies/files, or invalid metadata

usage() {
  cat <<'USAGE'
sync-marketplace-descriptions.sh — sync marketplace descriptions from plugin manifests

Usage:
  sync-marketplace-descriptions.sh [--check] [--plugin <name>]...

Options:
  --check          Verify-only mode (no file writes)
  --plugin <name>  Restrict to one plugin (repeatable)
  -h, --help       Show this message
USAGE
}

CHECK_ONLY="false"
declare -a TARGET_PLUGINS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY="true"
      shift
      ;;
    --plugin)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --plugin requires a value" >&2
        exit 1
      fi
      TARGET_PLUGINS+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required" >&2
  exit 1
fi

if [[ ! -f "$MARKETPLACE_JSON" ]]; then
  echo "Error: marketplace file not found: $MARKETPLACE_JSON" >&2
  exit 1
fi

if [[ "${#TARGET_PLUGINS[@]}" -eq 0 ]]; then
  while IFS= read -r plugin_name; do
    TARGET_PLUGINS+=("$plugin_name")
  done < <(jq -r '.plugins[].name' "$MARKETPLACE_JSON")
fi

if [[ "${#TARGET_PLUGINS[@]}" -eq 0 ]]; then
  echo "No plugins found in marketplace.json" >&2
  exit 0
fi

declare -a CHANGED=()
declare -a MISMATCH=()

for plugin in "${TARGET_PLUGINS[@]}"; do
  plugin_json="$REPO_ROOT/plugins/$plugin/.claude-plugin/plugin.json"

  if [[ ! -f "$plugin_json" ]]; then
    echo "Error: plugin manifest missing for '$plugin': $plugin_json" >&2
    exit 1
  fi

  plugin_desc="$(jq -r '.description // empty' "$plugin_json")"
  if [[ -z "$plugin_desc" ]]; then
    echo "Error: empty description in $plugin_json" >&2
    exit 1
  fi

  entry_exists="$(jq -r --arg name "$plugin" '[.plugins[] | select(.name == $name)] | length' "$MARKETPLACE_JSON")"
  if [[ "$entry_exists" == "0" ]]; then
    # Not a sync target yet (e.g. plugin under development not listed in marketplace).
    continue
  fi

  marketplace_desc="$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .description // empty' "$MARKETPLACE_JSON")"
  if [[ "$plugin_desc" == "$marketplace_desc" ]]; then
    continue
  fi

  if [[ "$CHECK_ONLY" == "true" ]]; then
    MISMATCH+=("$plugin")
    continue
  fi

  tmp_file="$(mktemp "$MARKETPLACE_JSON.tmp.XXXXXX")"
  jq --indent 2 --arg name "$plugin" --arg desc "$plugin_desc" \
    '(.plugins[] | select(.name == $name) | .description) = $desc' \
    "$MARKETPLACE_JSON" > "$tmp_file"
  mv "$tmp_file" "$MARKETPLACE_JSON"
  CHANGED+=("$plugin")
done

if [[ "$CHECK_ONLY" == "true" ]]; then
  if [[ "${#MISMATCH[@]}" -gt 0 ]]; then
    printf 'Description mismatch: %s\n' "${MISMATCH[*]}" >&2
    exit 1
  fi
  echo "Description sync check passed."
  exit 0
fi

if [[ "${#CHANGED[@]}" -gt 0 ]]; then
  printf 'Updated marketplace descriptions: %s\n' "${CHANGED[*]}"
else
  echo "Marketplace descriptions already aligned."
fi
