# Tidy Analysis: Commit 557b51d

> `refactor(cwf): internalize runtime scripts and remove root wrappers`

## Commit Summary

This commit migrated all runtime scripts from the repository root `scripts/` directory
into `plugins/cwf/scripts/`, deleted the root wrappers, and updated every call site
(git hooks, codex scripts, drift checker, test fixtures) to reference the new plugin-local
paths. The `check_mirror_script_drift` function was replaced with a simpler
`check_plugin_runtime_scripts` existence check, and the test fixture file was cleaned of
all root-script test cases.

## Files Analyzed

| File | Status at HEAD | Analyzed |
|---|---|---|
| `.githooks/pre-commit` | unchanged since 557b51d | yes |
| `.githooks/pre-push` | unchanged since 557b51d | yes |
| `plugins/cwf/hooks/scripts/check-links-local.sh` | unchanged since 557b51d | yes |
| `plugins/cwf/scripts/check-growth-drift.sh` | modified after 557b51d (new function added in 226cdd1) | yes, only regions unchanged since 557b51d |
| `plugins/cwf/scripts/codex/post-run-checks.sh` | unchanged since 557b51d | yes |
| `plugins/cwf/scripts/codex/sync-session-logs.sh` | unchanged since 557b51d | yes |
| `plugins/cwf/scripts/codex/sync-skills.sh` | unchanged since 557b51d | yes |
| `plugins/cwf/scripts/next-prompt-dir.sh` | unchanged since 557b51d | yes |
| `plugins/cwf/scripts/provenance-check.sh` | unchanged since 557b51d (new file in this commit) | yes |
| `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh` | unchanged since 557b51d | yes |
| `scripts/tests/next-prompt-dir-fixtures.sh` | unchanged since 557b51d | yes |

Deleted files (36 scripts under `scripts/`) are out of scope for tidying.

---

## Tidying Opportunities

### 1. Guard clause: flatten nested `if` in pre-commit markdown handling

`plugins/cwf/skills/setup/scripts/configure-git-hooks.sh:112-127` (the pre-commit template) and `.githooks/pre-commit:9-28` -- Extract the early-exit pattern to avoid one level of nesting.

**Before** (`.githooks/pre-commit:9-28`):

```bash
  mapfile -t md_files < <(
  git diff --cached --name-only --diff-filter=ACMR -- '*.md' '*.mdx' \
    | grep -Ev '^(\.cwf/projects/|\.cwf/sessions/|\.cwf/prompt-logs/|references/anthropic-skills-guide/)' || true
)

if [ "${#md_files[@]}" -gt 0 ]; then
  echo "[pre-commit] markdownlint on staged markdown files..."
  npx --yes markdownlint-cli2 "${md_files[@]}"

  if [[ "$PROFILE" != "fast" ]]; then
    echo "[pre-commit] local link validation on staged markdown files..."
    for file in "${md_files[@]}"; do
      ...
    done
  fi
fi
```

Note the spurious leading whitespace on the `mapfile` line (2-space indent at line 9) which creates a visual inconsistency with the rest of the script. This was introduced in the commit diff and persists at HEAD.

**After** (fix indentation only -- the safe, mechanical part):

```bash
mapfile -t md_files < <(
  git diff --cached --name-only --diff-filter=ACMR -- '*.md' '*.mdx' \
    | grep -Ev '^(\.cwf/projects/|\.cwf/sessions/|\.cwf/prompt-logs/|references/anthropic-skills-guide/)' || true
)
```

(reason: the 2-space indent on `mapfile` at line 9 is inconsistent with the rest of the file where all top-level statements start at column 0; fixing it is a whitespace-only change with no behavioral effect)

The same indentation issue appears in the template at `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh:107-110`.

---

### 2. Explaining variable: repeated long path string in `check-links-local.sh`

`plugins/cwf/hooks/scripts/check-links-local.sh:52-55` -- The path `plugins/cwf/skills/refactor/scripts/check-links.sh` appears both in the variable assignment (line 52) and again hard-coded in the error message (line 55). The error message should reference the variable instead of repeating the literal path.

**Before** (`plugins/cwf/hooks/scripts/check-links-local.sh:52-59`):

```bash
CHECK_LINKS="${REPO_ROOT}/plugins/cwf/skills/refactor/scripts/check-links.sh"

if [ ! -x "$CHECK_LINKS" ]; then
    REASON=$(printf 'Link checker unavailable for %s: plugins/cwf/skills/refactor/scripts/check-links.sh is missing or not executable.' "$FILE_PATH" | jq -Rs .)
    cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
    exit 0
fi
```

**After:**

```bash
CHECK_LINKS="${REPO_ROOT}/plugins/cwf/skills/refactor/scripts/check-links.sh"

if [ ! -x "$CHECK_LINKS" ]; then
    REASON=$(printf 'Link checker unavailable for %s: %s is missing or not executable.' "$FILE_PATH" "$CHECK_LINKS" | jq -Rs .)
    cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
    exit 0
fi
```

(reason: eliminates a duplicated magic string; if the path ever changes again, only the variable needs updating; purely a printf format change with identical runtime output)

---

### 3. Normalize symmetries: repeated `reasons` accumulation pattern in `provenance-check.sh`

`plugins/cwf/scripts/provenance-check.sh:139-171` -- The `reasons` string is built using the same 3-line idiom six times:

```bash
if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
reasons="${reasons}some message"
```

Extracting this into a small helper function normalizes the pattern and reduces the repetition from ~18 lines to ~8 + a 4-line helper.

**Before** (`plugins/cwf/scripts/provenance-check.sh:139-153`, first two blocks shown):

```bash
  if [[ -z "$recorded_skills" ]]; then
    is_stale=true
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}skill_count: missing"
  elif ! [[ "$recorded_skills" =~ ^[0-9]+$ ]]; then
    is_stale=true
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}skill_count: invalid (${recorded_skills})"
  elif [[ "$recorded_skills" != "$CURRENT_SKILLS" ]]; then
    is_stale=true
    skill_delta=$((CURRENT_SKILLS - recorded_skills))
    local_sign=""
    if [[ $skill_delta -gt 0 ]]; then local_sign="+"; fi
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}skills: ${recorded_skills} ... (${local_sign}${skill_delta})"
  fi
```

**After** (introduce helper above the loop):

```bash
append_reason() {
  if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
  reasons="${reasons}$1"
  is_stale=true
}
```

Then each call site simplifies to:

```bash
  if [[ -z "$recorded_skills" ]]; then
    append_reason "skill_count: missing"
  elif ! [[ "$recorded_skills" =~ ^[0-9]+$ ]]; then
    append_reason "skill_count: invalid (${recorded_skills})"
  elif [[ "$recorded_skills" != "$CURRENT_SKILLS" ]]; then
    skill_delta=$((CURRENT_SKILLS - recorded_skills))
    local_sign=""
    if [[ $skill_delta -gt 0 ]]; then local_sign="+"; fi
    append_reason "skills: ${recorded_skills} ... (${local_sign}${skill_delta})"
  fi
```

(reason: extracts a repeated 3-line idiom into a named helper; the `is_stale=true` assignment moves into the helper, removing 6 duplicated `is_stale=true` lines; purely mechanical with identical runtime behavior since `reasons` and `is_stale` are global-scope variables in the loop)

---

## Non-Candidates (Considered but Rejected)

| Pattern | File | Why skipped |
|---|---|---|
| `check_plugin_runtime_scripts` heredoc list could be externalized | `check-growth-drift.sh:270-286` | Region was modified in later commit 226cdd1; out of scope |
| `YELLOW` color variable declared but never used in `provenance-check.sh` | `provenance-check.sh:61` | `YELLOW` is used at line 88 in the no-provenance-files branch; not dead code |
| Large awk blocks in `post-run-checks.sh` could be extracted | `post-run-checks.sh:62-103` | Would be a refactor rather than a tidy; too large for a single atomic commit |
| `sync-skills.sh` layout detection could use a guard clause | `sync-skills.sh:144-152` | The if/else is already clean and symmetrical; no readability gain |

---

## Summary

| # | Technique | File | Safety |
|---|---|---|---|
| 1 | Normalize Symmetries (indentation) | `.githooks/pre-commit:9`, `configure-git-hooks.sh:107` | Whitespace-only, no behavior change |
| 2 | Explaining Variable (DRY path string) | `check-links-local.sh:55` | printf format change, identical output |
| 3 | Extract Helper (append_reason) | `provenance-check.sh:139-171` | Mechanical extraction, global-scope vars |

Each suggestion is independent and can be committed separately.

<!-- AGENT_COMPLETE -->
