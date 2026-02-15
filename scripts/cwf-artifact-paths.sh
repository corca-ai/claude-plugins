#!/usr/bin/env bash
# cwf-artifact-paths.sh: shared path resolver for CWF artifacts.
# Default artifact root: ./.cwf

set -euo pipefail

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
  local raw_artifact_root="${CWF_ARTIFACT_ROOT:-$base_dir/.cwf}"

  resolve_cwf_abs_path "$base_dir" "$raw_artifact_root"
}

resolve_cwf_projects_dir() {
  local base_dir="$1"
  local artifact_root
  local raw_projects_dir="${CWF_PROJECTS_DIR:-}"

  artifact_root="$(resolve_cwf_artifact_root "$base_dir")"
  if [[ -n "$raw_projects_dir" ]]; then
    resolve_cwf_abs_path "$base_dir" "$raw_projects_dir"
  else
    printf '%s\n' "$artifact_root/projects"
  fi
}

resolve_cwf_state_file() {
  local base_dir="$1"
  local artifact_root
  local raw_state_file="${CWF_STATE_FILE:-}"

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
  local raw_projects_dir="${CWF_PROJECTS_DIR:-}"
  local raw_artifact_root="${CWF_ARTIFACT_ROOT:-}"
  local rel_path=""

  if [[ -n "$raw_projects_dir" ]]; then
    if [[ "$raw_projects_dir" == /* ]]; then
      if [[ "$raw_projects_dir" == "$base_dir/"* ]]; then
        rel_path="${raw_projects_dir#$base_dir/}"
      else
        printf '%s\n' "projects"
        return 0
      fi
    else
      rel_path="$raw_projects_dir"
    fi
  elif [[ -n "$raw_artifact_root" ]]; then
    if [[ "$raw_artifact_root" == /* ]]; then
      if [[ "$raw_artifact_root" == "$base_dir/"* ]]; then
        rel_path="${raw_artifact_root#$base_dir/}/projects"
      else
        printf '%s\n' "$raw_artifact_root/projects"
        return 0
      fi
    else
      rel_path="$raw_artifact_root/projects"
    fi
  else
    rel_path=".cwf/projects"
  fi

  # normalize leading/trailing "./" and slash
  rel_path="${rel_path#./}"
  rel_path="${rel_path%/}"

  if [[ -z "$rel_path" || "$rel_path" == "." ]]; then
    printf '%s\n' "."
  else
    printf '%s\n' "$rel_path"
  fi
}
