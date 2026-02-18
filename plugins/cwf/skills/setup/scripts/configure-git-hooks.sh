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
  echo "Unable to compute configure-git-hooks.sh SHA-256 (sha256sum/shasum required)" >&2
  exit 2
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

write_pre_commit() {
  local path="$1"
  local profile="$2"

  cat > "$path" <<'SCRIPT'
#!/usr/bin/env bash
# cwf-hook-source-sha=__CONFIG_SHA__
set -euo pipefail

PROFILE="__PROFILE__"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
CWF_PLUGIN_ROOT="${CWF_PLUGIN_ROOT:-__CWF_PLUGIN_ROOT__}"

resolve_cwf_path() {
  local rel="$1"
  local candidate=""
  for candidate in \
    "$CWF_PLUGIN_ROOT/$rel" \
    "$CWF_PLUGIN_ROOT/plugins/cwf/$rel" \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/plugins/cwf/$rel"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_cwf_exec_path() {
  local rel="$1"
  local candidate=""
  for candidate in \
    "$CWF_PLUGIN_ROOT/$rel" \
    "$CWF_PLUGIN_ROOT/plugins/cwf/$rel" \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/plugins/cwf/$rel"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

CWF_LINK_CHECKER="$(resolve_cwf_exec_path "skills/refactor/scripts/check-links.sh" || true)"
CWF_ARTIFACT_PATHS="$(resolve_cwf_path "scripts/cwf-artifact-paths.sh" || true)"
CWF_PLUGIN_DESC_SYNC="$(resolve_cwf_exec_path "scripts/sync-marketplace-descriptions.sh" || true)"
CWF_UNIFIED_GATE="$(resolve_cwf_exec_path "scripts/check-portability-contract.sh" || true)"

normalize_rel_path() {
  local value="$1"
  value="${value#./}"
  value="${value%/}"
  printf '%s' "$value"
}

add_skip_prefix() {
  local rel_path="${1:-}"
  local normalized=""
  local existing=""
  [[ -n "$rel_path" ]] || return 0
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" && "$normalized" != "." ]] || return 0
  for existing in "${RUNTIME_SKIP_PREFIXES[@]}"; do
    if [[ "$existing" == "$normalized" ]]; then
      return 0
    fi
  done
  RUNTIME_SKIP_PREFIXES+=("$normalized")
}

add_skip_abs_dir() {
  local abs_path="${1:-}"
  local rel_path=""
  [[ -n "$abs_path" ]] || return 0
  abs_path="${abs_path%/}"
  if [[ "$abs_path" == "$REPO_ROOT" || "$abs_path" != "$REPO_ROOT/"* ]]; then
    return 0
  fi
  rel_path="${abs_path#"$REPO_ROOT"/}"
  add_skip_prefix "$rel_path"
}

init_runtime_skip_prefixes() {
  local projects_dir=""
  local sessions_dir=""
  local prompt_logs_dir=""
  RUNTIME_SKIP_PREFIXES=()
  if [[ -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    projects_dir="$(resolve_cwf_projects_dir "$REPO_ROOT" 2>/dev/null || true)"
    sessions_dir="$(resolve_cwf_session_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    prompt_logs_dir="$(resolve_cwf_prompt_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    add_skip_abs_dir "$projects_dir"
    add_skip_abs_dir "$sessions_dir"
    add_skip_abs_dir "$prompt_logs_dir"
  fi
  add_skip_prefix ".cwf/projects"
  add_skip_prefix ".cwf/sessions"
  add_skip_prefix ".cwf/prompt-logs"
}

is_runtime_skip_path() {
  local rel_path="$1"
  local normalized=""
  local prefix=""
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" ]] || return 1
  for prefix in "${RUNTIME_SKIP_PREFIXES[@]}"; do
    if [[ "$normalized" == "$prefix" || "$normalized" == "$prefix/"* ]]; then
      return 0
    fi
  done
  return 1
}

is_cwf_authoring_repo() {
  [[ -d "$REPO_ROOT/plugins/cwf" && -f "$REPO_ROOT/README.md" && -f "$REPO_ROOT/README.ko.md" ]]
}

ensure_markdownlint_cli2() {
  if command -v markdownlint-cli2 >/dev/null 2>&1; then
    return 0
  fi
  echo "[pre-commit] markdownlint-cli2 not found; run 'cwf:setup --tools'." >&2
  exit 1
}

RUNTIME_SKIP_PREFIXES=()
init_runtime_skip_prefixes

mapfile -t plugin_meta_files < <(
  git diff --cached --name-only --diff-filter=ACMR -- \
    '.claude-plugin/marketplace.json' \
    'plugins/*/.claude-plugin/plugin.json' \
    || true
)
if [ "${#plugin_meta_files[@]}" -gt 0 ]; then
  if [[ -z "$CWF_PLUGIN_DESC_SYNC" ]]; then
    echo "[pre-commit] sync-marketplace-descriptions.sh not found; skipping marketplace sync." >&2
  else
    run_all_plugins=false
    declare -a plugin_sync_args=()
    declare -a plugin_names_seen=()

    has_seen_plugin() {
      local candidate="$1"
      local existing=""
      for existing in "${plugin_names_seen[@]}"; do
        if [[ "$existing" == "$candidate" ]]; then
          return 0
        fi
      done
      return 1
    }

    for file in "${plugin_meta_files[@]}"; do
      if [[ "$file" == ".claude-plugin/marketplace.json" ]]; then
        run_all_plugins=true
        continue
      fi
      if [[ "$file" =~ ^plugins/([^/]+)/\.claude-plugin/plugin\.json$ ]]; then
        plugin_name="${BASH_REMATCH[1]}"
        if ! has_seen_plugin "$plugin_name"; then
          plugin_names_seen+=("$plugin_name")
          plugin_sync_args+=(--plugin "$plugin_name")
        fi
      fi
    done

    echo "[pre-commit] syncing marketplace descriptions from plugin manifests..."
    if [[ "$run_all_plugins" == "true" || "${#plugin_sync_args[@]}" -eq 0 ]]; then
      bash "$CWF_PLUGIN_DESC_SYNC"
      bash "$CWF_PLUGIN_DESC_SYNC" --check
    else
      bash "$CWF_PLUGIN_DESC_SYNC" "${plugin_sync_args[@]}"
      bash "$CWF_PLUGIN_DESC_SYNC" --check "${plugin_sync_args[@]}"
    fi

    git add .claude-plugin/marketplace.json
  fi
fi

mapfile -t md_candidates < <(git diff --cached --name-only --diff-filter=ACMR -- '*.md' '*.mdx' || true)
md_files=()
for file in "${md_candidates[@]}"; do
  if [[ "$file" == references/anthropic-skills-guide/* ]]; then
    continue
  fi
  if is_runtime_skip_path "$file"; then
    continue
  fi
  md_files+=("$file")
done

if [ "${#md_files[@]}" -gt 0 ]; then
  ensure_markdownlint_cli2
  echo "[pre-commit] markdownlint on staged markdown files..."
  markdownlint-cli2 "${md_files[@]}"

  if [[ "$PROFILE" != "fast" ]]; then
    if [[ -n "$CWF_LINK_CHECKER" ]]; then
      echo "[pre-commit] local link validation on staged markdown files..."
      for file in "${md_files[@]}"; do
        case "$file" in
          CHANGELOG.md|references/*)
            continue
            ;;
        esac
        bash "$CWF_LINK_CHECKER" --local --json --file "$file" >/dev/null
      done
    else
      echo "[pre-commit] CWF link checker unavailable; skipping local link validation." >&2
    fi
  fi
fi

if [[ "$PROFILE" != "fast" ]]; then
  mapfile -t sh_files < <(git diff --cached --name-only --diff-filter=ACMR -- '*.sh' || true)
  if [ "${#sh_files[@]}" -gt 0 ]; then
    if command -v shellcheck >/dev/null 2>&1; then
      echo "[pre-commit] shellcheck on staged shell scripts..."
      shellcheck -x "${sh_files[@]}"
    else
      echo "[pre-commit] shellcheck not found; skipping shell lint" >&2
    fi
  fi
fi

if [[ -n "$CWF_UNIFIED_GATE" ]]; then
  echo "[pre-commit] unified portability gate (hook context)..."
  bash "$CWF_UNIFIED_GATE" --contract auto --context hook
fi
SCRIPT

  perl -0pi -e "s/__PROFILE__/$profile/g; s/__CWF_PLUGIN_ROOT__/$CWF_PLUGIN_ROOT_ESCAPED/g; s/__CONFIG_SHA__/$CONFIG_SHA_ESCAPED/g" "$path"
  chmod +x "$path"
}

write_pre_push() {
  local path="$1"
  local profile="$2"

  cat > "$path" <<'SCRIPT'
#!/usr/bin/env bash
# cwf-hook-source-sha=__CONFIG_SHA__
set -euo pipefail

PROFILE="__PROFILE__"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
CWF_PLUGIN_ROOT="${CWF_PLUGIN_ROOT:-__CWF_PLUGIN_ROOT__}"

resolve_cwf_path() {
  local rel="$1"
  local candidate=""
  for candidate in \
    "$CWF_PLUGIN_ROOT/$rel" \
    "$CWF_PLUGIN_ROOT/plugins/cwf/$rel" \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/plugins/cwf/$rel"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_cwf_exec_path() {
  local rel="$1"
  local candidate=""
  for candidate in \
    "$CWF_PLUGIN_ROOT/$rel" \
    "$CWF_PLUGIN_ROOT/plugins/cwf/$rel" \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/plugins/cwf/$rel"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

CWF_LINK_CHECKER="$(resolve_cwf_exec_path "skills/refactor/scripts/check-links.sh" || true)"
CWF_ARTIFACT_PATHS="$(resolve_cwf_path "scripts/cwf-artifact-paths.sh" || true)"
CWF_INDEX_COVERAGE="$(resolve_cwf_exec_path "skills/setup/scripts/check-index-coverage.sh" || true)"
CWF_PROVENANCE="$(resolve_cwf_exec_path "scripts/provenance-check.sh" || true)"
CWF_GROWTH_DRIFT="$(resolve_cwf_exec_path "scripts/check-growth-drift.sh" || true)"
CWF_SCRIPT_DEPS="$(resolve_cwf_exec_path "scripts/check-script-deps.sh" || true)"
CWF_README_STRUCTURE="$(resolve_cwf_exec_path "scripts/check-readme-structure.sh" || true)"
CWF_UNIFIED_GATE="$(resolve_cwf_exec_path "scripts/check-portability-contract.sh" || true)"

normalize_rel_path() {
  local value="$1"
  value="${value#./}"
  value="${value%/}"
  printf '%s' "$value"
}

add_skip_prefix() {
  local rel_path="${1:-}"
  local normalized=""
  local existing=""
  [[ -n "$rel_path" ]] || return 0
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" && "$normalized" != "." ]] || return 0
  for existing in "${RUNTIME_SKIP_PREFIXES[@]}"; do
    if [[ "$existing" == "$normalized" ]]; then
      return 0
    fi
  done
  RUNTIME_SKIP_PREFIXES+=("$normalized")
}

add_skip_abs_dir() {
  local abs_path="${1:-}"
  local rel_path=""
  [[ -n "$abs_path" ]] || return 0
  abs_path="${abs_path%/}"
  if [[ "$abs_path" == "$REPO_ROOT" || "$abs_path" != "$REPO_ROOT/"* ]]; then
    return 0
  fi
  rel_path="${abs_path#"$REPO_ROOT"/}"
  add_skip_prefix "$rel_path"
}

init_runtime_skip_prefixes() {
  local projects_dir=""
  local sessions_dir=""
  local prompt_logs_dir=""
  RUNTIME_SKIP_PREFIXES=()
  if [[ -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    projects_dir="$(resolve_cwf_projects_dir "$REPO_ROOT" 2>/dev/null || true)"
    sessions_dir="$(resolve_cwf_session_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    prompt_logs_dir="$(resolve_cwf_prompt_logs_dir "$REPO_ROOT" 2>/dev/null || true)"
    add_skip_abs_dir "$projects_dir"
    add_skip_abs_dir "$sessions_dir"
    add_skip_abs_dir "$prompt_logs_dir"
  fi
  add_skip_prefix ".cwf/projects"
  add_skip_prefix ".cwf/sessions"
  add_skip_prefix ".cwf/prompt-logs"
}

is_runtime_skip_path() {
  local rel_path="$1"
  local normalized=""
  local prefix=""
  normalized="$(normalize_rel_path "$rel_path")"
  [[ -n "$normalized" ]] || return 1
  for prefix in "${RUNTIME_SKIP_PREFIXES[@]}"; do
    if [[ "$normalized" == "$prefix" || "$normalized" == "$prefix/"* ]]; then
      return 0
    fi
  done
  return 1
}

is_cwf_authoring_repo() {
  [[ -d "$REPO_ROOT/plugins/cwf" && -f "$REPO_ROOT/README.md" && -f "$REPO_ROOT/README.ko.md" ]]
}

read_contract_scalar() {
  local file_path="$1"
  local key="$2"
  local line=""
  local value=""

  [[ -f "$file_path" ]] || return 1
  line="$(grep -shm1 -E "^[[:space:]]*${key}:[[:space:]]*" "$file_path" 2>/dev/null || true)"
  [[ -n "$line" ]] || return 1

  value="${line#*:}"
  value="$(printf '%s' "$value" | sed -E 's/[[:space:]]+#.*$//' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  [[ -n "$value" ]] || return 1
  printf '%s\n' "$value"
}

resolve_setup_contract_path() {
  local artifact_root=""
  if [[ -n "$CWF_ARTIFACT_PATHS" && -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    artifact_root="$(resolve_cwf_artifact_root "$REPO_ROOT" 2>/dev/null || true)"
    if [[ -n "$artifact_root" ]]; then
      printf '%s\n' "$artifact_root/setup-contract.yaml"
      return 0
    fi
  fi
  printf '%s\n' "$REPO_ROOT/.cwf/setup-contract.yaml"
}

resolve_index_coverage_mode() {
  local contract_path="$1"
  local mode=""
  mode="$(read_contract_scalar "$contract_path" "hook_index_coverage_mode" 2>/dev/null || true)"
  if [[ -z "$mode" ]]; then
    mode="authoring-only"
  fi
  printf '%s\n' "$mode"
}

run_index_coverage_checks() {
  local coverage_rc=0
  local cap_index_file=".cwf/indexes/cwf-index.md"
  local cap_index_dir=""

  if [[ -n "$CWF_ARTIFACT_PATHS" && -f "$CWF_ARTIFACT_PATHS" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$CWF_ARTIFACT_PATHS"
    cap_index_dir="$(resolve_cwf_indexes_dir "$REPO_ROOT" 2>/dev/null || true)"
    if [[ -n "$cap_index_dir" ]]; then
      cap_index_file="${cap_index_dir}/cwf-index.md"
    fi
  fi

  if [[ -f AGENTS.md ]]; then
    if ! bash "$CWF_INDEX_COVERAGE" AGENTS.md --profile repo; then
      coverage_rc=1
    fi
  fi
  if [[ -f "$cap_index_file" ]]; then
    if ! bash "$CWF_INDEX_COVERAGE" "$cap_index_file" --profile cap; then
      coverage_rc=1
    fi
  fi

  return "$coverage_rc"
}

ensure_markdownlint_cli2() {
  if command -v markdownlint-cli2 >/dev/null 2>&1; then
    return 0
  fi
  echo "[pre-push] markdownlint-cli2 not found; run 'cwf:setup --tools'." >&2
  exit 1
}

RUNTIME_SKIP_PREFIXES=()
init_runtime_skip_prefixes

mapfile -t md_candidates < <(git ls-files '*.md' '*.mdx' || true)
md_files=()
for file in "${md_candidates[@]}"; do
  if [[ "$file" == references/anthropic-skills-guide/* ]]; then
    continue
  fi
  if is_runtime_skip_path "$file"; then
    continue
  fi
  md_files+=("$file")
done

if [ "${#md_files[@]}" -gt 0 ]; then
  ensure_markdownlint_cli2
  echo "[pre-push] markdownlint on tracked markdown files..."
  markdownlint-cli2 "${md_files[@]}"
else
  echo "[pre-push] no markdown files found; skipping markdownlint"
fi

if [[ "$PROFILE" != "fast" ]]; then
  if [[ -n "$CWF_LINK_CHECKER" ]]; then
    echo "[pre-push] local link validation..."
    bash "$CWF_LINK_CHECKER" --local --json
  else
    echo "[pre-push] CWF link checker unavailable; skipping local link validation." >&2
  fi

  if [[ -n "$CWF_INDEX_COVERAGE" ]]; then
    INDEX_COVERAGE_MODE="$(resolve_index_coverage_mode "$(resolve_setup_contract_path)")"
    should_run_index_coverage="false"
    index_coverage_blocking="true"

    case "$INDEX_COVERAGE_MODE" in
      always|enforce|required)
        should_run_index_coverage="true"
        index_coverage_blocking="true"
        ;;
      warn|advisory)
        should_run_index_coverage="true"
        index_coverage_blocking="false"
        ;;
      authoring-only|auto|default|"")
        if is_cwf_authoring_repo; then
          should_run_index_coverage="true"
          index_coverage_blocking="true"
        fi
        ;;
      off|disabled|none|skip|false)
        should_run_index_coverage="false"
        ;;
      *)
        echo "[pre-push] unknown hook_index_coverage_mode '$INDEX_COVERAGE_MODE'; defaulting to authoring-only." >&2
        if is_cwf_authoring_repo; then
          should_run_index_coverage="true"
          index_coverage_blocking="true"
        fi
        ;;
    esac

    if [[ "$should_run_index_coverage" == "true" ]]; then
      echo "[pre-push] index coverage checks (mode: $INDEX_COVERAGE_MODE, blocking: $index_coverage_blocking)..."
      if ! run_index_coverage_checks; then
        if [[ "$index_coverage_blocking" == "true" ]]; then
          exit 1
        fi
        echo "[pre-push] index coverage checks failed (non-blocking mode)." >&2
      fi
    else
      echo "[pre-push] index coverage checks skipped by policy (mode: $INDEX_COVERAGE_MODE)."
    fi
  else
    echo "[pre-push] check-index-coverage.sh unavailable; skipping index coverage checks." >&2
  fi
fi

if [[ -n "$CWF_UNIFIED_GATE" ]]; then
  echo "[pre-push] unified portability gate (hook context)..."
  bash "$CWF_UNIFIED_GATE" --contract auto --context hook
fi

if [[ "$PROFILE" == "strict" ]]; then
  if ! is_cwf_authoring_repo; then
    echo "[pre-push] strict CWF authoring checks skipped (non-CWF repository)." >&2
  else
    if [[ -n "$CWF_SCRIPT_DEPS" ]]; then
      echo "[pre-push] runtime script dependency checks..."
      bash "$CWF_SCRIPT_DEPS" --strict
    else
      echo "[pre-push] check-script-deps.sh unavailable; skipping strict dependency checks." >&2
    fi

    if [[ -n "$CWF_README_STRUCTURE" ]]; then
      echo "[pre-push] README structure checks..."
      bash "$CWF_README_STRUCTURE" --strict
    else
      echo "[pre-push] check-readme-structure.sh unavailable; skipping README structure checks." >&2
    fi

    if [[ -n "$CWF_PROVENANCE" ]]; then
      echo "[pre-push] provenance freshness report (inform)..."
      bash "$CWF_PROVENANCE" --level inform || true
    else
      echo "[pre-push] $CWF_PROVENANCE missing; skipping provenance report" >&2
    fi

    if [[ -n "$CWF_GROWTH_DRIFT" ]]; then
      echo "[pre-push] growth-drift report (inform)..."
      bash "$CWF_GROWTH_DRIFT" --level inform || true
    else
      echo "[pre-push] $CWF_GROWTH_DRIFT missing; skipping growth-drift report" >&2
    fi
  fi
fi
SCRIPT

  perl -0pi -e "s/__PROFILE__/$profile/g; s/__CWF_PLUGIN_ROOT__/$CWF_PLUGIN_ROOT_ESCAPED/g; s/__CONFIG_SHA__/$CONFIG_SHA_ESCAPED/g" "$path"
  chmod +x "$path"
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
