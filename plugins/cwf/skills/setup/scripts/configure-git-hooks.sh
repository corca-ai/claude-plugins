#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
configure-git-hooks.sh — install/update repository git hook gates

Usage:
  configure-git-hooks.sh [--install none|pre-commit|pre-push|both] [--profile fast|balanced|strict] [--no-hooks-path]

Options:
  --install       Which git hooks to install (default: both)
  --profile       Gate depth profile (default: balanced)
  --no-hooks-path Do not modify git core.hooksPath
  -h, --help      Show this message

Profiles:
  fast      pre-commit: staged markdownlint; pre-push: repo markdownlint
  balanced  fast + local link checks + staged shellcheck (if available) + index coverage checks on push
  strict    balanced + script dependency/readme structure hard gates + provenance/growth-drift reports
USAGE
}

INSTALL_MODE="both"
PROFILE="balanced"
APPLY_HOOKS_PATH="true"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CWF_PLUGIN_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

escape_for_perl_replacement() {
  printf '%s' "$1" | sed 's/[\\/&]/\\&/g'
}

compute_sha256() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return 0
  fi
  return 1
}

CWF_PLUGIN_ROOT_ESCAPED="$(escape_for_perl_replacement "$CWF_PLUGIN_ROOT_DEFAULT")"
CONFIG_SHA="$(compute_sha256 "$0" 2>/dev/null || true)"
if [[ -z "$CONFIG_SHA" ]]; then
  echo "Warning: SHA-256 tool missing (sha256sum/shasum). Using source marker 'sha-unavailable'." >&2
  CONFIG_SHA="sha-unavailable"
fi
CONFIG_SHA_ESCAPED="$(escape_for_perl_replacement "$CONFIG_SHA")"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      INSTALL_MODE="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --no-hooks-path)
      APPLY_HOOKS_PATH="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$INSTALL_MODE" in
  none|pre-commit|pre-push|both) ;;
  *)
    echo "Invalid --install value: $INSTALL_MODE (expected: none|pre-commit|pre-push|both)" >&2
    exit 2
    ;;
esac

case "$PROFILE" in
  fast|balanced|strict) ;;
  *)
    echo "Invalid --profile value: $PROFILE (expected: fast|balanced|strict)" >&2
    exit 2
    ;;
esac

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Not inside a git repository" >&2
  exit 2
fi

HOOK_DIR="$REPO_ROOT/.githooks"
mkdir -p "$HOOK_DIR"

want_pre_commit="false"
want_pre_push="false"
case "$INSTALL_MODE" in
  pre-commit)
    want_pre_commit="true"
    ;;
  pre-push)
    want_pre_push="true"
    ;;
  both)
    want_pre_commit="true"
    want_pre_push="true"
    ;;
esac

HOOK_TEMPLATE_DIR="$SCRIPT_DIR/../assets/githooks"
PRE_COMMIT_TEMPLATE="$HOOK_TEMPLATE_DIR/pre-commit.template.sh"
PRE_PUSH_TEMPLATE="$HOOK_TEMPLATE_DIR/pre-push.template.sh"

render_hook_template() {
  local template_path="$1"
  local output_path="$2"
  local profile="$3"
  local profile_escaped=""
  local perl_expr=""
  local tmp_rendered=""

  if [[ ! -f "$template_path" ]]; then
    echo "Hook template not found: $template_path" >&2
    exit 2
  fi

  cp "$template_path" "$output_path"
  profile_escaped="$(escape_for_perl_replacement "$profile")"

  if command -v perl >/dev/null 2>&1; then
    perl_expr="s/__PROFILE__/$profile_escaped/g;"
    perl_expr+=" s/__CWF_PLUGIN_ROOT__/$CWF_PLUGIN_ROOT_ESCAPED/g;"
    perl_expr+=" s/__CONFIG_SHA__/$CONFIG_SHA_ESCAPED/g"
    perl -0pi -e "$perl_expr" "$output_path"
  else
    tmp_rendered="$(mktemp)"
    sed \
      -e "s/__PROFILE__/$profile_escaped/g" \
      -e "s/__CWF_PLUGIN_ROOT__/$CWF_PLUGIN_ROOT_ESCAPED/g" \
      -e "s/__CONFIG_SHA__/$CONFIG_SHA_ESCAPED/g" \
      "$output_path" > "$tmp_rendered"
    mv "$tmp_rendered" "$output_path"
  fi

  chmod +x "$output_path"
}

write_pre_commit() {
  local path="$1"
  local profile="$2"
  render_hook_template "$PRE_COMMIT_TEMPLATE" "$path" "$profile"
}

write_pre_push() {
  local path="$1"
  local profile="$2"
  render_hook_template "$PRE_PUSH_TEMPLATE" "$path" "$profile"
}

if [[ "$want_pre_commit" == "true" ]]; then
  write_pre_commit "$HOOK_DIR/pre-commit" "$PROFILE"
else
  rm -f "$HOOK_DIR/pre-commit"
fi

if [[ "$want_pre_push" == "true" ]]; then
  write_pre_push "$HOOK_DIR/pre-push" "$PROFILE"
else
  rm -f "$HOOK_DIR/pre-push"
fi

if [[ "$APPLY_HOOKS_PATH" == "true" ]]; then
  if [[ "$INSTALL_MODE" == "none" ]]; then
    current_hooks_path="$(git config --get core.hooksPath || true)"
    if [[ "$current_hooks_path" == ".githooks" ]]; then
      git config --unset core.hooksPath || true
    fi
  else
    git config core.hooksPath .githooks
  fi
fi

echo "Git hook configuration updated"
echo "  install mode : $INSTALL_MODE"
echo "  gate profile : $PROFILE"
if [[ "$APPLY_HOOKS_PATH" == "true" ]]; then
  echo "  core.hooksPath: $(git config --get core.hooksPath 2>/dev/null || echo '(unset)')"
else
  echo "  core.hooksPath: unchanged"
fi

echo "  pre-commit   : $([[ -f "$HOOK_DIR/pre-commit" ]] && echo installed || echo removed)"
echo "  pre-push     : $([[ -f "$HOOK_DIR/pre-push" ]] && echo installed || echo removed)"
