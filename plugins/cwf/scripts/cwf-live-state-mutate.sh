#!/usr/bin/env bash
# cwf-live-state-mutate.sh — sync and mutating command handlers.

if ! declare -F cwf_live_resolve_root_state_file >/dev/null 2>&1; then
  # shellcheck source=plugins/cwf/scripts/cwf-live-state-core.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cwf-live-state-core.sh"
fi
if ! declare -F cwf_live_bump_state_version >/dev/null 2>&1; then
  # shellcheck source=plugins/cwf/scripts/cwf-live-state-journal.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cwf-live-state-journal.sh"
fi

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

cwf_live_validate_run_done_transition() {
  local base_dir="$1"
  shift || true
  local assignment=""
  local key=""
  local value=""
  local phase_target=""
  local current_pipeline=""
  local remaining_raw=""
  local gate_checker=""
  local session_dir_raw=""
  local session_dir_abs=""

  for assignment in "$@"; do
    [[ "$assignment" == *=* ]] || continue
    key="${assignment%%=*}"
    value="${assignment#*=}"
    if [[ "$key" == "phase" ]]; then
      phase_target="$value"
      break
    fi
  done

  if [[ "$phase_target" != "done" ]]; then
    return 0
  fi

  current_pipeline="$(cwf_live_get_scalar "$base_dir" "active_pipeline" 2>/dev/null || true)"
  if [[ "$current_pipeline" != "cwf:run" ]]; then
    return 0
  fi

  remaining_raw="$(cwf_live_get_list "$base_dir" "remaining_gates" 2>/dev/null || true)"
  if printf '%s\n' "$remaining_raw" | sed '/^$/d' | grep -q .; then
    echo "Cannot set phase=done while live.active_pipeline=cwf:run and remaining_gates is non-empty" >&2
    return 1
  fi

  gate_checker="$SCRIPT_DIR/check-run-gate-artifacts.sh"
  if [[ ! -x "$gate_checker" ]]; then
    echo "Cannot set phase=done for cwf:run: missing gate checker ($gate_checker)" >&2
    return 1
  fi

  session_dir_raw="$(cwf_live_get_scalar "$base_dir" "dir" 2>/dev/null || true)"
  if [[ -z "$session_dir_raw" ]]; then
    echo "Cannot set phase=done for cwf:run: live.dir is empty" >&2
    return 1
  fi

  if [[ "$session_dir_raw" == /* ]]; then
    session_dir_abs="$session_dir_raw"
  else
    session_dir_abs="$(cwf_live_to_abs_path "$base_dir" "$session_dir_raw")"
  fi

  if ! bash "$gate_checker" \
    --session-dir "$session_dir_abs" \
    --stage review-code \
    --stage refactor \
    --stage retro \
    --stage ship \
    --strict; then
    echo "Cannot set phase=done for cwf:run: run gate artifact check failed" >&2
    return 1
  fi

  return 0
}

cwf_live_set_scalars() {
  local base_dir="${1:-.}"
  shift || true
  local root_state=""
  local effective_state=""
  local synced_state=""
  local rel_path=""
  local assignment=""
  local assignments=()
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
    assignments+=("$assignment")
    keys+=("$key")
    values+=("$value")
  done

  if ! cwf_live_validate_run_done_transition "$base_dir" "${assignments[@]}"; then
    return 1
  fi

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
