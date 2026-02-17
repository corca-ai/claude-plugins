## Expert Beta Review
### Concerns (blocking)
- **[C1] Stage-level provenance contract is violated by the committed provenance artifact, breaking architectural traceability.** `plugins/cwf/skills/run/SKILL.md:118-128` defines explicit Stage->Skill mapping (`impl` -> `cwf:impl --skip-clarify`), and `plugins/cwf/skills/run/SKILL.md:302-308` requires provenance rows to record the invoked skill. But `.cwf/projects/260217-05-full-skill-refactor-run/run-stage-provenance.md:4` records `Stage=impl` with `Skill=cwf:run`. This collapses orchestrator/stage boundaries and makes provenance unsuitable as reliable audit evidence.
- **[C2] A newly declared mandatory invariant has no deterministic enforcement path, creating policy/gate drift.** `plugins/cwf/skills/run/SKILL.md:443` declares per-stage provenance mandatory, but the strict run gate (`plugins/cwf/scripts/check-run-gate-artifacts.sh:6-8`, `plugins/cwf/scripts/check-run-gate-artifacts.sh:21`, `plugins/cwf/scripts/check-run-gate-artifacts.sh:234-240`) validates only `review-code|refactor|retro|ship` and has no `run-stage-provenance.md` schema/presence check. This leaves the new requirement as prose-only and undermines fail-closed deterministic governance.

### Suggestions (non-blocking)
- Add a dedicated deterministic check for `run-stage-provenance.md` (row existence, Stage->Skill mapping validity, timestamp/duration schema, gate outcome enum) and run it in both stage-close and final completion paths.
- Normalize provenance source metadata so human-readable and machine-readable counts cannot drift. `plugins/cwf/references/concept-map.md:3` says `15 hooks` while `plugins/cwf/references/concept-map.provenance.yaml:5` says `18`.
- In `plugins/cwf/skills/update/SKILL.md:27-35` and `plugins/cwf/skills/update/SKILL.md:52-55`, capture an immutable pre-update snapshot path before marketplace/install steps so Phase 3 diffs (`plugins/cwf/skills/update/SKILL.md:105-121`) remain valid even when cache paths are reused.

### Behavioral Criteria Assessment
- [ ] Deterministic provenance integrity: stage provenance must preserve Stage->Skill boundary and remain audit-reliable (`plugins/cwf/skills/run/SKILL.md:118-128`, `.cwf/projects/260217-05-full-skill-refactor-run/run-stage-provenance.md:4`).
- [ ] Mandatory invariants must be gate-enforced, not prose-only (`plugins/cwf/skills/run/SKILL.md:443`, `plugins/cwf/scripts/check-run-gate-artifacts.sh:21`).
- [x] Cross-skill concept hardening via canonical references improved consistency (examples: `plugins/cwf/skills/plan/SKILL.md`, `plugins/cwf/skills/handoff/SKILL.md`, `plugins/cwf/skills/hitl/references/hitl-state-model.md`).

### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: Expert Beta
duration_ms: —
command: —

<!-- AGENT_COMPLETE -->
