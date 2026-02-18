#!/usr/bin/env bash
set -euo pipefail
# cwf-live-state-core.sh — shared helpers for hybrid live-state parsing/upserts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/cwf-artifact-paths.sh"

if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
  echo "Missing resolver script: $RESOLVER_SCRIPT" >&2
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 2
  fi
  exit 2
fi

# shellcheck source=./cwf-artifact-paths.sh
# shellcheck disable=SC1091
source "$RESOLVER_SCRIPT"

cwf_live_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

cwf_live_strip_quotes() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

cwf_live_normalize_scalar() {
  local value="$1"
  value="${value%%#*}"
  value="$(cwf_live_trim "$value")"
  value="$(cwf_live_strip_quotes "$value")"
  printf '%s' "$value"
}

cwf_live_to_abs_path() {
  local base_dir="$1"
  local raw_path="$2"
  if [[ "$raw_path" == /* ]]; then
    printf '%s\n' "$raw_path"
  else
    printf '%s\n' "$base_dir/$raw_path"
  fi
}

cwf_live_to_repo_rel_path() {
  local base_dir="$1"
  local abs_path="$2"
  if [[ "$abs_path" == "$base_dir/"* ]]; then
    printf '%s\n' "${abs_path#"$base_dir"/}"
  else
    printf '%s\n' "$abs_path"
  fi
}

cwf_live_extract_scalar_from_file() {
  local file_path="$1"
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
  ' "$file_path"
}

cwf_live_extract_live_block() {
  local file_path="$1"
  awk '
    /^live:/ { in_live=1; print; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live { print }
  ' "$file_path"
}

cwf_live_resolve_root_state_file() {
  local base_dir="$1"
  resolve_cwf_state_file "$base_dir"
}

cwf_live_derive_session_state_path() {
  local base_dir="$1"
  local root_state="$2"
  local dir_raw=""
  dir_raw="$(cwf_live_extract_scalar_from_file "$root_state" "dir" || true)"
  dir_raw="$(cwf_live_normalize_scalar "$dir_raw")"
  if [[ -z "$dir_raw" ]]; then
    return 1
  fi
  local dir_abs
  dir_abs="$(cwf_live_to_abs_path "$base_dir" "$dir_raw")"
  printf '%s\n' "$dir_abs/session-state.yaml"
}

cwf_live_resolve_file() {
  local base_dir="${1:-.}"
  local root_state=""
  local pointer_raw=""

  root_state="$(cwf_live_resolve_root_state_file "$base_dir")"
  [[ -f "$root_state" ]] || return 1

  pointer_raw="$(cwf_live_extract_scalar_from_file "$root_state" "state_file" || true)"
  pointer_raw="$(cwf_live_normalize_scalar "$pointer_raw")"
  if [[ -n "$pointer_raw" ]]; then
    local pointer_abs
    pointer_abs="$(cwf_live_to_abs_path "$base_dir" "$pointer_raw")"
    if [[ -f "$pointer_abs" ]]; then
      printf '%s\n' "$pointer_abs"
      return 0
    fi
  fi

  local derived=""
  derived="$(cwf_live_derive_session_state_path "$base_dir" "$root_state" 2>/dev/null || true)"
  if [[ -n "$derived" && -f "$derived" ]]; then
    printf '%s\n' "$derived"
    return 0
  fi

  printf '%s\n' "$root_state"
}

cwf_live_upsert_state_file_pointer() {
  local root_state="$1"
  local pointer_value="$2"
  local tmp_file

  tmp_file="$(mktemp)"
  awk -v pointer="$pointer_value" '
    BEGIN { in_live=0; replaced=0; inserted=0; saw_live=0 }
    /^live:/ { in_live=1; saw_live=1; print; next }
    in_live && /^[^[:space:]]/ {
      if (!inserted) {
        print "  state_file: \"" pointer "\""
        inserted=1
      }
      in_live=0
    }
    in_live && /^[[:space:]]{2}state_file:/ {
      if (!replaced) {
        print "  state_file: \"" pointer "\""
        replaced=1
        inserted=1
      }
      next
    }
    { print }
    END {
      if (in_live && !inserted) {
        print "  state_file: \"" pointer "\""
        inserted=1
      }
      if (!saw_live) {
        print ""
        print "live:"
        print "  state_file: \"" pointer "\""
      }
    }
  ' "$root_state" > "$tmp_file"
  mv "$tmp_file" "$root_state"
  return 0
}

cwf_live_escape_dq() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  # Replace literal newlines with spaces to prevent YAML line structure corruption.
  # In double-quoted YAML strings, a literal newline would break the value across lines.
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

cwf_live_sanitize_yaml_value() {
  local value="$1"
  # Defense-in-depth: strip characters that could break YAML structure
  # even inside double-quoted strings. cwf_live_escape_dq handles \ " \n;
  # this additionally neutralizes [ ] which could confuse YAML list parsers
  # operating on the raw file. Colons and braces are safe inside
  # double-quoted YAML strings and are not sanitized.
  value="${value//[/（}"
  value="${value//]/）}"
  value="$(cwf_live_escape_dq "$value")"
  printf '%s' "$value"
}

cwf_live_upsert_live_scalar() {
  local state_file="$1"
  local key="$2"
  local value="$3"
  local tmp_file
  local escaped_value

  escaped_value="$(cwf_live_sanitize_yaml_value "$value")"
  tmp_file="$(mktemp)"
  awk -v key="$key" -v value="$escaped_value" '
    BEGIN { in_live=0; replaced=0; inserted=0; saw_live=0 }
    /^live:/ { in_live=1; saw_live=1; print; next }
    in_live && /^[^[:space:]]/ {
      if (!inserted) {
        print "  " key ": \"" value "\""
        inserted=1
      }
      in_live=0
    }
    in_live {
      pat = "^[[:space:]]{2}" key ":[[:space:]]*"
      if ($0 ~ pat) {
        if (!replaced) {
          print "  " key ": \"" value "\""
          replaced=1
          inserted=1
        }
        next
      }
    }
    { print }
    END {
      if (in_live && !inserted) {
        print "  " key ": \"" value "\""
        inserted=1
      }
      if (!saw_live) {
        print ""
        print "live:"
        print "  " key ": \"" value "\""
      }
    }
  ' "$state_file" > "$tmp_file"
  mv "$tmp_file" "$state_file"
}

cwf_live_validate_scalar_key() {
  local key="$1"
  case "$key" in
    ""|state_file|hitl|key_files|dont_touch|decisions|decision_journal|remaining_gates)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

cwf_live_validate_list_key() {
  local key="$1"
  case "$key" in
    key_files|dont_touch|decisions|decision_journal|remaining_gates)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Source of truth: plugins/cwf/skills/run/SKILL.md Stage Definition table
cwf_live_validate_gate_name() {
  # Source of truth: plugins/cwf/skills/run/SKILL.md Stage Definition table
  local gate="$1"
  case "$gate" in
    gather|clarify|plan|review-plan|impl|review-code|refactor|retro|ship)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

cwf_live_extract_list_from_file() {
  local file_path="$1"
  local key="$2"
  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      full = "^[[:space:]]{2}" key ":[[:space:]]*$"
      empty = "^[[:space:]]{2}" key ":[[:space:]]*\\[\\][[:space:]]*$"
      if ($0 ~ empty) {
        exit
      }
      if ($0 ~ full) {
        in_key=1
        next
      }
      if (in_key) {
        if ($0 ~ /^[[:space:]]{4}-[[:space:]]*/) {
          line=$0
          sub(/^[[:space:]]{4}-[[:space:]]*/, "", line)
          gsub(/^"/, "", line)
          gsub(/"$/, "", line)
          gsub(/^'\''/, "", line)
          gsub(/'\''$/, "", line)
          print line
          next
        }
        if ($0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:/ || $0 ~ /^[^[:space:]]/) {
          exit
        }
      }
    }
  ' "$file_path"
}

cwf_live_validate_query_key() {
  local key="$1"
  [[ "$key" =~ ^[A-Za-z0-9_-]+$ ]]
}

cwf_live_get_scalar() {
  local base_dir="${1:-.}"
  local key="${2:-}"
  local effective_state=""
  local raw_value=""

  if [[ -z "$key" ]]; then
    echo "get requires a key" >&2
    return 2
  fi
  if ! cwf_live_validate_query_key "$key"; then
    echo "Invalid key for get: $key" >&2
    return 2
  fi

  effective_state="$(cwf_live_resolve_file "$base_dir")"
  [[ -f "$effective_state" ]] || return 1

  raw_value="$(cwf_live_extract_scalar_from_file "$effective_state" "$key" || true)"
  printf '%s\n' "$(cwf_live_normalize_scalar "$raw_value")"
}

cwf_live_get_list() {
  local base_dir="${1:-.}"
  local key="${2:-}"
  local effective_state=""

  if [[ -z "$key" ]]; then
    echo "list-get requires a key" >&2
    return 2
  fi
  if ! cwf_live_validate_query_key "$key"; then
    echo "Invalid key for list-get: $key" >&2
    return 2
  fi

  effective_state="$(cwf_live_resolve_file "$base_dir")"
  [[ -f "$effective_state" ]] || return 1

  cwf_live_extract_list_from_file "$effective_state" "$key"
}
