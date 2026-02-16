#!/usr/bin/env bash
set -euo pipefail

# bootstrap-project-config.sh
# Initialize project-scoped CWF config files:
#   - .cwf/config.yaml (shared, non-secret)
#   - .cwf/config.local.yaml (local/secret, gitignored)
#
# Usage:
#   bootstrap-project-config.sh [--project-root <path>] [--force]

PROJECT_ROOT_INPUT=""
FORCE="false"

usage() {
  cat <<'EOF'
Usage:
  bootstrap-project-config.sh [--project-root <path>] [--force]

Options:
  --project-root <path>  Explicit repository root (default: git root or pwd)
  --force                Overwrite existing config templates
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT_INPUT="${2-}"
      if [[ -z "$PROJECT_ROOT_INPUT" ]]; then
        echo "Error: --project-root requires a value" >&2
        exit 1
      fi
      shift
      ;;
    --force)
      FORCE="true"
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

resolve_project_root() {
  local input="$1"
  if [[ -n "$input" ]]; then
    if [[ "$input" == /* ]]; then
      printf '%s\n' "$input"
    else
      printf '%s\n' "$(cd "$input" && pwd)"
    fi
    return 0
  fi

  if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$root"
    return 0
  fi

  printf '%s\n' "$(pwd)"
}

write_if_missing_or_forced() {
  local path="$1"
  local body="$2"

  if [[ -f "$path" && "$FORCE" != "true" ]]; then
    printf '%s\n' "exists"
    return 0
  fi

  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$body" > "$path"
  if [[ "$FORCE" == "true" && -f "$path" ]]; then
    printf '%s\n' "written"
  else
    printf '%s\n' "created"
  fi
}

ensure_gitignore_entry() {
  local gitignore_path="$1"
  local entry=".cwf/config.local.yaml"

  if [[ -f "$gitignore_path" ]] && grep -qxF "$entry" "$gitignore_path"; then
    printf '%s\n' "present"
    return 0
  fi

  mkdir -p "$(dirname "$gitignore_path")"
  touch "$gitignore_path"

  if [[ -s "$gitignore_path" ]]; then
    printf '\n' >> "$gitignore_path"
  fi
  {
    printf '%s\n' "# CWF local project config"
    printf '%s\n' "$entry"
  } >> "$gitignore_path"
  printf '%s\n' "added"
}

PROJECT_ROOT="$(resolve_project_root "$PROJECT_ROOT_INPUT")"
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Error: project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

SHARED_CONFIG_PATH="$PROJECT_ROOT/.cwf/config.yaml"
LOCAL_CONFIG_PATH="$PROJECT_ROOT/.cwf/config.local.yaml"
GITIGNORE_PATH="$PROJECT_ROOT/.gitignore"

read -r -d '' SHARED_TEMPLATE <<'EOF' || true
# CWF project-shared config (non-secret).
# Priority: .cwf/config.local.yaml > .cwf/config.yaml > process env > shell profile
#
# Put repository-wide defaults here (safe to commit).

# Optional artifact path overrides
# CWF_ARTIFACT_ROOT: ".cwf"
# CWF_PROJECTS_DIR: ".cwf/projects"
# CWF_STATE_FILE: ".cwf/cwf-state.yaml"

# Optional runtime overrides (non-secret)
# CWF_GATHER_OUTPUT_DIR: ".cwf/projects"
# CWF_READ_WARN_LINES: 500
# CWF_READ_DENY_LINES: 2000
# CWF_SESSION_LOG_DIR: ".cwf/projects/sessions"
# CWF_SESSION_LOG_ENABLED: true
# CWF_SESSION_LOG_TRUNCATE: 10
# CWF_SESSION_LOG_AUTO_COMMIT: false
EOF

read -r -d '' LOCAL_TEMPLATE <<'EOF' || true
# CWF project-local config (secret/local-only).
# Highest priority. Keep this file out of version control.

# Required keys for full capability
# SLACK_BOT_TOKEN: "xoxb-your-bot-token"
# SLACK_CHANNEL_ID: "D0123456789"
# TAVILY_API_KEY: "tvly-your-key"
# EXA_API_KEY: "your-key"

# Optional local overrides
# SLACK_WEBHOOK_URL: "https://hooks.slack.com/services/..."
# CWF_ATTENTION_USER_ID: "U0123456789"
EOF

shared_status="$(write_if_missing_or_forced "$SHARED_CONFIG_PATH" "$SHARED_TEMPLATE")"
local_status="$(write_if_missing_or_forced "$LOCAL_CONFIG_PATH" "$LOCAL_TEMPLATE")"
gitignore_status="$(ensure_gitignore_entry "$GITIGNORE_PATH")"

echo "project_root: $PROJECT_ROOT"
echo "shared_config: $shared_status ($SHARED_CONFIG_PATH)"
echo "local_config: $local_status ($LOCAL_CONFIG_PATH)"
echo "gitignore: $gitignore_status ($GITIGNORE_PATH)"
