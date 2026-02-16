#!/usr/bin/env bash
# cwf-artifact-paths.sh: shared path resolver for CWF artifacts.
# Default artifact root: ./.cwf

set -euo pipefail

_cwf_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

_cwf_strip_quotes() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

_cwf_escape_regex() {
  printf '%s' "$1" | sed 's/[][(){}.^$+*?|\\]/\\&/g'
}

_cwf_read_config_value() {
  local file_path="$1"
  local key="$2"
  local escaped_key
  local line=""
  local value=""

  [[ -f "$file_path" ]] || return 1

  escaped_key="$(_cwf_escape_regex "$key")"
  line=$(grep -shm1 -E "^[[:space:]]*${escaped_key}[[:space:]]*:" "$file_path" 2>/dev/null || true)
  [[ -n "$line" ]] || return 1

  value="${line#*:}"
  value="$(_cwf_trim "$value")"

  # Only treat '#' as comment for unquoted values.
  if [[ ! "$value" =~ ^\".*\"$ ]] && [[ ! "$value" =~ ^\'.*\'$ ]]; then
    value="${value%%#*}"
    value="$(_cwf_trim "$value")"
  fi

  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="$(_cwf_strip_quotes "$value")"
  fi

  [[ -n "$value" ]] || return 1
  printf '%s\n' "$value"
}

_cwf_resolve_config_value() {
  local base_dir="$1"
  local key="$2"
  local local_cfg="${base_dir}/.cwf/config.local.yaml"
  local shared_cfg="${base_dir}/.cwf/config.yaml"
  local resolved=""

  # Project-local override > project-shared config > process environment.
  resolved="$(_cwf_read_config_value "$local_cfg" "$key" 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    printf '%s\n' "$resolved"
    return 0
  fi

  resolved="$(_cwf_read_config_value "$shared_cfg" "$key" 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    printf '%s\n' "$resolved"
    return 0
  fi

  if [[ -n "${!key:-}" ]]; then
    printf '%s\n' "${!key}"
    return 0
  fi

  return 1
}

resolve_cwf_abs_path() {
  local base_dir="$1"
  local raw_path="$2"

  if [[ "$raw_path" == /* ]]; then
    printf '%s\n' "$raw_path"
  else
    printf '%s\n' "$base_dir/$raw_path"
  fi
}

resolve_cwf_artifact_root() {
  local base_dir="$1"
  local raw_artifact_root=""

  raw_artifact_root="$(_cwf_resolve_config_value "$base_dir" "CWF_ARTIFACT_ROOT" 2>/dev/null || true)"
  if [[ -z "$raw_artifact_root" ]]; then
    raw_artifact_root="$base_dir/.cwf"
  fi

  resolve_cwf_abs_path "$base_dir" "$raw_artifact_root"
}

resolve_cwf_projects_dir() {
  local base_dir="$1"
  local artifact_root
  local raw_projects_dir=""

  artifact_root="$(resolve_cwf_artifact_root "$base_dir")"
  raw_projects_dir="$(_cwf_resolve_config_value "$base_dir" "CWF_PROJECTS_DIR" 2>/dev/null || true)"
  if [[ -n "$raw_projects_dir" ]]; then
    resolve_cwf_abs_path "$base_dir" "$raw_projects_dir"
  else
    printf '%s\n' "$artifact_root/projects"
  fi
}

resolve_cwf_session_logs_dir() {
  local base_dir="$1"
  local artifact_root
  local projects_dir
  local modern_default
  local legacy_default
  local raw_log_dir=""

  raw_log_dir="$(_cwf_resolve_config_value "$base_dir" "CWF_SESSION_LOG_DIR" 2>/dev/null || true)"
  if [[ -n "$raw_log_dir" ]]; then
    resolve_cwf_abs_path "$base_dir" "$raw_log_dir"
    return 0
  fi

  artifact_root="$(resolve_cwf_artifact_root "$base_dir")"
  projects_dir="$(resolve_cwf_projects_dir "$base_dir")"
  modern_default="$artifact_root/sessions"
  legacy_default="$projects_dir/sessions"

  # Prefer the modern path when available. If only legacy exists, keep using it
  # so existing repositories don't split logs across two locations.
  if [[ -d "$modern_default" ]]; then
    printf '%s\n' "$modern_default"
  elif [[ -d "$legacy_default" ]]; then
    printf '%s\n' "$legacy_default"
  else
    printf '%s\n' "$modern_default"
  fi
}

resolve_cwf_state_file() {
  local base_dir="$1"
  local artifact_root
  local raw_state_file=""

  raw_state_file="$(_cwf_resolve_config_value "$base_dir" "CWF_STATE_FILE" 2>/dev/null || true)"

  if [[ -n "$raw_state_file" ]]; then
    resolve_cwf_abs_path "$base_dir" "$raw_state_file"
    return 0
  fi

  artifact_root="$(resolve_cwf_artifact_root "$base_dir")"
  printf '%s\n' "$artifact_root/cwf-state.yaml"
}

# Return a stable projects-path prefix for script output.
resolve_cwf_projects_relpath() {
  local base_dir="$1"
  local projects_dir
  local rel_path

  projects_dir="$(resolve_cwf_projects_dir "$base_dir")"

  if [[ "$projects_dir" == "$base_dir" ]]; then
    printf '%s\n' "."
  elif [[ "$projects_dir" == "$base_dir/"* ]]; then
    rel_path="${projects_dir#"$base_dir"/}"
    rel_path="${rel_path#./}"
    rel_path="${rel_path%/}"
    if [[ -z "$rel_path" || "$rel_path" == "." ]]; then
      printf '%s\n' "."
    else
      printf '%s\n' "$rel_path"
    fi
  else
    printf '%s\n' "$projects_dir"
  fi
}
