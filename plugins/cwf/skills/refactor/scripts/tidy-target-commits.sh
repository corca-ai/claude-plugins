#!/usr/bin/env bash
set -euo pipefail
# Get recent non-tidying commits for analysis
# Usage: tidy-target-commits.sh <count> [branch]
#
# Arguments:
#   count  - Number of commits to retrieve
#   branch - Optional branch name (defaults to HEAD)
#
# Output: List of commit hashes and messages (one per line)

count=${1:-5}
branch=${2:-HEAD}

git log "$branch" --grep="^tidy:" --invert-grep --no-merges --oneline -n "$count"
