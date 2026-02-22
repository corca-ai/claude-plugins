#!/usr/bin/env bash
set -euo pipefail

# retro-coverage-contract.sh
# Generates deterministic coverage artifacts for deep retro scope evidence.

usage() {
  cat <<'USAGE'
retro-coverage-contract.sh — generate retro coverage matrix artifacts

Usage:
  retro-coverage-contract.sh --session-dir <path> [options]

Options:
  --session-dir <path>    Retro session directory (required)
  --base-ref <git-ref>    Diff baseline ref (default: HEAD~1)
  --repo-root <path>      Repository root (default: git top-level)
  --projects-root <path>  Projects root for lessons/retro scan (default: <repo>/.cwf/projects)
  --exclude-prefix <path> Exclude changed files by prefix (repeatable, default: .cwf/sessions/)
  -h, --help              Show this help
USAGE
}

SESSION_DIR=""
BASE_REF="HEAD~1"
REPO_ROOT=""
PROJECTS_ROOT=""
declare -a EXCLUDE_PREFIXES=(".cwf/sessions/")

resolve_version_ref() {
  local version_ref="$1"
  local plugin_json_path="plugins/cwf/.claude-plugin/plugin.json"
  local commit=""
  local commit_version=""

  if [[ ! "$version_ref" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 1
  fi

  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    commit_version="$(
      git -C "$REPO_ROOT" show "$commit:$plugin_json_path" 2>/dev/null \
        | jq -r '.version // empty' 2>/dev/null || true
    )"
    if [[ "$commit_version" == "$version_ref" ]]; then
      printf '%s\n' "$commit"
      return 0
    fi
  done < <(git -C "$REPO_ROOT" log --format='%H' -- "$plugin_json_path")

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-dir)
      SESSION_DIR="${2:-}"
      shift 2
      ;;
    --base-ref)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT="${2:-}"
      shift 2
      ;;
    --projects-root)
      PROJECTS_ROOT="${2:-}"
      shift 2
      ;;
    --exclude-prefix)
      EXCLUDE_PREFIXES+=("${2:-}")
      shift 2
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

if [[ -z "$SESSION_DIR" ]]; then
  echo "Error: --session-dir is required" >&2
  exit 1
fi

if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

if [[ "$SESSION_DIR" != /* ]]; then
  SESSION_DIR="$REPO_ROOT/$SESSION_DIR"
fi
mkdir -p "$SESSION_DIR"

if [[ -z "$PROJECTS_ROOT" ]]; then
  PROJECTS_ROOT="$REPO_ROOT/.cwf/projects"
fi

COVERAGE_DIR="$SESSION_DIR/coverage"
mkdir -p "$COVERAGE_DIR"

DIFF_ALL="$COVERAGE_DIR/diff-all-excl-session-logs.txt"
DIFF_TOP="$COVERAGE_DIR/diff-top-level-breakdown.txt"
DIFF_NON_CWF="$COVERAGE_DIR/diff-non-cwf.txt"
DIFF_PLUGINS_CWF="$COVERAGE_DIR/diff-plugins-cwf.txt"
DIFF_NON_CWF_STAT="$COVERAGE_DIR/diff-non-cwf-stat.txt"
PROJECT_FILES="$COVERAGE_DIR/project-lessons-retro-files.txt"
PROJECT_PRIMARY="$COVERAGE_DIR/project-lessons-retro-primary.txt"
PROJECT_SANDBOX="$COVERAGE_DIR/project-lessons-retro-sandbox.txt"
HISTORICAL_SIGNALS="$COVERAGE_DIR/historical-signals-grep.txt"
HISTORICAL_FREQ="$COVERAGE_DIR/historical-signal-file-frequency.txt"
HISTORICAL_COUNTS="$COVERAGE_DIR/historical-project-coverage-counts.txt"
SUMMARY_FILE="$COVERAGE_DIR/coverage-contract-summary.txt"

if ! git -C "$REPO_ROOT" rev-parse --verify "$BASE_REF^{commit}" >/dev/null 2>&1; then
  resolved_ref="$(resolve_version_ref "$BASE_REF" || true)"
  if [[ -n "${resolved_ref:-}" ]] && git -C "$REPO_ROOT" rev-parse --verify "$resolved_ref^{commit}" >/dev/null 2>&1; then
    BASE_REF="$resolved_ref"
  else
    echo "Error: invalid --base-ref: $BASE_REF" >&2
    exit 1
  fi
fi

# 1) Full changed-file list with exclusions.
git -C "$REPO_ROOT" diff --name-only "$BASE_REF..HEAD" \
  | awk 'NF > 0' \
  > "$DIFF_ALL.tmp"

for prefix in "${EXCLUDE_PREFIXES[@]}"; do
  [[ -n "$prefix" ]] || continue
  awk -v p="$prefix" 'index($0, p) != 1' "$DIFF_ALL.tmp" > "$DIFF_ALL.next"
  mv "$DIFF_ALL.next" "$DIFF_ALL.tmp"
done

mv "$DIFF_ALL.tmp" "$DIFF_ALL"

# 2) Top-level breakdown.
awk -F'/' '
  NF == 0 { next }
  {
    if (index($0, "/") == 0) {
      key=$0
    } else {
      key=$1
    }
    counts[key]++
  }
  END {
    for (k in counts) {
      printf "%7d %s\n", counts[k], k
    }
  }
' "$DIFF_ALL" | sort -nr > "$DIFF_TOP"

# 3) Focused subsets.
awk 'index($0, ".cwf/") != 1' "$DIFF_ALL" > "$DIFF_NON_CWF"
awk 'index($0, "plugins/cwf/") == 1' "$DIFF_ALL" > "$DIFF_PLUGINS_CWF"

if [[ -s "$DIFF_NON_CWF" ]]; then
  non_cwf_files=()
  while IFS= read -r non_cwf_file; do
    non_cwf_files+=("$non_cwf_file")
  done < "$DIFF_NON_CWF"
  git -C "$REPO_ROOT" diff --stat "$BASE_REF..HEAD" -- "${non_cwf_files[@]}" > "$DIFF_NON_CWF_STAT" 2>/dev/null || true
else
  : > "$DIFF_NON_CWF_STAT"
fi

# 4) Historical lessons/retro corpus inventory.
if [[ -d "$PROJECTS_ROOT" ]]; then
  find "$PROJECTS_ROOT" -type f \( -name lessons.md -o -name retro.md \) | sort > "$PROJECT_FILES"
else
  : > "$PROJECT_FILES"
fi

awk 'index($0, "/sandbox/") == 0' "$PROJECT_FILES" > "$PROJECT_PRIMARY"
awk 'index($0, "/sandbox/") != 0' "$PROJECT_FILES" > "$PROJECT_SANDBOX"

# 5) Historical signal extraction.
if command -v rg >/dev/null 2>&1; then
  if [[ -s "$PROJECT_PRIMARY" ]]; then
    primary_files=()
    while IFS= read -r primary_file; do
      primary_files+=("$primary_file")
    done < "$PROJECT_PRIMARY"
    rg -i -n --no-heading \
      "stale|drift|timeout|no[_ -]?output|fail[- ]?open|unverified|unknown|marketplace|latest" \
      "${primary_files[@]}" \
      > "$HISTORICAL_SIGNALS" || true
  else
    : > "$HISTORICAL_SIGNALS"
  fi
else
  : > "$HISTORICAL_SIGNALS"
fi

if [[ -s "$HISTORICAL_SIGNALS" ]]; then
  awk -F: '{print $1}' "$HISTORICAL_SIGNALS" | sort | uniq -c | sort -nr > "$HISTORICAL_FREQ"
else
  : > "$HISTORICAL_FREQ"
fi

if [[ -s "$PROJECT_PRIMARY" ]]; then
  awk -v root="$PROJECTS_ROOT/" '
    {
      rel=$0
      sub("^" root, "", rel)
      split(rel, parts, "/")
      if (parts[1] != "") {
        counts[parts[1]]++
      }
    }
    END {
      for (p in counts) {
        printf "%7d %s\n", counts[p], p
      }
    }
  ' "$PROJECT_PRIMARY" | sort -nr > "$HISTORICAL_COUNTS"
else
  : > "$HISTORICAL_COUNTS"
fi

# 6) Summary contract.
{
  echo "retro_coverage_contract=PASS"
  echo "base_ref=$BASE_REF"
  echo "diff_total=$(wc -l < "$DIFF_ALL" | tr -d ' ')"
  echo "diff_non_cwf=$(wc -l < "$DIFF_NON_CWF" | tr -d ' ')"
  echo "diff_plugins_cwf=$(wc -l < "$DIFF_PLUGINS_CWF" | tr -d ' ')"
  echo "project_lessons_retro_total=$(wc -l < "$PROJECT_FILES" | tr -d ' ')"
  echo "project_lessons_retro_primary=$(wc -l < "$PROJECT_PRIMARY" | tr -d ' ')"
  echo "project_lessons_retro_sandbox=$(wc -l < "$PROJECT_SANDBOX" | tr -d ' ')"
  echo "historical_signal_matches=$(wc -l < "$HISTORICAL_SIGNALS" | tr -d ' ')"
} > "$SUMMARY_FILE"

echo "Retro coverage contract"
echo "  session_dir : ${SESSION_DIR#"$REPO_ROOT"/}"
echo "  coverage_dir: ${COVERAGE_DIR#"$REPO_ROOT"/}"
cat "$SUMMARY_FILE"
