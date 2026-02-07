#!/usr/bin/env bash
# Install corca-plugins by category.
# Usage: bash scripts/install.sh [--all | --workflow | --<stage> | --infra]
#
# Categories:
#   --all        Install all plugins (workflow + infra)
#   --workflow   Install all workflow plugins (stages 1-6)
#   --context    Stage 1: gather-context
#   --clarify    Stage 2: clarify
#   --plan       Stage 3: plan-and-lessons
#   --implement  Stage 4: smart-read
#   --reflect    Stage 5: retro
#   --refactor   Stage 6: refactor
#   --infra      Infrastructure: attention-hook, prompt-logger
#
# Multiple flags can be combined: bash scripts/install.sh --workflow --infra
# No args prints usage.

set -euo pipefail

MARKETPLACE="corca-plugins"
MARKETPLACE_URL="https://github.com/corca-ai/claude-plugins.git"

# --- plugin registry (ordered by workflow stage) ---

declare -A STAGE_PLUGINS=(
  [context]="gather-context"
  [clarify]="clarify"
  [plan]="plan-and-lessons"
  [implement]="smart-read"
  [reflect]="retro"
  [refactor]="refactor"
)

WORKFLOW_ORDER=(context clarify plan implement reflect refactor)
INFRA_PLUGINS=(attention-hook prompt-logger)

# --- helpers ---

usage() {
  cat <<'USAGE'
Install corca-plugins by category.

Usage: bash scripts/install.sh [flags]

Flags:
  --all        Install all plugins (workflow + infra)
  --workflow   Install all workflow plugins (stages 1-6)
  --context    Stage 1: gather-context
  --clarify    Stage 2: clarify
  --plan       Stage 3: plan-and-lessons
  --implement  Stage 4: smart-read
  --reflect    Stage 5: retro
  --refactor   Stage 6: refactor
  --infra      Infrastructure: attention-hook, prompt-logger

Multiple flags can be combined.
Example: bash scripts/install.sh --workflow --infra
USAGE
}

install_plugin() {
  local name="$1"
  echo "--- ${name}@${MARKETPLACE}"
  if claude plugin install "${name}@${MARKETPLACE}"; then
    echo "  OK"
  else
    echo "  FAILED" >&2
    fail=$((fail + 1))
  fi
  total=$((total + 1))
  echo ""
}

# --- parse args ---

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

do_workflow=false
do_infra=false
do_stages=()

for arg in "$@"; do
  case "$arg" in
    --all)
      do_workflow=true
      do_infra=true
      ;;
    --workflow)
      do_workflow=true
      ;;
    --infra)
      do_infra=true
      ;;
    --context|--clarify|--plan|--implement|--reflect|--refactor)
      do_stages+=("${arg#--}")
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

# --- ensure marketplace ---

echo "==> Ensuring marketplace: ${MARKETPLACE}"
if claude plugin marketplace update "$MARKETPLACE" 2>/dev/null; then
  echo "  Marketplace updated."
else
  echo "  Marketplace not found, adding..."
  claude plugin marketplace add "$MARKETPLACE_URL"
fi
echo ""

# --- build install list (deduplicated, ordered) ---

declare -A seen
plugins_to_install=()

add_plugin() {
  local name="$1"
  if [[ -z "${seen[$name]:-}" ]]; then
    seen[$name]=1
    plugins_to_install+=("$name")
  fi
}

# Workflow stages
if [[ "$do_workflow" == "true" ]]; then
  for stage in "${WORKFLOW_ORDER[@]}"; do
    add_plugin "${STAGE_PLUGINS[$stage]}"
  done
fi

# Individual stages
for stage in "${do_stages[@]}"; do
  add_plugin "${STAGE_PLUGINS[$stage]}"
done

# Infra
if [[ "$do_infra" == "true" ]]; then
  for p in "${INFRA_PLUGINS[@]}"; do
    add_plugin "$p"
  done
fi

# --- install ---

total=0
fail=0

echo "==> Installing ${#plugins_to_install[@]} plugin(s)..."
echo ""

for plugin in "${plugins_to_install[@]}"; do
  install_plugin "$plugin"
done

echo "==> Done. $((total - fail))/${total} installed successfully."
if [[ $fail -gt 0 ]]; then
  echo "  ${fail} failed. Check output above."
fi
echo "Restart Claude Code for changes to take effect."
