#!/usr/bin/env bash
set -euo pipefail

# Repository-maintainer wrapper for authoring-only gate profile.
# Keeps generic runtime defaults portable while preserving explicit authoring checks.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UNIFIED_GATE="$REPO_ROOT/plugins/cwf/scripts/check-portability-contract.sh"

if [[ ! -x "$UNIFIED_GATE" ]]; then
  echo "CHECK_FAIL: unified gate script not found: $UNIFIED_GATE" >&2
  exit 1
fi

bash "$UNIFIED_GATE" --contract authoring "$@"
