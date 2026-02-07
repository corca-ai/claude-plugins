#!/usr/bin/env bash
# quick-scan.sh: Scan all plugins' SKILL.md files for structural issues.
# Checks word count, line count, unreferenced resource files, and Anthropic compliance.
#
# Usage: quick-scan.sh [repo-root]
# Output: JSON report with per-skill results and summary

set -euo pipefail

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../../../.." && pwd; })}"

# Collect results
results=()
total_skills=0
warn_count=0
error_count=0

scan_skill() {
  local plugin_name="$1"
  local skill_name="$2"
  local skill_md="$3"
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

  # Check description length from plugin.json
  local plugin_json="$REPO_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"
  if [[ -f "$plugin_json" ]]; then
    local desc_len
    desc_len=$(python3 -c "
import json, sys
with open('$plugin_json') as f:
    d = json.load(f)
print(len(d.get('description', '')))
" 2>/dev/null || echo "0")
    if [[ "$desc_len" -gt 1024 ]]; then
      anthropic_flags+=("description_too_long: ${desc_len} chars (max 1024)")
    fi
  fi

  # Check frontmatter description length in SKILL.md
  local skill_desc
  skill_desc=$(sed -n '/^---$/,/^---$/p' "$skill_md" | grep -A 100 'description:' | grep -v 'description:' | grep -v '^---$' | sed '/^[a-z]/q' | head -n -1 | tr -d '\n' | wc -c | tr -d ' ')
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

  # Build JSON for this skill
  local flags_json="["
  for i in "${!flags[@]}"; do
    if [[ $i -gt 0 ]]; then flags_json+=","; fi
    local escaped="${flags[$i]//\"/\\\"}"
    flags_json+="\"$escaped\""
  done
  flags_json+="]"

  local unreferenced_json="["
  for i in "${!unreferenced[@]}"; do
    if [[ $i -gt 0 ]]; then unreferenced_json+=","; fi
    unreferenced_json+="\"${unreferenced[$i]}\""
  done
  unreferenced_json+="]"

  results+=("{
    \"plugin\": \"$plugin_name\",
    \"skill\": \"$skill_name\",
    \"word_count\": $word_count,
    \"line_count\": $line_count,
    \"size_severity\": \"$size_severity\",
    \"resource_files\": $ref_count,
    \"unreferenced_files\": $unreferenced_json,
    \"large_references\": $(if [[ "${#large_refs[@]}" -gt 0 ]]; then printf '['; for i in "${!large_refs[@]}"; do [[ $i -gt 0 ]] && printf ','; printf '"%s"' "${large_refs[$i]}"; done; printf ']'; else printf '[]'; fi),
    \"flag_count\": ${#flags[@]},
    \"flags\": $flags_json
  }")

  total_skills=$((total_skills + 1))
}

# Scan marketplace plugins (skip deprecated)
for skill_md in "$REPO_ROOT"/plugins/*/skills/*/SKILL.md; do
  [[ -f "$skill_md" ]] || continue

  # Extract plugin name and skill name from path
  local_path="${skill_md#"$REPO_ROOT"/plugins/}"
  plugin_name="${local_path%%/*}"

  # Skip deprecated plugins
  pjson="$REPO_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"
  if [[ -f "$pjson" ]]; then
    if python3 -c "import json; d=json.load(open('$pjson')); exit(0 if d.get('deprecated') else 1)" 2>/dev/null; then
      continue
    fi
  fi

  skill_name="$(basename "$(dirname "$skill_md")")"
  scan_skill "$plugin_name" "$skill_name" "$skill_md"
done

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

cat <<EOF
{
  "total_skills": $total_skills,
  "warnings": $warn_count,
  "errors": $error_count,
  "flagged_skills": $flagged_count,
  "results": $results_json
}
EOF
