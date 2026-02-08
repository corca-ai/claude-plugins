#!/usr/bin/env bash
set -euo pipefail
# check-markdown.sh — PostToolUse hook for Write|Edit
# Validates markdown files using markdownlint after write/edit operations.
# Stub: real implementation in S6a migration.

HOOK_GROUP="lint_markdown"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

exit 0
