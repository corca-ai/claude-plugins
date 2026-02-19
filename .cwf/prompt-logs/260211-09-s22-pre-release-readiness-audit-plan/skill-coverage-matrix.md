# S23 Skill Coverage Matrix

Date: 2026-02-11
Scope: all active CWF skills under `plugins/cwf/skills/*` (12 total)

## Coverage Summary

- Audited skills: **12/12**
- `PASS`: 7
- `WARN`: 3
- `FAIL`: 2

## Matrix

| Skill | Words / Lines | Structural Check | Resource / Size Flags | Concept-Map Row | Verdict | Notes |
|---|---:|---|---|---|---|---|
| `clarify` | 2074 / 461 | PASS | none | present | PASS | Meets current structural gates. |
| `gather` | 1287 / 270 | PASS | unreferenced `scripts/csv-to-toon.sh` | present | WARN | Cleanup/reference decision needed for orphan script. |
| `handoff` | 2052 / 428 | PASS | none | present | PASS | No structural drift detected. |
| `impl` | 2221 / 425 | PASS | none | present | PASS | No structural drift detected. |
| `plan` | 1418 / 323 | PASS | none | present | PASS | No structural drift detected. |
| `refactor` | 1900 / 390 | WARN | 3 unreferenced provenance sidecars | present | WARN | `References` precedes `Rules` (`plugins/cwf/skills/refactor/SKILL.md:371`, `plugins/cwf/skills/refactor/SKILL.md:381`). |
| `retro` | 2661 / 346 | WARN | none | present | WARN | Uses `Invocation` instead of explicit Quick section; `References` before `Rules` (`plugins/cwf/skills/retro/SKILL.md:325`, `plugins/cwf/skills/retro/SKILL.md:331`). |
| `review` | 3703 / 697 | PASS | size warning (>3000 words, >500 lines) | **missing** | WARN | Exceeds size guideline and not represented in concept map. |
| `run` | 949 / 205 | FAIL | none | **missing** | FAIL | Missing `## References` (`plugins/cwf/skills/run/SKILL.md:205`). |
| `setup` | 1692 / 458 | PASS | none | present (in map sparse row set) | PASS | Structurally acceptable; see discoverability audit for self-containment concerns. |
| `ship` | 1310 / 288 | FAIL | none | **missing** | FAIL | Missing both `## Rules` and `## References` (`plugins/cwf/skills/ship/SKILL.md:288`). |
| `update` | 388 / 124 | PASS | none | present | PASS | No structural drift detected. |

## Supporting Evidence

### Quick scan evidence (`quick-scan.sh`)

```text
Total skills: 12
Warnings: 4
Errors: 0
Flagged skills: 3 (gather, refactor, review)
```

### Convention baseline

Convention source:
- `plugins/cwf/references/skill-conventions.md:65`
- `plugins/cwf/references/skill-conventions.md:120`
- `plugins/cwf/references/skill-conventions.md:184`

### Concept-map coverage gap

`plugins/cwf/references/concept-map.md` currently models 9 skills and omits active skills:
- `review`
- `run`
- `ship`

## S24 Remediation Delta

Date: 2026-02-11
Re-check basis: `bash plugins/cwf/skills/refactor/scripts/quick-scan.sh` + targeted manual structural checks.

### Updated Coverage Summary

- Audited skills: **12/12**
- `PASS`: 9
- `WARN`: 3
- `FAIL`: 0

### Verdict Changes from S23

| Skill | S23 | S24 | Evidence |
|---|---|---|---|
| `run` | FAIL | PASS | Added missing `## References` (`plugins/cwf/skills/run/SKILL.md:207`) |
| `ship` | FAIL | PASS | Added `## Rules` + `## References` (`plugins/cwf/skills/ship/SKILL.md:290`, `plugins/cwf/skills/ship/SKILL.md:299`) |
| `retro` | WARN | PASS | Added explicit quick section + corrected section order (`plugins/cwf/skills/retro/SKILL.md:27`, `plugins/cwf/skills/retro/SKILL.md:325`, `plugins/cwf/skills/retro/SKILL.md:342`) |
| `refactor` | WARN | WARN | Section order fixed; remaining warning is unreferenced provenance sidecars |
| `review` | WARN | WARN | Size warning remains (>3000 words, >500 lines) |
| `gather` | WARN | WARN | Unreferenced `scripts/csv-to-toon.sh` remains |

### Updated Blocking Status

- Structural convention blockers: **resolved**.
- Coverage blocker for active skill inventory: **resolved**.
- Remaining warnings: **non-blocking maintainability advisories**.
