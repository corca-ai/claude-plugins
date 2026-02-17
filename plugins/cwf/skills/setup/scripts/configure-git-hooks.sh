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
set -euo pipefail

PROFILE="__PROFILE__"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
CWF_LINK_CHECKER="plugins/cwf/skills/refactor/scripts/check-links.sh"
CWF_ARTIFACT_PATHS="plugins/cwf/scripts/cwf-artifact-paths.sh"

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

RUNTIME_SKIP_PREFIXES=()
init_runtime_skip_prefixes

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
  echo "[pre-commit] markdownlint on staged markdown files..."
  npx --yes markdownlint-cli2 "${md_files[@]}"

  if [[ "$PROFILE" != "fast" ]]; then
    echo "[pre-commit] local link validation on staged markdown files..."
    for file in "${md_files[@]}"; do
      case "$file" in
        CHANGELOG.md|references/*)
          continue
          ;;
      esac
      bash "$CWF_LINK_CHECKER" --local --json --file "$file" >/dev/null
    done
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
SCRIPT

  perl -0pi -e "s/__PROFILE__/$profile/g" "$path"
  chmod +x "$path"
}

write_pre_push() {
  local path="$1"
  local profile="$2"

  cat > "$path" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

PROFILE="__PROFILE__"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
CWF_LINK_CHECKER="plugins/cwf/skills/refactor/scripts/check-links.sh"
CWF_ARTIFACT_PATHS="plugins/cwf/scripts/cwf-artifact-paths.sh"
CWF_INDEX_COVERAGE="plugins/cwf/skills/setup/scripts/check-index-coverage.sh"
CWF_PROVENANCE="plugins/cwf/scripts/provenance-check.sh"
CWF_GROWTH_DRIFT="plugins/cwf/scripts/check-growth-drift.sh"
CWF_SCRIPT_DEPS="plugins/cwf/scripts/check-script-deps.sh"
CWF_README_STRUCTURE="plugins/cwf/scripts/check-readme-structure.sh"

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
  echo "[pre-push] markdownlint on tracked markdown files..."
  npx --yes markdownlint-cli2 "${md_files[@]}"
else
  echo "[pre-push] no markdown files found; skipping markdownlint"
fi

if [[ "$PROFILE" != "fast" ]]; then
  echo "[pre-push] local link validation..."
  bash "$CWF_LINK_CHECKER" --local --json

  if [[ -x "$CWF_INDEX_COVERAGE" ]]; then
    echo "[pre-push] index coverage checks..."
    CAP_INDEX_FILE=".cwf/indexes/cwf-index.md"
    if [[ -f "$CWF_ARTIFACT_PATHS" ]]; then
      # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
      source "$CWF_ARTIFACT_PATHS"
      CAP_INDEX_DIR="$(resolve_cwf_indexes_dir "$REPO_ROOT" 2>/dev/null || true)"
      if [[ -n "$CAP_INDEX_DIR" ]]; then
        CAP_INDEX_FILE="${CAP_INDEX_DIR}/cwf-index.md"
      fi
    fi
    if [[ -f AGENTS.md ]]; then
      bash "$CWF_INDEX_COVERAGE" AGENTS.md --profile repo
    fi
    if [[ -f "$CAP_INDEX_FILE" ]]; then
      bash "$CWF_INDEX_COVERAGE" "$CAP_INDEX_FILE" --profile cap
    fi
  else
    echo "[pre-push] $CWF_INDEX_COVERAGE missing or not executable" >&2
    exit 1
  fi
fi

if [[ "$PROFILE" == "strict" ]]; then
  if [[ -x "$CWF_SCRIPT_DEPS" ]]; then
    echo "[pre-push] runtime script dependency checks..."
    bash "$CWF_SCRIPT_DEPS" --strict
  else
    echo "[pre-push] $CWF_SCRIPT_DEPS missing or not executable" >&2
    exit 1
  fi

  if [[ -x "$CWF_README_STRUCTURE" ]]; then
    echo "[pre-push] README structure checks..."
    bash "$CWF_README_STRUCTURE" --strict
  else
    echo "[pre-push] $CWF_README_STRUCTURE missing or not executable" >&2
    exit 1
  fi

  if [[ -x "$CWF_PROVENANCE" ]]; then
    echo "[pre-push] provenance freshness report (inform)..."
    bash "$CWF_PROVENANCE" --level inform
  else
    echo "[pre-push] $CWF_PROVENANCE missing; skipping provenance report" >&2
  fi

  if [[ -x "$CWF_GROWTH_DRIFT" ]]; then
    echo "[pre-push] growth-drift report (inform)..."
    bash "$CWF_GROWTH_DRIFT" --level inform
  else
    echo "[pre-push] $CWF_GROWTH_DRIFT missing; skipping growth-drift report" >&2
  fi
fi
SCRIPT

  perl -0pi -e "s/__PROFILE__/$profile/g" "$path"
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
