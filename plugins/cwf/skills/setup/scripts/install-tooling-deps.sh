#!/usr/bin/env bash
# install-tooling-deps.sh — Check/install common local tooling dependencies for CWF workflows.

set -euo pipefail

MODE="check"
INSTALL_TARGETS="missing"
QUIET="false"

DEFAULT_TOOLS=(shellcheck jq gh node python3)
TARGET_TOOLS=("${DEFAULT_TOOLS[@]}")

SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-v0.10.0}"
JQ_VERSION="${JQ_VERSION:-jq-1.7.1}"
APT_UPDATED="false"

usage() {
  cat <<'USAGE'
Usage:
  install-tooling-deps.sh [--check]
  install-tooling-deps.sh --install <missing|all|tool1,tool2,...>

Options:
  --check                      Check dependency status only (default)
  --install <targets>          Install targets:
                               missing (default), all, or comma list
  --quiet                      Suppress informational logs
  -h, --help                   Show this help

Managed tools:
  shellcheck, jq, gh, node, python3
USAGE
}

log() {
  if [[ "$QUIET" != "true" ]]; then
    echo "[cwf:setup deps] $*"
  fi
}

warn() {
  echo "[cwf:setup deps] WARN: $*" >&2
}

tool_cmd() {
  case "$1" in
    shellcheck) echo "shellcheck" ;;
    jq) echo "jq" ;;
    gh) echo "gh" ;;
    node) echo "node" ;;
    python3) echo "python3" ;;
    *) return 1 ;;
  esac
}

is_available() {
  local cmd
  cmd="$(tool_cmd "$1")" || return 1
  command -v "$cmd" >/dev/null 2>&1
}

resolve_tools_from_arg() {
  local arg="$1"
  local token=""
  local items=()
  IFS=',' read -r -a items <<<"$arg"
  TARGET_TOOLS=()
  for token in "${items[@]}"; do
    token="$(echo "$token" | tr -d '[:space:]')"
    [[ -n "$token" ]] || continue
    case "$token" in
      shellcheck|jq|gh|node|python3)
        TARGET_TOOLS+=("$token")
        ;;
      *)
        warn "unknown tool ignored: $token"
        ;;
    esac
  done
}

can_use_sudo_noninteractive() {
  command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1
}

run_as_root_or_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return $?
  fi
  if can_use_sudo_noninteractive; then
    sudo "$@"
    return $?
  fi
  return 1
}

apt_install() {
  local pkg="$1"
  command -v apt-get >/dev/null 2>&1 || return 1
  if ! run_as_root_or_sudo true >/dev/null 2>&1; then
    return 1
  fi
  if [[ "$APT_UPDATED" != "true" ]]; then
    run_as_root_or_sudo apt-get update -y >/dev/null 2>&1 || return 1
    APT_UPDATED="true"
  fi
  run_as_root_or_sudo apt-get install -y "$pkg" >/dev/null 2>&1
}

brew_install() {
  local pkg="$1"
  command -v brew >/dev/null 2>&1 || return 1
  brew install "$pkg" >/dev/null 2>&1
}

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os/$arch" in
    Linux/x86_64) echo "linux-amd64" ;;
    Linux/aarch64|Linux/arm64) echo "linux-arm64" ;;
    Darwin/x86_64) echo "darwin-amd64" ;;
    Darwin/arm64) echo "darwin-arm64" ;;
    *) echo "unsupported" ;;
  esac
}

install_shellcheck_local() {
  local platform url tmpdir
  platform="$(detect_platform)"
  case "$platform" in
    linux-amd64) url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" ;;
    linux-arm64) url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.aarch64.tar.xz" ;;
    darwin-amd64) url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.darwin.x86_64.tar.xz" ;;
    darwin-arm64) url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.darwin.aarch64.tar.xz" ;;
    *)
      return 1
      ;;
  esac

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  curl -fsSL "$url" -o "$tmpdir/shellcheck.tar.xz" || return 1
  tar -xJf "$tmpdir/shellcheck.tar.xz" -C "$tmpdir" || return 1
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$tmpdir/shellcheck-${SHELLCHECK_VERSION}/shellcheck" "$HOME/.local/bin/shellcheck"
}

install_jq_local() {
  local platform asset url
  platform="$(detect_platform)"
  case "$platform" in
    linux-amd64) asset="jq-linux-amd64" ;;
    linux-arm64) asset="jq-linux-arm64" ;;
    darwin-amd64) asset="jq-macos-amd64" ;;
    darwin-arm64) asset="jq-macos-arm64" ;;
    *)
      return 1
      ;;
  esac
  url="https://github.com/jqlang/jq/releases/download/${JQ_VERSION}/${asset}"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "$url" -o "$HOME/.local/bin/jq" || return 1
  chmod 0755 "$HOME/.local/bin/jq"
}

manual_hint() {
  case "$1" in
    shellcheck)
      echo "brew install shellcheck  OR  sudo apt-get install -y shellcheck"
      ;;
    jq)
      echo "brew install jq  OR  sudo apt-get install -y jq"
      ;;
    gh)
      echo "brew install gh  OR  sudo apt-get install -y gh"
      ;;
    node)
      echo "brew install node  OR  sudo apt-get install -y nodejs npm"
      ;;
    python3)
      echo "brew install python  OR  sudo apt-get install -y python3"
      ;;
  esac
}

install_tool() {
  local tool="$1"

  if is_available "$tool"; then
    echo "$tool|already_available|$(tool_cmd "$tool")"
    return 0
  fi

  case "$tool" in
    shellcheck)
      if brew_install shellcheck || apt_install shellcheck || install_shellcheck_local; then
        if is_available shellcheck; then
          echo "shellcheck|installed|$(tool_cmd shellcheck)"
          return 0
        fi
      fi
      ;;
    jq)
      if brew_install jq || apt_install jq || install_jq_local; then
        if is_available jq; then
          echo "jq|installed|$(tool_cmd jq)"
          return 0
        fi
      fi
      ;;
    gh)
      if brew_install gh || apt_install gh; then
        if is_available gh; then
          echo "gh|installed|$(tool_cmd gh)"
          return 0
        fi
      fi
      ;;
    node)
      if brew_install node || apt_install nodejs; then
        if is_available node; then
          echo "node|installed|$(tool_cmd node)"
          return 0
        fi
      fi
      ;;
    python3)
      if brew_install python || apt_install python3; then
        if is_available python3; then
          echo "python3|installed|$(tool_cmd python3)"
          return 0
        fi
      fi
      ;;
  esac

  echo "$tool|failed|$(manual_hint "$tool")"
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --install)
      MODE="install"
      INSTALL_TARGETS="${2:-}"
      if [[ -z "$INSTALL_TARGETS" ]]; then
        echo "Error: --install requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --quiet)
      QUIET="true"
      shift
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

if [[ "$MODE" == "install" ]]; then
  case "$INSTALL_TARGETS" in
    missing)
      TARGET_TOOLS=()
      for t in "${DEFAULT_TOOLS[@]}"; do
        if ! is_available "$t"; then
          TARGET_TOOLS+=("$t")
        fi
      done
      ;;
    all)
      TARGET_TOOLS=("${DEFAULT_TOOLS[@]}")
      ;;
    *)
      resolve_tools_from_arg "$INSTALL_TARGETS"
      ;;
  esac
fi

if [[ "${#TARGET_TOOLS[@]}" -eq 0 ]]; then
  log "no target tools selected"
  exit 0
fi

missing_count=0
failed_count=0

echo "Tool dependency status:"
for tool in "${TARGET_TOOLS[@]}"; do
  if is_available "$tool"; then
    echo "  - $tool: available ($(command -v "$(tool_cmd "$tool")"))"
  else
    echo "  - $tool: missing"
    missing_count=$((missing_count + 1))
  fi
done

if [[ "$MODE" == "check" ]]; then
  if [[ "$missing_count" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

echo
echo "Install attempt results:"
for tool in "${TARGET_TOOLS[@]}"; do
  if output="$(install_tool "$tool")"; then
    IFS='|' read -r t status detail <<<"$output"
    case "$status" in
      already_available)
        echo "  - $t: already available"
        ;;
      installed)
        echo "  - $t: installed ($detail)"
        ;;
      *)
        echo "  - $t: $status ($detail)"
        ;;
    esac
  else
    IFS='|' read -r t status detail <<<"$output"
    echo "  - $t: $status ($detail)"
    failed_count=$((failed_count + 1))
  fi
done

echo
echo "Final status:"
for tool in "${TARGET_TOOLS[@]}"; do
  if is_available "$tool"; then
    echo "  - $tool: available"
  else
    echo "  - $tool: missing"
  fi
done

if [[ "$failed_count" -gt 0 ]]; then
  exit 1
fi
exit 0
