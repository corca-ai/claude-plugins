# Tidying Analysis: Commit 504ecf8

> **Commit**: `504ecf8` — `docs(cwf): standardize script path placeholder to CWF_PLUGIN_DIR`
> **Analyzed at**: HEAD (`226cdd1`)
> **Files touched**: 10 SKILL.md files + 2 reference docs

## Commit Summary

This commit performed a bulk find-and-replace across CWF skill documents, converting `{SKILL_DIR}/../../scripts/...` references to the canonical `{CWF_PLUGIN_DIR}/scripts/...` form. It also added a "Runtime Script Path Placeholder (Global Contract)" section to `skill-conventions.md` documenting the new convention.

**HEAD delta note**: The `skill-conventions.md` addition was reverted by a subsequent commit (`226cdd1`). The section "Runtime Script Path Placeholder (Global Contract)" no longer exists at HEAD. All other file changes from this commit remain intact at HEAD.

---

## Tidying Opportunities

### 1. Incomplete placeholder migration: `{SKILL_DIR}/../../references/` remnants

`plugins/cwf/skills/impl/SKILL.md:191` and `plugins/cwf/skills/plan/SKILL.md:175` — Normalize two remaining `{SKILL_DIR}/../../references/` paths to `{CWF_PLUGIN_DIR}/references/` for consistency with the commit's own convention.

(reason: The commit standardized all `{SKILL_DIR}/../../scripts/` to `{CWF_PLUGIN_DIR}/scripts/`, but missed the parallel case for `references/`. These two lines use the old deep-traversal form for shared reference files. Normalizing them is a mechanical string replacement that does not change any runtime behavior, since both placeholder forms resolve to the same directory.)

**Before** (`plugins/cwf/skills/plan/SKILL.md:175`):

```markdown
Synthesize research from both sub-agents into a structured plan. Read `{SKILL_DIR}/../../references/plan-protocol.md` for protocol rules on location, sections, and format.
```

**After**:

```markdown
Synthesize research from both sub-agents into a structured plan. Read `{CWF_PLUGIN_DIR}/references/plan-protocol.md` for protocol rules on location, sections, and format.
```

**Before** (`plugins/cwf/skills/impl/SKILL.md:191`):

```markdown
Read `{SKILL_DIR}/../../references/agent-patterns.md` for general agent principles.
```

**After**:

```markdown
Read `{CWF_PLUGIN_DIR}/references/agent-patterns.md` for general agent principles.
```

---

### 2. Normalize `{PLUGIN_ROOT}/references/` to `{CWF_PLUGIN_DIR}/references/`

`plugins/cwf/skills/refactor/SKILL.md:177,258,267` and `plugins/cwf/skills/refactor/references/review-criteria.md:112`, `plugins/cwf/skills/refactor/references/holistic-criteria.md:11,43,52` — Replace 7 instances of `{PLUGIN_ROOT}/references/` with `{CWF_PLUGIN_DIR}/references/`.

(reason: The commit established `{CWF_PLUGIN_DIR}` as the canonical placeholder for the CWF plugin root. `{PLUGIN_ROOT}` is a second alias for the same directory, creating a symmetry break. All other skill files already use `{CWF_PLUGIN_DIR}` for this same path. This is a mechanical rename that does not change resolution semantics, and normalizing it eliminates a reader's need to mentally confirm that `{PLUGIN_ROOT}` and `{CWF_PLUGIN_DIR}` are equivalent.)

**Before** (`plugins/cwf/skills/refactor/SKILL.md:177`):

```markdown
- `{PLUGIN_ROOT}/references/concept-map.md` (for Criterion 8: Concept Integrity)
```

**After**:

```markdown
- `{CWF_PLUGIN_DIR}/references/concept-map.md` (for Criterion 8: Concept Integrity)
```

---

### 3. Inconsistent placeholder use within `retro/SKILL.md` references section

`plugins/cwf/skills/retro/SKILL.md:413-414` — The References section at lines 413-414 uses `{SKILL_DIR}/references/` for local reference links, while all other `retro/SKILL.md` body references to CWF-level files (lines 31, 42-44, 51, 94) correctly use `{CWF_PLUGIN_DIR}/...`. This is internally consistent (skill-local references use `{SKILL_DIR}`, plugin-level references use `{CWF_PLUGIN_DIR}`), so no change is needed for `{SKILL_DIR}/references/` paths that point to skill-local files.

**Assessment**: No tidying opportunity here. The `{SKILL_DIR}/references/` form is correct for skill-local reference files (e.g., `cdm-guide.md`, `expert-lens-guide.md` which live inside the skill's own `references/` directory). This is a different semantic scope from `{CWF_PLUGIN_DIR}/references/` which points to plugin-level shared references. The distinction is intentional.

---

## Summary

| # | File(s) | Suggestion | Safety |
|---|---------|-----------|--------|
| 1 | `plugins/cwf/skills/impl/SKILL.md:191`, `plugins/cwf/skills/plan/SKILL.md:175` | Replace `{SKILL_DIR}/../../references/` with `{CWF_PLUGIN_DIR}/references/` (2 instances) | Safe: mechanical string replacement; both forms resolve identically; aligns with the convention this commit established |
| 2 | `plugins/cwf/skills/refactor/SKILL.md:177,258,267` + `refactor/references/review-criteria.md:112` + `refactor/references/holistic-criteria.md:11,43,52` | Replace `{PLUGIN_ROOT}/references/` with `{CWF_PLUGIN_DIR}/references/` (7 instances) | Safe: mechanical string replacement; normalizes a second alias to the canonical form; no behavioral change |

Both suggestions are direct extensions of the convention established by commit `504ecf8` itself. They complete the normalization that the commit started but did not finish for the `references/` path family.

<!-- AGENT_COMPLETE -->
