#!/usr/bin/env bash
# quick-scan.sh: Scan all plugins' SKILL.md files for structural issues.
# Checks word count, line count, unreferenced resource files, and Anthropic compliance.
#
# Usage: quick-scan.sh [repo-root] [--include-local-skills] [--local-skill-glob "<glob>"]
# Output: JSON report with per-skill results and summary

set -euo pipefail

print_usage() {
  cat <<'EOF'
quick-scan.sh: Scan skill structure and resource hygiene.

Usage:
  quick-scan.sh [repo-root]
  quick-scan.sh [repo-root] --include-local-skills
  quick-scan.sh [repo-root] --local-skill-glob ".claude/skills/*/SKILL.md"

Options:
  --include-local-skills     Also scan local skills (defaults include .claude/skills/*/SKILL.md and .codex/skills/*/SKILL.md)
  --local-skill-glob <glob>  Add one extra local-skill glob under repo root (repeatable)
  -h, --help                 Show this help and exit
EOF
}

REPO_ROOT_DEFAULT="$(git rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../../../.." && pwd; })"
REPO_ROOT="$REPO_ROOT_DEFAULT"
REPO_ROOT_ARG_SET="false"
INCLUDE_LOCAL_SKILLS="false"
LOCAL_SKILL_GLOBS=(
  ".claude/skills/*/SKILL.md"
  ".codex/skills/*/SKILL.md"
)
EXTRA_LOCAL_SKILL_GLOBS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --include-local-skills)
      INCLUDE_LOCAL_SKILLS="true"
      ;;
    --local-skill-glob)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Error: --local-skill-glob requires a value" >&2
        exit 1
      fi
      INCLUDE_LOCAL_SKILLS="true"
      EXTRA_LOCAL_SKILL_GLOBS+=("$1")
      ;;
    --)
      shift
      if [[ $# -gt 0 ]]; then
        echo "Error: unexpected trailing arguments: $*" >&2
        exit 1
      fi
      break
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      print_usage
      exit 1
      ;;
    *)
      if [[ "$REPO_ROOT_ARG_SET" == "true" ]]; then
        echo "Error: unexpected extra positional argument: $1" >&2
        exit 1
      fi
      REPO_ROOT="$1"
      REPO_ROOT_ARG_SET="true"
      ;;
  esac
  shift
done

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Error: repo-root not found: $REPO_ROOT" >&2
  exit 1
fi
REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

if [[ ${#EXTRA_LOCAL_SKILL_GLOBS[@]} -gt 0 ]]; then
  LOCAL_SKILL_GLOBS+=("${EXTRA_LOCAL_SKILL_GLOBS[@]}")
fi

shopt -s nullglob

# Collect results
results=()
total_skills=0
warn_count=0
error_count=0
declare -a seen_skill_files=()

get_frontmatter_description_length() {
  local skill_md="$1"

  python3 - "$skill_md" <<'PY'
import re
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        text = f.read()
except Exception:
    print(0)
    raise SystemExit

if not text.startswith("---\n"):
    print(0)
    raise SystemExit

frontmatter = re.match(r"---\n(.*?)\n---\n", text, re.S)
if not frontmatter:
    print(0)
    raise SystemExit

description = None
for line in frontmatter.group(1).splitlines():
    if line.lstrip().startswith("description:"):
        description = line.split(":", 1)[1].strip()
        break

if description is None:
    print(0)
else:
    print(len(description))
PY
}

scan_skill() {
  local plugin_name="$1"
  local skill_name="$2"
  local skill_md="$3"
  local scan_origin="${4:-marketplace}"
  local plugin_json="${5:-}"
  local skill_dir
  skill_dir="$(dirname "$skill_md")"

  local word_count line_count
  word_count=$(wc -w < "$skill_md" | tr -d ' ')
  line_count=$(wc -l < "$skill_md" | tr -d ' ')

  # Determine severity
  local size_severity="ok"
  if [[ "$word_count" -gt 5000 ]]; then
    size_severity="error"
  elif [[ "$word_count" -gt 3000 ]]; then
    size_severity="warning"
  fi

  local line_severity="ok"
  if [[ "$line_count" -gt 500 ]]; then
    line_severity="warning"
  fi

  # Check for unreferenced resource files
  local unreferenced=()
  local ref_count=0
  local unref_count=0

  for dir in scripts references assets; do
    if [[ -d "$skill_dir/$dir" ]]; then
      while IFS= read -r -d '' file; do
        local basename
        basename="$(basename "$file")"
        ref_count=$((ref_count + 1))
        if ! grep -q "$basename" "$skill_md" 2>/dev/null; then
          unreferenced+=("$dir/$basename")
          unref_count=$((unref_count + 1))
        fi
      done < <(find "$skill_dir/$dir" -maxdepth 1 -type f -print0 2>/dev/null)
    fi
  done

  # Check for large reference files without grep patterns
  local large_refs=()
  if [[ -d "$skill_dir/references" ]]; then
    while IFS= read -r -d '' ref_file; do
      local ref_words
      ref_words=$(wc -w < "$ref_file" | tr -d ' ')
      if [[ "$ref_words" -gt 10000 ]]; then
        large_refs+=("$(basename "$ref_file"):${ref_words}w")
      fi
    done < <(find "$skill_dir/references" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)
  fi

  # Anthropic compliance checks
  local anthropic_flags=()

  # Check folder naming (kebab-case)
  if [[ "$plugin_name" =~ [A-Z_] ]]; then
    anthropic_flags+=("folder_not_kebab_case: $plugin_name")
  fi
  if [[ "$skill_name" =~ [A-Z_] ]]; then
    anthropic_flags+=("skill_folder_not_kebab_case: $skill_name")
  fi

  # Check description length from plugin.json (marketplace plugins)
  if [[ -n "$plugin_json" && -f "$plugin_json" ]]; then
    local desc_len
    desc_len=$(python3 - "$plugin_json" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    print(len(data.get("description", "")))
except Exception:
    print(0)
PY
)
    if [[ "$desc_len" -gt 1024 ]]; then
      anthropic_flags+=("description_too_long: ${desc_len} chars (max 1024)")
    fi
  fi

  # Check frontmatter description length in SKILL.md
  local skill_desc
  skill_desc="$(get_frontmatter_description_length "$skill_md")"
  if ! [[ "$skill_desc" =~ ^[0-9]+$ ]]; then
    skill_desc=0
  fi
  if [[ "$skill_desc" -gt 1024 ]]; then
    anthropic_flags+=("skill_description_too_long: ${skill_desc} chars")
  fi

  # Build flags array
  local flags=()
  if [[ "$size_severity" == "warning" ]]; then
    flags+=("word_count_warning (${word_count}w > 3000)")
    warn_count=$((warn_count + 1))
  elif [[ "$size_severity" == "error" ]]; then
    flags+=("word_count_error (${word_count}w > 5000)")
    error_count=$((error_count + 1))
  fi

  if [[ "$line_severity" == "warning" ]]; then
    flags+=("line_count_warning (${line_count}L > 500)")
    warn_count=$((warn_count + 1))
  fi

  if [[ "$unref_count" -gt 0 ]]; then
    for u in "${unreferenced[@]}"; do
      flags+=("unreferenced: $u")
    done
    warn_count=$((warn_count + 1))
  fi

  if [[ "${#large_refs[@]}" -gt 0 ]]; then
    for lr in "${large_refs[@]}"; do
      flags+=("large_ref_no_grep: $lr")
    done
    warn_count=$((warn_count + 1))
  fi

  # Add Anthropic flags
  if [[ ${#anthropic_flags[@]} -gt 0 ]]; then
    for af in "${anthropic_flags[@]}"; do
      flags+=("anthropic: $af")
      warn_count=$((warn_count + 1))
    done
  fi

  # Build JSON arrays with jq for safe escaping
  local flags_json="[]"
  if [[ ${#flags[@]} -gt 0 ]]; then
    flags_json=$(printf '%s\n' "${flags[@]}" | jq -Rs '[split("\n")[:-1][]]')
  fi

  local unreferenced_json="[]"
  if [[ ${#unreferenced[@]} -gt 0 ]]; then
    unreferenced_json=$(printf '%s\n' "${unreferenced[@]}" | jq -Rs '[split("\n")[:-1][]]')
  fi

  local large_refs_json="[]"
  if [[ ${#large_refs[@]} -gt 0 ]]; then
    large_refs_json=$(printf '%s\n' "${large_refs[@]}" | jq -Rs '[split("\n")[:-1][]]')
  fi

  results+=("{
    \"origin\": $(printf '%s' "$scan_origin" | jq -Rs .),
    \"plugin\": $(printf '%s' "$plugin_name" | jq -Rs .),
    \"skill\": $(printf '%s' "$skill_name" | jq -Rs .),
    \"word_count\": $word_count,
    \"line_count\": $line_count,
    \"size_severity\": \"$size_severity\",
    \"resource_files\": $ref_count,
    \"unreferenced_files\": $unreferenced_json,
    \"large_references\": $large_refs_json,
    \"flag_count\": ${#flags[@]},
    \"flags\": $flags_json
  }")

  total_skills=$((total_skills + 1))
}

scan_skill_file_once() {
  local plugin_name="$1"
  local skill_name="$2"
  local skill_md="$3"
  local scan_origin="$4"
  local plugin_json="${5:-}"
  local seen_skill=""

  [[ -f "$skill_md" ]] || return 0
  for seen_skill in "${seen_skill_files[@]}"; do
    if [[ "$seen_skill" == "$skill_md" ]]; then
      return 0
    fi
  done
  seen_skill_files+=("$skill_md")
  scan_skill "$plugin_name" "$skill_name" "$skill_md" "$scan_origin" "$plugin_json"
}

scan_marketplace_plugins() {
  local skill_md local_path plugin_name pjson skill_name
  for skill_md in "$REPO_ROOT"/plugins/*/skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue

    local_path="${skill_md#"$REPO_ROOT"/plugins/}"
    plugin_name="${local_path%%/*}"
    pjson="$REPO_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"

    # Skip deprecated marketplace plugins
    if [[ -f "$pjson" ]]; then
      if python3 - "$pjson" <<'PY'
import json
import sys
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    raise SystemExit(0 if data.get("deprecated") else 1)
except Exception:
    raise SystemExit(1)
PY
      then
        continue
      fi
    fi

    skill_name="$(basename "$(dirname "$skill_md")")"
    scan_skill_file_once "$plugin_name" "$skill_name" "$skill_md" "marketplace" "$pjson"
  done
}

scan_local_skills() {
  local skill_glob skill_md local_path plugin_name skill_name
  for skill_glob in "${LOCAL_SKILL_GLOBS[@]}"; do
    for skill_md in "$REPO_ROOT"/$skill_glob; do
      [[ -f "$skill_md" ]] || continue
      local_path="${skill_md#"$REPO_ROOT"/}"
      plugin_name="${local_path%%/*}"
      skill_name="$(basename "$(dirname "$skill_md")")"
      scan_skill_file_once "$plugin_name" "$skill_name" "$skill_md" "local"
    done
  done
}

scan_marketplace_plugins
if [[ "$INCLUDE_LOCAL_SKILLS" == "true" ]]; then
  scan_local_skills
fi

# Build final JSON
flagged_count=0
results_json="["
for i in "${!results[@]}"; do
  if [[ $i -gt 0 ]]; then results_json+=","; fi
  results_json+="${results[$i]}"
  if echo "${results[$i]}" | grep -qP '"flag_count": [1-9]'; then
    flagged_count=$((flagged_count + 1))
  fi
done
results_json+="]"

local_skill_globs_json="[]"
if [[ ${#LOCAL_SKILL_GLOBS[@]} -gt 0 ]]; then
  local_skill_globs_json=$(printf '%s\n' "${LOCAL_SKILL_GLOBS[@]}" | jq -Rs '[split("\n")[:-1][]]')
fi

cat <<EOF
{
  "options": {
    "include_local_skills": $([[ "$INCLUDE_LOCAL_SKILLS" == "true" ]] && echo "true" || echo "false"),
    "local_skill_globs": $local_skill_globs_json
  },
  "total_skills": $total_skills,
  "warnings": $warn_count,
  "errors": $error_count,
  "flagged_skills": $flagged_count,
  "results": $results_json
}
EOF
