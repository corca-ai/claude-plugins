# Structural Review: gather Skill (Criteria 1-4)

**Skill**: `plugins/cwf/skills/gather`
**Date**: 2026-02-16
**Reviewer**: Agent (structural pass)

---

## 1. SKILL.md Size

| Metric | Value | Threshold | Verdict |
|--------|-------|-----------|---------|
| Word count | 1,430 | warn > 3,000 / error > 5,000 | PASS |
| Line count | 263 | warn > 500 | PASS |

The skill is well within size limits. At 1,430 words it uses roughly half the warning budget, leaving headroom for future handler additions without breaching thresholds.

---

## 2. Progressive Disclosure Compliance

### Metadata (frontmatter)

| Check | Verdict | Notes |
|-------|---------|-------|
| `name` + `description` only | PASS | No extra fields in frontmatter |
| Description includes what + when | PASS | Lists purpose and four explicit trigger conditions |
| Description length <= 1,024 chars | PASS | ~406 characters |
| No "When to Use" section in body | PASS | Trigger info lives exclusively in the description |

### Body content

| Check | Verdict | Notes |
|-------|---------|-------|
| Core workflow < 5k words | PASS | 1,430 words |
| Long code examples offloaded | PASS | Body contains only invocation one-liners; logic lives in scripts |
| API docs / schemas in references | PASS | Tavily/Exa parameters are in `search-api-reference.md`; routing logic is in `query-intelligence.md` |
| Large references have grep patterns | N/A | No reference exceeds 10k words (largest: `search-api-reference.md` at 472 words) |

### Red flags

None detected. The body is procedural (parse, classify, dispatch, save), with detailed reference material correctly deferred to `references/`.

---

## 3. Duplication Check

### 3a. Token Allocation table (DUPLICATE)

The "Code Search Token Allocation" table appears **identically** in two reference files:

- `references/query-intelligence.md` lines 49-58 (Section "Code Search Token Allocation")
- `references/search-api-reference.md` lines 58-67 (Section "Exa Code Context -- Token Allocation")

Both contain the same four-tier table (Simple lookup 3000 / Standard 5000 / Complex 10000 / Deep 15000) with identical example queries.

**Recommendation**: Keep the table in one canonical location. `query-intelligence.md` is the routing-and-enrichment reference that the agent reads before executing search, so it is the natural home. `search-api-reference.md` should reference or defer to it instead of duplicating.

### 3b. Prerequisite information (acceptable overlap)

SKILL.md inlines a one-line prerequisite summary for each handler (Google, Slack, Notion) with a "Details:" pointer to the respective reference file. The reference files expand on those prerequisites. This is the preferred pattern (summary in SKILL.md, detail in references) and does not constitute duplication.

### 3c. Graceful degradation (minor overlap)

SKILL.md mentions graceful degradation in three places (line 161, rule 2 at line 249, rule 7 at line 254). These serve different purposes (operational instruction, rule summary, rule detail) and are acceptably concise -- not a true duplication concern.

---

## 4. Resource Health

### 4a. File quality

| Reference file | Words | Lines | TOC needed (>100 lines)? | Grep patterns needed (>10k words)? |
|----------------|-------|-------|--------------------------|-------------------------------------|
| `google-export.md` | 99 | 16 | No | No |
| `notion-export.md` | 70 | 18 | No | No |
| `query-intelligence.md` | 343 | 69 | No | No |
| `search-api-reference.md` | 472 | 80 | No | No |
| `slack-export.md` | 83 | 19 | No | No |
| `TOON.md` | 140 | 65 | No | No |

All reference files are compact and well within thresholds. No table-of-contents or grep patterns are required.

Deeply nested references: None detected. All references are one level deep from SKILL.md.

### 4b. Script inventory

| Script | Lines | Referenced in SKILL.md? |
|--------|-------|------------------------|
| `g-export.sh` | 121 | Yes (line 46) |
| `slack-api.mjs` | 304 | Yes (line 48) |
| `slack-to-md.sh` | 154 | Yes (line 48) |
| `notion-to-md.py` | 523 | Yes (line 49) |
| `extract.sh` | 138 | Yes (line 50) |
| `search.sh` | 146 | Yes (lines 144, 147, 156, 208) |
| `code-search.sh` | 115 | Yes (lines 147, 157) |
| **`csv-to-toon.sh`** | **176** | **No** |

### 4c. Unreferenced file: `scripts/csv-to-toon.sh` (FINDING)

**Status**: The filename `csv-to-toon.sh` does not appear anywhere in SKILL.md (0 occurrences).

**Is it actually used?** Yes. `g-export.sh` calls it at line 111 (`"$SCRIPT_DIR/csv-to-toon.sh" "$OUTPUT_PATH"`) to convert CSV downloads from Google Sheets into TOON format. It is a runtime dependency of the Google Sheets export pipeline.

**Impact**: An agent reading only SKILL.md would not know this script exists. If someone triaged unused files, they might mistakenly flag it for removal, breaking the Sheets-to-TOON pipeline.

**Recommendation**: Add a brief mention in the Google Export subsection of SKILL.md. For example, in the handler table row for Google Export or in the "Google Export" subsection text, note that Sheets TOON conversion uses `scripts/csv-to-toon.sh` internally via `g-export.sh`. Alternatively, add it to the References section at the bottom as a script reference. This satisfies the "filename appears in SKILL.md" criterion without bloating the body.

### 4d. `__pycache__` directory (FINDING)

`scripts/__pycache__/notion-to-md.cpython-310.pyc` exists in the tree. This is a Python bytecode cache artifact that should not be committed to the repository.

**Recommendation**: Add `__pycache__/` to `.gitignore` (if not already present at repo root) and remove the cached file.

---

## Summary of Findings

| # | Criterion | Severity | Description |
|---|-----------|----------|-------------|
| 1 | Size | PASS | 1,430 words / 263 lines -- well within limits |
| 2 | Progressive Disclosure | PASS | Clean three-level hierarchy; no red flags |
| 3 | Duplication | **warning** | Token Allocation table duplicated between `query-intelligence.md` and `search-api-reference.md` |
| 4a | Resource Health: file quality | PASS | All references compact; no TOC or grep patterns needed |
| 4b | Resource Health: unused files | **warning** | `scripts/csv-to-toon.sh` is a runtime dependency but unreferenced in SKILL.md |
| 4c | Resource Health: artifact | **info** | `scripts/__pycache__/` should be gitignored and removed |

### Recommended Actions

1. **Deduplicate Token Allocation table**: Remove the table from `search-api-reference.md` and replace with a pointer to `query-intelligence.md` Section "Code Search Token Allocation".
2. **Reference `csv-to-toon.sh` in SKILL.md**: Add the filename to the Google Export subsection or the bottom References list so it satisfies the "filename appears in SKILL.md" check.
3. **Remove `__pycache__`**: Delete `scripts/__pycache__/` and ensure `.gitignore` covers it.

<!-- AGENT_COMPLETE -->
