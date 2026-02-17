#!/usr/bin/env bash
set -euo pipefail

# check-script-deps.sh — validate runtime script dependency edges.
#
# Detects references to plugin scripts from:
# - hooks manifest commands (plugins/cwf/hooks/hooks.json)
# - shell hook/setup scripts and tracked pre-push hook templates
#
# Usage:
#   check-script-deps.sh [--strict] [-h|--help]

usage() {
  cat <<'USAGE'
check-script-deps.sh — validate runtime script dependency edges

Usage:
  check-script-deps.sh [--strict]

Options:
  --strict   Exit non-zero when broken edges exist.
  -h, --help Show this message.
USAGE
}

STRICT="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if ! command -v jq >/dev/null 2>&1; then
  echo "[FAIL] jq is required" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EDGE_FILE="$TMP_DIR/edges.tsv"
BROKEN_FILE="$TMP_DIR/broken.tsv"
: > "$EDGE_FILE"
: > "$BROKEN_FILE"

normalize_ref() {
  local source_file="$1"
  local ref="$2"
  local source_dir=""

  ref="${ref//\$\{CWF_PLUGIN_DIR\}/plugins/cwf}"
  ref="${ref//\$CWF_PLUGIN_DIR/plugins/cwf}"
  ref="${ref//\$\{CLAUDE_PLUGIN_ROOT\}/plugins/cwf}"
  ref="${ref//\$CLAUDE_PLUGIN_ROOT/plugins/cwf}"
  ref="${ref//\$\{PLUGIN_ROOT\}/plugins/cwf}"
  ref="${ref//\$PLUGIN_ROOT/plugins/cwf}"

  if [[ -n "$source_file" ]]; then
    source_dir="$(dirname "$source_file")"
    ref="${ref//\$\{SCRIPT_DIR\}/$source_dir}"
    ref="${ref//\$SCRIPT_DIR/$source_dir}"
    if [[ "$ref" == ./* || "$ref" == ../* ]]; then
      ref="$source_dir/$ref"
    fi
  fi

  if [[ "$ref" == "$REPO_ROOT/"* ]]; then
    ref="${ref#"$REPO_ROOT"/}"
  fi
  printf '%s\n' "$ref"
}

record_edge() {
  local source_file="$1"
  local raw_ref="$2"
  local require_exec="${3:-false}"
  local normalized=""
  local reason=""

  normalized="$(normalize_ref "$source_file" "$raw_ref")"
  if [[ "$normalized" != plugins/cwf/* ]]; then
    return 0
  fi

  printf '%s\t%s\n' "$source_file" "$normalized" >> "$EDGE_FILE"

  if [[ ! -f "$normalized" ]]; then
    reason="missing"
  elif [[ "$require_exec" == "true" && "$normalized" == *.sh && ! -x "$normalized" ]]; then
    reason="not_executable"
  fi

  if [[ -n "$reason" ]]; then
    printf '%s\t%s\t%s\n' "$source_file" "$normalized" "$reason" >> "$BROKEN_FILE"
  fi
}

extract_edges_from_hooks_manifest() {
  local manifest="plugins/cwf/hooks/hooks.json"
  local command_line=""
  local first_token=""

  [[ -f "$manifest" ]] || return 0

  while IFS= read -r command_line; do
    [[ -n "$command_line" ]] || continue
    first_token="${command_line%% *}"
    record_edge "$manifest" "$first_token" "true"
  done < <(jq -r '.hooks | to_entries[].value[]?.hooks[]?.command // empty' "$manifest")
}

extract_edges_from_script_text() {
  local source_file=""
  local match=""
  # shellcheck disable=SC2016
  local ref_pattern='(plugins/cwf|\$\{CWF_PLUGIN_DIR\}|\$CWF_PLUGIN_DIR|\$\{CLAUDE_PLUGIN_ROOT\}|\$CLAUDE_PLUGIN_ROOT|\$\{PLUGIN_ROOT\}|\$PLUGIN_ROOT|\$\{SCRIPT_DIR\}|\$SCRIPT_DIR)/[A-Za-z0-9._/-]+\.(sh|pl)'

  while IFS= read -r source_file; do
    [[ -f "$source_file" ]] || continue
    while IFS= read -r match; do
      [[ -n "$match" ]] || continue
      record_edge "$source_file" "$match"
    done < <(grep -vE '^[[:space:]]*#' "$source_file" | grep -oE "$ref_pattern" || true)
  done < <(
    {
      find plugins/cwf/hooks/scripts -type f -name '*.sh' 2>/dev/null
      find plugins/cwf/scripts -type f -name '*.sh' 2>/dev/null
      find plugins/cwf/skills/setup/scripts -type f -name '*.sh' 2>/dev/null
      [[ -f .githooks/pre-push ]] && printf '%s\n' .githooks/pre-push
    } | sort -u
  )
}

extract_edges_from_hooks_manifest
extract_edges_from_script_text

if [[ -s "$EDGE_FILE" ]]; then
  sort -u "$EDGE_FILE" -o "$EDGE_FILE"
fi
if [[ -s "$BROKEN_FILE" ]]; then
  sort -u "$BROKEN_FILE" -o "$BROKEN_FILE"
fi

EDGE_COUNT="$(wc -l < "$EDGE_FILE" | tr -d ' ')"
BROKEN_COUNT="$(wc -l < "$BROKEN_FILE" | tr -d ' ')"

echo "Script dependency check"
echo "  edges  : ${EDGE_COUNT}"
echo "  broken : ${BROKEN_COUNT}"

if [[ "$BROKEN_COUNT" -gt 0 ]]; then
  while IFS=$'\t' read -r src dst reason; do
    [[ -n "$src" ]] || continue
    echo "[FAIL] ${src} -> ${dst} (${reason})"
  done < "$BROKEN_FILE"

  if [[ "$STRICT" == "true" ]]; then
    exit 1
  fi
  exit 0
fi

echo "[PASS] all referenced runtime scripts resolve"
exit 0
