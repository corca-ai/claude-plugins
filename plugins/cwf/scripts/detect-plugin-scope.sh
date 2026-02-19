#!/usr/bin/env bash
# detect-plugin-scope.sh: resolve active Claude plugin scope for current cwd.
#
# Usage:
#   detect-plugin-scope.sh [--plugin <name>] [--cwd <path>] [--mode active|list]
#
# Output (mode=active, default): key=value lines
#   active_scope=user|project|local|none
#   active_plugin_id=<id or empty>
#   active_install_path=<path or empty>
#   active_project_path=<path or empty>
#   installed_scopes=comma,separated,list
#
# Selection rule for active scope:
#   1) local (enabled + cwd within projectPath; nearest match wins)
#   2) project (enabled + cwd within projectPath; nearest match wins)
#   3) user (enabled)
#   4) none

set -euo pipefail

PLUGIN_NAME="cwf"
TARGET_CWD="$(pwd)"
MODE="active"

usage() {
  cat <<'USAGE'
Detect active Claude plugin scope for the current directory.

Usage:
  detect-plugin-scope.sh [options]

Options:
  --plugin <name>         Plugin name prefix before '@' (default: cwf)
  --cwd <path>            Working directory to evaluate (default: current dir)
  --mode <active|list>    active: print resolved scope info, list: print raw entries
  -h, --help              Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin)
      PLUGIN_NAME="${2:-}"
      shift 2
      ;;
    --cwd)
      TARGET_CWD="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$TARGET_CWD" ]]; then
  echo "cwd not found: $TARGET_CWD" >&2
  exit 1
fi
TARGET_CWD="$(cd "$TARGET_CWD" && pwd)"

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found in PATH" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for scope detection" >&2
  exit 1
fi

raw_json="$(claude plugin list --json 2>/dev/null || printf '[]')"
entries_json="$(
  printf '%s' "$raw_json" \
    | jq --arg prefix "${PLUGIN_NAME}@" '[.[] | select(.id | startswith($prefix))]'
)"

if [[ "$MODE" == "list" ]]; then
  printf '%s\n' "$entries_json"
  exit 0
fi
if [[ "$MODE" != "active" ]]; then
  echo "Invalid mode: $MODE (allowed: active|list)" >&2
  exit 1
fi

installed_scopes="$(
  printf '%s' "$entries_json" \
    | jq -r 'map(.scope) | unique | join(",")'
)"

best_local_line=""
best_project_line=""
user_line=""
best_local_len=0
best_project_len=0

while IFS=$'\t' read -r scope enabled project_path plugin_id install_path; do
  [[ -n "$scope" ]] || continue

  case "$scope" in
    local|project)
      if [[ "$enabled" != "true" || -z "$project_path" ]]; then
        continue
      fi
      if [[ "$TARGET_CWD" != "$project_path" && "$TARGET_CWD/" != "$project_path/"* ]]; then
        continue
      fi
      path_len="${#project_path}"
      if [[ "$scope" == "local" ]]; then
        if (( path_len >= best_local_len )); then
          best_local_len="$path_len"
          best_local_line="$scope"$'\t'"$plugin_id"$'\t'"$install_path"$'\t'"$project_path"
        fi
      else
        if (( path_len >= best_project_len )); then
          best_project_len="$path_len"
          best_project_line="$scope"$'\t'"$plugin_id"$'\t'"$install_path"$'\t'"$project_path"
        fi
      fi
      ;;
    user)
      if [[ "$enabled" == "true" ]]; then
        user_line="$scope"$'\t'"$plugin_id"$'\t'"$install_path"$'\t'
      fi
      ;;
  esac
done < <(
  printf '%s' "$entries_json" \
    | jq -r '.[] | [.scope, (.enabled|tostring), (.projectPath // ""), .id, (.installPath // "")] | @tsv'
)

active_scope="none"
active_plugin_id=""
active_install_path=""
active_project_path=""

if [[ -n "$best_local_line" ]]; then
  IFS=$'\t' read -r active_scope active_plugin_id active_install_path active_project_path <<< "$best_local_line"
elif [[ -n "$best_project_line" ]]; then
  IFS=$'\t' read -r active_scope active_plugin_id active_install_path active_project_path <<< "$best_project_line"
elif [[ -n "$user_line" ]]; then
  IFS=$'\t' read -r active_scope active_plugin_id active_install_path active_project_path <<< "$user_line"
fi

printf 'active_scope=%s\n' "$active_scope"
printf 'active_plugin_id=%s\n' "$active_plugin_id"
printf 'active_install_path=%s\n' "$active_install_path"
printf 'active_project_path=%s\n' "$active_project_path"
printf 'installed_scopes=%s\n' "$installed_scopes"

