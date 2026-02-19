#!/usr/bin/env bash
# install-tooling-deps.sh — Check/install common local tooling dependencies for CWF workflows.

set -euo pipefail

MODE="check"
INSTALL_TARGETS="missing"
QUIET="false"

DEFAULT_TOOLS=(shellcheck jq gh node python3 lychee markdownlint-cli2)
TARGET_TOOLS=("${DEFAULT_TOOLS[@]}")

SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-v0.10.0}"
JQ_VERSION="${JQ_VERSION:-jq-1.7.1}"
LYCHEE_VERSION="${LYCHEE_VERSION:-v0.15.1}"
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
  core: shellcheck, jq, gh, node, python3, lychee, markdownlint-cli2
  optional: yq, rg, realpath, perl
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
    lychee) echo "lychee" ;;
    markdownlint-cli2) echo "markdownlint-cli2" ;;
    yq) echo "yq" ;;
    rg) echo "rg" ;;
    realpath) echo "realpath" ;;
    perl) echo "perl" ;;
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
      shellcheck|jq|gh|node|python3|lychee|markdownlint-cli2|yq|rg|realpath|perl)
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
  local platform url tmpdir base_url
  platform="$(detect_platform)"
  base_url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}"
  case "$platform" in
    linux-amd64) url="${base_url}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" ;;
    linux-arm64) url="${base_url}/shellcheck-${SHELLCHECK_VERSION}.linux.aarch64.tar.xz" ;;
    darwin-amd64) url="${base_url}/shellcheck-${SHELLCHECK_VERSION}.darwin.x86_64.tar.xz" ;;
    darwin-arm64) url="${base_url}/shellcheck-${SHELLCHECK_VERSION}.darwin.aarch64.tar.xz" ;;
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

install_lychee_local() {
  local platform asset url tmpdir binary_path
  platform="$(detect_platform)"
  case "$platform" in
    linux-amd64) asset="lychee-x86_64-unknown-linux-gnu.tar.gz" ;;
    linux-arm64) asset="lychee-aarch64-unknown-linux-gnu.tar.gz" ;;
    darwin-amd64) asset="lychee-x86_64-apple-darwin.tar.gz" ;;
    darwin-arm64) asset="lychee-aarch64-apple-darwin.tar.gz" ;;
    *)
      return 1
      ;;
  esac

  url="https://github.com/lycheeverse/lychee/releases/download/${LYCHEE_VERSION}/${asset}"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  curl -fsSL "$url" -o "$tmpdir/lychee.tar.gz" || return 1
  tar -xzf "$tmpdir/lychee.tar.gz" -C "$tmpdir" || return 1
  binary_path="$(find "$tmpdir" -type f -name lychee | head -n 1)"
  [[ -n "$binary_path" ]] || return 1

  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$binary_path" "$HOME/.local/bin/lychee"
}

install_markdownlint_local() {
  local user_bin="$HOME/.local/bin"
  local user_npm_bin="$HOME/.local/node_modules/.bin/markdownlint-cli2"

  command -v npm >/dev/null 2>&1 || return 1

  if npm install -g markdownlint-cli2 >/dev/null 2>&1; then
    return 0
  fi

  npm install --prefix "$HOME/.local" markdownlint-cli2 >/dev/null 2>&1 || return 1
  if [[ -x "$user_npm_bin" ]]; then
    mkdir -p "$user_bin"
    ln -sf "$user_npm_bin" "$user_bin/markdownlint-cli2"
  fi
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
    lychee)
      echo "brew install lychee  OR  sudo apt-get install -y lychee"
      ;;
    markdownlint-cli2)
      echo "npm install -g markdownlint-cli2"
      echo "  OR"
      echo "npm install --prefix ~/.local markdownlint-cli2"
      echo "  && ln -sf ~/.local/node_modules/.bin/markdownlint-cli2 ~/.local/bin/markdownlint-cli2"
      ;;
    yq)
      echo "brew install yq  OR  sudo apt-get install -y yq"
      ;;
    rg)
      echo "brew install ripgrep  OR  sudo apt-get install -y ripgrep"
      ;;
    realpath)
      echo "brew install coreutils  OR  sudo apt-get install -y coreutils"
      ;;
    perl)
      echo "brew install perl  OR  sudo apt-get install -y perl"
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
    lychee)
      if brew_install lychee || apt_install lychee || install_lychee_local; then
        if is_available lychee; then
          echo "lychee|installed|$(tool_cmd lychee)"
          return 0
        fi
      fi
      ;;
    markdownlint-cli2)
      if install_markdownlint_local; then
        if is_available markdownlint-cli2; then
          echo "markdownlint-cli2|installed|$(tool_cmd markdownlint-cli2)"
          return 0
        fi
      fi
      ;;
    yq)
      if brew_install yq || apt_install yq; then
        if is_available yq; then
          echo "yq|installed|$(tool_cmd yq)"
          return 0
        fi
      fi
      ;;
    rg)
      if brew_install ripgrep || apt_install ripgrep; then
        if is_available rg; then
          echo "rg|installed|$(tool_cmd rg)"
          return 0
        fi
      fi
      ;;
    realpath)
      if brew_install coreutils || apt_install coreutils; then
        if is_available realpath; then
          echo "realpath|installed|$(tool_cmd realpath)"
          return 0
        fi
      fi
      ;;
    perl)
      if brew_install perl || apt_install perl; then
        if is_available perl; then
          echo "perl|installed|$(tool_cmd perl)"
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
