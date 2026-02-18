#!/usr/bin/env bash
set -euo pipefail

# next-prompt-dir.sh — Resolve or bootstrap the next session directory for today.
# Usage: plugins/cwf/scripts/next-prompt-dir.sh [--bootstrap] <title>
# Output: <projects-dir>/YYMMDD-NN-title (NN = zero-padded sequence number)
# --bootstrap:
#   - create session directory
#   - initialize plan.md and lessons.md when missing
#   - append a pending session entry to cwf-state.yaml sessions when missing
# Optional env for deterministic testing:
#   CWF_NEXT_PROMPT_DATE=YYMMDD   Override today's date
#   CWF_PROJECTS_DIR=/path        Override projects scan directory
#   CWF_ARTIFACT_ROOT=/path        Override artifact root (default: ./.cwf)
#   CWF_STATE_FILE=/path          Override state file path

usage() {
  cat >&2 <<'EOF'
Usage: plugins/cwf/scripts/next-prompt-dir.sh [--bootstrap] <title>

Options:
  --bootstrap   Create the resolved session directory, initialize plan/lessons,
                and register the new session in cwf-state.yaml (if present)
  -h, --help    Show this help message
EOF
}

bootstrap=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap)
      bootstrap=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

title="$1"

resolve_project_root() {
  local git_root=""
  local candidate=""
  local script_dir=""
  local root_override="${CWF_PROJECT_ROOT:-}"

  if [[ -n "$root_override" ]]; then
    if [[ -d "$root_override" ]]; then
      printf '%s\n' "$(cd "$root_override" && pwd)"
      return 0
    fi
    echo "Warning: CWF_PROJECT_ROOT is set but not a directory: $root_override" >&2
  fi

  # Prefer git root from the caller's current working directory.
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$git_root"
    return 0
  fi

  # Fallback: walk ancestor directories from caller cwd.
  candidate="$(pwd)"
  while [[ -n "$candidate" ]]; do
    if [[ -e "$candidate/.git" || -f "$candidate/AGENTS.md" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if [[ "$candidate" == "/" ]]; then
      break
    fi
    candidate="$(dirname "$candidate")"
  done

  # Compatibility fallback: walk ancestors from the script location.
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  candidate="$script_dir"
  while [[ -n "$candidate" ]]; do
    if [[ -e "$candidate/.git" || -f "$candidate/AGENTS.md" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if [[ "$candidate" == "/" ]]; then
      break
    fi
    candidate="$(dirname "$candidate")"
  done

  echo "Unable to resolve project root from current working directory: $(pwd)" >&2
  return 1
}

project_root="$(resolve_project_root)"
resolver_script="$(cd "$(dirname "$0")" && pwd)/cwf-artifact-paths.sh"

if [[ ! -f "$resolver_script" ]]; then
  echo "Missing resolver script: $resolver_script" >&2
  exit 1
fi

# shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
source "$resolver_script"
projects_dir="$(resolve_cwf_projects_dir "$project_root")"
projects_rel="$(resolve_cwf_projects_relpath "$project_root")"

# Get date in YYMMDD format (overridable for fixture tests).
today="${CWF_NEXT_PROMPT_DATE:-$(date +%y%m%d)}"
if [[ ! "$today" =~ ^[0-9]{6}$ ]]; then
  echo "Error: CWF_NEXT_PROMPT_DATE must match YYMMDD, got '$today'" >&2
  exit 2
fi

# Find existing directories for today and determine the next sequence number
max_seq=0
if [[ -d "$projects_dir" ]]; then
  while IFS= read -r -d '' dir; do
    basename="$(basename "$dir")"

    # Match only YYMMDD-NN-*; ignore other same-day directories.
    if [[ "$basename" =~ ^${today}-([0-9]{2})- ]]; then
      seq_str="${BASH_REMATCH[1]}"
      seq_num=$((10#$seq_str))
      if (( seq_num > max_seq )); then
        max_seq=$seq_num
      fi
    fi
  done < <(
    find "$projects_dir" -mindepth 1 -maxdepth 1 -type d -name "${today}-*" -print0 2>/dev/null
  )
fi

next_seq=$(( max_seq + 1 ))
next_seq_padded=$(printf "%02d" "$next_seq")

if [[ "$projects_rel" == "." ]]; then
  session_path="${today}-${next_seq_padded}-${title}"
else
  session_path="${projects_rel}/${today}-${next_seq_padded}-${title}"
fi

escape_yaml_dq() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

session_entry_exists() {
  local state_file="$1"
  local target_dir="$2"

  awk -v target="$target_dir" '
    BEGIN { in_sessions=0; found=0 }
    /^sessions:[[:space:]]*$/ { in_sessions=1; next }
    in_sessions && /^[^[:space:]#]/ { exit }
    in_sessions {
      if ($0 ~ /^[[:space:]]*dir:[[:space:]]*/) {
        line=$0
        sub(/^[[:space:]]*dir:[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        gsub(/^"/, "", line); gsub(/"$/, "", line)
        gsub(/^'\''/, "", line); gsub(/'\''$/, "", line)
        if (line == target) {
          found=1
          exit
        }
      }
    }
    END { exit(found ? 0 : 1) }
  ' "$state_file"
}

append_session_entry() {
  local state_file="$1"
  local session_id="$2"
  local session_title="$3"
  local session_dir="$4"
  local session_branch="$5"
  local tmp_file

  tmp_file="$(mktemp)"
  awk \
    -v sid="$session_id" \
    -v stitle="$session_title" \
    -v sdir="$session_dir" \
    -v sbranch="$session_branch" '
    BEGIN { in_sessions=0; inserted=0 }
    /^sessions:[[:space:]]*$/ {
      in_sessions=1
      print
      next
    }
    in_sessions && /^[^[:space:]#]/ {
      if (!inserted) {
        print ""
        print "  - id: \"" sid "\""
        print "    title: \"" stitle "\""
        print "    dir: \"" sdir "\""
        print "    branch: \"" sbranch "\""
        print "    artifacts: [plan.md, lessons.md]"
        print ""
        inserted=1
      }
      in_sessions=0
    }
    { print }
    END {
      if (in_sessions && !inserted) {
        print ""
        print "  - id: \"" sid "\""
        print "    title: \"" stitle "\""
        print "    dir: \"" sdir "\""
        print "    branch: \"" sbranch "\""
        print "    artifacts: [plan.md, lessons.md]"
      }
    }
  ' "$state_file" > "$tmp_file"
  mv "$tmp_file" "$state_file"
}

bootstrap_session() {
  local session_abs_path="$1"
  local state_file
  local branch
  local session_id
  local escaped_title
  local escaped_dir
  local escaped_branch

  mkdir -p "$session_abs_path"

  if [[ ! -f "$session_abs_path/plan.md" ]]; then
    cat > "$session_abs_path/plan.md" <<EOF
# Plan — ${title}

Initialized by \`next-prompt-dir --bootstrap\`.
Replace this with the finalized plan content.
EOF
  fi

  if [[ ! -f "$session_abs_path/lessons.md" ]]; then
    cat > "$session_abs_path/lessons.md" <<EOF
# Lessons — ${title}

- Initialized by \`next-prompt-dir --bootstrap\`
- Add concrete learnings during planning and implementation
EOF
  fi

  state_file="$(resolve_cwf_state_file "$project_root")"
  if [[ ! -f "$state_file" ]]; then
    return 0
  fi

  if ! grep -q '^sessions:[[:space:]]*$' "$state_file"; then
    return 0
  fi

  if session_entry_exists "$state_file" "$session_path"; then
    return 0
  fi

  branch="$(git -C "$project_root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    branch="unknown"
  fi

  session_id="S${today}-${next_seq_padded}"
  escaped_title="$(escape_yaml_dq "$title")"
  escaped_dir="$(escape_yaml_dq "$session_path")"
  escaped_branch="$(escape_yaml_dq "$branch")"

  append_session_entry "$state_file" "$session_id" "$escaped_title" "$escaped_dir" "$escaped_branch"
}

if [[ "$bootstrap" == "true" ]]; then
  session_abs="$(resolve_cwf_abs_path "$project_root" "$session_path")"
  bootstrap_session "$session_abs"
fi

echo "$session_path"
