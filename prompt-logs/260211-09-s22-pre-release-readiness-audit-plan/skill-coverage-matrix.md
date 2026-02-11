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
