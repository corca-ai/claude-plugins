# Holistic Concept Integrity (Rerun)
## Findings
1. **Concept-map blind spot for scope-aware contract (high).**
   Setup and update now share a concrete scope-resolution and mutation-boundary behavior (`plugins/cwf/skills/setup/SKILL.md:253`, `plugins/cwf/skills/update/SKILL.md:21`, `plugins/cwf/scripts/detect-plugin-scope.sh:14`), but `plugins/cwf/references/concept-map.md:171` and `plugins/cwf/references/concept-map.md:178` still treat both as concept-empty infrastructure rows. This leaves no formal concept criterion for scope precedence, scope-target confirmation, or scope-specific rollback/reporting.
2. **Guard asymmetry for user-global mutation between setup and update (medium).**
   Setup requires an explicit second confirmation when a non-user context chooses user-global Codex targets (`plugins/cwf/skills/setup/SKILL.md:309`, `plugins/cwf/skills/setup/SKILL.md:1058`). Update allows `User scope` selection (`plugins/cwf/skills/update/SKILL.md:63`) and then can reconcile user-global paths (`plugins/cwf/skills/update/SKILL.md:245`) without an equivalent side-effect warning/second confirmation step.
3. **Operational decision gates exist but are unmapped in the current concept model (medium).**
   Setup/update now rely on explicit decision prompts for safe execution (`plugins/cwf/skills/setup/SKILL.md:292`, `plugins/cwf/skills/update/SKILL.md:56`), while current `Decision Point` requires evidence mapping and provenance records (`plugins/cwf/references/concept-map.md:91`). The behavior is real and safety-critical, but currently not representable in the synchronization map.
4. **Holistic criteria provenance is fresh (informational).**
   `bash plugins/cwf/scripts/provenance-check.sh --level inform --json` reports `holistic-criteria.provenance.yaml` as `fresh` (13 skills, 18 hooks), so this rerun has no provenance-staleness blocker.

## Under/Over Synchronization Notes
- **Under-synchronization:** setup/update have a shared scope-aware contract but no mapped concept ownership in `concept-map.md`, so cross-skill integrity checks cannot validate this behavior class.
- **Under-synchronization:** setup/update use explicit operational decision gates, but current concept taxonomy has no fitting lightweight concept for this pattern.
- **Over-synchronization:** none confirmed in current state.
- **Over-synchronization risk:** forcing setup/update into existing `Decision Point` as-is would overstate compliance, because evidence-tiering/provenance requirements do not match operational confirmation prompts.

## Priority Actions
1. Add a dedicated concept (for example, `Scope Boundary` / `Scope Authority`) to `plugins/cwf/references/concept-map.md` and map `setup` + `update` to it.
2. Add an update-side explicit warning/second confirmation when active context is non-user and selected target scope is `user`, before Codex reconciliation.
3. Decide concept treatment for operational prompts: either define a lightweight concept (recommended) or document an explicit exclusion rule in concept-map usage guidance.

<!-- AGENT_COMPLETE -->
