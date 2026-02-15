# S23 Discoverability Architecture Audit

Date: 2026-02-11
Concern: AGENTS entry path quality + repository/plugin self-containment

## Entry-Path Trace

Primary documented route:

1. `AGENTS.md` progressive disclosure index (`AGENTS.md:5`, `AGENTS.md:9`, `AGENTS.md:10`)
2. `cwf-index.md` map (`cwf-index.md:8`, `cwf-index.md:14`)
3. root README + plugin skill docs (`README.md`, `plugins/cwf/skills/*/SKILL.md`)

Result: **navigable**, with valid file references in core entry docs.

## Gate Results

| Gate | Check | Verdict |
|---|---|---|
| C3-G1 | AGENTS -> index -> docs path exists and resolves | PASS |
| C3-G2 | Entry docs avoid dead links in core navigation set | PASS |
| C3-G3 | Plugin is self-contained when installed from marketplace source path | FAIL |
| C3-G4 | Skill discoverability reflects active runtime inventory | FAIL |
| C3-G5 | Concept/discoverability metadata is synchronized with live system | FAIL |

## Findings

### 1) Self-containment boundary is violated (blocking)

Multiple active skills call scripts outside plugin root (repo-root `scripts/*`).
This is a self-containment risk because marketplace source is `./plugins/cwf`.

Evidence:
- `plugins/cwf/skills/setup/SKILL.md:193`
- `plugins/cwf/skills/run/SKILL.md:162`
- `plugins/cwf/skills/impl/SKILL.md:387`
- `plugins/cwf/skills/handoff/SKILL.md:399`
- `plugins/cwf/skills/plan/SKILL.md:270`
- `plugins/cwf/skills/retro/SKILL.md:49`

### 2) Skill discoverability mismatch

- Active skills on disk: 12
- README/README.ko skill reference tables: 11 (missing `run`)

This creates onboarding ambiguity: users cannot discover one active orchestrator skill from top-level docs.

### 3) Concept/discoverability metadata stale

- Concept map still models 9-skill system (`plugins/cwf/references/concept-map.md:3`, `plugins/cwf/references/concept-map.md:5`).
- Current live state is 12 skills / 15 hooks.
- Provenance check reports 7/7 stale provenance files.

## Verdict

Concern 3 status: **FAIL (blocking)**.

Rationale: navigation is present, but self-containment and inventory synchronization are not release-ready for first-user discoverability.

## S24 Remediation Update

Date: 2026-02-11

### Re-check Evidence

- Entry path remains valid (`AGENTS.md` -> `cwf-index.md` -> README/skills).
- Self-containment remediation applied:
  - plugin-local scripts added under `plugins/cwf/scripts/*`
  - blocker-scope and external-review skill references repointed to plugin-local paths
  - evidence: `plugins/cwf/skills/setup/SKILL.md:193`, `plugins/cwf/skills/run/SKILL.md:40`, `plugins/cwf/skills/impl/SKILL.md:387`, `plugins/cwf/skills/handoff/SKILL.md:401`, `plugins/cwf/skills/plan/SKILL.md:270`, `plugins/cwf/skills/retro/SKILL.md:49`, `plugins/cwf/skills/review/SKILL.md:293`
- Discoverability inventory synchronization:
  - README skill tables now include `run` and represent 12 active skills (`README.md:81`, `README.ko.md:81`)
- Concept/discoverability metadata synchronization:
  - concept map updated to 12x6 and includes `review`/`run`/`ship` (`plugins/cwf/references/concept-map.md:5`, `plugins/cwf/references/concept-map.md:168`, `plugins/cwf/references/concept-map.md:169`, `plugins/cwf/references/concept-map.md:171`)
  - provenance freshness is 7/7 (`bash scripts/provenance-check.sh --level warn`)

### Updated Gate Results

| Gate | Check | Verdict |
|---|---|---|
| C3-G1 | AGENTS -> index -> docs path exists and resolves | PASS |
| C3-G2 | Entry docs avoid dead links in core navigation set | PASS |
| C3-G3 | Plugin is self-contained when installed from marketplace source path | PASS |
| C3-G4 | Skill discoverability reflects active runtime inventory | PASS |
| C3-G5 | Concept/discoverability metadata is synchronized with live system | PASS |

## Updated Verdict

Concern 3 status after S24 remediation: **PASS**.
