# Documentation Audit & Improvement Plan

## Goal

Comprehensive audit of all markdown docs against prompt-logs lessons/retros. Fix gaps, trim bloat, enforce progressive disclosure.

## Success Criteria

```gherkin
Given the full set of prompt-logs lessons and retros
When compared against current documentation
Then all actionable lessons are reflected in the appropriate docs
And no document exceeds its intended scope
And duplication across files is eliminated (single source of truth)
And progressive disclosure is maintained (CLAUDE.md → cheatsheet → deep docs)
```

## Findings

### A. Bloated / Scope Violation

1. ✅ **`docs/claude-marketplace.md`** (510→43 lines): Replaced with slim project-specific reference + official docs link.

2. ✅ **`web-search/references/api-reference.md`** (381→56 lines): Kept env vars, params, token table. Removed all curl/jq/python patterns.

### B. Duplication

3. ✅ **checklist.md**: Removed duplicated Version Bump Rules and marketplace.json format. Added cross-reference to cheatsheet.

4. ✅ (merged with #3)

5. ✅ **api-reference.md**: Usage Message removed along with overall slim-down.

### C. Stale / Missing Content

6. ✅ **`CHANGELOG.md`**: Added v1.9.0 entry with all Feb 3 changes.

7. ✅ **`docs/project-context.md`**: Added Architecture Patterns section (script delegation, hook redirects, 3-tier env, local vs marketplace) and Plugins section.

### D. Lessons Not Yet Reflected in Docs

8. ✅ **cheatsheet Testing**: Added "hooks are snapshots at session start" note.

9. ✅ **cheatsheet hooks.json**: Added `type: prompt` tip.

10. ✅ **cheatsheet Script Guidelines**: Added `((var++))` gotcha.

### E. Not Needed

- README.md / README.ko.md duplication: intentional for i18n (confirmed in 260130-doc-compression lesson). Keep as-is.
- SKILL.md detail levels: each is appropriate for its purpose. No changes needed.

## Deferred Actions

(none)

## File Change Summary

| File | Action |
|------|--------|
| `docs/claude-marketplace.md` | Replace 510 lines → ~30 lines + official docs link |
| `plugins/web-search/skills/web-search/references/api-reference.md` | Slim 381 lines → ~80 lines (env vars, params, token table only) |
| `.claude/skills/plugin-deploy/references/checklist.md` | Remove duplicated sections, add cheatsheet refs |
| `CHANGELOG.md` | Add Feb 3 entries |
| `docs/project-context.md` | Add new patterns |
| `docs/plugin-dev-cheatsheet.md` | Add 3 missing lessons (hooks snapshot, type:prompt, bash gotcha) |
