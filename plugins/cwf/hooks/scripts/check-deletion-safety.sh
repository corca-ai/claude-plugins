#!/usr/bin/env bash
set -euo pipefail
# check-deletion-safety.sh — PreToolUse fail-closed guard for destructive deletions.
# Blocks BEFORE execution when the command would delete files that have in-repo callers.
#
# Detection boundary: grep -rl only catches literal string matches; interpolated paths
# are an accepted residual risk.
# Scope: Bash tool calls only (Write/Edit do not delete filesystem entries).

HOOK_GROUP="deletion_safety"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ARTIFACT_PATHS_SCRIPT="$PLUGIN_ROOT/scripts/cwf-artifact-paths.sh"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"

INPUT="$(cat)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  exit 0
fi

json_block() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    local reason_json
    reason_json="$(printf '%s' "$reason" | jq -Rs .)"
    cat <<EOF
{"decision":"block","reason":${reason_json}}
EOF
  else
    cat <<'EOF'
{"decision":"block","reason":"Deletion safety gate requires jq for safe parsing."}
EOF
  fi
  exit 1
}

trim_ws() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_quotes() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

to_repo_rel() {
  local raw_path="$1"
  local rel=""

  raw_path="$(trim_ws "$raw_path")"
  raw_path="$(strip_quotes "$raw_path")"
  [[ -n "$raw_path" ]] || return 1

  if [[ "$raw_path" == /* ]]; then
    if [[ "$raw_path" != "$REPO_ROOT/"* ]]; then
      return 1
    fi
    rel="${raw_path#"$REPO_ROOT"/}"
  else
    rel="$raw_path"
  fi

  while [[ "$rel" == ./* ]]; do
    rel="${rel#./}"
  done

  if [[ "$rel" == ../* || "$rel" == */../* ]]; then
    return 1
  fi

  printf '%s' "$rel"
}

normalize_rel_path() {
  local value="$1"
  value="${value#./}"
  value="${value%/}"
  printf '%s' "$value"
}

append_runtime_artifact_prefix() {
  local candidate_rel="${1:-}"
  local normalized=""
  local existing=""

  [[ -n "$candidate_rel" ]] || return 0
  normalized="$(normalize_rel_path "$candidate_rel")"
  [[ -n "$normalized" && "$normalized" != "." ]] || return 0

  for existing in "${RUNTIME_ARTIFACT_PREFIXES[@]}"; do
    if [[ "$existing" == "$normalized" ]]; then
      return 0
    fi
  done
  RUNTIME_ARTIFACT_PREFIXES+=("$normalized")
}

append_runtime_artifact_abs() {
  local abs_path="${1:-}"
  local rel=""

  [[ -n "$abs_path" ]] || return 0
  abs_path="${abs_path%/}"

  if [[ "$abs_path" == "$REPO_ROOT" || "$abs_path" != "$REPO_ROOT/"* ]]; then
    return 0
  fi
  rel="${abs_path#"$REPO_ROOT"/}"
  append_runtime_artifact_prefix "$rel"
}

init_runtime_artifact_prefixes() {
  local projects_dir=""
  local sessions_dir=""
  local prompt_logs_dir=""

  RUNTIME_ARTIFACT_PREFIXES=()
  if [[ -f "$ARTIFACT_PATHS_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$ARTIFACT_PATHS_SCRIPT"
    projects_dir="$(resolve_cwf_projects_dir "$REPO_ROOT" 2>/dev/null || true)"
    sessions_dir="$(resolve_cwf_session_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    prompt_logs_dir="$(resolve_cwf_prompt_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    append_runtime_artifact_abs "$projects_dir"
    append_runtime_artifact_abs "$sessions_dir"
    append_runtime_artifact_abs "$prompt_logs_dir"
  fi

  append_runtime_artifact_prefix ".cwf/projects"
  append_runtime_artifact_prefix ".cwf/sessions"
  append_runtime_artifact_prefix ".cwf/prompt-logs"
}

is_runtime_artifact_rel() {
  local rel_path="$1"
  local normalized=""
  local prefix=""

  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" ]] || return 1

  for prefix in "${RUNTIME_ARTIFACT_PREFIXES[@]}"; do
    if [[ "$normalized" == "$prefix" || "$normalized" == "$prefix/"* ]]; then
      return 0
    fi
  done
  return 1
}

is_external_tmp_artifact() {
  local raw_path="$1"
  local tmp_root=""

  raw_path="$(trim_ws "$raw_path")"
  raw_path="$(strip_quotes "$raw_path")"
  [[ "$raw_path" == /* ]] || return 1

  if [[ "$raw_path" == "$REPO_ROOT/"* ]]; then
    return 1
  fi

  case "$raw_path" in
    /tmp/*|/private/tmp/*) return 0 ;;
  esac

  tmp_root="${TMPDIR:-}"
  tmp_root="${tmp_root%/}"
  if [[ -n "$tmp_root" && "$raw_path" == "$tmp_root"/* ]]; then
    return 0
  fi

  return 1
}

extract_deleted_from_bash() {
  local command_text="$1"
  local normalized=""
  local segment=""
  local i=0
  local start_idx=0
  local arg=""

  normalized="$(printf '%s' "$command_text" | tr '\n' ' ' | sed -E 's/&&/;/g; s/\|\|/;/g')"
  IFS=';' read -r -a segments <<< "$normalized"

  for segment in "${segments[@]}"; do
    segment="$(trim_ws "$segment")"
    [[ -n "$segment" ]] || continue
    IFS=' ' read -r -a argv <<< "$segment"
    [[ ${#argv[@]} -gt 0 ]] || continue

    if [[ "${argv[0]}" == "git" && "${argv[1]:-}" == "rm" ]]; then
      start_idx=2
    elif [[ "${argv[0]}" == "rm" || "${argv[0]}" == "/bin/rm" ]]; then
      start_idx=1
    elif [[ "${argv[0]}" == "unlink" ]]; then
      start_idx=1
    else
      continue
    fi

    for ((i = start_idx; i < ${#argv[@]}; i++)); do
      arg="${argv[$i]}"
      [[ -n "$arg" ]] || continue
      if [[ "$arg" == -* ]]; then
        continue
      fi
      if [[ "$arg" == *"*"* || "$arg" == *"?"* || "$arg" == *"["* ]]; then
        WILDCARD_DELETE=1
        continue
      fi
      DELETED_RAW+=("$arg")
    done
  done
}

search_callers() {
  local needle="$1"
  local rc=0
  local output=""
  local stderr_tmp=""

  stderr_tmp="$(mktemp "${TMPDIR:-/tmp}/cwf-deletion-safety-XXXXXX.err" 2>/dev/null || true)"
  if [[ -z "$stderr_tmp" ]]; then
    SEARCH_FAILED=1
    SEARCH_ERROR="failed to allocate temporary file for deletion-safety search"
    return 0
  fi

  set +e
  output="$(cd "$REPO_ROOT" && grep -rl --fixed-strings \
    --include='*.sh' \
    --include='*.md' \
    --include='*.mjs' \
    --include='*.yaml' \
    --include='*.json' \
    --include='*.py' \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    --exclude-dir=projects \
    --exclude-dir=prompt-logs \
    --exclude-dir=sessions \
    "$needle" . 2>"$stderr_tmp")"
  rc=$?
  set -e

  if [[ $rc -gt 1 ]]; then
    SEARCH_FAILED=1
    SEARCH_ERROR="$(head -n 1 "$stderr_tmp" 2>/dev/null || true)"
    rm -f "$stderr_tmp"
    return 0
  fi

  rm -f "$stderr_tmp"
  printf '%s\n' "$output"
}

TOOL_NAME=""
TOOL_COMMAND=""

if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // .tool // empty')"
  TOOL_COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
else
  if printf '%s' "$INPUT" | grep -Eiq 'git[[:space:]]+rm|(^|[^[:alnum:]_])rm[[:space:]]|unlink[[:space:]]'; then
    json_block "Deletion safety gate requires jq for safe parsing."
  fi
  exit 0
fi

DELETED_RAW=()
WILDCARD_DELETE=0
SEARCH_FAILED=0
SEARCH_ERROR=""
RUNTIME_ARTIFACT_PREFIXES=()

init_runtime_artifact_prefixes

if [[ "$TOOL_NAME" == "Bash" && -n "$TOOL_COMMAND" ]]; then
  extract_deleted_from_bash "$TOOL_COMMAND"
fi

if [[ ${#DELETED_RAW[@]} -eq 0 && "$WILDCARD_DELETE" -eq 0 ]]; then
  exit 0
fi

if [[ "$WILDCARD_DELETE" -eq 1 ]]; then
  json_block "BLOCKED: wildcard deletion detected. Resolve to explicit file paths and rerun."
fi

DELETED_REL=()
for candidate in "${DELETED_RAW[@]}"; do
  if is_external_tmp_artifact "$candidate"; then
    continue
  fi

  rel_path="$(to_repo_rel "$candidate" || true)"
  [[ -n "$rel_path" ]] || continue

  case "$rel_path" in
    node_modules/*) continue ;;
  esac
  if is_runtime_artifact_rel "$rel_path"; then
    continue
  fi

  is_dup=0
  for existing in "${DELETED_REL[@]}"; do
    if [[ "$existing" == "$rel_path" ]]; then
      is_dup=1
      break
    fi
  done
  if [[ "$is_dup" -eq 0 ]]; then
    DELETED_REL+=("$rel_path")
  fi
done

if [[ ${#DELETED_REL[@]} -eq 0 ]]; then
  exit 0
fi

FILES_WITH_CALLERS=()
CALLER_LINES=()

for rel_path in "${DELETED_REL[@]}"; do
  combined_hits="$(search_callers "$rel_path")"

  base_name="$(basename "$rel_path")"
  if [[ -n "$base_name" && "$base_name" != "$rel_path" ]]; then
    base_hits="$(search_callers "$base_name")"
    if [[ -n "$base_hits" ]]; then
      combined_hits="$(printf '%s\n%s\n' "$combined_hits" "$base_hits")"
    fi
  fi

  if [[ "$SEARCH_FAILED" -eq 1 ]]; then
    json_block "BLOCKED: deletion safety search failed (${SEARCH_ERROR:-unknown error})."
  fi

  combined_hits="$(printf '%s\n' "$combined_hits" | sed '/^$/d' | sed 's#^\./##' | sort -u)"
  filtered_hits=()
  while IFS= read -r caller_path; do
    [[ -n "$caller_path" ]] || continue
    if [[ "$caller_path" == "$rel_path" ]]; then
      continue
    fi
    if is_runtime_artifact_rel "$caller_path"; then
      continue
    fi
    filtered_hits+=("$caller_path")
  done <<< "$combined_hits"
  if [[ ${#filtered_hits[@]} -gt 0 ]]; then
    combined_hits="$(printf '%s\n' "${filtered_hits[@]}" | sort -u)"
  else
    combined_hits=""
  fi
  if [[ -z "$combined_hits" ]]; then
    continue
  fi

  FILES_WITH_CALLERS+=("$rel_path")
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    CALLER_LINES+=("$line")
    if [[ ${#CALLER_LINES[@]} -ge 6 ]]; then
      break
    fi
  done <<< "$combined_hits"
done

if [[ ${#FILES_WITH_CALLERS[@]} -eq 0 ]]; then
  exit 0
fi

blocked_files="$(printf '%s, ' "${FILES_WITH_CALLERS[@]}")"
blocked_files="${blocked_files%, }"

caller_preview=""
if [[ ${#CALLER_LINES[@]} -gt 0 ]]; then
  caller_preview="$(printf '%s; ' "${CALLER_LINES[@]}")"
  caller_preview="${caller_preview%; }"
fi

reason="BLOCKED: deleted file(s) have runtime callers: ${blocked_files}."
if [[ -n "$caller_preview" ]]; then
  reason="${reason} Callers: ${caller_preview}."
fi
reason="${reason} Restore file(s) or remove callers first."

json_block "$reason"
