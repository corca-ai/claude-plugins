# Tidying Analysis: Commit 3580a49

> **Commit**: `3580a49` — `fix(cwf): harden quick-scan and persist review/refactor outputs`
> **Scope**: 1 script file (`quick-scan.sh`), 3 docs files, 1 `README.md`, 6 review artifact files
> **Analysis date**: 2026-02-16
> **Methodology**: Kent Beck's "Tidy First?" — safe, mechanical, behavior-preserving improvements

---

## Changed Files Summary

| File | Type | Still at HEAD |
|------|------|---------------|
| `plugins/cwf/skills/refactor/scripts/quick-scan.sh` | Script (logic change) | Yes |
| `README.md` | Documentation | Yes |
| `docs/architecture-patterns.md` | Documentation | Yes |
| `docs/project-context.md` | Documentation | Yes |
| `docs/v3-migration-decisions.md` | Documentation (2 locations) | Yes |
| `.cwf/projects/260216-03-*/review-*-code.md` (6 files) | Persisted review artifacts | Yes |

The 6 review artifact files (`.cwf/projects/260216-03-hitl-readme-restart/review-*-code.md`) are generated output persisted to disk. These are not candidates for tidying because they are machine-generated, immutable session records.

The 4 documentation changes (`README.md`, `docs/architecture-patterns.md`, `docs/project-context.md`, `docs/v3-migration-decisions.md`) are all path reference updates: converting bare `check-session.sh` mentions to full relative Markdown links after root wrapper scripts were moved to `plugins/cwf/scripts/`. These are already clean and tidy.

The primary tidying candidate is `plugins/cwf/skills/refactor/scripts/quick-scan.sh`.

---

## Tidying Opportunities

### 1. Normalize Symmetries: Inline Python for `plugin.json` description vs. `SKILL.md` frontmatter description

`plugins/cwf/skills/refactor/scripts/quick-scan.sh:121-134` — Extract the inline `python3 -c` for `plugin.json` description-length into a named function, symmetric with the existing `get_frontmatter_description_length` function.

**(reason: the commit introduced `get_frontmatter_description_length` as a clean named function for SKILL.md frontmatter parsing, but the structurally identical `plugin.json` description-length check at lines 125-130 remains an anonymous inline `python3 -c` snippet; extracting it into a parallel `get_plugin_description_length` function normalizes the two description-check paths and makes both testable independently)**

**Before** (lines 121-134):
```bash
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
```

**After**:
```bash
  # Check description length from plugin.json
  local plugin_json="$REPO_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"
  if [[ -f "$plugin_json" ]]; then
    local desc_len
    desc_len="$(get_plugin_description_length "$plugin_json")"
    if ! [[ "$desc_len" =~ ^[0-9]+$ ]]; then
      desc_len=0
    fi
    if [[ "$desc_len" -gt 1024 ]]; then
      anthropic_flags+=("description_too_long: ${desc_len} chars (max 1024)")
    fi
  fi
```

With a new top-level function (placed near `get_frontmatter_description_length`):

```bash
get_plugin_description_length() {
  local plugin_json="$1"
  python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
print(len(d.get('description', '')))
" "$plugin_json" 2>/dev/null || echo "0"
}
```

Note: this also fixes a secondary issue where the current inline Python uses shell-interpolated `$plugin_json` inside the Python string (line 127: `with open('$plugin_json')`), which is fragile if the path contains single quotes. The extracted version would pass it as `sys.argv[1]` instead, matching the safer pattern already used by `get_frontmatter_description_length`.

---

### 2. Guard Clause: Early return for `raise SystemExit` pattern in embedded Python

`plugins/cwf/skills/refactor/scripts/quick-scan.sh:26-40` — Replace the three sequential `print(0); raise SystemExit` blocks with `sys.exit(0)` for clarity and remove the bare `raise SystemExit` anti-pattern.

**(reason: `raise SystemExit` without an argument is functionally equivalent to `sys.exit(0)` but is less idiomatic; `sys.exit()` is the standard Python way to exit, and `sys` is already imported; this is a pure readability improvement with no behavior change)**

**Before** (lines 26-40 within the heredoc):
```python
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
```

**After**:
```python
try:
    with open(path, encoding="utf-8") as f:
        text = f.read()
except Exception:
    print(0)
    sys.exit(0)

if not text.startswith("---\n"):
    print(0)
    sys.exit(0)

frontmatter = re.match(r"---\n(.*?)\n---\n", text, re.S)
if not frontmatter:
    print(0)
    sys.exit(0)
```

---

### 3. Dead Code / Explaining Variable: Simplify `if/else` for `description` result

`plugins/cwf/skills/refactor/scripts/quick-scan.sh:42-51` — Replace the `description = None` / for-loop / `if description is None` pattern with a direct variable assignment and early return.

**(reason: the variable `description` is initialized to `None`, then conditionally set in a loop, then checked for `None` with an if/else to decide whether to print `0` or `len(description)`; a guard clause after the loop eliminates the trailing if/else branch, reducing cognitive load)**

**Before** (lines 42-51 within the heredoc):
```python
description = None
for line in frontmatter.group(1).splitlines():
    if line.lstrip().startswith("description:"):
        description = line.split(":", 1)[1].strip()
        break

if description is None:
    print(0)
else:
    print(len(description))
```

**After**:
```python
description = None
for line in frontmatter.group(1).splitlines():
    if line.lstrip().startswith("description:"):
        description = line.split(":", 1)[1].strip()
        break

if description is None:
    print(0)
    sys.exit(0)

print(len(description))
```

---

## Skipped Regions (No Tidying Needed)

- **Lines 136-144** (`skill_desc` validation with regex guard): Already clean — the `if ! [[ ... =~ ^[0-9]+$ ]]` guard was added by this commit and follows good defensive coding practice.
- **Lines 215-233** (main scan loop): Straightforward iteration with standard skip logic; no improvement opportunities.
- **Lines 236-255** (JSON assembly): The `grep -qP` on line 241 could be replaced with `jq`, but that would change tool dependencies and is not a safe mechanical tidy.
- **Documentation files**: All 4 doc edits are single-line link updates that are already clean and consistent with each other.
- **Review artifact files** (6 files): Generated output; not candidates for source tidying.

---

## Summary

| # | Technique | File | Lines | Risk |
|---|-----------|------|-------|------|
| 1 | Normalize Symmetries | `quick-scan.sh` | 121-134 | None — extract to named function |
| 2 | Guard Clause (Python idiom) | `quick-scan.sh` | 26-40 (heredoc) | None — `sys.exit(0)` = `raise SystemExit` |
| 3 | Guard Clause + Dead Code | `quick-scan.sh` | 42-51 (heredoc) | None — early exit removes else branch |

All three suggestions are independent, atomic, and can each be a single commit. Suggestion 1 also fixes a latent shell-injection risk (single quotes in paths) as a bonus.

<!-- AGENT_COMPLETE -->
