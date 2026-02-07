#!/usr/bin/env bash
# install.sh: Install corca-plugins by category.
#
# Usage:
#   install.sh --all                  Install all active plugins
#   install.sh --workflow             Install all workflow-stage plugins (1-6)
#   install.sh --context              Stage 1: gather-context
#   install.sh --clarify              Stage 2: clarify
#   install.sh --plan                 Stage 3: plan-and-lessons
#   install.sh --implement            Stage 4: smart-read
#   install.sh --reflect              Stage 5: retro
#   install.sh --refactor             Stage 6: refactor
#   install.sh --infra                Install infra plugins (attention-hook, prompt-logger)
#   install.sh <name> [<name>...]     Install specific plugin(s) by name
#
# Prerequisite: marketplace must be added first:
#   claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

set -euo pipefail

MARKETPLACE="corca-plugins"

# --- Plugin definitions by stage ---
STAGE_1_CONTEXT=(gather-context)
STAGE_2_CLARIFY=(clarify)
STAGE_3_PLAN=(plan-and-lessons)
STAGE_4_IMPLEMENT=(smart-read)
STAGE_5_REFLECT=(retro)
STAGE_6_REFACTOR=(refactor)
INFRA=(attention-hook prompt-logger)

ALL_WORKFLOW=("${STAGE_1_CONTEXT[@]}" "${STAGE_2_CLARIFY[@]}" "${STAGE_3_PLAN[@]}" "${STAGE_4_IMPLEMENT[@]}" "${STAGE_5_REFLECT[@]}" "${STAGE_6_REFACTOR[@]}")
ALL_PLUGINS=("${ALL_WORKFLOW[@]}" "${INFRA[@]}")

# --- Helpers ---
usage() {
  cat <<'EOF'
corca-plugins installer

Usage:
  install.sh --all                  Install all active plugins
  install.sh --workflow             Install all workflow-stage plugins (1-6)
  install.sh --context              Stage 1: gather-context
  install.sh --clarify              Stage 2: clarify
  install.sh --plan                 Stage 3: plan-and-lessons
  install.sh --implement            Stage 4: smart-read
  install.sh --reflect              Stage 5: retro
  install.sh --refactor             Stage 6: refactor
  install.sh --infra                Infra: attention-hook, prompt-logger
  install.sh <name> [<name>...]     Install specific plugin(s) by name

Flags can be combined: install.sh --context --clarify --infra

Prerequisite:
  claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git
EOF
}

install_plugins() {
  local plugins=("$@")
  local success=0
  local fail=0

  for plugin in "${plugins[@]}"; do
    echo "--- ${plugin}@${MARKETPLACE}"
    if claude plugin install "${plugin}@${MARKETPLACE}"; then
      success=$((success + 1))
    else
      fail=$((fail + 1))
    fi
    echo ""
  done

  echo "==> ${success} installed, ${fail} failed."
}

# --- Main ---
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

# Ensure marketplace is registered
if ! claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE"; then
  echo "Marketplace '${MARKETPLACE}' not found. Adding..."
  claude plugin marketplace add "https://github.com/corca-ai/claude-plugins.git"
  echo ""
fi

# Collect plugins to install
declare -A seen
to_install=()

add_plugins() {
  for p in "$@"; do
    if [[ -z "${seen[$p]:-}" ]]; then
      seen[$p]=1
      to_install+=("$p")
    fi
  done
}

for arg in "$@"; do
  case "$arg" in
    --all)        add_plugins "${ALL_PLUGINS[@]}" ;;
    --workflow)   add_plugins "${ALL_WORKFLOW[@]}" ;;
    --context)    add_plugins "${STAGE_1_CONTEXT[@]}" ;;
    --clarify)    add_plugins "${STAGE_2_CLARIFY[@]}" ;;
    --plan)       add_plugins "${STAGE_3_PLAN[@]}" ;;
    --implement)  add_plugins "${STAGE_4_IMPLEMENT[@]}" ;;
    --reflect)    add_plugins "${STAGE_5_REFLECT[@]}" ;;
    --refactor)   add_plugins "${STAGE_6_REFACTOR[@]}" ;;
    --infra)      add_plugins "${INFRA[@]}" ;;
    -h|--help)    usage; exit 0 ;;
    -*)           echo "Unknown flag: $arg"; usage; exit 1 ;;
    *)            add_plugins "$arg" ;;
  esac
done

if [[ ${#to_install[@]} -eq 0 ]]; then
  echo "No plugins selected."
  exit 0
fi

echo "==> Installing ${#to_install[@]} plugin(s): ${to_install[*]}"
echo ""
install_plugins "${to_install[@]}"
echo "Restart Claude Code for changes to take effect."
