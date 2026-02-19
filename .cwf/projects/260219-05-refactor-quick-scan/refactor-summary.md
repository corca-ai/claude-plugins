# Refactor Quick Scan Summary

## Refactor Summary

**Mode:** `cwf:refactor` (Quick Scan)
**Date:** 2026-02-19
**Scope:** 13 marketplace skills (local skills not included)

## Provenance Warning

Provenance checker returned 0 sidecar files (no criteria sidecars registered for quick-scan mode). This is expected — quick scan uses structural heuristics, not criteria documents.

## Results

| Plugin | Skill | Words | Lines | Resources | Flags |
|--------|-------|------:|------:|----------:|-------|
| cwf | clarify | 2,080 | 456 | 4 | — |
| cwf | gather | 1,879 | 347 | 14 | — |
| cwf | handoff | 2,110 | 358 | 0 | — |
| cwf | hitl | 1,235 | 188 | 1 | — |
| cwf | impl | 2,555 | 453 | 2 | — |
| cwf | plan | 1,596 | 292 | 0 | — |
| cwf | refactor | 1,572 | 331 | 25 | — |
| cwf | retro | 2,921 | 415 | 3 | — |
| cwf | **review** | 2,950 | **507** | 4 | `line_count_warning (507L > 500)` |
| cwf | run | 2,623 | 492 | 0 | — |
| cwf | **setup** | 2,450 | 465 | 15 | `unreferenced: scripts/migrate-env-vars.sh` |
| cwf | ship | 1,797 | 349 | 2 | — |
| cwf | update | 1,199 | 296 | 1 | — |

**Total:** 13 skills scanned · 2 flagged · 0 errors

## Flagged Skills

### 1. review — `line_count_warning`
SKILL.md is 507 lines (threshold: 500). Slightly over limit. Consider extracting a reference doc for one of the longer sections to bring it under 500L.

### 2. setup — `unreferenced: scripts/migrate-env-vars.sh`
`scripts/migrate-env-vars.sh` exists in the skill directory but is not referenced from SKILL.md. Either add a reference or remove the orphaned file.

## Recommendations

- Run `cwf:refactor --skill review` for a deep review of the review skill.
- Run `cwf:refactor --skill setup` for a deep review of the setup skill.

---
*Scan command:* `bash plugins/cwf/skills/refactor/scripts/quick-scan.sh /home/hwidong/codes/claude-plugins`
