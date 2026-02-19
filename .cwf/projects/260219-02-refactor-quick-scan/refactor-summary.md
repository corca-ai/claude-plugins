# Refactor Quick Scan Summary

**Mode:** `cwf:refactor` (Quick Scan)
**Scan command:** `bash plugins/cwf/skills/refactor/scripts/quick-scan.sh {REPO_ROOT}`
**Provenance:** No mode-relevant sidecars required for quick scan mode.

## Refactor Summary

| Plugin | Skill | Words | Lines | Flags |
|--------|-------|------:|------:|------:|
| cwf | clarify | 2,080 | 456 | 0 |
| cwf | gather | 1,879 | 347 | 0 |
| cwf | handoff | 2,110 | 358 | 0 |
| cwf | hitl | 1,235 | 188 | 0 |
| cwf | impl | 2,555 | 453 | 0 |
| cwf | plan | 1,596 | 292 | 0 |
| cwf | refactor | 1,572 | 331 | 0 |
| cwf | retro | 2,921 | 415 | 0 |
| cwf | **review** | 2,950 | 507 | **1** |
| cwf | run | 2,623 | 492 | 0 |
| cwf | **setup** | 2,450 | 465 | **1** |
| cwf | ship | 1,797 | 349 | 0 |
| cwf | update | 1,199 | 296 | 0 |

**Total skills:** 13 | **Flagged:** 2 | **Warnings:** 2 | **Errors:** 0

## Flagged Skills

### review (1 flag)
- `line_count_warning` — 507 lines exceeds 500-line threshold

### setup (1 flag)
- `unreferenced` — `scripts/migrate-env-vars.sh` is not referenced from SKILL.md

## Recommendations

- Run `cwf:refactor --skill review` for a deep review (line count near threshold — consider splitting or extracting references).
- Run `cwf:refactor --skill setup` for a deep review (unreferenced script may be dead code or missing a SKILL.md reference).
