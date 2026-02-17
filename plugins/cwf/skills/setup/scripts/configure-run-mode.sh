#!/usr/bin/env bash
set -euo pipefail

# configure-run-mode.sh
# Persist cwf:run ambiguity handling mode into project config.
#
# Usage:
#   configure-run-mode.sh --mode <strict|defer-blocking|defer-reversible|explore-worktrees> \
#     [--scope shared|local] [--project-root <path>]

MODE=""
SCOPE="shared"
PROJECT_ROOT_INPUT=""
KEY_NAME="CWF_RUN_AMBIGUITY_MODE"

usage() {
  cat <<'EOF'
Usage:
  configure-run-mode.sh --mode <strict|defer-blocking|defer-reversible|explore-worktrees> [options]

Options:
  --mode <value>         Required. Run ambiguity mode value.
  --scope <shared|local> Target config file (default: shared)
  --project-root <path>  Repository root (default: git root or current directory)
  -h, --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2-}"
      if [[ -z "$MODE" ]]; then
        echo "Error: --mode requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --scope)
      SCOPE="${2-}"
      if [[ -z "$SCOPE" ]]; then
        echo "Error: --scope requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --project-root)
      PROJECT_ROOT_INPUT="${2-}"
      if [[ -z "$PROJECT_ROOT_INPUT" ]]; then
        echo "Error: --project-root requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "Error: --mode is required" >&2
  usage >&2
  exit 2
fi

case "$MODE" in
  strict|defer-blocking|defer-reversible|explore-worktrees)
    ;;
  *)
    echo "Error: invalid mode: $MODE" >&2
    echo "Allowed: strict, defer-blocking, defer-reversible, explore-worktrees" >&2
    exit 2
    ;;
esac

case "$SCOPE" in
  shared|local)
    ;;
  *)
    echo "Error: invalid scope: $SCOPE (allowed: shared|local)" >&2
    exit 2
    ;;
esac

resolve_project_root() {
  local input="$1"
  local root=""

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

upsert_key_value() {
  local path="$1"
  local key="$2"
  local value="$3"
  local tmp_file=""
  local escaped_value=""

  escaped_value="${value//\\/\\\\}"
  escaped_value="${escaped_value//\"/\\\"}"

  tmp_file="$(mktemp)"
  awk -v key="$key" -v value="$escaped_value" '
    BEGIN { updated=0 }
    {
      if (!updated && $0 ~ "^[[:space:]]*" key "[[:space:]]*:") {
        print key ": \"" value "\""
        updated=1
        next
      }
      print
    }
    END {
      if (!updated) {
        if (NR > 0) {
          print ""
        }
        print "# cwf:run ambiguity handling mode"
        print key ": \"" value "\""
      }
    }
  ' "$path" > "$tmp_file"
  mv "$tmp_file" "$path"
}

PROJECT_ROOT="$(resolve_project_root "$PROJECT_ROOT_INPUT")"
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Error: project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

CONFIG_PATH="$PROJECT_ROOT/.cwf-config.yaml"
if [[ "$SCOPE" == "local" ]]; then
  CONFIG_PATH="$PROJECT_ROOT/.cwf-config.local.yaml"
fi

mkdir -p "$(dirname "$CONFIG_PATH")"
if [[ ! -f "$CONFIG_PATH" ]]; then
  cat > "$CONFIG_PATH" <<EOF
# CWF ${SCOPE} project config
EOF
fi

upsert_key_value "$CONFIG_PATH" "$KEY_NAME" "$MODE"

echo "project_root: $PROJECT_ROOT"
echo "scope: $SCOPE"
echo "config_file: $CONFIG_PATH"
echo "key: $KEY_NAME"
echo "value: $MODE"
