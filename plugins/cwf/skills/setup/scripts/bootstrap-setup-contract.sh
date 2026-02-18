#!/usr/bin/env bash
set -euo pipefail

# bootstrap-setup-contract.sh — create/refresh repository-local setup contract.
# Usage: bootstrap-setup-contract.sh [--contract <path>] [--force] [--json]
# Defaults to {artifact_root}/setup-contract.yaml; artifact root resolves via
# cwf-artifact-paths.sh (fallback: ./.cwf). Existing files are preserved unless
# --force. On bootstrap failure, emit fallback metadata and keep setup flow moving.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

CONTRACT_PATH=""
FORCE="false"
JSON_OUTPUT="false"
WARNING=""

CORE_TOOLS=(shellcheck jq gh node python3 lychee markdownlint-cli2)
REPO_TOOL_CANDIDATES=(yq rg realpath perl)

declare -a REPO_TOOLS_FOUND=()
declare -A REPO_TOOL_EVIDENCE=()

usage() {
  cat <<'USAGE'
bootstrap-setup-contract.sh — bootstrap setup contract

Usage:
  bootstrap-setup-contract.sh [options]

Options:
  --contract <path>  Explicit contract path (default: {artifact_root}/setup-contract.yaml)
  --force            Overwrite existing contract file
  --json             Print machine-readable result
  -h, --help         Show this help
USAGE
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

yaml_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

append_warning() {
  local message="$1"
  if [[ -z "$WARNING" ]]; then
    WARNING="$message"
  else
    WARNING="$WARNING; $message"
  fi
}

emit_result() {
  local status="$1"
  local path="$2"
  local artifact_root="$3"
  local warning="${4-}"

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    if [[ -n "$warning" ]]; then
      printf '{"status":"%s","path":"%s","artifact_root":"%s","warning":"%s"}\n' \
        "$status" \
        "$(json_escape "$path")" \
        "$(json_escape "$artifact_root")" \
        "$(json_escape "$warning")"
    else
      printf '{"status":"%s","path":"%s","artifact_root":"%s"}\n' \
        "$status" \
        "$(json_escape "$path")" \
        "$(json_escape "$artifact_root")"
    fi
  else
    echo "status: $status"
    echo "path: $path"
    echo "artifact_root: $artifact_root"
    if [[ -n "$warning" ]]; then
      echo "warning: $warning"
    fi
  fi
}

resolve_artifact_root() {
  local resolved=""

  if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
    return 1
  fi

  if resolved="$(
    bash -c 'source "$1" && resolve_cwf_artifact_root "$2"' _ "$RESOLVER_SCRIPT" "$REPO_ROOT" 2>/dev/null
  )"; then
    if [[ -n "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  fi

  return 1
}

path_to_abs() {
  local path_value="$1"
  if [[ "$path_value" == /* ]]; then
    printf '%s\n' "$path_value"
  else
    printf '%s\n' "$REPO_ROOT/$path_value"
  fi
}

tool_install_hint() {
  case "$1" in
    shellcheck)
      echo "brew install shellcheck OR sudo apt-get install -y shellcheck"
      ;;
    jq)
      echo "brew install jq OR sudo apt-get install -y jq"
      ;;
    gh)
      echo "brew install gh OR sudo apt-get install -y gh"
      ;;
    node)
      echo "brew install node OR sudo apt-get install -y nodejs npm"
      ;;
    python3)
      echo "brew install python OR sudo apt-get install -y python3"
      ;;
    lychee)
      echo "brew install lychee OR sudo apt-get install -y lychee"
      ;;
    markdownlint-cli2)
      echo "npm install -g markdownlint-cli2"
      ;;
    yq)
      echo "brew install yq OR sudo apt-get install -y yq"
      ;;
    rg)
      echo "brew install ripgrep OR sudo apt-get install -y ripgrep"
      ;;
    realpath)
      echo "brew install coreutils OR sudo apt-get install -y coreutils"
      ;;
    perl)
      echo "brew install perl OR sudo apt-get install -y perl"
      ;;
    *)
      echo "manual install required"
      ;;
  esac
}

tool_reason() {
  case "$1" in
    shellcheck)
      echo "Shell lint gates in hooks and post-run checks."
      ;;
    jq)
      echo "JSON parsing for hooks and skill scripts."
      ;;
    gh)
      echo "GitHub automation in ship/release workflows."
      ;;
    node)
      echo "Node runtime for JavaScript utilities and lint tooling."
      ;;
    python3)
      echo "Python runtime used by repository helper scripts."
      ;;
    lychee)
      echo "Deterministic Markdown link checks in refactor/docs workflows."
      ;;
    markdownlint-cli2)
      echo "Deterministic Markdown lint checks in hooks and post-run checks."
      ;;
    yq)
      echo "Detected in repository-local automation scripts."
      ;;
    rg)
      echo "Detected in repository-local automation scripts."
      ;;
    realpath)
      echo "Detected in repository-local automation scripts."
      ;;
    perl)
      echo "Detected in repository-local automation scripts."
      ;;
    *)
      echo "Detected in repository-local automation scripts."
      ;;
  esac
}

tool_pattern() {
  case "$1" in
    yq)
      printf '%s\n' '(^|[^[:alnum:]_./-])yq([[:space:]]|$)'
      ;;
    rg)
      printf '%s\n' '(^|[^[:alnum:]_./-])rg([[:space:]]|$)'
      ;;
    realpath)
      printf '%s\n' '(^|[^[:alnum:]_./-])realpath([[:space:]]|$)'
      ;;
    perl)
      printf '%s\n' '(^|[^[:alnum:]_./-])perl([[:space:]]|$)'
      ;;
    *)
      return 1
      ;;
  esac
}

collect_repo_tool_evidence() {
  local scan_file=""
  local tracked_rel=""
  local tracked_abs=""
  local first_line=""
  local tool=""
  local pattern=""
  local rel_path=""
  local evidence_lines=""
  local -a scan_files=()

  if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r -d '' tracked_rel; do
      [[ -n "$tracked_rel" ]] || continue
      case "$tracked_rel" in
        .git/*|.cwf/*|node_modules/*|.venv/*|venv/*)
          continue
          ;;
      esac

      tracked_abs="$REPO_ROOT/$tracked_rel"
      [[ -f "$tracked_abs" ]] || continue

      case "$tracked_rel" in
        *.sh|*.bash|*.zsh|.githooks/*|*/.githooks/*)
          scan_files+=("$tracked_abs")
          continue
          ;;
      esac

      case "$tracked_rel" in
        scripts/*|*/scripts/*|ci/*|*/ci/*)
          first_line="$(head -n 1 "$tracked_abs" 2>/dev/null || true)"
          if [[ "$first_line" == "#!"* ]] && [[ "$first_line" =~ (bash|sh|zsh) ]]; then
            scan_files+=("$tracked_abs")
          fi
          ;;
      esac
    done < <(git -C "$REPO_ROOT" ls-files -z 2>/dev/null || true)
  fi

  if [[ "${#scan_files[@]}" -eq 0 ]]; then
    mapfile -t scan_files < <(
      find "$REPO_ROOT" \
        \( -path "$REPO_ROOT/.git" -o -path "$REPO_ROOT/.cwf" -o -path "$REPO_ROOT/node_modules" -o -path "$REPO_ROOT/.venv" -o -path "$REPO_ROOT/venv" \) -prune -o \
        -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' \) -print 2>/dev/null | sort -u
    )
  fi

  if [[ "${#scan_files[@]}" -eq 0 ]]; then
    append_warning "repository scan found no candidate shell files"
    return 0
  fi

  for tool in "${REPO_TOOL_CANDIDATES[@]}"; do
    pattern="$(tool_pattern "$tool")" || continue
    evidence_lines=""

    for scan_file in "${scan_files[@]}"; do
      [[ -f "$scan_file" ]] || continue
      if grep -Eq "$pattern" "$scan_file"; then
        rel_path="${scan_file#"$REPO_ROOT"/}"
        evidence_lines+="$rel_path"$'\n'
      fi
    done

    if [[ -n "$evidence_lines" ]]; then
      REPO_TOOLS_FOUND+=("$tool")
      REPO_TOOL_EVIDENCE["$tool"]="$(printf '%s' "$evidence_lines" | sed '/^$/d' | sort -u)"
    fi
  done
}

write_contract_file() {
  local destination="$1"
  local generated_at_utc="$2"
  local tool=""
  local evidence=""
  local evidence_path=""

  {
    echo 'version: 1'
    printf 'generated_at_utc: %s\n' "$(yaml_quote "$generated_at_utc")"
    echo 'mode: "advisory"'
    echo
    echo 'policy:'
    echo '  core_tools_required: true'
    echo '  repo_tools_opt_in: true'
    echo '  hook_index_coverage_mode: "authoring-only"'
    echo
    echo 'core_tools:'
    for tool in "${CORE_TOOLS[@]}"; do
      echo '  - name: '"$(yaml_quote "$tool")"
      echo '    required: true'
      echo '    reason: '"$(yaml_quote "$(tool_reason "$tool")")"
      echo '    install_hint: '"$(yaml_quote "$(tool_install_hint "$tool")")"
    done

    if [[ "${#REPO_TOOLS_FOUND[@]}" -eq 0 ]]; then
      echo
      echo 'repo_tools: []'
    else
      echo
      echo 'repo_tools:'
      for tool in "${REPO_TOOLS_FOUND[@]}"; do
        echo '  - name: '"$(yaml_quote "$tool")"
        echo '    required: false'
        echo '    reason: '"$(yaml_quote "$(tool_reason "$tool")")"
        echo '    install_hint: '"$(yaml_quote "$(tool_install_hint "$tool")")"
        echo '    evidence:'
        evidence="${REPO_TOOL_EVIDENCE[$tool]-}"
        while IFS= read -r evidence_path; do
          [[ -n "$evidence_path" ]] || continue
          echo '      - '"$(yaml_quote "$evidence_path")"
        done <<< "$evidence"
      done
    fi

    echo
    echo 'notes:'
    echo '  - "Auto-generated by setup contract bootstrap."'
    echo '  - "Review repo_tools and approve only repository-specific tools you want setup to manage."'
    echo '  - "Core tools are the deterministic baseline for cwf hooks/refactor workflows."'
  } > "$destination"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract)
      CONTRACT_PATH="${2-}"
      if [[ -z "$CONTRACT_PATH" ]]; then
        echo "Error: --contract requires a path value" >&2
        exit 1
      fi
      shift 2
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    --json)
      JSON_OUTPUT="true"
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
done

ARTIFACT_ROOT_RAW=""
if ! ARTIFACT_ROOT_RAW="$(resolve_artifact_root)"; then
  ARTIFACT_ROOT_RAW=".cwf"
  append_warning "artifact root resolver unavailable; using .cwf fallback"
fi
ARTIFACT_ROOT_ABS="$(path_to_abs "$ARTIFACT_ROOT_RAW")"

if [[ -z "$CONTRACT_PATH" ]]; then
  CONTRACT_PATH="$ARTIFACT_ROOT_ABS/setup-contract.yaml"
else
  CONTRACT_PATH="$(path_to_abs "$CONTRACT_PATH")"
fi

if ! mkdir -p "$(dirname "$CONTRACT_PATH")" 2>/dev/null; then
  append_warning "unable to create contract directory; continue with fallback defaults"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if [[ -f "$CONTRACT_PATH" && "$FORCE" != "true" ]]; then
  emit_result "existing" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

collect_repo_tool_evidence

generated_at_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
tmp_file="$(mktemp "$CONTRACT_PATH.tmp.XXXXXX" 2>/dev/null || true)"
if [[ -z "$tmp_file" ]]; then
  append_warning "unable to allocate temporary file for contract generation"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if ! write_contract_file "$tmp_file" "$generated_at_utc"; then
  mv "$tmp_file" "$tmp_file.failed" >/dev/null 2>&1 || true
  append_warning "failed to render setup contract draft"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if ! mv "$tmp_file" "$CONTRACT_PATH" 2>/dev/null; then
  mv "$tmp_file" "$tmp_file.failed" >/dev/null 2>&1 || true
  append_warning "failed to write setup contract file"
  emit_result "fallback" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
  exit 0
fi

if [[ "$FORCE" == "true" ]]; then
  emit_result "updated" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
else
  emit_result "created" "$CONTRACT_PATH" "$ARTIFACT_ROOT_ABS" "$WARNING"
fi

exit 0
