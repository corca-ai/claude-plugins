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
  --runtime-residual-mode <off|observe|strict>
                               Runtime residual gate mode (default: off for premerge, observe for predeploy)
  --update-top-level-scope <user|project|local>
                               Scope used for top-level update consistency gate in predeploy mode (default: user)
  -h, --help                   Show this message
USAGE
}

MODE="premerge"
PUBLIC_REPO="corca-ai/claude-plugins"
PUBLIC_REF="main"
PLUGIN="cwf"
RUNTIME_RESIDUAL_MODE="auto"
UPDATE_TOP_LEVEL_SCOPE="user"

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
    --runtime-residual-mode)
      RUNTIME_RESIDUAL_MODE="${2:-}"
      shift 2
      ;;
    --update-top-level-scope)
      UPDATE_TOP_LEVEL_SCOPE="${2:-}"
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

if [[ "$RUNTIME_RESIDUAL_MODE" == "auto" ]]; then
  if [[ "$MODE" == "predeploy" ]]; then
    RUNTIME_RESIDUAL_MODE="observe"
  else
    RUNTIME_RESIDUAL_MODE="off"
  fi
fi

if [[ "$RUNTIME_RESIDUAL_MODE" != "off" && "$RUNTIME_RESIDUAL_MODE" != "observe" && "$RUNTIME_RESIDUAL_MODE" != "strict" ]]; then
  echo "Error: unsupported runtime residual mode: $RUNTIME_RESIDUAL_MODE" >&2
  exit 1
fi

if [[ "$UPDATE_TOP_LEVEL_SCOPE" != "user" && "$UPDATE_TOP_LEVEL_SCOPE" != "project" && "$UPDATE_TOP_LEVEL_SCOPE" != "local" ]]; then
  echo "Error: unsupported update top-level scope: $UPDATE_TOP_LEVEL_SCOPE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONSISTENCY_CHECKER="$SCRIPT_DIR/../.claude/skills/plugin-deploy/scripts/check-consistency.sh"
UPDATE_CONSISTENCY_CHECKER="$SCRIPT_DIR/../plugins/cwf/scripts/check-update-latest-consistency.sh"

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

run_step "update consistency fixtures" \
  bash "$SCRIPT_DIR/tests/check-update-latest-consistency-fixtures.sh"

run_step "lessons metadata fixtures" \
  bash "$SCRIPT_DIR/tests/check-lessons-metadata-fixtures.sh"

run_step "retro coverage contract fixtures" \
  bash "$SCRIPT_DIR/tests/retro-coverage-contract-fixtures.sh"

run_step "update consistency contract" \
  bash "$UPDATE_CONSISTENCY_CHECKER" --mode contract

run_step "deep retro lessons metadata" \
  bash "$SCRIPT_DIR/../plugins/cwf/scripts/check-lessons-metadata.sh" --root "$SCRIPT_DIR/../.cwf/projects"

run_step "non-interactive smoke fixtures" \
  bash "$SCRIPT_DIR/tests/noninteractive-skill-smoke-fixtures.sh"

run_step "runtime residual smoke fixtures" \
  bash "$SCRIPT_DIR/tests/runtime-residual-smoke-fixtures.sh"

if [[ "$RUNTIME_RESIDUAL_MODE" != "off" ]]; then
  run_step "runtime residual smoke (${RUNTIME_RESIDUAL_MODE})" \
    bash "$SCRIPT_DIR/runtime-residual-smoke.sh" \
      --mode "$RUNTIME_RESIDUAL_MODE" \
      --plugin-dir "$SCRIPT_DIR/../plugins/cwf" \
      --workdir "$SCRIPT_DIR/.." \
      --k46-timeout 120 \
      --s10-timeout 120 \
      --s10-runs 5
fi

run_step "hook core smoke" \
  bash "$SCRIPT_DIR/hook-core-smoke.sh"

if [[ "$MODE" == "predeploy" ]]; then
  run_step "update consistency top-level (${UPDATE_TOP_LEVEL_SCOPE})" \
    bash "$UPDATE_CONSISTENCY_CHECKER" --mode top-level --scope "$UPDATE_TOP_LEVEL_SCOPE"

  run_step "public marketplace entry (${PUBLIC_REPO}@${PUBLIC_REF})" \
    bash "$SCRIPT_DIR/check-public-marketplace-entry.sh" \
      --repo "$PUBLIC_REPO" \
      --ref "$PUBLIC_REF" \
      --plugin "$PLUGIN"
fi

echo "---"
echo "CWF gate result: PASS"
