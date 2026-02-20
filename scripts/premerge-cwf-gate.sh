#!/usr/bin/env bash
set -euo pipefail

# premerge-cwf-gate.sh — consolidated pre-merge/pre-deploy checks for CWF.
#
# Modes:
# - premerge (default): local deterministic checks only
# - predeploy: premerge checks + public marketplace entry check

usage() {
  cat <<'USAGE'
premerge-cwf-gate.sh — run CWF release gates before merge/deploy

Usage:
  premerge-cwf-gate.sh [options]

Options:
  --mode <premerge|predeploy>  Gate mode (default: premerge)
  --repo <owner/name>          Public repo for predeploy check (default: corca-ai/claude-plugins)
  --ref <git-ref>              Public ref for predeploy check (default: main)
  --plugin <name>              Plugin name for marketplace checks (default: cwf)
  -h, --help                   Show this message
USAGE
}

MODE="premerge"
PUBLIC_REPO="corca-ai/claude-plugins"
PUBLIC_REF="main"
PLUGIN="cwf"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --repo)
      PUBLIC_REPO="${2:-}"
      shift 2
      ;;
    --ref)
      PUBLIC_REF="${2:-}"
      shift 2
      ;;
    --plugin)
      PLUGIN="${2:-}"
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

if [[ "$MODE" != "premerge" && "$MODE" != "predeploy" ]]; then
  echo "Error: unsupported mode: $MODE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONSISTENCY_CHECKER="$SCRIPT_DIR/../.claude/skills/plugin-deploy/scripts/check-consistency.sh"

run_step() {
  local label="$1"
  shift
  echo "---"
  echo "[gate] $label"
  "$@"
}

run_plugin_consistency_gate() {
  local report=""

  if [[ ! -x "$CONSISTENCY_CHECKER" ]]; then
    echo "Error: consistency checker missing or not executable: $CONSISTENCY_CHECKER" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required for plugin consistency gate." >&2
    return 1
  fi

  report="$(bash "$CONSISTENCY_CHECKER" "$PLUGIN")"
  printf '%s\n' "$report" | jq -r '.gaps[]?'

  if ! printf '%s\n' "$report" | jq -e '.gap_count == 0' >/dev/null; then
    echo "Error: plugin consistency gaps detected." >&2
    return 1
  fi
}

echo "CWF gate mode: $MODE"
echo "Plugin: $PLUGIN"

run_step "local marketplace entry" \
  bash "$SCRIPT_DIR/check-marketplace-entry.sh" --source . --plugin "$PLUGIN"

run_step "plugin consistency" \
  run_plugin_consistency_gate

run_step "marketplace checker fixtures" \
  bash "$SCRIPT_DIR/tests/check-marketplace-entry-fixtures.sh"

run_step "non-interactive smoke fixtures" \
  bash "$SCRIPT_DIR/tests/noninteractive-skill-smoke-fixtures.sh"

run_step "hook core smoke" \
  bash "$SCRIPT_DIR/hook-core-smoke.sh"

if [[ "$MODE" == "predeploy" ]]; then
  run_step "public marketplace entry (${PUBLIC_REPO}@${PUBLIC_REF})" \
    bash "$SCRIPT_DIR/check-public-marketplace-entry.sh" \
      --repo "$PUBLIC_REPO" \
      --ref "$PUBLIC_REF" \
      --plugin "$PLUGIN"
fi

echo "---"
echo "CWF gate result: PASS"
