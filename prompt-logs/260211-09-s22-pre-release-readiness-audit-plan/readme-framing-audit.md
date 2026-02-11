# S23 README Framing Audit

Date: 2026-02-11
Targets:
- `README.md`
- `README.ko.md`

## Gate Criteria (Concern 2)

| Gate | Requirement | Verdict |
|---|---|---|
| C2-G1 | CWF philosophy and core concept composition are explicit and actionable | PASS |
| C2-G2 | README explicitly states **what CWF is** | PASS |
| C2-G3 | README explicitly states **what CWF is not** | FAIL |
| C2-G4 | README explicitly lists core assumptions/premises | FAIL |
| C2-G5 | README explicitly lists major decisions and rationale (decision + why) | FAIL |
| C2-G6 | English/Korean conceptual equivalence is maintained | FAIL |
| C2-G7 | Skill inventory framing matches current runtime inventory | FAIL |

## Findings

### Strengths

- Philosophy and concept architecture are present and readable:
  - problem statement and motivation (`README.md:7`)
  - six concept definitions (`README.md:15`)
  - workflow and per-skill quick usage (`README.md:31`, `README.md:86`)

### Blocking Gaps

1. **No explicit boundary contract (`is / is-not`)**
- Current text strongly explains capabilities, but no explicit "not for X" boundary section exists.
- This increases over-application risk by first-time users (scope expectations remain implicit).

2. **Assumptions and decision rationale are implicit, not contractual**
- Major principles are described narratively, but not as a decision register (assumption, decision, why, trade-off).
- Release-readiness framing requested this as a first-class criterion.

3. **Inventory consistency drift (9 vs 11 vs 12)**
- README still says "compose across nine skills" (`README.md:11`).
- README summary claims 11 skills (`README.md:13`) and table enumerates 11 (`README.md:50`, `README.md:51`).
- Actual active skill directories are 12 (includes `run`).

4. **Korean/English conceptual mismatch**
- `README.ko.md` states review concept composition differently from English (`README.ko.md:53` vs `README.md:53`).
- `README.ko.md` includes an extra "deleted plugins" chapter (`README.ko.md:347`) and legacy marketplace framing (`README.ko.md:84`) that does not mirror English structure/content.

## Recommended Section Contract (minimal patch design)

Add an explicit pre-Installation framing block in both README files:

1. `What CWF Is`
2. `What CWF Is Not`
3. `Assumptions`
4. `Key Decisions and Why`

For each decision, use a compact tuple:
- Decision
- Rationale
- Trade-off
- Impacted skills/hooks

## Verdict

Concern 2 status: **FAIL (blocking)**.

Rationale: core philosophy exists, but boundary/assumption/decision framing and bilingual consistency are insufficient for release-level first-user clarity.
