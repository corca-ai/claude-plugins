#!/usr/bin/env bash
set -euo pipefail

# bootstrap-gate-contract.sh — create/refresh repository-local run gate contract.
# Usage:
#   bootstrap-gate-contract.sh [--project-root <path>] [--contract <path>] [--force] [--json]
#
# Default output path:
#   {artifact_root}/gate-contract.yaml
# where artifact_root resolves via plugins/cwf/scripts/cwf-artifact-paths.sh
# (fallback: {repo_root}/.cwf).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

PROJECT_ROOT_INPUT=""
CONTRACT_PATH_INPUT=""
FORCE="false"
JSON_OUTPUT="false"
EXISTED_BEFORE="false"

usage() {
  cat <<'USAGE'
bootstrap-gate-contract.sh — bootstrap run gate contract

Usage:
  bootstrap-gate-contract.sh [options]

Options:
  --project-root <path>  Explicit repository root (default: git root or pwd)
  --contract <path>      Explicit gate contract output path
  --force                Overwrite existing contract
  --json                 Emit machine-readable result JSON
  -h, --help             Show this help
USAGE
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

emit_result() {
  local status="$1"
  local path="$2"
  local artifact_root="$3"
  local warning="${4-}"

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    if [[ -n "$warning" ]]; then
      printf '{"status":"%s","path":"%s","artifact_root":"%s","warning":"%s"}\n' \
        "$status" \
        "$(json_escape "$path")" \
        "$(json_escape "$artifact_root")" \
        "$(json_escape "$warning")"
    else
      printf '{"status":"%s","path":"%s","artifact_root":"%s"}\n' \
        "$status" \
        "$(json_escape "$path")" \
        "$(json_escape "$artifact_root")"
    fi
  else
    echo "status: $status"
    echo "path: $path"
    echo "artifact_root: $artifact_root"
    if [[ -n "$warning" ]]; then
      echo "warning: $warning"
    fi
  fi
}

to_abs_path() {
  local root="$1"
  local raw="$2"
  if [[ "$raw" == /* ]]; then
    printf '%s\n' "$raw"
  else
    printf '%s\n' "$root/$raw"
  fi
}

resolve_repo_root() {
  local input="$1"
  local root=""

  if [[ -n "$input" ]]; then
    if [[ "$input" == /* ]]; then
      printf '%s\n' "$input"
    else
      printf '%s\n' "$(cd "$input" && pwd)"
    fi
    return 0
  fi

  if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$root"
    return 0
  fi

  printf '%s\n' "$(pwd)"
}

resolve_artifact_root() {
  local repo_root="$1"
  local resolved=""

  if [[ -f "$RESOLVER_SCRIPT" ]]; then
    if resolved="$(
      bash -c 'source "$1" && resolve_cwf_artifact_root "$2"' _ "$RESOLVER_SCRIPT" "$repo_root" 2>/dev/null
    )"; then
      if [[ -n "$resolved" ]]; then
        printf '%s\n' "$resolved"
        return 0
      fi
    fi
  fi

  printf '%s\n' "$repo_root/.cwf"
}

render_contract() {
  cat <<'EOF'
version: 1

stages:
  review-code: fail
  refactor: fail
  retro: fail
  ship: fail

policies:
  # External provider preference should be resilient to local environment/auth gaps.
  # Use warn by default (no hard fail) unless a session needs stricter enforcement.
  provider_gemini_mode: warn
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT_INPUT="${2-}"
      if [[ -z "$PROJECT_ROOT_INPUT" ]]; then
        echo "Error: --project-root requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --contract)
      CONTRACT_PATH_INPUT="${2-}"
      if [[ -z "$CONTRACT_PATH_INPUT" ]]; then
        echo "Error: --contract requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    --json)
      JSON_OUTPUT="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ROOT="$(resolve_repo_root "$PROJECT_ROOT_INPUT")"
if [[ ! -d "$REPO_ROOT" ]]; then
  emit_result "fallback" "${CONTRACT_PATH_INPUT:-}" "${REPO_ROOT:-}" "project root does not exist"
  exit 1
fi

ARTIFACT_ROOT="$(resolve_artifact_root "$REPO_ROOT")"
if [[ -n "$CONTRACT_PATH_INPUT" ]]; then
  CONTRACT_PATH="$(to_abs_path "$REPO_ROOT" "$CONTRACT_PATH_INPUT")"
else
  CONTRACT_PATH="$ARTIFACT_ROOT/gate-contract.yaml"
fi

CONTRACT_DIR="$(dirname "$CONTRACT_PATH")"
if [[ -f "$CONTRACT_PATH" && "$FORCE" != "true" ]]; then
  emit_result "existing" "$CONTRACT_PATH" "$ARTIFACT_ROOT"
  exit 0
fi
if [[ -f "$CONTRACT_PATH" ]]; then
  EXISTED_BEFORE="true"
fi

if ! mkdir -p "$CONTRACT_DIR"; then
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT" "failed to create contract directory"
  exit 1
fi

tmp_file="$(mktemp "$CONTRACT_PATH.tmp.XXXXXX")"
cleanup_tmp() {
  if [[ -n "${tmp_file:-}" && -f "${tmp_file:-}" ]]; then
    rm -f "$tmp_file"
  fi
}
trap cleanup_tmp EXIT

if ! render_contract > "$tmp_file"; then
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT" "failed to render gate contract"
  exit 1
fi

if ! mv "$tmp_file" "$CONTRACT_PATH"; then
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT" "failed to write gate contract"
  exit 1
fi
tmp_file=""

if [[ "$EXISTED_BEFORE" == "true" ]]; then
  emit_result "updated" "$CONTRACT_PATH" "$ARTIFACT_ROOT"
else
  emit_result "created" "$CONTRACT_PATH" "$ARTIFACT_ROOT"
fi
