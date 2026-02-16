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
  strict    balanced + provenance freshness + growth-drift reports on push (inform level)
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

mapfile -t md_files < <(
  git diff --cached --name-only --diff-filter=ACMR -- '*.md' '*.mdx' \
    | grep -Ev '^(\.cwf/projects/|\.cwf/prompt-logs/|references/anthropic-skills-guide/)' || true
)

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
      bash scripts/check-links.sh --local --json --file "$file" >/dev/null
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

mapfile -t md_files < <(
  git ls-files '*.md' '*.mdx' \
    | grep -Ev '^(\.cwf/projects/|\.cwf/prompt-logs/|references/anthropic-skills-guide/)' || true
)

if [ "${#md_files[@]}" -gt 0 ]; then
  echo "[pre-push] markdownlint on tracked markdown files..."
  npx --yes markdownlint-cli2 "${md_files[@]}"
else
  echo "[pre-push] no markdown files found; skipping markdownlint"
fi

if [[ "$PROFILE" != "fast" ]]; then
  echo "[pre-push] local link validation..."
  bash scripts/check-links.sh --local --json

  if [[ -x scripts/check-index-coverage.sh ]]; then
    echo "[pre-push] index coverage checks..."
    if [[ -f AGENTS.md ]]; then
      bash scripts/check-index-coverage.sh AGENTS.md --profile repo
    fi
    if [[ -f .cwf/indexes/cwf-index.md ]]; then
      bash scripts/check-index-coverage.sh .cwf/indexes/cwf-index.md --profile cap
    fi
  else
    echo "[pre-push] scripts/check-index-coverage.sh missing or not executable" >&2
    exit 1
  fi
fi

if [[ "$PROFILE" == "strict" ]]; then
  if [[ -x scripts/provenance-check.sh ]]; then
    echo "[pre-push] provenance freshness report (inform)..."
    bash scripts/provenance-check.sh --level inform
  else
    echo "[pre-push] scripts/provenance-check.sh missing; skipping provenance report" >&2
  fi

  if [[ -x scripts/check-growth-drift.sh ]]; then
    echo "[pre-push] growth-drift report (inform)..."
    bash scripts/check-growth-drift.sh --level inform
  else
    echo "[pre-push] scripts/check-growth-drift.sh missing; skipping growth-drift report" >&2
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
