## Refactor Review: plan

### Summary
- Word count: 1,705 (well below the 3,000-word warning cut-off)
- Line count: 351 (below the 500-line warning threshold)
- Resources: 0 supporting `references/`, `scripts/`, or `assets/` files are bundled with the skill (only a README exists)
- Duplication: the Required Plan Sections, Success Criteria format, and artifact-writing rules in `plugins/cwf/skills/plan/SKILL.md:214-332` repeat the same guidance already captured in `plugins/cwf/references/plan-protocol.md:5-90`

### Findings

#### [medium] Duplicate plan structure rules bleed into the SKILL instead of staying in plan-protocol
**What**: The skill contains a long verbatim block spelling out the plan sections, BDD/qualitative success criteria, artifact tables, and artifact-writing rules that the reference already defines. That duplication increases the chance of divergence when the protocol changes and bloats the SKILL body, working against Progressive Disclosure.
**Where**: `plugins/cwf/skills/plan/SKILL.md:214-332` ↔ `plugins/cwf/references/plan-protocol.md:5-90`
**Suggestion**: Replace the block in the SKILL with a concise summary and an explicit pointer to the reference (e.g., “Follow the plan & lessons protocol in `plan-protocol.md` for sections, success criteria, and artifact placement”); keep only the few skill-specific reminders that are not already documented upstream.

#### [minor] Decision Log template omits the explicit evidence/resolution metadata required by Decision Point
**What**: The Decision Log section currently asks only for #/Decision/Rationale/Alternatives. Concept Integrity Criterion 8 (Decision Point) mandates capturing evidence per point plus a resolution record (decision, decided-by, evidence cited) so the plan can be audited and tiered correctly.
**Where**: `plugins/cwf/skills/plan/SKILL.md:256-274` versus the Decision Point guaranteed state/actions listed in `plugins/cwf/references/concept-map.md:85-107`
**Suggestion**: Expand the Decision Log table to include columns such as Evidence (source file/agent output/tier) and Status/Resolved By, or explicitly require each entry to cite the evidence used and the authority that closed it, ensuring the log satisfies the Decision Point contract.

### Suggested Actions
1. Replace the duplicated plan-section block with a short summary plus a reference call-out to `plan-protocol.md`, keeping the SKILL focused on the gating narrative (Effort: small).
2. Extend the Decision Log template to surface evidence/source/tier/resolution metadata so Decision Point tracking meets the concept-map requirements (Effort: medium).

<!-- AGENT_COMPLETE -->
