#!/usr/bin/env bash
set -euo pipefail
# cwf-live-state-journal.sh — list mutation and decision journal helpers.

if ! declare -F cwf_live_resolve_root_state_file >/dev/null 2>&1; then
  # shellcheck source=plugins/cwf/scripts/cwf-live-state-core.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cwf-live-state-core.sh"
fi

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

cwf_live_trim_list_file_to_max() {
  local list_file="$1"
  local max_entries="$2"
  local current_count=0
  local tmp_file=""

  current_count="$(wc -l < "$list_file" | tr -d ' ')"
  if [[ -z "$current_count" || "$current_count" -le "$max_entries" ]]; then
    return 0
  fi

  tmp_file="$(mktemp)"
  tail -n "$max_entries" "$list_file" > "$tmp_file"
  mv "$tmp_file" "$list_file"
}

cwf_live_journal_append() {
  local base_dir="${1:-.}"
  local raw_entry_json="${2:-}"
  local root_state=""
  local effective_state=""
  local rel_path=""
  local entry_json=""
  local decision_id=""
  local supersedes=""
  local synced_state=""
  local max_entries="${CWF_DECISION_JOURNAL_MAX_ENTRIES:-50}"
  local list_file=""
  local existing=""
  local existing_id=""
  local normalized_existing=""
  local new_entry_added=0
  local state_version=""
  local idx_key=""
  local required_keys=(decision_id ts session_id question answer source_hook state_version)

  if [[ -z "$raw_entry_json" ]]; then
    echo "journal-append requires an entry JSON argument" >&2
    return 2
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "journal-append requires jq" >&2
    return 2
  fi
  if [[ ! "$max_entries" =~ ^[0-9]+$ ]] || [[ "$max_entries" -le 0 ]]; then
    max_entries=50
  fi

  entry_json="$(printf '%s' "$raw_entry_json" | jq -c . 2>/dev/null || true)"
  if [[ -z "$entry_json" ]]; then
    echo "journal-append requires valid JSON" >&2
    return 2
  fi

  for idx_key in "${required_keys[@]}"; do
    if [[ "$(printf '%s' "$entry_json" | jq -r --arg k "$idx_key" '.[$k] // empty')" == "" ]]; then
      echo "journal-append missing required field: $idx_key" >&2
      return 2
    fi
  done

  decision_id="$(printf '%s' "$entry_json" | jq -r '.decision_id // empty')"
  supersedes="$(printf '%s' "$entry_json" | jq -r '.supersedes // empty')"

  root_state="$(cwf_live_resolve_root_state_file "$base_dir")"
  [[ -f "$root_state" ]] || return 1
  effective_state="$(cwf_live_resolve_file "$base_dir")"
  [[ -n "$effective_state" ]] || return 1

  list_file="$(mktemp)"
  while IFS= read -r existing; do
    [[ -n "$existing" ]] || continue
    normalized_existing="$(printf '%s' "$existing" | jq -c . 2>/dev/null || true)"
    if [[ -z "$normalized_existing" ]]; then
      normalized_existing="$(printf '%s' "$existing" | sed 's/\\"/"/g' | jq -c . 2>/dev/null || true)"
    fi
    if [[ -z "$normalized_existing" ]]; then
      normalized_existing="$existing"
    fi

    existing_id="$(printf '%s' "$normalized_existing" | jq -r '.decision_id // empty' 2>/dev/null || true)"
    if [[ "$existing_id" == "$decision_id" ]]; then
      if [[ "$new_entry_added" -eq 0 ]]; then
        printf '%s\n' "$entry_json" >> "$list_file"
        new_entry_added=1
      fi
      continue
    fi
    if [[ -n "$supersedes" && "$existing_id" == "$supersedes" ]]; then
      continue
    fi
    printf '%s\n' "$normalized_existing" >> "$list_file"
  done < <(cwf_live_extract_list_from_file "$effective_state" "decision_journal" || true)

  if [[ "$new_entry_added" -eq 0 ]]; then
    printf '%s\n' "$entry_json" >> "$list_file"
  fi

  cwf_live_trim_list_file_to_max "$list_file" "$max_entries"

  if [[ "$effective_state" == "$root_state" ]]; then
    cwf_live_upsert_live_list "$root_state" "decision_journal" "$list_file"
    state_version="$(cwf_live_bump_state_version "$root_state")"
    synced_state="$(cwf_live_sync_from_root "$base_dir" 2>/dev/null || true)"
    if [[ -n "$synced_state" && -f "$synced_state" ]]; then
      cwf_live_upsert_live_list "$synced_state" "decision_journal" "$list_file"
      cwf_live_upsert_live_scalar "$synced_state" "state_version" "$state_version"
      rm -f "$list_file"
      printf '%s\n' "$synced_state"
      return 0
    fi
    rm -f "$list_file"
    printf '%s\n' "$root_state"
    return 0
  fi

  cwf_live_upsert_live_list "$effective_state" "decision_journal" "$list_file"
  state_version="$(cwf_live_bump_state_version "$effective_state")"

  cwf_live_upsert_live_list "$root_state" "decision_journal" "$list_file"
  cwf_live_upsert_live_scalar "$root_state" "state_version" "$state_version"

  rel_path="$(cwf_live_to_repo_rel_path "$base_dir" "$effective_state")"
  cwf_live_upsert_state_file_pointer "$root_state" "$rel_path" >/dev/null || true

  rm -f "$list_file"
  printf '%s\n' "$effective_state"
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
