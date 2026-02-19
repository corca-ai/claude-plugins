#!/usr/bin/env bash
set -euo pipefail

# cwf-live-state.sh — shared helper for hybrid live state (D-003).
#
# Commands:
#   resolve [base_dir]
#     Print effective live-state file path.
#   sync [base_dir]
#     Copy root live section to session live-state file and upsert live.state_file pointer.
#   get [base_dir] key
#     Read a scalar field from resolved live state.
#   list-get [base_dir] key
#     Read a list field from resolved live state.
#   set [base_dir] key=value [key=value ...]
#     Update top-level scalar fields in live state.
#   list-set [base_dir] key=item1,item2,...
#     Replace a top-level list field in live state.
#   list-remove [base_dir] key item
#     Remove a single item from a list field (idempotent).
#   journal-append [base_dir] '<entry-json>'
#     Append/replace a decision_journal entry by decision_id.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/scripts/cwf-live-state-core.sh
source "$SCRIPT_DIR/cwf-live-state-core.sh"
# shellcheck source=plugins/cwf/scripts/cwf-live-state-journal.sh
source "$SCRIPT_DIR/cwf-live-state-journal.sh"
# shellcheck source=plugins/cwf/scripts/cwf-live-state-mutate.sh
source "$SCRIPT_DIR/cwf-live-state-mutate.sh"

cwf_live_print_usage() {
  cat <<'USAGE' >&2
Usage: cwf-live-state.sh {resolve|sync} [base_dir]
       cwf-live-state.sh get [base_dir] key
       cwf-live-state.sh list-get [base_dir] key
       cwf-live-state.sh set [base_dir] key=value [key=value ...]
       cwf-live-state.sh list-set [base_dir] key=item1,item2,...
       cwf-live-state.sh list-remove [base_dir] key item
       cwf-live-state.sh journal-append [base_dir] '<entry-json>'
USAGE
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
    get)
      case "$#" in
        1)
          base_dir="."
          get_key="$1"
          ;;
        2)
          base_dir="$1"
          get_key="$2"
          ;;
        *)
          echo "get requires: [base_dir] key" >&2
          exit 2
          ;;
      esac
      cwf_live_get_scalar "$base_dir" "$get_key"
      ;;
    list-get)
      case "$#" in
        1)
          base_dir="."
          get_list_key="$1"
          ;;
        2)
          base_dir="$1"
          get_list_key="$2"
          ;;
        *)
          echo "list-get requires: [base_dir] key" >&2
          exit 2
          ;;
      esac
      cwf_live_get_list "$base_dir" "$get_list_key"
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
        if [[ "${1:-}" == */* || "${1:-}" == "." ]]; then
          echo "list-remove requires: [base_dir] key item" >&2
          exit 2
        fi
        echo "list-remove requires: [base_dir] key item" >&2
        exit 2
      fi
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
        rl_version="$(cwf_live_bump_state_version "$effective_state")"
        if [[ "$effective_state" != "$root_state" ]]; then
          cwf_live_upsert_live_scalar "$root_state" "state_version" "$rl_version"
        fi
      fi
      printf '%s\n' "$effective_state"
      ;;
    journal-append)
      base_dir="."
      if [[ "$#" -lt 1 ]]; then
        echo "journal-append requires: [base_dir] <entry-json>" >&2
        exit 2
      fi
      if [[ "$#" -eq 1 ]]; then
        ja_entry="$1"
      else
        base_dir="$1"
        shift
        ja_entry="$1"
      fi
      cwf_live_journal_append "$base_dir" "$ja_entry"
      ;;
    -h|--help)
      cwf_live_print_usage
      ;;
    *)
      cwf_live_print_usage
      exit 2
      ;;
  esac
fi
