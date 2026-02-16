#!/usr/bin/env bash
set -euo pipefail

# configure-agent-teams.sh
# Toggle Claude Code Agent Team mode by editing:
#   ~/.claude/settings.json -> env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
#
# Usage:
#   configure-agent-teams.sh --status
#   configure-agent-teams.sh --enable
#   configure-agent-teams.sh --disable
#   configure-agent-teams.sh --status --settings-file /path/to/settings.json

ACTION="status"
ACTION_SET="false"
SETTINGS_FILE="${HOME}/.claude/settings.json"

usage() {
  cat <<'EOF'
Usage:
  configure-agent-teams.sh --status|--enable|--disable [--settings-file <path>]

Options:
  --status                 Show current Agent Team mode state (default)
  --enable                 Set env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
  --disable                Remove env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
  --settings-file <path>   Override settings file path (default: ~/.claude/settings.json)
  -h, --help               Show this help
EOF
}

set_action() {
  local next="$1"
  if [[ "$ACTION_SET" == "true" && "$ACTION" != "$next" ]]; then
    echo "Error: only one action can be specified (--status|--enable|--disable)" >&2
    exit 1
  fi
  ACTION="$next"
  ACTION_SET="true"
}

abs_path() {
  local p="$1"
  if [[ "$p" == /* ]]; then
    printf '%s\n' "$p"
  else
    printf '%s/%s\n' "$(pwd)" "$p"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)
      set_action "status"
      ;;
    --enable)
      set_action "enable"
      ;;
    --disable)
      set_action "disable"
      ;;
    --settings-file)
      SETTINGS_FILE="${2-}"
      if [[ -z "$SETTINGS_FILE" ]]; then
        echo "Error: --settings-file requires a value" >&2
        exit 1
      fi
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

SETTINGS_FILE="$(abs_path "$SETTINGS_FILE")"
KEY_NAME="CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"

read_settings_or_default() {
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    printf '{}\n'
    return 0
  fi

  if ! jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "Error: invalid JSON: $SETTINGS_FILE" >&2
    exit 1
  fi

  cat "$SETTINGS_FILE"
}

write_settings_json() {
  local json="$1"
  local dir
  local tmp

  dir="$(dirname "$SETTINGS_FILE")"
  mkdir -p "$dir"
  tmp="$(mktemp "${TMPDIR:-/tmp}/cwf-agent-teams.XXXXXX")"
  printf '%s\n' "$json" > "$tmp"
  mv "$tmp" "$SETTINGS_FILE"
}

print_status() {
  local value
  local state

  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "settings_file: $SETTINGS_FILE"
    echo "state: disabled"
    echo "key: $KEY_NAME"
    echo "value: <unset>"
    echo "reason: settings_file_missing"
    return 0
  fi

  value="$(jq -r --arg key "$KEY_NAME" '.env[$key] // empty' "$SETTINGS_FILE")"
  if [[ "$value" == "1" ]]; then
    state="enabled"
  else
    state="disabled"
  fi

  if [[ -z "$value" ]]; then
    value="<unset>"
  fi

  echo "settings_file: $SETTINGS_FILE"
  echo "state: $state"
  echo "key: $KEY_NAME"
  echo "value: $value"
}

apply_enable() {
  local current
  local updated

  current="$(read_settings_or_default)"
  updated="$(printf '%s' "$current" | jq --arg key "$KEY_NAME" '
    .env = ((.env // {}) | if type == "object" then . else {} end)
    | .env[$key] = "1"
  ')"
  write_settings_json "$updated"
  echo "action: enable"
  print_status
}

apply_disable() {
  local current
  local updated

  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "action: disable"
    print_status
    return 0
  fi

  current="$(read_settings_or_default)"
  updated="$(printf '%s' "$current" | jq --arg key "$KEY_NAME" '
    if (.env | type) == "object" then
      .env |= del(.[$key])
      | if (.env | length) == 0 then del(.env) else . end
    else
      .
    end
  ')"
  write_settings_json "$updated"
  echo "action: disable"
  print_status
}

case "$ACTION" in
  status)
    print_status
    ;;
  enable)
    apply_enable
    ;;
  disable)
    apply_disable
    ;;
  *)
    echo "Error: unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
