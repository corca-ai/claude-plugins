#!/usr/bin/env bash
set -uo pipefail

# bootstrap-codebase-contract.sh — Create/refresh repository-local codebase scan contract.
#
# Usage:
#   bootstrap-codebase-contract.sh [--contract <path>] [--force] [--json]
#
# Behavior:
# - Default contract location: {artifact_root}/codebase-contract.json
# - Artifact root resolution: CWF config/env via cwf-artifact-paths.sh, fallback ./.cwf
# - Idempotent by default: existing contract is never overwritten unless --force
# - On bootstrap failure, emit fallback metadata and return success so scan can continue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

CONTRACT_PATH=""
FORCE="false"
JSON_OUTPUT="false"
WARNING=""

usage() {
  cat <<'USAGE'
bootstrap-codebase-contract.sh — bootstrap codebase scan contract

Usage:
  bootstrap-codebase-contract.sh [options]

Options:
  --contract <path>  Explicit contract path (default: {artifact_root}/codebase-contract.json)
  --force            Overwrite existing contract file
  --json             Print machine-readable result
  -h, --help         Show this help
USAGE
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

append_warning() {
  local message="$1"
  if [[ -z "$WARNING" ]]; then
    WARNING="$message"
  else
    WARNING="$WARNING; $message"
  fi
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

path_to_abs() {
  local path_value="$1"
  if [[ "$path_value" == /* ]]; then
    printf '%s\n' "$path_value"
  else
    printf '%s\n' "$REPO_ROOT/$path_value"
  fi
}

write_contract_file() {
  local destination="$1"
  local generated_at_utc="$2"

  cat > "$destination" <<EOF
{
  "version": 1,
  "generated_at_utc": "$generated_at_utc",
  "mode": "advisory",
  "source": {
    "git_tracked_only": true
  },
  "scope": {
    "include_globs": [
      "**/*"
    ],
    "exclude_globs": [
      ".git/**",
      ".cwf/**",
      "node_modules/**",
      "dist/**",
      "build/**",
      "coverage/**",
      ".venv/**",
      "venv/**",
      "**/*.md",
      "**/*.mdx",
      "**/*.png",
      "**/*.jpg",
      "**/*.jpeg",
      "**/*.gif",
      "**/*.svg",
      "**/*.pdf",
      "**/*.lock",
      "**/*.snap",
      "**/*.min.js",
      "**/*.min.css"
    ],
    "include_extensions": [
      ".sh",
      ".bash",
      ".zsh",
      ".py",
      ".js",
      ".jsx",
      ".ts",
      ".tsx",
      ".mjs",
      ".cjs",
      ".java",
      ".go",
      ".rs",
      ".rb",
      ".php",
      ".cs",
      ".kt",
      ".swift",
      ".scala",
      ".lua",
      ".sql",
      ".yaml",
      ".yml",
      ".json",
      ".toml",
      ".ini",
      ".cfg",
      ".conf",
      ".xml"
    ]
  },
  "checks": {
    "large_file_lines": {
      "enabled": true,
      "warn_at": 400,
      "error_at": 800
    },
    "long_line_length": {
      "enabled": true,
      "warn_at": 140
    },
    "todo_markers": {
      "enabled": true,
      "patterns": [
        "TODO",
        "FIXME",
        "HACK",
        "XXX"
      ]
    },
    "shell_strict_mode": {
      "enabled": true,
      "exclude_globs": []
    }
  },
  "deep_review": {
    "enabled": true,
    "fixed_experts": [
      {
        "name": "Martin Fowler",
        "domain": "refactoring patterns, knowledge duplication (Rule of Three), shared abstractions, evolutionary design",
        "source": "Refactoring: Improving the Design of Existing Code 2nd ed. (2018), Is Design Dead? (martinfowler.com), BeckDesignRules (martinfowler.com/bliki)"
      },
      {
        "name": "Kent Beck",
        "domain": "Tidy First, small safe refactorings, test-driven development, simple design",
        "source": "Tidy First? (2023), Test-Driven Development: By Example (2002), Extreme Programming Explained (2004)"
      }
    ],
    "context_expert_count": 2,
    "roster_state_file": ".cwf/cwf-state.yaml"
  },
  "reporting": {
    "top_findings_limit": 30,
    "include_clean_summary": true
  },
  "notes": [
    "Auto-generated by refactor codebase contract bootstrap.",
    "Tune scope and thresholds for your repository before enforcing as policy."
  ]
}
EOF
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
      exit 1
      ;;
  esac
done

ARTIFACT_ROOT_RAW=""
if ! ARTIFACT_ROOT_RAW="$(resolve_artifact_root)"; then
  ARTIFACT_ROOT_RAW=".cwf"
  append_warning "artifact root resolver unavailable; using .cwf fallback"
fi
ARTIFACT_ROOT_ABS="$(path_to_abs "$ARTIFACT_ROOT_RAW")"

if [[ -z "$CONTRACT_PATH" ]]; then
  CONTRACT_PATH="$ARTIFACT_ROOT_ABS/codebase-contract.json"
else
  CONTRACT_PATH="$(path_to_abs "$CONTRACT_PATH")"
fi

if ! mkdir -p "$(dirname "$CONTRACT_PATH")" 2>/dev/null; then
  append_warning "unable to create contract directory; continue with fallback defaults"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if [[ -f "$CONTRACT_PATH" && "$FORCE" != "true" ]]; then
  emit_result "existing" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

generated_at_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
tmp_file="$(mktemp "$CONTRACT_PATH.tmp.XXXXXX" 2>/dev/null || true)"
if [[ -z "$tmp_file" ]]; then
  append_warning "unable to allocate temporary file for contract generation"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if ! write_contract_file "$tmp_file" "$generated_at_utc"; then
  mv "$tmp_file" "$tmp_file.failed" >/dev/null 2>&1 || true
  append_warning "failed to render contract draft; continue with fallback defaults"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if ! mv "$tmp_file" "$CONTRACT_PATH" 2>/dev/null; then
  mv "$tmp_file" "$tmp_file.failed" >/dev/null 2>&1 || true
  append_warning "failed to write contract file; continue with fallback defaults"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if [[ "$FORCE" == "true" ]]; then
  emit_result "updated" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
else
  emit_result "created" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
fi
