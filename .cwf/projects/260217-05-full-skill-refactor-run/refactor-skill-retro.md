# Refactor Review: retro

## Summary
- `retro` SKILL currently runs 3,108 words with a dense rules/gate block that repeats downstream requirements, pushing the document beyond the 3,000-word warning threshold and making it harder for agents to choose what to read. Splitting the procedural recipes (persist gates, post-retro reporting, rules checklist) into a dedicated reference or checklist would restore progressive disclosure.
- `plugins/cwf/skills/retro/references/expert-lens-guide.md` is never referenced from `SKILL.md` even though the README advertises it. The contents are therefore effectively dead weight and the skill has no single source of truth for Expert Lens expectations.
- Concept-map validation for Expert Advisor (`plugins/cwf/references/concept-map.md:11-33`) requires not only two expert analyses but an explicit synthesis of agreements/disagreements. `SKILL.md` (e.g., lines 183-191) only instructs agents to integrate each expert's output without guiding this synthesis, so the Expert Advisor concept is only half realized.

## Findings
### [warning] `SKILL.md` exceeds the 3,000-word lean threshold because it duplicates gated rules and stage policies
**What**: Section 4 through the “Rules” block repeats the same orchestration policies twice (deep-mode batching, gating, persistence notes, direct-invocation reporting) in prose before restating them as enumerated rules. The duplicates inflate the skill to 3,108 words/414 lines and weaken progressive disclosure.
**Where**: `plugins/cwf/skills/retro/SKILL.md:80-409`
**Suggestion**: Reserve `SKILL.md` for a high-level workflow summary and move the detailed gating/remediation checklist into a dedicated reference (e.g., `references/retro-gate-guide.md`) or append the current “Rules” block to that reference. Then have `SKILL.md` link to the reference rather than restating the same requirements twice.

### [warning] The Expert Lens reference file is orphaned
**What**: `references/expert-lens-guide.md` contains detailed identity/analysis guidance, but `SKILL.md` never mentions it, so agents never know to open it. The only pointer is `README.md`, which is not part of the skill execution path.
**Where**: `plugins/cwf/skills/retro/references/expert-lens-guide.md` (unused) and absence in `plugins/cwf/skills/retro/SKILL.md` search results
**Suggestion**: Either remove the redundant file or, preferably, point `SKILL.md` Section 5 (Expert Lens) to it for the “grounding requirements”/analysis format and collapse the explanatory text there. That way the skill keeps just a pointer and the heavy guidance lives in the reference, matching progressive disclosure.

### [warning] Expert Advisor concept lacks an explicit tension synthesis step
**What**: Concept map 1.1 says the Expert Advisor concept must “synthesize tension (surface agreements and disagreements)”, but Section 5 only instructs the agent to merge the expert outputs without that explicit step. Without it, retro outputs can devolve into two isolated expert write-ups instead of the contrasting insight the concept demands.
**Where**: `plugins/cwf/skills/retro/SKILL.md:183-191` (Expert Lens execution instructions) vs `plugins/cwf/references/concept-map.md:11-33` (Expert Advisor required actions)
**Suggestion**: Add a short “Synthesis” subbullet beneath Section 5 that asks agents to explicitly call out where Expert α and Expert β agreed/disagreed and what that tension means for the lessons/action items. This written synthesis can live in Section 5 of retro.md (e.g., a final paragraph or table) and satisfies the concept-map requirement.

## Concept Integrity
- **Agent Orchestration** is well-covered by the two-batch sub-agent design (batches described in `SKILL.md:89-147` with clear dependency ordering, gating, and context recovery), so the skill maintains the required work-item decomposition, batch plan, and output verification.
- **Expert Advisor** is partially covered (two experts, roster maintenance instructions, expert files) but currently skips the “synthesize tension” action mentioned in the concept map, so tightening Section 5 with an explicit synthesis paragraph would close the gap.

## Suggested Actions
1. **Extract the gating/rule checklist into a reference** (Medium effort). Create a short companion reference that contains the persistence gate checklist, direct-invocation reporting guidelines, and rules, then replace the duplicate prose in `SKILL.md` with a link plus a brief summary. This resolves the >3,000-word warning and reinforces progressive disclosure.
2. **Surface `expert-lens-guide.md` from SKILL** (Small effort). Point Section 5 (Expert Lens) explicitly to the existing reference (or merge its content into SKILL and keep the file for reuse) so that agents pulling the skill have a single canonical location for the expert-grounding rules and the unused file no longer lingers.
3. **Add an explicit synthesis step for Expert Lens outputs** (Small effort). After describing the two expert sections, require a short subsection that contrasts the experts, calls out agreements/disagreements, and derives the action/persistence implications. This aligns the skill with the Expert Advisor concept map and makes the retro narrative easier to audit.

<!-- AGENT_COMPLETE -->
