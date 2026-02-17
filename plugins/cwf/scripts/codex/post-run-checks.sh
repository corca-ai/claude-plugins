#!/usr/bin/env bash
# post-run-checks.sh: Run non-blocking quality checks for files changed by a Codex run.
#
# Usage:
#   post-run-checks.sh [--cwd <path>] [--since-epoch <sec>] [--mode warn|strict] [--quiet]
#
# Default mode is "warn" (always exit 0). "strict" exits non-zero when checks fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REFACTOR_CHECK_LINKS="$PLUGIN_ROOT/skills/refactor/scripts/check-links.sh"
LIVE_STATE_SCRIPT="$PLUGIN_ROOT/scripts/cwf-live-state.sh"
CHECK_SESSION_SCRIPT="$PLUGIN_ROOT/scripts/check-session.sh"
ARTIFACT_PATHS_SCRIPT="$PLUGIN_ROOT/scripts/cwf-artifact-paths.sh"

CWD="$(pwd)"
SINCE_EPOCH=""
MODE="warn"
QUIET="false"

usage() {
  cat <<'USAGE'
Usage:
  post-run-checks.sh [--cwd <path>] [--since-epoch <sec>] [--mode warn|strict] [--quiet]

Options:
  --cwd <path>          Working directory to inspect (default: current directory)
  --since-epoch <sec>   Only include changed files modified at/after this epoch
  --mode <warn|strict>  warn: report only, strict: return non-zero on failures
  --quiet               Suppress informational logs (failures still shown)
  -h, --help            Show this help
USAGE
}

log() {
  if [[ "$QUIET" != "true" ]]; then
    echo "[cwf:codex post-run] $*"
  fi
}

warn() {
  echo "[cwf:codex post-run] WARN: $*" >&2
}

file_mtime_epoch() {
  local path="$1"
  stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null || echo "0"
}

normalize_yaml_scalar() {
  local v="$1"
  v="${v%%#*}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  if [[ "$v" =~ ^\".*\"$ ]] || [[ "$v" =~ ^\'.*\'$ ]]; then
    v="${v:1:${#v}-2}"
  fi
  printf '%s' "$v"
}

extract_live_field() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      pat = "^[[:space:]]{2}" key ":[[:space:]]*"
      if ($0 ~ pat) {
        sub(pat, "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

extract_live_hitl_field() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      if ($0 ~ /^[[:space:]]+hitl:[[:space:]]*$/) {
        in_hitl=1
        next
      }
      if (in_hitl && $0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:/ && $0 !~ /^[[:space:]]{4}/) {
        in_hitl=0
      }
      if (in_hitl) {
        pat = "^[[:space:]]{4}" key ":[[:space:]]*"
        if ($0 ~ pat) {
          sub(pat, "", $0)
          print $0
          exit
        }
      }
    }
  ' "$file"
}

resolve_repo_path() {
  local value="$1"
  if [[ -z "$value" ]]; then
    return 1
  fi
  if [[ "$value" == /* ]]; then
    printf '%s' "$value"
  else
    printf '%s/%s' "$REPO_ROOT" "$value"
  fi
}

normalize_rel_path() {
  local value="$1"
  value="${value#./}"
  value="${value%/}"
  printf '%s' "$value"
}

add_runtime_skip_prefix() {
  local rel_path="${1:-}"
  local normalized=""
  local existing=""

  [[ -n "$rel_path" ]] || return 0
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" && "$normalized" != "." ]] || return 0

  for existing in "${RUNTIME_MD_SKIP_PREFIXES[@]}"; do
    if [[ "$existing" == "$normalized" ]]; then
      return 0
    fi
  done
  RUNTIME_MD_SKIP_PREFIXES+=("$normalized")
}

add_runtime_skip_abs_dir() {
  local abs_path="${1:-}"
  local rel_path=""

  [[ -n "$abs_path" ]] || return 0
  abs_path="${abs_path%/}"

  if [[ "$abs_path" == "$REPO_ROOT" || "$abs_path" != "$REPO_ROOT/"* ]]; then
    return 0
  fi
  rel_path="${abs_path#"$REPO_ROOT"/}"
  add_runtime_skip_prefix "$rel_path"
}

init_runtime_skip_paths() {
  local projects_dir=""
  local sessions_dir=""
  local prompt_logs_dir=""
  local state_file=""

  RUNTIME_MD_SKIP_PREFIXES=()
  HITL_SCRATCHPAD_GLOB_PREFIX=".cwf/projects"
  LIVE_STATE_FILE_PROBE="$REPO_ROOT/.cwf/cwf-state.yaml"

  if [[ -f "$ARTIFACT_PATHS_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$ARTIFACT_PATHS_SCRIPT"
    projects_dir="$(resolve_cwf_projects_dir "$REPO_ROOT" 2>/dev/null || true)"
    sessions_dir="$(resolve_cwf_session_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    prompt_logs_dir="$(resolve_cwf_prompt_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    state_file="$(resolve_cwf_state_file "$REPO_ROOT" 2>/dev/null || true)"

    add_runtime_skip_abs_dir "$projects_dir"
    add_runtime_skip_abs_dir "$sessions_dir"
    add_runtime_skip_abs_dir "$prompt_logs_dir"

    if [[ -n "$projects_dir" && "$projects_dir" == "$REPO_ROOT/"* ]]; then
      HITL_SCRATCHPAD_GLOB_PREFIX="${projects_dir#"$REPO_ROOT"/}"
      HITL_SCRATCHPAD_GLOB_PREFIX="$(normalize_rel_path "$HITL_SCRATCHPAD_GLOB_PREFIX")"
    fi

    if [[ -n "$state_file" ]]; then
      LIVE_STATE_FILE_PROBE="$state_file"
    fi
  fi

  add_runtime_skip_prefix ".cwf/projects"
  add_runtime_skip_prefix ".cwf/sessions"
  add_runtime_skip_prefix ".cwf/prompt-logs"
}

is_runtime_md_artifact_path() {
  local rel_path="$1"
  local normalized=""
  local prefix=""

  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" ]] || return 1

  for prefix in "${RUNTIME_MD_SKIP_PREFIXES[@]}"; do
    if [[ "$normalized" == "$prefix" || "$normalized" == "$prefix/"* ]]; then
      return 0
    fi
  done
  return 1
}

is_hitl_scratchpad_path() {
  local rel_path="$1"
  if [[ -n "$HITL_SCRATCHPAD_GLOB_PREFIX" && "$rel_path" == "$HITL_SCRATCHPAD_GLOB_PREFIX"/*/hitl/hitl-scratchpad.md ]]; then
    return 0
  fi
  return 1
}

command_invokes_apply_patch() {
  local cmd="$1"
  local sanitized=""
  # Strip quoted strings first to avoid false positives from search patterns
  # like `rg "apply_patch"` that mention the token as plain text.
  sanitized="$(printf '%s' "$cmd" | sed -E "s/'([^'\\\\]|\\\\.)*'//g; s/\"([^\"\\\\]|\\\\.)*\"//g")"
  printf '%s\n' "$sanitized" | grep -Eq '(^|[[:space:];|&()])apply_patch([[:space:]]|$)'
}

find_latest_codex_session_for_cwd() {
  local target_cwd="$1"
  local min_epoch="${2:-}"
  local sessions_dir="${CODEX_SESSIONS_DIR:-$HOME/.codex/sessions}"
  local f
  local file_epoch
  local session_cwd

  [[ -d "$sessions_dir" ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1

  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    if [[ -n "$min_epoch" ]]; then
      file_epoch="$(file_mtime_epoch "$f")"
      if [[ -n "$file_epoch" && "$file_epoch" -lt "$min_epoch" ]]; then
        continue
      fi
    fi

    session_cwd="$(jq -r 'select(.type == "session_meta") | .payload.cwd // empty' "$f" 2>/dev/null | head -n1)"
    if [[ "$session_cwd" == "$target_cwd" ]]; then
      printf '%s' "$f"
      return 0
    fi
  done < <(find "$sessions_dir" -type f -name '*.jsonl' -print0 2>/dev/null | xargs -0 ls -1t 2>/dev/null || true)

  return 1
}

check_exec_command_tool_hygiene() {
  local target_cwd="$1"
  local since_epoch="${2:-0}"
  local jsonl=""
  local cmd=""
  local jq_since=0

  if ! command -v jq >/dev/null 2>&1; then
    log "jq not found; skipping exec_command hygiene check"
    return 0
  fi

  jsonl="$(find_latest_codex_session_for_cwd "$target_cwd" "$SINCE_EPOCH" || true)"
  if [[ -z "$jsonl" || ! -f "$jsonl" ]]; then
    log "no codex session jsonl matched cwd; skipping exec_command hygiene check"
    return 0
  fi

  if [[ -n "$since_epoch" ]]; then
    jq_since="$since_epoch"
  fi

  while IFS= read -r cmd; do
    [[ -n "$cmd" ]] || continue
    if command_invokes_apply_patch "$cmd"; then
      warn "tool hygiene check failed: exec_command payload invokes apply_patch"
      warn "offending cmd: $(printf '%s' "$cmd" | tr '\n' ' ' | cut -c1-140)"
      return 1
    fi
  done < <(
    jq -r --argjson since "$jq_since" '
      select(.type == "response_item" and .payload.type == "function_call" and .payload.name == "exec_command")
      | select(((.timestamp | try fromdateiso8601 catch 0) >= $since))
      | (.payload.arguments | try fromjson catch {} | .cmd // empty)
    ' "$jsonl" 2>/dev/null || true
  )

  return 0
}

check_hitl_scratchpad_sync() {
  local since_epoch="${1:-}"
  local live_state_file=""
  local phase_raw=""
  local phase=""
  local hitl_state_raw=""
  local hitl_state_file=""
  local hitl_status_raw=""
  local hitl_status=""
  local scratchpad_file=""
  local scratchpad_rel=""
  local doc_sync_target_count=0
  local scratchpad_touched=0
  local file=""

  if [[ "${#md_files[@]}" -eq 0 ]]; then
    return 0
  fi

  if [[ ! -x "$LIVE_STATE_SCRIPT" ]]; then
    log "cwf-live-state.sh not found; skipping HITL scratchpad sync gate"
    return 0
  fi

  live_state_file="$(bash "$LIVE_STATE_SCRIPT" resolve 2>/dev/null || true)"
  if [[ -z "$live_state_file" || ! -f "$live_state_file" ]]; then
    log "live-state file not found; skipping HITL scratchpad sync gate"
    return 0
  fi

  phase_raw="$(extract_live_field "$live_state_file" "phase" || true)"
  phase="$(normalize_yaml_scalar "$phase_raw")"
  hitl_state_raw="$(extract_live_hitl_field "$live_state_file" "state_file" || true)"
  hitl_state_raw="$(normalize_yaml_scalar "$hitl_state_raw")"

  if [[ -z "$hitl_state_raw" && "$phase" != "hitl" ]]; then
    return 0
  fi

  if [[ -z "$hitl_state_raw" ]]; then
    warn "HITL sync gate failed: live phase is hitl but live.hitl.state_file is empty"
    return 1
  fi

  hitl_state_file="$(resolve_repo_path "$hitl_state_raw" || true)"
  if [[ -z "$hitl_state_file" || ! -f "$hitl_state_file" ]]; then
    warn "HITL sync gate failed: missing hitl state file ($hitl_state_raw)"
    return 1
  fi

  hitl_status_raw="$(awk '/^status:[[:space:]]*/ { sub(/^status:[[:space:]]*/, "", $0); print; exit }' "$hitl_state_file")"
  hitl_status="$(normalize_yaml_scalar "$hitl_status_raw")"
  if [[ "$hitl_status" == "completed" || "$hitl_status" == "closed_by_user" ]]; then
    return 0
  fi

  scratchpad_file="$(cd "$(dirname "$hitl_state_file")" && pwd)/hitl-scratchpad.md"
  if [[ ! -f "$scratchpad_file" ]]; then
    warn "HITL sync gate failed: scratchpad file not found near hitl state ($scratchpad_file)"
    return 1
  fi

  if [[ "$scratchpad_file" == "$REPO_ROOT/"* ]]; then
    scratchpad_rel="${scratchpad_file#"$REPO_ROOT"/}"
  else
    scratchpad_rel="$scratchpad_file"
  fi

  for file in "${md_files[@]}"; do
    if [[ "$file" == "$scratchpad_rel" ]] || is_hitl_scratchpad_path "$file"; then
      continue
    fi
    doc_sync_target_count=$((doc_sync_target_count + 1))
  done

  if [[ "$doc_sync_target_count" -eq 0 ]]; then
    return 0
  fi

  for file in "${changed_files[@]}"; do
    if [[ "$file" == "$scratchpad_rel" ]] || is_hitl_scratchpad_path "$file"; then
      scratchpad_touched=1
      break
    fi
  done

  if [[ "$scratchpad_touched" -eq 0 && -n "$since_epoch" ]]; then
    if [[ "$(file_mtime_epoch "$scratchpad_file")" -ge "$since_epoch" ]]; then
      scratchpad_touched=1
    fi
  fi

  if [[ "$scratchpad_touched" -eq 0 ]]; then
    warn "HITL sync gate failed: doc markdown changed (${doc_sync_target_count} files) but scratchpad was not updated"
    warn "expected scratchpad update: $scratchpad_rel"
    return 1
  fi

  return 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)
      CWD="${2-}"
      if [[ -z "$CWD" ]]; then
        echo "Error: --cwd requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --since-epoch)
      SINCE_EPOCH="${2-}"
      if [[ -z "$SINCE_EPOCH" ]]; then
        echo "Error: --since-epoch requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --mode)
      MODE="${2-}"
      if [[ "$MODE" != "warn" && "$MODE" != "strict" ]]; then
        echo "Error: --mode must be warn or strict" >&2
        exit 1
      fi
      shift 2
      ;;
    --quiet)
      QUIET="true"
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

if [[ ! -d "$CWD" ]]; then
  warn "cwd does not exist: $CWD"
  exit 0
fi

REPO_ROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  log "not a git repository; skipping post-run checks"
  exit 0
fi
cd "$REPO_ROOT"
RUNTIME_MD_SKIP_PREFIXES=()
HITL_SCRATCHPAD_GLOB_PREFIX=".cwf/projects"
LIVE_STATE_FILE_PROBE="$REPO_ROOT/.cwf/cwf-state.yaml"
init_runtime_skip_paths

readarray -t changed_candidates < <(
  {
    git diff --name-only --diff-filter=ACMR || true
    git diff --cached --name-only --diff-filter=ACMR || true
    git ls-files --others --exclude-standard || true
  } | awk 'NF && !seen[$0]++'
)

if [[ "${#changed_candidates[@]}" -eq 0 ]]; then
  log "no changed files; skipping checks"
  exit 0
fi

changed_files=()
for file in "${changed_candidates[@]}"; do
  [[ -e "$file" ]] || continue
  if [[ -n "$SINCE_EPOCH" ]]; then
    mtime="$(file_mtime_epoch "$file")"
    if [[ "$mtime" -lt "$SINCE_EPOCH" ]]; then
      continue
    fi
  fi
  changed_files+=("$file")
done

if [[ "${#changed_files[@]}" -eq 0 ]]; then
  log "no run-local changed files after since-epoch filter; skipping checks"
  exit 0
fi

md_files=()
sh_files=()
for file in "${changed_files[@]}"; do
  case "$file" in
    *.md|*.mdx)
      if [[ "$file" == references/anthropic-skills-guide/* ]]; then
        continue
      fi
      if is_runtime_md_artifact_path "$file"; then
        continue
      fi
      md_files+=("$file")
      ;;
    *.sh)
      sh_files+=("$file")
      ;;
  esac
done

fail_count=0
check_count=0

if [[ "${#md_files[@]}" -gt 0 ]]; then
  check_count=$((check_count + 1))
  if command -v npx >/dev/null 2>&1; then
    log "markdownlint on changed markdown files (${#md_files[@]})"
    if ! npx --yes markdownlint-cli2 "${md_files[@]}"; then
      warn "markdownlint failed on changed markdown files"
      fail_count=$((fail_count + 1))
    fi
  else
    warn "npx not found; skipping markdownlint"
  fi

  check_count=$((check_count + 1))
  if [[ -x "$REFACTOR_CHECK_LINKS" ]]; then
    log "local link checks on changed markdown files"
    for file in "${md_files[@]}"; do
      case "$file" in
        CHANGELOG.md|references/*)
          continue
          ;;
      esac
      if ! bash "$REFACTOR_CHECK_LINKS" --local --json --file "$file" >/dev/null; then
        warn "local link check failed: $file"
        fail_count=$((fail_count + 1))
      fi
    done
  else
    warn "plugins/cwf/skills/refactor/scripts/check-links.sh not found; skipping link checks"
  fi
fi

if [[ "${#sh_files[@]}" -gt 0 ]]; then
  check_count=$((check_count + 1))
  if command -v shellcheck >/dev/null 2>&1; then
    log "shellcheck on changed shell scripts (${#sh_files[@]})"
    if ! shellcheck -x "${sh_files[@]}"; then
      warn "shellcheck failed on changed shell scripts"
      fail_count=$((fail_count + 1))
    fi
  else
    warn "shellcheck not found; skipping shell lint (run 'cwf:setup --tools' or 'bash plugins/cwf/skills/setup/scripts/install-tooling-deps.sh --install shellcheck')"
  fi
fi

check_count=$((check_count + 1))
if ! check_exec_command_tool_hygiene "$REPO_ROOT" "${SINCE_EPOCH:-0}"; then
  fail_count=$((fail_count + 1))
fi

check_count=$((check_count + 1))
if ! check_hitl_scratchpad_sync "$SINCE_EPOCH"; then
  fail_count=$((fail_count + 1))
fi

check_count=$((check_count + 1))
if [[ -x "$CHECK_SESSION_SCRIPT" && -f "$LIVE_STATE_FILE_PROBE" ]]; then
  log "live session-state check"
  if ! bash "$CHECK_SESSION_SCRIPT" --live >/dev/null; then
    warn "live session-state check failed ($CHECK_SESSION_SCRIPT --live)"
    fail_count=$((fail_count + 1))
  fi
else
  log "check-session live gate unavailable; skipping"
fi

if [[ "$fail_count" -eq 0 ]]; then
  log "post-run checks passed ($check_count checks)"
  exit 0
fi

warn "post-run checks reported $fail_count failure(s)"
if [[ "$MODE" == "strict" ]]; then
  exit 1
fi

exit 0
