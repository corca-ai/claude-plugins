#!/usr/bin/env bash
# cwf-hook-source-sha=__CONFIG_SHA__
set -euo pipefail

PROFILE="__PROFILE__"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
CWF_PLUGIN_ROOT="${CWF_PLUGIN_ROOT:-__CWF_PLUGIN_ROOT__}"

resolve_cwf_path() {
  local rel="$1"
  local candidate=""
  for candidate in \
    "$CWF_PLUGIN_ROOT/$rel" \
    "$CWF_PLUGIN_ROOT/plugins/cwf/$rel" \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/plugins/cwf/$rel"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_cwf_exec_path() {
  local rel="$1"
  local candidate=""
  for candidate in \
    "$CWF_PLUGIN_ROOT/$rel" \
    "$CWF_PLUGIN_ROOT/plugins/cwf/$rel" \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/plugins/cwf/$rel"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

CWF_LINK_CHECKER="$(resolve_cwf_exec_path "skills/refactor/scripts/check-links.sh" || true)"
CWF_ARTIFACT_PATHS="$(resolve_cwf_path "scripts/cwf-artifact-paths.sh" || true)"
CWF_INDEX_COVERAGE="$(resolve_cwf_exec_path "skills/setup/scripts/check-index-coverage.sh" || true)"
CWF_PROVENANCE="$(resolve_cwf_exec_path "scripts/provenance-check.sh" || true)"
CWF_GROWTH_DRIFT="$(resolve_cwf_exec_path "scripts/check-growth-drift.sh" || true)"
CWF_SCRIPT_DEPS="$(resolve_cwf_exec_path "scripts/check-script-deps.sh" || true)"
CWF_README_STRUCTURE="$(resolve_cwf_exec_path "scripts/check-readme-structure.sh" || true)"
CWF_UNIFIED_GATE="$(resolve_cwf_exec_path "scripts/check-portability-contract.sh" || true)"

normalize_rel_path() {
  local value="$1"
  value="${value#./}"
  value="${value%/}"
  printf '%s' "$value"
}

add_skip_prefix() {
  local rel_path="${1:-}"
  local normalized=""
  local existing=""
  [[ -n "$rel_path" ]] || return 0
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" && "$normalized" != "." ]] || return 0
  for existing in "${RUNTIME_SKIP_PREFIXES[@]}"; do
    if [[ "$existing" == "$normalized" ]]; then
      return 0
    fi
  done
  RUNTIME_SKIP_PREFIXES+=("$normalized")
}

add_skip_abs_dir() {
  local abs_path="${1:-}"
  local rel_path=""
  [[ -n "$abs_path" ]] || return 0
  abs_path="${abs_path%/}"
  if [[ "$abs_path" == "$REPO_ROOT" || "$abs_path" != "$REPO_ROOT/"* ]]; then
    return 0
  fi
  rel_path="${abs_path#"$REPO_ROOT"/}"
  add_skip_prefix "$rel_path"
}

init_runtime_skip_prefixes() {
  local projects_dir=""
  local sessions_dir=""
  local prompt_logs_dir=""
  RUNTIME_SKIP_PREFIXES=()
  if [[ -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    projects_dir="$(resolve_cwf_projects_dir "$REPO_ROOT" 2>/dev/null || true)"
    sessions_dir="$(resolve_cwf_session_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    prompt_logs_dir="$(resolve_cwf_prompt_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    add_skip_abs_dir "$projects_dir"
    add_skip_abs_dir "$sessions_dir"
    add_skip_abs_dir "$prompt_logs_dir"
  fi
  add_skip_prefix ".cwf/projects"
  add_skip_prefix ".cwf/sessions"
  add_skip_prefix ".cwf/prompt-logs"
}

is_runtime_skip_path() {
  local rel_path="$1"
  local normalized=""
  local prefix=""
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" ]] || return 1
  for prefix in "${RUNTIME_SKIP_PREFIXES[@]}"; do
    if [[ "$normalized" == "$prefix" || "$normalized" == "$prefix/"* ]]; then
      return 0
    fi
  done
  return 1
}

is_cwf_authoring_repo() {
  [[ -d "$REPO_ROOT/plugins/cwf" && -f "$REPO_ROOT/README.md" && -f "$REPO_ROOT/README.ko.md" ]]
}

normalize_contract_scalar_value() {
  local value="$1"
  value="$(printf '%s' "$value" | sed -E 's/[[:space:]]+#.*$//' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s\n' "$value"
}

read_contract_scalar() {
  local file_path="$1"
  local key="$2"
  local line=""
  local value=""

  [[ -f "$file_path" ]] || return 1
  line="$(grep -shm1 -E "^[[:space:]]*${key}:[[:space:]]*" "$file_path" 2>/dev/null || true)"
  [[ -n "$line" ]] || return 1

  value="${line#*:}"
  value="$(normalize_contract_scalar_value "$value")"
  [[ -n "$value" ]] || return 1
  printf '%s\n' "$value"
}

read_pre_push_extension_scalar() {
  local file_path="$1"
  local key="$2"
  local raw_line=""
  local value=""
  [[ -f "$file_path" ]] || return 1
  raw_line="$(
    awk -v key="$key" '
      BEGIN { in_extensions=0; in_pre_push=0 }
      /^[[:space:]]*#/ { next }
      {
        line=$0
        if (!in_extensions) {
          if (line ~ /^[[:space:]]*hook_extensions:[[:space:]]*($|#)/) {
            in_extensions=1
          }
          next
        }

        if (line ~ /^[^[:space:]][^:]*:[[:space:]]*($|#)/) {
          exit
        }

        if (!in_pre_push) {
          if (line ~ /^[[:space:]][[:space:]]pre_push:[[:space:]]*($|#)/) {
            in_pre_push=1
          }
          next
        }

        if (line ~ /^[[:space:]][[:space:]][A-Za-z0-9_-]+:[[:space:]]*($|#)/) {
          exit
        }

        if (line ~ ("^[[:space:]][[:space:]][[:space:]][[:space:]]" key ":[[:space:]]*")) {
          sub("^[[:space:]][[:space:]][[:space:]][[:space:]]" key ":[[:space:]]*", "", line)
          print line
          exit
        }
      }
    ' "$file_path"
  )"
  [[ -n "$raw_line" ]] || return 1
  value="$(normalize_contract_scalar_value "$raw_line")"
  [[ -n "$value" ]] || return 1
  printf '%s\n' "$value"
}

resolve_setup_contract_path() {
  local artifact_root=""
  if [[ -n "$CWF_ARTIFACT_PATHS" && -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    artifact_root="$(resolve_cwf_artifact_root "$REPO_ROOT" 2>/dev/null || true)"
    if [[ -n "$artifact_root" ]]; then
      printf '%s\n' "$artifact_root/setup-contract.yaml"
      return 0
    fi
  fi
  printf '%s\n' "$REPO_ROOT/.cwf/setup-contract.yaml"
}

resolve_pre_push_extension_required() {
  local contract_path="$1"
  local raw=""
  raw="$(read_pre_push_extension_scalar "$contract_path" "required" 2>/dev/null || true)"
  case "${raw,,}" in
    1|true|yes|on|required)
      printf 'true\n'
      ;;
    *)
      printf 'false\n'
      ;;
  esac
}

run_pre_push_extension() {
  local contract_path="$1"
  local required="false"
  local extension_path_raw=""
  local extension_path_abs=""
  local -a extension_cmd=()

  extension_path_raw="$(read_pre_push_extension_scalar "$contract_path" "path" 2>/dev/null || true)"
  [[ -n "$extension_path_raw" ]] || return 0

  required="$(resolve_pre_push_extension_required "$contract_path")"
  if [[ "$extension_path_raw" == /* ]]; then
    extension_path_abs="$extension_path_raw"
  else
    extension_path_abs="$REPO_ROOT/${extension_path_raw#./}"
  fi

  if [[ ! -f "$extension_path_abs" ]]; then
    if [[ "$required" == "true" ]]; then
      echo "[pre-push] required contract extension missing: $extension_path_raw" >&2
      return 1
    fi
    echo "[pre-push] optional contract extension missing; skipping: $extension_path_raw" >&2
    return 0
  fi

  if [[ -x "$extension_path_abs" ]]; then
    extension_cmd=("$extension_path_abs")
  else
    extension_cmd=(bash "$extension_path_abs")
  fi

  echo "[pre-push] contract extension: $extension_path_raw (required: $required)..."
  if CWF_HOOK_EVENT="pre-push" CWF_HOOK_PROFILE="$PROFILE" CWF_SETUP_CONTRACT_PATH="$contract_path" "${extension_cmd[@]}"; then
    return 0
  fi

  if [[ "$required" == "true" ]]; then
    echo "[pre-push] required contract extension failed: $extension_path_raw" >&2
    return 1
  fi
  echo "[pre-push] optional contract extension failed; continuing: $extension_path_raw" >&2
  return 0
}

resolve_index_coverage_mode() {
  local contract_path="$1"
  local mode=""
  mode="$(read_contract_scalar "$contract_path" "hook_index_coverage_mode" 2>/dev/null || true)"
  if [[ -z "$mode" ]]; then
    mode="authoring-only"
  fi
  printf '%s\n' "$mode"
}

run_index_coverage_checks() {
  local coverage_rc=0
  local cap_index_file=".cwf/indexes/cwf-index.md"
  local cap_index_dir=""

  if [[ -n "$CWF_ARTIFACT_PATHS" && -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    cap_index_dir="$(resolve_cwf_indexes_dir "$REPO_ROOT" 2>/dev/null || true)"
    if [[ -n "$cap_index_dir" ]]; then
      cap_index_file="${cap_index_dir}/cwf-index.md"
    fi
  fi

  if [[ -f AGENTS.md ]]; then
    if ! bash "$CWF_INDEX_COVERAGE" AGENTS.md --profile repo; then
      coverage_rc=1
    fi
  fi
  if [[ -f "$cap_index_file" ]]; then
    if ! bash "$CWF_INDEX_COVERAGE" "$cap_index_file" --profile cap; then
      coverage_rc=1
    fi
  fi

  return "$coverage_rc"
}

ensure_markdownlint_cli2() {
  if command -v markdownlint-cli2 >/dev/null 2>&1; then
    return 0
  fi
  echo "[pre-push] markdownlint-cli2 not found; run 'cwf:setup --tools'." >&2
  exit 1
}

RUNTIME_SKIP_PREFIXES=()
init_runtime_skip_prefixes
SETUP_CONTRACT_PATH="$(resolve_setup_contract_path)"

mapfile -t md_candidates < <(git ls-files '*.md' '*.mdx' || true)
md_files=()
for file in "${md_candidates[@]}"; do
  if [[ "$file" == references/anthropic-skills-guide/* ]]; then
    continue
  fi
  if is_runtime_skip_path "$file"; then
    continue
  fi
  md_files+=("$file")
done

if [ "${#md_files[@]}" -gt 0 ]; then
  ensure_markdownlint_cli2
  echo "[pre-push] markdownlint on tracked markdown files..."
  markdownlint-cli2 "${md_files[@]}"
else
  echo "[pre-push] no markdown files found; skipping markdownlint"
fi

if [[ "$PROFILE" != "fast" ]]; then
  if [[ -n "$CWF_LINK_CHECKER" ]]; then
    echo "[pre-push] local link validation..."
    bash "$CWF_LINK_CHECKER" --local --json
  else
    echo "[pre-push] CWF link checker unavailable; skipping local link validation." >&2
  fi

  if [[ -n "$CWF_INDEX_COVERAGE" ]]; then
    INDEX_COVERAGE_MODE="$(resolve_index_coverage_mode "$SETUP_CONTRACT_PATH")"
    should_run_index_coverage="false"
    index_coverage_blocking="true"

    case "$INDEX_COVERAGE_MODE" in
      always|enforce|required)
        should_run_index_coverage="true"
        index_coverage_blocking="true"
        ;;
      warn|advisory)
        should_run_index_coverage="true"
        index_coverage_blocking="false"
        ;;
      authoring-only|auto|default|"")
        if is_cwf_authoring_repo; then
          should_run_index_coverage="true"
          index_coverage_blocking="true"
        fi
        ;;
      off|disabled|none|skip|false)
        should_run_index_coverage="false"
        ;;
      *)
        echo "[pre-push] unknown hook_index_coverage_mode '$INDEX_COVERAGE_MODE'; defaulting to authoring-only." >&2
        if is_cwf_authoring_repo; then
          should_run_index_coverage="true"
          index_coverage_blocking="true"
        fi
        ;;
    esac

    if [[ "$should_run_index_coverage" == "true" ]]; then
      echo "[pre-push] index coverage checks (mode: $INDEX_COVERAGE_MODE, blocking: $index_coverage_blocking)..."
      if ! run_index_coverage_checks; then
        if [[ "$index_coverage_blocking" == "true" ]]; then
          exit 1
        fi
        echo "[pre-push] index coverage checks failed (non-blocking mode)." >&2
      fi
    else
      echo "[pre-push] index coverage checks skipped by policy (mode: $INDEX_COVERAGE_MODE)."
    fi
  else
    echo "[pre-push] check-index-coverage.sh unavailable; skipping index coverage checks." >&2
  fi
fi

if [[ -n "$CWF_UNIFIED_GATE" ]]; then
  echo "[pre-push] unified portability gate (hook context)..."
  bash "$CWF_UNIFIED_GATE" --contract auto --context hook
fi

if ! run_pre_push_extension "$SETUP_CONTRACT_PATH"; then
  exit 1
fi

if [[ "$PROFILE" == "strict" ]]; then
  if ! is_cwf_authoring_repo; then
    echo "[pre-push] strict CWF authoring checks skipped (non-CWF repository)." >&2
  else
    if [[ -n "$CWF_SCRIPT_DEPS" ]]; then
      echo "[pre-push] runtime script dependency checks..."
      bash "$CWF_SCRIPT_DEPS" --strict
    else
      echo "[pre-push] check-script-deps.sh unavailable; skipping strict dependency checks." >&2
    fi

    if [[ -n "$CWF_README_STRUCTURE" ]]; then
      echo "[pre-push] README structure checks..."
      bash "$CWF_README_STRUCTURE" --strict
    else
      echo "[pre-push] check-readme-structure.sh unavailable; skipping README structure checks." >&2
    fi

    if [[ -n "$CWF_PROVENANCE" ]]; then
      echo "[pre-push] provenance freshness report (inform)..."
      bash "$CWF_PROVENANCE" --level inform || true
    else
      echo "[pre-push] $CWF_PROVENANCE missing; skipping provenance report" >&2
    fi

    if [[ -n "$CWF_GROWTH_DRIFT" ]]; then
      echo "[pre-push] growth-drift report (inform)..."
      bash "$CWF_GROWTH_DRIFT" --level inform || true
    else
      echo "[pre-push] $CWF_GROWTH_DRIFT missing; skipping growth-drift report" >&2
    fi
  fi
fi
