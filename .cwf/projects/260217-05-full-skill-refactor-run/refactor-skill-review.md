# Refactor Review: review

## Summary
- Phase 2 of `review` (plugins/cwf/skills/review/SKILL.md:188-347) orchestrates six reviewers in a single batch, and the Expert α/β slots plus the Phase 4 Expert Roster Update (plugins/cwf/skills/review/SKILL.md:663-667) delegate updates to `expert-advisor-guide.md` (plugins/cwf/references/expert-advisor-guide.md:115-123). That workflow satisfies the Expert Advisor and Agent Orchestration rows listed for `review` in the concept map (plugins/cwf/references/concept-map.md, Section 2).
- The SKILL.md body currently clocks in at 4,567 words and 783 lines, which exceeds the review criteria thresholds of 3,000 words or 500 lines (plugins/cwf/skills/refactor/references/review-criteria.md, Section 1). This makes every trigger load a large procedural document and increases scheduler latency.
- Both `references/prompts.md` (145 lines) and `references/external-review.md` (209 lines) exceed the 100-line guideline from the review criteria resource-health checklist (plugins/cwf/skills/refactor/references/review-criteria.md, Section 4) but lack simple tables of contents, making it harder for an agent or maintainer to navigate these reference documents.

## Findings
### [warning] SKILL.md overwhelms the Progressive Disclosure budget (Criterion 1)
- The thresholds in review-criteria Section 1 were designed to keep the trigger payload light; at 4,567 words/783 lines, `plugins/cwf/skills/review/SKILL.md` now holds nearly 1.5× of the warning threshold and loads low-level recovery, CLI-error, and BDD blocks that could be offloaded. (See the dense Phase 2/3/4 instructions that span lines 188-691.)
- Suggestion: keep the SKILL.md narrative at the high-level workflow and move detailed CLI/error-handling sequences (external routing, error classification, gate invocation, BDD checks) into new reference files, linking from the body. This will reduce the on-trigger footprint and let the agent load the majority of the guidance only when needed.

### [warning] Large reference files need a quick TOC (Criterion 4)
- Both `plugins/cwf/skills/review/references/prompts.md` (145 lines) and `plugins/cwf/skills/review/references/external-review.md` (209 lines) exceed the >100-line file guideline stated in review-criteria Section 4 but currently start with a long prose body instead of an index. Without a brief table of contents or anchor list, the agent has to scan a 200-line document when only a particular checklist/module is needed.
- Suggestion: prepend each reference with a short table of contents (e.g., list the reviewer/persona sections and mode-specific checklists) that links to the relevant section. That satisfies the resource-health rule and helps future editors know where to extend the prompts without reading the whole file.

### [info] Concept integrity is intact for Expert Advisor + Agent Orchestration
- The review concept map (plugins/cwf/references/concept-map.md, Section 2) tags `review` with Expert Advisor and Agent Orchestration. Phase 2 (plugins/cwf/skills/review/SKILL.md:188-347) sets up the six-slot parallel run, enforces max-turn budgets/timeouts, and applies the context-recovery protocol, meeting the required behavior and actions for Agent Orchestration. The expert slots (lines 298-352 and 362-407) ground the Expert Advisor concept, and the Expert Roster Update (lines 663-667) plus the instructions in `expert-advisor-guide.md` (plugins/cwf/references/expert-advisor-guide.md:115-123) cover the required state/action updates. No additional concept gaps were detected.

## Suggested Actions
1. (Medium) Extract the lower-priority procedural blocks (external CLI failure handling, BDD acceptance checks, error classification tables) from SKILL.md into dedicated reference appendices so that the skill body stays within the 3,000-word/500-line Progressive Disclosure target. Provide concise summaries or links in SKILL.md to the new appendices.
2. (Small) Add a short table-of-contents or indexed list at the top of `references/prompts.md` and `references/external-review.md` so each file complies with the >100-line TOC requirement from the resource-health checklist. Include a line that references the contents from SKILL.md to keep the navigation contract explicit.

<!-- AGENT_COMPLETE -->
