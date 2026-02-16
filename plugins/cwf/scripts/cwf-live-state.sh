#!/usr/bin/env bash
set -euo pipefail

# cwf-live-state.sh — shared helper for hybrid live state (D-003).
#
# Root state (.cwf/cwf-state.yaml):
#   - global metadata (workflow/session history/tools/hooks)
#   - live pointer metadata (live.state_file)
#
# Session state (.cwf/projects/<session>/session-state.yaml):
#   - volatile live execution state (phase/task/decisions/journal/hitl pointer)
#
# Commands:
#   resolve [base_dir]
#     Print effective live-state file path.
#   sync [base_dir]
#     Copy root live section to session live-state file and upsert live.state_file pointer.
#   set [base_dir] key=value [key=value ...]
#     Update top-level scalar fields in live state (session-first write target)
#     and synchronize root live summary fields for compatibility.
#   list-set [base_dir] key=item1,item2,...
#     Replace a top-level list field in live state and synchronize root/session state.
#   list-remove [base_dir] key item
#     Remove a single item from a list field (idempotent).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/cwf-artifact-paths.sh"

if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
  echo "Missing resolver script: $RESOLVER_SCRIPT" >&2
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
  # this additionally neutralizes : [ ] { } which could confuse parsers
  # operating on the raw file.
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

cwf_live_upsert_live_list() {
  local state_file="$1"
  local key="$2"
  local list_file="$3"
  local tmp_file

  tmp_file="$(mktemp)"
  awk -v key="$key" -v list_file="$list_file" '
    BEGIN {
      while ((getline line < list_file) > 0) {
        items[++item_count]=line
      }
      close(list_file)
      in_live=0
      in_target=0
      inserted=0
      saw_live=0
    }
    function escape_dq(v, out) {
      out=v
      gsub(/\\/,"\\\\",out)
      gsub(/"/,"\\\"",out)
      return out
    }
    function print_list(i) {
      if (item_count == 0) {
        print "  " key ": []"
        return
      }
      print "  " key ":"
      for (i = 1; i <= item_count; i++) {
        print "    - \"" escape_dq(items[i]) "\""
      }
    }
    /^live:/ {
      in_live=1
      saw_live=1
      print
      next
    }
    in_live && /^[^[:space:]]/ {
      if (!inserted) {
        print_list()
        inserted=1
      }
      in_live=0
    }
    in_live {
      target_pat = "^[[:space:]]{2}" key ":[[:space:]]*"
      if ($0 ~ target_pat) {
        if (!inserted) {
          print_list()
          inserted=1
        }
        in_target=1
        next
      }
      if (in_target) {
        if ($0 ~ /^[[:space:]]{4}-[[:space:]]*/) {
          next
        }
        if ($0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:/ || $0 ~ /^[^[:space:]]/) {
          in_target=0
        } else {
          next
        }
      }
    }
    { print }
    END {
      if (in_live && !inserted) {
        print_list()
        inserted=1
      }
      if (!saw_live) {
        print ""
        print "live:"
        print_list()
      }
    }
  ' "$state_file" > "$tmp_file"
  mv "$tmp_file" "$state_file"
}

cwf_live_remove_list_item() {
  local state_file="$1"
  local key="$2"
  local item_to_remove="$3"
  local tmp_file
  local list_file

  # Read current list, filter out the item, then upsert the filtered list.
  # Idempotent: silent success when item is not found.
  list_file="$(mktemp)"
  cwf_live_extract_list_from_file "$state_file" "$key" | while IFS= read -r line; do
    if [[ "$line" != "$item_to_remove" ]]; then
      printf '%s\n' "$line"
    fi
  done > "$list_file"

  cwf_live_upsert_live_list "$state_file" "$key" "$list_file"
  rm -f "$list_file"
}

cwf_live_extract_state_version() {
  local state_file="$1"
  local current=""
  current="$(cwf_live_extract_scalar_from_file "$state_file" "state_version" || true)"
  current="$(cwf_live_normalize_scalar "$current")"
  if [[ "$current" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$current"
  else
    printf '0\n'
  fi
}

cwf_live_bump_state_version() {
  local state_file="$1"
  local current=0
  local next=1

  current="$(cwf_live_extract_state_version "$state_file")"
  next=$((current + 1))
  cwf_live_upsert_live_scalar "$state_file" "state_version" "$next"
  printf '%s\n' "$next"
}

cwf_live_sync_from_root() {
  local base_dir="${1:-.}"
  local root_state=""
  local target_state=""
  local live_block=""
  local sanitized_live_block=""
  local rel_path=""
  local tmp_file=""

  root_state="$(cwf_live_resolve_root_state_file "$base_dir")"
  [[ -f "$root_state" ]] || return 1

  target_state="$(cwf_live_derive_session_state_path "$base_dir" "$root_state" 2>/dev/null || true)"
  if [[ -z "$target_state" ]]; then
    return 1
  fi

  live_block="$(cwf_live_extract_live_block "$root_state")"
  if [[ -z "$live_block" ]]; then
    return 1
  fi
  # live.state_file is a root pointer metadata field; do not duplicate it
  # into session-local volatile state.
  sanitized_live_block="$(printf '%s\n' "$live_block" | sed '/^[[:space:]]\{2\}state_file:[[:space:]]*/d')"

  mkdir -p "$(dirname "$target_state")"
  tmp_file="$(mktemp)"
  {
    echo "# session-state.yaml — volatile session live state"
    echo "# Synced from .cwf/cwf-state.yaml live section."
    echo ""
    printf '%s\n' "$sanitized_live_block"
  } > "$tmp_file"
  mv "$tmp_file" "$target_state"

  rel_path="$(cwf_live_to_repo_rel_path "$base_dir" "$target_state")"
  cwf_live_upsert_state_file_pointer "$root_state" "$rel_path" >/dev/null || true

  printf '%s\n' "$target_state"
}

cwf_live_set_scalars() {
  local base_dir="${1:-.}"
  shift || true
  local root_state=""
  local effective_state=""
  local synced_state=""
  local rel_path=""
  local assignment=""
  local key=""
  local value=""
  local keys=()
  local values=()
  local idx=0

  if [[ "$#" -eq 0 ]]; then
    echo "set requires at least one key=value assignment" >&2
    return 2
  fi

  while [[ "$#" -gt 0 ]]; do
    assignment="$1"
    shift
    if [[ "$assignment" != *=* ]]; then
      echo "Invalid assignment: $assignment (expected key=value)" >&2
      return 2
    fi
    key="${assignment%%=*}"
    value="${assignment#*=}"
    if ! cwf_live_validate_scalar_key "$key"; then
      echo "Unsupported scalar key for set: $key" >&2
      return 2
    fi
    keys+=("$key")
    values+=("$value")
  done

  root_state="$(cwf_live_resolve_root_state_file "$base_dir")"
  [[ -f "$root_state" ]] || return 1
  effective_state="$(cwf_live_resolve_file "$base_dir")"
  [[ -n "$effective_state" ]] || return 1

  if [[ "$effective_state" == "$root_state" ]]; then
    # Apply incoming fields to root first so sync can derive session path from
    # possibly updated live.dir.
    for idx in "${!keys[@]}"; do
      cwf_live_upsert_live_scalar "$root_state" "${keys[$idx]}" "${values[$idx]}"
    done

    synced_state="$(cwf_live_sync_from_root "$base_dir" 2>/dev/null || true)"
    if [[ -n "$synced_state" && -f "$synced_state" ]]; then
      for idx in "${!keys[@]}"; do
        cwf_live_upsert_live_scalar "$synced_state" "${keys[$idx]}" "${values[$idx]}"
      done
      printf '%s\n' "$synced_state"
      return 0
    fi

    printf '%s\n' "$root_state"
    return 0
  fi

  # Session-local state exists: write there first, then sync summary fields
  # in root live for backward-compatible readers.
  for idx in "${!keys[@]}"; do
    cwf_live_upsert_live_scalar "$effective_state" "${keys[$idx]}" "${values[$idx]}"
  done
  for idx in "${!keys[@]}"; do
    cwf_live_upsert_live_scalar "$root_state" "${keys[$idx]}" "${values[$idx]}"
  done

  rel_path="$(cwf_live_to_repo_rel_path "$base_dir" "$effective_state")"
  cwf_live_upsert_state_file_pointer "$root_state" "$rel_path" >/dev/null || true

  printf '%s\n' "$effective_state"
}

cwf_live_set_list() {
  local base_dir="${1:-.}"
  shift || true
  local assignment=""
  local key=""
  local raw_value=""
  local root_state=""
  local effective_state=""
  local synced_state=""
  local rel_path=""
  local list_file=""
  local state_version=""
  local trimmed=""
  local item=""
  local idx=0
  local raw_items=()
  local items=()

  if [[ "$#" -ne 1 ]]; then
    echo "list-set requires exactly one key=item1,item2 assignment" >&2
    return 2
  fi

  assignment="$1"
  if [[ "$assignment" != *=* ]]; then
    echo "Invalid assignment for list-set: $assignment (expected key=item1,item2,...)" >&2
    return 2
  fi

  key="${assignment%%=*}"
  raw_value="${assignment#*=}"

  if ! cwf_live_validate_list_key "$key"; then
    echo "Unsupported list key for list-set: $key" >&2
    return 2
  fi

  if [[ -n "$raw_value" ]]; then
    IFS=',' read -r -a raw_items <<< "$raw_value"
    for idx in "${!raw_items[@]}"; do
      trimmed="$(cwf_live_trim "${raw_items[$idx]}")"
      if [[ -n "$trimmed" ]]; then
        items+=("$trimmed")
      fi
    done
  fi

  if [[ "$key" == "remaining_gates" && ${#items[@]} -gt 0 ]]; then
    for item in "${items[@]}"; do
      if ! cwf_live_validate_gate_name "$item"; then
        echo "Invalid gate name for remaining_gates: $item" >&2
        return 2
      fi
    done
  fi

  list_file="$(mktemp)"
  if [[ ${#items[@]} -gt 0 ]]; then
    for item in "${items[@]}"; do
      printf '%s\n' "$item" >> "$list_file"
    done
  fi

  root_state="$(cwf_live_resolve_root_state_file "$base_dir")"
  [[ -f "$root_state" ]] || {
    rm -f "$list_file"
    return 1
  }
  effective_state="$(cwf_live_resolve_file "$base_dir")"
  [[ -n "$effective_state" ]] || {
    rm -f "$list_file"
    return 1
  }

  if [[ "$effective_state" == "$root_state" ]]; then
    cwf_live_upsert_live_list "$root_state" "$key" "$list_file"

    state_version=""
    if [[ "$key" == "remaining_gates" ]]; then
      state_version="$(cwf_live_bump_state_version "$root_state")"
    fi

    synced_state="$(cwf_live_sync_from_root "$base_dir" 2>/dev/null || true)"
    if [[ -n "$synced_state" && -f "$synced_state" ]]; then
      cwf_live_upsert_live_list "$synced_state" "$key" "$list_file"
      if [[ -n "$state_version" ]]; then
        cwf_live_upsert_live_scalar "$synced_state" "state_version" "$state_version"
      fi
      rm -f "$list_file"
      printf '%s\n' "$synced_state"
      return 0
    fi

    rm -f "$list_file"
    printf '%s\n' "$root_state"
    return 0
  fi

  cwf_live_upsert_live_list "$effective_state" "$key" "$list_file"

  state_version=""
  if [[ "$key" == "remaining_gates" ]]; then
    state_version="$(cwf_live_bump_state_version "$effective_state")"
  fi

  cwf_live_upsert_live_list "$root_state" "$key" "$list_file"
  if [[ -n "$state_version" ]]; then
    cwf_live_upsert_live_scalar "$root_state" "state_version" "$state_version"
  fi

  rel_path="$(cwf_live_to_repo_rel_path "$base_dir" "$effective_state")"
  cwf_live_upsert_state_file_pointer "$root_state" "$rel_path" >/dev/null || true

  rm -f "$list_file"
  printf '%s\n' "$effective_state"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cmd="${1:-}"
  base_dir=""
  shift || true
  case "$cmd" in
    resolve)
      base_dir="${1:-.}"
      cwf_live_resolve_file "$base_dir"
      ;;
    sync)
      base_dir="${1:-.}"
      cwf_live_sync_from_root "$base_dir"
      ;;
    set)
      base_dir="."
      if [[ "${1:-}" == *=* || -z "${1:-}" ]]; then
        cwf_live_set_scalars "$base_dir" "$@"
      else
        base_dir="$1"
        shift
        cwf_live_set_scalars "$base_dir" "$@"
      fi
      ;;
    list-set)
      base_dir="."
      if [[ "${1:-}" == *=* || -z "${1:-}" ]]; then
        cwf_live_set_list "$base_dir" "$@"
      else
        base_dir="$1"
        shift
        cwf_live_set_list "$base_dir" "$@"
      fi
      ;;
    list-remove)
      base_dir="."
      if [[ "$#" -lt 2 ]]; then
        # Check if first arg is base_dir or key
        if [[ "${1:-}" == */* || "${1:-}" == "." ]]; then
          echo "list-remove requires: [base_dir] key item" >&2
          exit 2
        fi
        echo "list-remove requires: [base_dir] key item" >&2
        exit 2
      fi
      # Determine if first arg is base_dir or key
      if [[ "$#" -ge 3 && ("$1" == */* || "$1" == ".") ]]; then
        base_dir="$1"
        shift
      fi
      rl_key="$1"
      rl_item="$2"
      if ! cwf_live_validate_list_key "$rl_key"; then
        echo "Unsupported list key for list-remove: $rl_key" >&2
        exit 2
      fi
      if [[ "$rl_key" == "remaining_gates" ]] && ! cwf_live_validate_gate_name "$rl_item"; then
        echo "Invalid gate name for remaining_gates: $rl_item" >&2
        exit 2
      fi
      root_state="$(cwf_live_resolve_root_state_file "$base_dir")"
      [[ -f "$root_state" ]] || exit 1
      effective_state="$(cwf_live_resolve_file "$base_dir")"
      [[ -n "$effective_state" ]] || exit 1
      cwf_live_remove_list_item "$effective_state" "$rl_key" "$rl_item"
      if [[ "$effective_state" != "$root_state" ]]; then
        cwf_live_remove_list_item "$root_state" "$rl_key" "$rl_item"
      fi
      if [[ "$rl_key" == "remaining_gates" ]]; then
        cwf_live_bump_state_version "$effective_state" >/dev/null
        if [[ "$effective_state" != "$root_state" ]]; then
          cwf_live_bump_state_version "$root_state" >/dev/null
        fi
      fi
      printf '%s\n' "$effective_state"
      ;;
    -h|--help)
      sed -n '3,22p' "$0" | sed 's/^# \?//'
      ;;
    *)
      echo "Usage: $0 {resolve|sync} [base_dir]" >&2
      echo "       $0 set [base_dir] key=value [key=value ...]" >&2
      echo "       $0 list-set [base_dir] key=item1,item2,..." >&2
      echo "       $0 list-remove [base_dir] key item" >&2
      exit 2
      ;;
  esac
fi
