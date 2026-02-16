#!/usr/bin/env bash
# Shared environment variable loader for CWF scripts.
#
# Source priority (high -> low):
#   1) Project-local config (.cwf/config.local.yaml)
#   2) Project-shared config (.cwf/config.yaml)
#   3) Current process environment
#   4) Shell profiles (~/.zshenv, ~/.zprofile, ~/.zshrc, ~/.bash_profile, ~/.bashrc, ~/.profile)
#
# Why shell-profile fallback?
# - Reduces runtime coupling to Claude-specific paths while keeping
#   compatibility with non-interactive shell execution.
#
# Safety:
# - Profile values are extracted with grep/string parsing (no eval/source).

CWF_ENV_PROJECT_ROOT=""
CWF_ENV_PROJECT_CONFIG_LOCAL=""
CWF_ENV_PROJECT_CONFIG_SHARED=""

CWF_ENV_PROFILES=(
  "$HOME/.zshenv"
  "$HOME/.zprofile"
  "$HOME/.zshrc"
  "$HOME/.bash_profile"
  "$HOME/.bashrc"
  "$HOME/.profile"
)

cwf_env_strip_quotes() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

cwf_env_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

cwf_env_escape_regex() {
  printf '%s' "$1" | sed 's/[][(){}.^$+*?|\\]/\\&/g'
}

cwf_env_resolve_project_root() {
  if [[ -n "$CWF_ENV_PROJECT_ROOT" ]]; then
    printf '%s' "$CWF_ENV_PROJECT_ROOT"
    return 0
  fi

  local root=""
  if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    CWF_ENV_PROJECT_ROOT="$root"
    printf '%s' "$CWF_ENV_PROJECT_ROOT"
    return 0
  fi

  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    if [[ "${CLAUDE_PROJECT_DIR}" == /* ]]; then
      CWF_ENV_PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
    else
      CWF_ENV_PROJECT_ROOT="$(cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null && pwd || pwd)"
    fi
    printf '%s' "$CWF_ENV_PROJECT_ROOT"
    return 0
  fi

  CWF_ENV_PROJECT_ROOT="$(pwd)"
  printf '%s' "$CWF_ENV_PROJECT_ROOT"
}

cwf_env_init_project_config_paths() {
  if [[ -n "$CWF_ENV_PROJECT_CONFIG_LOCAL" || -n "$CWF_ENV_PROJECT_CONFIG_SHARED" ]]; then
    return 0
  fi

  local root
  root="$(cwf_env_resolve_project_root)"
  CWF_ENV_PROJECT_CONFIG_LOCAL="${root}/.cwf/config.local.yaml"
  CWF_ENV_PROJECT_CONFIG_SHARED="${root}/.cwf/config.yaml"
}

cwf_env_load_from_yaml_file() {
  local var_name="$1"
  local yaml_file="$2"
  local escaped_var
  local line=""
  local value=""

  [[ -f "$yaml_file" ]] || return 1

  escaped_var="$(cwf_env_escape_regex "$var_name")"
  line=$(grep -shm1 -E "^[[:space:]]*${escaped_var}[[:space:]]*:" "$yaml_file" 2>/dev/null || true)
  [[ -n "$line" ]] || return 1

  value="${line#*:}"
  value="$(cwf_env_trim "$value")"

  # Only treat '#' as comment for unquoted values.
  if [[ ! "$value" =~ ^\".*\"$ ]] && [[ ! "$value" =~ ^\'.*\'$ ]]; then
    value="${value%%#*}"
    value="$(cwf_env_trim "$value")"
  fi

  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="$(cwf_env_strip_quotes "$value")"
  fi

  [[ -n "$value" ]] || return 1

  printf -v "$var_name" '%s' "$value"
  export "$var_name"
  return 0
}

cwf_env_load_from_project_configs() {
  local var_name="$1"
  cwf_env_init_project_config_paths

  # Project-local override wins over shared config.
  if cwf_env_load_from_yaml_file "$var_name" "$CWF_ENV_PROJECT_CONFIG_LOCAL"; then
    return 0
  fi

  if cwf_env_load_from_yaml_file "$var_name" "$CWF_ENV_PROJECT_CONFIG_SHARED"; then
    return 0
  fi

  return 1
}

cwf_env_load_from_profiles() {
  local var_name="$1"
  local line=""
  local value=""

  line=$(grep -shm1 -E "^(export[[:space:]]+)?${var_name}=" "${CWF_ENV_PROFILES[@]}" 2>/dev/null || true)
  if [ -z "$line" ]; then
    return 0
  fi

  value="${line#*=}"
  value="${value%"${value##*[![:space:]]}"}"
  value=$(cwf_env_strip_quotes "$value")
  printf -v "$var_name" '%s' "$value"
  export "$var_name"
}

cwf_env_load_var() {
  local var_name="$1"

  # Project-scoped values override global values by design.
  if cwf_env_load_from_project_configs "$var_name"; then
    return 0
  fi

  if [ -n "${!var_name:-}" ]; then
    return 0
  fi

  cwf_env_load_from_profiles "$var_name"
  if [ -n "${!var_name:-}" ]; then
    return 0
  fi
}

cwf_env_load_vars() {
  local var_name
  for var_name in "$@"; do
    cwf_env_load_var "$var_name"
  done
}
