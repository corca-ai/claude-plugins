#!/usr/bin/env bash
set -euo pipefail
# check-deletion-safety.sh — PreToolUse fail-closed guard for destructive deletions.
# Blocks BEFORE execution when the command would delete files that have in-repo callers.
#
# Detection boundary: grep -rl detects literal string matches only. Variable-interpolated
# references (e.g., "$SCRIPT_DIR/csv-to-toon.sh", source "$DIR/lib.sh") will NOT be
# detected. This is an accepted residual risk — static analysis cannot resolve all
# dynamic references.
#
# Scope: This hook targets Bash tool calls only. The Write and Edit tools overwrite
# file content but do not remove files from the filesystem, so they are out of scope
# for deletion safety.

# shellcheck disable=SC2034
HOOK_GROUP="deletion_safety"
# shellcheck source=cwf-hook-gate.sh
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

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
    "$needle" . 2>/tmp/cwf-deletion-safety.err)"
  rc=$?
  set -e

  if [[ $rc -gt 1 ]]; then
    SEARCH_FAILED=1
    SEARCH_ERROR="$(head -n 1 /tmp/cwf-deletion-safety.err 2>/dev/null || true)"
    rm -f /tmp/cwf-deletion-safety.err
    return 0
  fi

  rm -f /tmp/cwf-deletion-safety.err
  printf '%s\n' "$output"
}

TOOL_NAME=""
TOOL_COMMAND=""

if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // .tool // empty')"
  TOOL_COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
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
  rel_path="$(to_repo_rel "$candidate" || true)"
  [[ -n "$rel_path" ]] || continue

  # Skip non-project paths (not worth caller-searching)
  case "$rel_path" in
    node_modules/*|.cwf/projects/*|tmp/*) continue ;;
  esac
  # Skip absolute /tmp/ paths that survived to_repo_rel
  case "$candidate" in
    /tmp/*) continue ;;
  esac

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
  if [[ -n "$combined_hits" ]]; then
    :
  fi

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
  # Exclude the deleted file itself from caller results (grep -rl returns bare paths)
  combined_hits="$(printf '%s\n' "$combined_hits" | grep -vxF "$rel_path" || true)"
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
