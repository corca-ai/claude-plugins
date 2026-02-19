# Refactor Quick Scan Summary

**Mode:** `cwf:refactor` (Quick Scan)
**Date:** 2026-02-19
**Scope:** 13 marketplace skills (local skills excluded)

## Refactor Summary

Provenance check found 0 sidecar files (no sidecars tracked for quick-scan mode — informational only).

**Total:** 13 skills scanned, **2 flagged**, 0 errors

## Results

| Plugin | Skill | Words | Lines | Resources | Flags |
|--------|-------|------:|------:|----------:|:-----:|
| cwf | clarify | 2,080 | 456 | 4 | 0 |
| cwf | gather | 1,879 | 347 | 14 | 0 |
| cwf | handoff | 2,110 | 358 | 0 | 0 |
| cwf | hitl | 1,235 | 188 | 1 | 0 |
| cwf | impl | 2,555 | 453 | 2 | 0 |
| cwf | plan | 1,596 | 292 | 0 | 0 |
| cwf | refactor | 1,572 | 331 | 25 | 0 |
| cwf | retro | 2,921 | 415 | 3 | 0 |
| cwf | **review** | 2,950 | 507 | 4 | **1** |
| cwf | run | 2,623 | 492 | 0 | 0 |
| cwf | **setup** | 2,450 | 465 | 15 | **1** |
| cwf | ship | 1,797 | 349 | 2 | 0 |
| cwf | update | 1,199 | 296 | 1 | 0 |

**Total:** 13 skills scanned, **2 flagged**, 0 errors

## Flagged Skills

### review (1 flag)
- `line_count_warning`: 507 lines exceeds 500-line threshold

### setup (1 flag)
- `unreferenced`: `scripts/migrate-env-vars.sh` is present but not referenced in SKILL.md

## Recommendations

- **review**: Consider extracting sections into reference files to bring SKILL.md under 500 lines. Run `cwf:refactor --skill review` for deep review.
- **setup**: Either reference `scripts/migrate-env-vars.sh` in SKILL.md or remove it if unused. Run `cwf:refactor --skill setup` for deep review.

## Scan Command

```bash
bash plugins/cwf/skills/refactor/scripts/quick-scan.sh /home/hwidong/codes/claude-plugins
```
