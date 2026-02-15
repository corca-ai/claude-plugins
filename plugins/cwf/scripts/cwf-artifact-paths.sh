#!/usr/bin/env bash
# cwf-artifact-paths.sh: shared path resolver for CWF artifacts.

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
  local raw_artifact_root="${CWF_ARTIFACT_ROOT:-$base_dir}"

  resolve_cwf_abs_path "$base_dir" "$raw_artifact_root"
}

resolve_cwf_prompt_logs_dir() {
  local base_dir="$1"
  local artifact_root
  local raw_prompt_logs_dir="${CWF_PROMPT_LOGS_DIR:-}"

  artifact_root="$(resolve_cwf_artifact_root "$base_dir")"
  if [[ -n "$raw_prompt_logs_dir" ]]; then
    resolve_cwf_abs_path "$base_dir" "$raw_prompt_logs_dir"
  else
    printf '%s\n' "$artifact_root/prompt-logs"
  fi
}

# Return a stable session-path prefix for script output.
# Legacy compatibility:
# - When CWF_PROMPT_LOGS_DIR is absolute outside base_dir, keep "prompt-logs".
resolve_cwf_prompt_logs_relpath() {
  local base_dir="$1"
  local raw_prompt_logs_dir="${CWF_PROMPT_LOGS_DIR:-}"
  local raw_artifact_root="${CWF_ARTIFACT_ROOT:-}"
  local rel_path=""

  if [[ -n "$raw_prompt_logs_dir" ]]; then
    if [[ "$raw_prompt_logs_dir" == /* ]]; then
      if [[ "$raw_prompt_logs_dir" == "$base_dir/"* ]]; then
        rel_path="${raw_prompt_logs_dir#$base_dir/}"
      else
        printf '%s\n' "prompt-logs"
        return 0
      fi
    else
      rel_path="$raw_prompt_logs_dir"
    fi
  elif [[ -n "$raw_artifact_root" ]]; then
    if [[ "$raw_artifact_root" == /* ]]; then
      if [[ "$raw_artifact_root" == "$base_dir/"* ]]; then
        rel_path="${raw_artifact_root#$base_dir/}/prompt-logs"
      else
        printf '%s\n' "$raw_artifact_root/prompt-logs"
        return 0
      fi
    else
      rel_path="$raw_artifact_root/prompt-logs"
    fi
  else
    rel_path="prompt-logs"
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
