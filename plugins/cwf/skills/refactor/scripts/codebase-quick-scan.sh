#!/usr/bin/env bash
set -euo pipefail

# codebase-quick-scan.sh: Contract-driven structural scan for repository code files.
#
# Usage:
#   codebase-quick-scan.sh [repo-root] [--contract <path>]
#
# Output:
#   JSON report to stdout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DEFAULT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

REPO_ROOT="$REPO_ROOT_DEFAULT"
CONTRACT_PATH=""
REPO_ROOT_ARG_SET="false"

usage() {
  cat <<'USAGE'
codebase-quick-scan.sh — contract-driven codebase scan

Usage:
  codebase-quick-scan.sh [repo-root] [--contract <path>]

Options:
  --contract <path>  Contract path (default: {artifact_root}/codebase-contract.json)
  -h, --help         Show help
USAGE
}

path_to_abs() {
  local base="$1"
  local path_value="$2"
  if [[ "$path_value" == /* ]]; then
    printf '%s\n' "$path_value"
  else
    printf '%s\n' "$base/$path_value"
  fi
}

resolve_artifact_root() {
  local resolved=""
  if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
    return 1
  fi

  if resolved="$(
    bash -c 'source "$1" && resolve_cwf_artifact_root "$2"' _ "$RESOLVER_SCRIPT" "$REPO_ROOT" 2>/dev/null
  )"; then
    if [[ -n "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  fi

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract)
      CONTRACT_PATH="${2-}"
      if [[ -z "$CONTRACT_PATH" ]]; then
        echo "Error: --contract requires a path value" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ "$REPO_ROOT_ARG_SET" == "true" ]]; then
        echo "Error: repo-root provided more than once" >&2
        usage >&2
        exit 1
      fi
      REPO_ROOT="$(path_to_abs "$PWD" "$1")"
      REPO_ROOT_ARG_SET="true"
      shift
      ;;
  esac
done

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Error: repo-root not found: $REPO_ROOT" >&2
  exit 1
fi

if [[ -z "$CONTRACT_PATH" ]]; then
  artifact_root="$(resolve_artifact_root 2>/dev/null || true)"
  if [[ -z "$artifact_root" ]]; then
    artifact_root="$REPO_ROOT/.cwf"
  fi
  CONTRACT_PATH="$artifact_root/codebase-contract.json"
else
  CONTRACT_PATH="$(path_to_abs "$PWD" "$CONTRACT_PATH")"
fi

tmp_candidates="$(mktemp "${TMPDIR:-/tmp}/cwf-codebase-scan-candidates.XXXXXX")"
cleanup() {
  rm -f "$tmp_candidates"
}
trap cleanup EXIT

source_mode="find"
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$REPO_ROOT" ls-files -z > "$tmp_candidates" 2>/dev/null; then
    source_mode="git_ls_files"
  fi
fi

if [[ "$source_mode" == "find" ]]; then
  find "$REPO_ROOT" -type f -print0 > "$tmp_candidates"
fi

python_script="$SCRIPT_DIR/codebase-quick-scan.py"
if [[ ! -f "$python_script" ]]; then
  echo "Error: missing python scanner script: $python_script" >&2
  exit 1
fi

python3 "$python_script" "$REPO_ROOT" "$CONTRACT_PATH" "$source_mode" "$tmp_candidates"
