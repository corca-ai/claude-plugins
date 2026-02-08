#!/usr/bin/env bash
# install.sh: Install the CWF (Corca Workflow Framework) plugin.
#
# Usage:
#   install.sh              Install cwf plugin (default)
#   install.sh -h|--help    Show usage
#
# Legacy flags (--all, --workflow, --context, etc.) are accepted
# with a deprecation warning and install cwf.
#
# Prerequisite: marketplace must be added first:
#   claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

set -euo pipefail

MARKETPLACE="corca-plugins"
PLUGIN="cwf"

usage() {
  cat <<'EOF'
CWF plugin installer

Usage:
  install.sh              Install cwf plugin
  install.sh -h|--help    Show this help

All workflow skills (gather, clarify, plan, impl, retro, refactor)
and infra hooks are bundled in the single cwf plugin.

Prerequisite:
  claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git
EOF
}

install_cwf() {
  echo "==> Installing ${PLUGIN}@${MARKETPLACE}"
  echo ""
  if claude plugin install "${PLUGIN}@${MARKETPLACE}"; then
    echo ""
    echo "==> Success. Restart Claude Code for changes to take effect."
  else
    echo ""
    echo "==> Installation failed." >&2
    exit 1
  fi
}

# --- Main ---

# Ensure marketplace is registered
ensure_marketplace() {
  if ! claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE"; then
    echo "Marketplace '${MARKETPLACE}' not found. Adding..."
    claude plugin marketplace add "https://github.com/corca-ai/claude-plugins.git"
    echo ""
  fi
}

# No args: install cwf
if [[ $# -eq 0 ]]; then
  ensure_marketplace
  install_cwf
  exit 0
fi

# Parse args
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --all|--workflow|--context|--clarify|--plan|--implement|--reflect|--refactor|--infra)
      echo "WARNING: '$arg' is deprecated. All plugins are now consolidated into 'cwf'."
      echo "         Installing cwf instead."
      echo ""
      ensure_marketplace
      install_cwf
      exit 0
      ;;
    -*)
      echo "Unknown flag: $arg" >&2
      usage
      exit 1
      ;;
    *)
      # Named plugin: if it's cwf, install directly; otherwise warn
      if [[ "$arg" == "$PLUGIN" ]]; then
        ensure_marketplace
        install_cwf
        exit 0
      else
        echo "WARNING: Plugin '$arg' has been consolidated into 'cwf'."
        echo "         Installing cwf instead."
        echo ""
        ensure_marketplace
        install_cwf
        exit 0
      fi
      ;;
  esac
done
