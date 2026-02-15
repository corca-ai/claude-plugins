#!/usr/bin/env bash
# Shared environment variable loader for CWF scripts.
#
# Source priority (high -> low):
#   1) Current process environment
#   2) Shell profiles (~/.zshenv, ~/.zprofile, ~/.zshrc, ~/.bash_profile, ~/.bashrc, ~/.profile)
#
# Why profile-first?
# - Reduces runtime coupling to Claude-specific paths.
#
# Safety:
# - Profile values are extracted with grep/string parsing (no eval/source).

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
