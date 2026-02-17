#!/usr/bin/env bash
# install-wrapper.sh: Opt-in installer for Codex logging wrapper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SRC="$SCRIPT_DIR/codex-with-log.sh"

SCOPE="${CWF_CLAUDE_PLUGIN_SCOPE:-user}"
PROJECT_ROOT=""

BIN_DIR=""
DEST_BIN=""
BACKUP_ROOT=""

MODE="status"
ADD_PATH=false

usage() {
  cat <<'USAGE'
Manage Codex wrapper installation.

Usage:
  install-wrapper.sh --status
  install-wrapper.sh --enable [--add-path]
  install-wrapper.sh --disable

Options:
  --scope <user|project|local>
                    Wrapper scope (default: user)
  --project-root <path>
                    Project root for project/local scope (default: git root or cwd)
  --enable          Install/activate wrapper at scope-specific codex path
  --disable         Remove wrapper symlink if managed by this script
  --status          Show current status (default)
  --add-path        Add PATH line to shell rc files (user scope only)
  -h, --help        Show help
USAGE
}

resolve_scope_paths() {
  case "$SCOPE" in
    user)
      BIN_DIR="${CODEX_WRAPPER_BIN_DIR:-$HOME/.local/bin}"
      BACKUP_ROOT="$HOME/.codex/tmp"
      ;;
    project|local)
      if [ -z "$PROJECT_ROOT" ]; then
        PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"
      fi
      if [ ! -d "$PROJECT_ROOT" ]; then
        echo "Project root not found: $PROJECT_ROOT" >&2
        exit 1
      fi
      PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
      BIN_DIR="${CODEX_WRAPPER_BIN_DIR:-$PROJECT_ROOT/.codex/bin}"
      BACKUP_ROOT="$PROJECT_ROOT/.codex/tmp"
      ;;
    *)
      echo "Invalid scope: $SCOPE (allowed: user|project|local)" >&2
      exit 1
      ;;
  esac

  DEST_BIN="$BIN_DIR/codex"
}

ensure_path_line() {
  local rc_file="$1"
  local path_line="$2"
  local marker="# Added by CWF codex wrapper"

  touch "$rc_file"

  if grep -Fq "$path_line" "$rc_file"; then
    return 0
  fi

  {
    echo ""
    echo "$marker"
    echo "$path_line"
  } >> "$rc_file"
}

status() {
  local active="false"

  if [ -L "$DEST_BIN" ] && [ "$(readlink "$DEST_BIN")" = "$WRAPPER_SRC" ]; then
    active="true"
  fi

  echo "Scope         : $SCOPE"
  if [ "$SCOPE" = "project" ] || [ "$SCOPE" = "local" ]; then
    echo "Project root  : $PROJECT_ROOT"
  fi
  echo "Wrapper source: $WRAPPER_SRC"
  echo "Wrapper link  : $DEST_BIN"
  echo "Active        : $active"
  echo "command -v codex: $(command -v codex 2>/dev/null || echo 'not found')"

  if command -v codex >/dev/null 2>&1; then
    echo "which -a codex:"
    which -a codex | awk '!seen[$0]++ {print "  - " $0}'
  fi
}

backup_existing_dest() {
  mkdir -p "$BACKUP_ROOT"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local backup_path="$BACKUP_ROOT/codex-wrapper-backup-${stamp}"
  mv "$DEST_BIN" "$backup_path"
  echo "Backed up existing $DEST_BIN -> $backup_path"
}

enable_wrapper() {
  if [ ! -x "$WRAPPER_SRC" ]; then
    echo "Wrapper script not executable: $WRAPPER_SRC" >&2
    exit 1
  fi

  mkdir -p "$BIN_DIR"

  if [ -e "$DEST_BIN" ] && [ ! -L "$DEST_BIN" ]; then
    backup_existing_dest
  fi

  if [ -L "$DEST_BIN" ] && [ "$(readlink "$DEST_BIN")" = "$WRAPPER_SRC" ]; then
    echo "Wrapper already active: $DEST_BIN"
  else
    ln -sfn "$WRAPPER_SRC" "$DEST_BIN"
    echo "Installed wrapper: $DEST_BIN -> $WRAPPER_SRC"
  fi

  if [ "$ADD_PATH" = "true" ]; then
    if [ "$SCOPE" = "user" ]; then
      if [ "$BIN_DIR" = "$HOME/.local/bin" ]; then
        path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
      else
        path_line="export PATH=\"$BIN_DIR:\$PATH\""
      fi

      ensure_path_line "$HOME/.zshrc" "$path_line"
      ensure_path_line "$HOME/.bashrc" "$path_line"
      echo "Ensured PATH line in ~/.zshrc and ~/.bashrc"
    else
      echo "Skipping --add-path for scope '$SCOPE'."
      echo "Add PATH manually when needed: export PATH=\"$BIN_DIR:\$PATH\""
    fi
  fi

  status
  if [ "$SCOPE" = "user" ]; then
    echo "Open a new shell (or run: source ~/.zshrc) before testing codex."
  else
    echo "Use PATH override to activate project wrapper: export PATH=\"$BIN_DIR:\$PATH\""
  fi
  echo "Aliases that call 'codex' (e.g., codexyolo='codex ...') will also use the wrapper."
}

disable_wrapper() {
  if [ -L "$DEST_BIN" ] && [ "$(readlink "$DEST_BIN")" = "$WRAPPER_SRC" ]; then
    rm -f "$DEST_BIN"
    echo "Removed wrapper symlink: $DEST_BIN"
  else
    echo "Wrapper symlink not active at $DEST_BIN"
  fi

  status
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope)
      SCOPE="${2:-}"
      shift 2
      ;;
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --enable)
      MODE="enable"
      shift
      ;;
    --disable)
      MODE="disable"
      shift
      ;;
    --status)
      MODE="status"
      shift
      ;;
    --add-path)
      ADD_PATH=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

resolve_scope_paths

case "$MODE" in
  enable)
    enable_wrapper
    ;;
  disable)
    disable_wrapper
    ;;
  status)
    status
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac

exit 0
