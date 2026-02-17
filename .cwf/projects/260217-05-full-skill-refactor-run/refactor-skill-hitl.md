## Refactor Review: hitl

### Summary
- Word count: 1,235 (within limits).
- Line count: 209 (within limits).
- Resources: 0 total, 0 unreferenced (no `references/`, `scripts/`, or `assets/` files besides the README map).
- Duplication: `state.yaml`/intent-resync field descriptions appear twice (State Model overview + Phase 0.75), which raises maintenance friction.

### Findings
#### [warning] State schema duplication bloats the scorecard
**What**: The `State Model` section enumerates every field (`session_id`, `status`, `intent_resync_required`, etc.) and is later echoed in Phase 0.75 when the intent-resync gate reiterates the same schema and state transitions. Having that information embedded twice makes the SKILL.md heavier and increases the risk that one description drifts from the other.
**Where**: `plugins/cwf/skills/hitl/SKILL.md` (State Model, Phase 0.75 Intent Resync Gate, and the repeated explanations of `state.yaml`, `queue.json`, `fix-queue.yaml`).
**Suggestion**: Extract the state/queue schema and field descriptions into a dedicated reference document (e.g., `references/hitl-state-model.md`). Keep the SKILL focused on the phase-by-phase workflow and link to the reference when describing the files that need updating; that keeps the core instructions lean and avoids duplication when Phase 0.75 refers back to the same state structure.

#### [warning] Concept integrity cannot be verified because hitl lacks a concept-map entry
**What**: The Concept Synchronization Map (`plugins/cwf/references/concept-map.md`) lists which generic concepts each skill composes, but hitl is not present in the table. Without that row, Criterion 8 (Concept Integrity) has no anchor for this skill, and future reviewers cannot tell whether hitl is expected to implement Expert Advisor, Decision Point, or other concepts.
**Where**: `plugins/cwf/skills/hitl/SKILL.md` (the workflow clearly composes decision gating/Hand-off concerns) and `plugins/cwf/references/concept-map.md` (the row for hitl is missing entirely).
**Suggestion**: Add a hitl row to `concept-map.md` with the appropriate `x` marks (at minimum Decision Point and Handoff, perhaps Provenance or Tier Classification if justified). Link that row to the documented behaviors (agreement round, intent resync, resumable queue, rule propagation) so later reviews can verify the claimed concepts against the SKILL text.

### Suggested Actions
1. Extract the detailed state/queue schema and intent-resync rules into a reference file and cross-link it from the SKILL so both the overview and the gate logic point to the same source of truth (effort: medium).
2. Extend `plugins/cwf/references/concept-map.md` with a hitl row, marking the concepts the skill actually composes and linking to the behaviors already described in the SKILL (effort: small).
3. After the new reference exists, add a concise reference pointer to the SKILL wherever `state.yaml`, `queue.json`, or the intent-resync gate is discussed to avoid re-stating schema details (effort: small).

<!-- AGENT_COMPLETE -->
