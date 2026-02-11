#!/usr/bin/env bash
# install-wrapper.sh: Opt-in installer for Codex logging wrapper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WRAPPER_SRC="$REPO_ROOT/scripts/codex/codex-with-log.sh"

BIN_DIR="${CODEX_WRAPPER_BIN_DIR:-$HOME/.local/bin}"
DEST_BIN="$BIN_DIR/codex"
BACKUP_ROOT="$HOME/.codex/tmp"

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
  --enable          Install/activate wrapper at ~/.local/bin/codex
  --disable         Remove wrapper symlink if managed by this script
  --status          Show current status (default)
  --add-path        Append ~/.local/bin PATH export to ~/.zshrc and ~/.bashrc if missing
  -h, --help        Show help
USAGE
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
    if [ "$BIN_DIR" = "$HOME/.local/bin" ]; then
      path_line='export PATH="$HOME/.local/bin:$PATH"'
    else
      path_line="export PATH=\"$BIN_DIR:\$PATH\""
    fi

    ensure_path_line "$HOME/.zshrc" "$path_line"
    ensure_path_line "$HOME/.bashrc" "$path_line"
    echo "Ensured PATH line in ~/.zshrc and ~/.bashrc"
  fi

  status
  echo "Open a new shell (or run: source ~/.zshrc) before testing codex."
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
