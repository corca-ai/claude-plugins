## Refactor Review: refactor

### Summary
- Word count: 2,312 (below all warning thresholds)
- Line count: 457 (below the 500-line warning)
- Resources: 8 primary resources (4 references + 4 scripts); 3 `.provenance` sidecars exist but are not mentioned anywhere, so they currently feel unreferenced
- Duplication: none observed

### Findings

#### [major] Provenance concept is claimed but not enforced
**What**: Concept-map Section 1.6 (Provenance) requires every reference to carry metadata about the creation context, comparison to the current system state, and a warning when the assumptions go stale. The refactor skill (SKILL.md:171-205) simply tells the agent to read the references/concept map but never mentions the `.provenance.yaml` sidecars or how to compare `skill_count`/`hook_count`/`last_reviewed` to the live session. Without that check the skill cannot detect stale guidance even though it claims to compose the Provenance concept.
**Where**: `plugins/cwf/skills/refactor/SKILL.md:171-205` plus the concept specification in `plugins/cwf/references/concept-map.md` Section 1.6.
**Suggestion**: After the “Read the SKILL.md and all files…” step (and anywhere else the references are consumed), add a Provenance verification step: read each `.provenance.yaml`, compare its `skill_count`/`hook_count`/`last_reviewed` to `cwf-live-state.sh`, and surface a warning or trigger a refresh when the delta exceeds a threshold. Recording this check and surfacing it to the user makes the Provenance concept actionable and prevents silent drift.

#### [minor] Provenance sidecars appear as unused resources
**What**: The files `references/docs-criteria.provenance.yaml`, `references/holistic-criteria.provenance.yaml`, and `references/review-criteria.provenance.yaml` live in the skill tree but their basenames are never referenced in SKILL.md. Review Criterion 4 (Resource Health) calls out unreferenced files as confusing additions to the resource set.
**Where**: `plugins/cwf/skills/refactor/references/*.provenance.yaml` with no mention in `plugins/cwf/skills/refactor/SKILL.md`.
**Suggestion**: Either remove/relocate the sidecars if they are no longer used, or add a short “Provenance metadata” subsection under References that explicitly links to them and describes their contents (e.g., `skill_count`, `hook_count`, `written_session`). That makes the inventory complete and supports the Provenance check described above.

### Suggested Actions
1. medium – Add an explicit Provenance verification step so the references consume the `.provenance.yaml` files, compare counts to the live state via `cwf-live-state.sh`, and warn when there is a significant delta (effort: medium).
2. small – Surface or retire the `.provenance.yaml` files so they are no longer unreferenced in the resource inventory (effort: small).

<!-- AGENT_COMPLETE -->
