# Phase Handoff: S13.5-B3 Plan → Implementation

> Source phase: clarify + orthogonality analysis + plan design
> Target phase: implementation
> Written: 2026-02-09

## Context Files to Read

1. `CLAUDE.md` — project-level behavioral rules
2. `cwf-state.yaml` — current project state, expert roster
3. `prompt-logs/260209-27-s13.5-b3-concept-refactor/plan.md` — implementation plan (WHAT)
4. `prompt-logs/260209-27-s13.5-b3-concept-refactor/lessons.md` — session lessons so far
5. `prompt-logs/260209-26-s13.5-b2-concept-distillation/concept-distillation.md` — source material for concept-map.md (sections 2 and 4)
6. `plugins/cwf/skills/refactor/SKILL.md` — current refactor skill to modify
7. `plugins/cwf/skills/refactor/references/review-criteria.md` — deep review criteria to restructure
8. `plugins/cwf/skills/refactor/references/holistic-criteria.md` — holistic analysis to restructure
9. `plugins/cwf/references/skill-conventions.md` — shared conventions (context for Axis 1)

## Design Decision Summary

**Problem**: S13.5-B2 proposed 3 integration points for concept-based analysis in
refactor. During planning, orthogonality analysis revealed existing holistic
dimensions and deep review criteria are themselves not fully orthogonal.

**Solution**: Full restructuring of both frameworks, not just addition of concept
analysis.

**Key decisions**:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Holistic structure | Form / Meaning / Function (3 axes) | Semiotic decomposition is principled and orthogonal. Existing Boundary Issues dissolved into Axes 2+3 |
| Deep Review structure | Merge criteria 4+5, add Concept Integrity → 8 criteria, 4+4 | Criteria 4 unused check ⊂ criteria 5. Balanced agent split |
| concept-map.md location | `plugins/cwf/references/` | Project-level architectural document. Same pattern as skill-conventions.md |
| 4th holistic agent | NOT added | Synchronization Analysis is not orthogonal to existing dimensions. Concept analysis absorbed into Axis 2 |

## Protocols to Follow

1. **All code fences must have language specifier** — enforced by `.markdownlint.json`. Never use bare fences.
2. **Read each file before editing** — CLAUDE.md requires this. Do not propose changes to code you haven't read.
3. **concept-map.md extraction from distillation**: For each of the 6 generic concepts, extract from concept-distillation.md Section 2:
   - Purpose (1 sentence)
   - Required behavior (from operational principle — what the concept MUST do)
   - Required state (from State section)
   - Required actions (from Actions section)
   - Format for verification, not for explanation. Agent needs to check "does the skill do X?" not "understand what X means."
4. **holistic-criteria.md is a REWRITE, not an edit**: The existing 3 sections are replaced entirely. Use the mapping below:
   - Old PP 1a, 1b → New Axis 1 (Convention Compliance) sections 1a, 1b
   - Old PP 1c structural subset → New Axis 1 section 1c
   - Old PP 1c behavioral subset + old BI functional duplication → New Axis 2 (Concept Integrity)
   - Old MC all + old BI trigger/hook items → New Axis 3 (Workflow Coherence)
5. **review-criteria.md is a RESTRUCTURE**: Preserve existing content where possible, merge 4+5, renumber, add section 8.
6. **SKILL.md updates are EDITS**: Change agent prompt descriptions, criteria ranges, dimension names, and references section. Do not rewrite entire modes.
7. **Provenance sidecars**: update `last_reviewed` and `designed_for` in existing sidecars. Create new sidecar for concept-map.md.
8. **Record lessons incrementally** — don't wait until end. Update lessons.md as discoveries emerge during implementation.

## Do NOT

- Do NOT modify individual `plugins/cwf/skills/*/SKILL.md` files (except `refactor`)
- Do NOT modify `plugins/cwf/references/expert-advisor-guide.md` or `expert-lens-guide.md`
- Do NOT modify `scripts/` directory (including `provenance-check.sh`)
- Do NOT modify hook configurations
- Do NOT modify `README.md` or `README.ko.md`
- Do NOT add phase handoff output to plan.md — keep WHAT and HOW separate
- Do NOT change refactor's Quick Scan or Code Tidying or Docs Review modes — only Deep Review and Holistic modes change
- Do NOT add a 4th holistic agent — the design is 3 agents with restructured dimensions
- Do NOT add a 3rd deep review agent — the design is 2 agents with 4+4 criteria split

## Implementation Hints

- **Holistic criteria "How to report" and "Important constraints" sections**: Preserve the reporting format guidance from existing criteria. Each new sub-section should have its own "How to report" with concrete examples.
- **Holistic provenance comment**: The existing HTML comment `<!-- Provenance: written at 5 skills... -->` should be updated to reflect the restructuring context.
- **SKILL.md holistic agent prompts** (lines ~207-230): Each agent prompt includes the condensed inventory map, the relevant criteria section content, and specific instructions. Update dimension names and add concept-map.md to Agent B's prompt.
- **SKILL.md deep review agent prompts** (lines ~138-155): Agent A receives criteria sections by number range. Update from "1-5" to "1-4" and Agent B from "6-8" to "5-8".
- **concept-map.md Usage Guide section**: Must clearly distinguish deep review usage (per-skill: look up skill's row, check each concept) from holistic usage (cross-skill: look up concept's column, compare implementations).
- **Provenance-check.sh compatibility**: The script finds `.provenance.yaml` files via `find`. New sidecar at `plugins/cwf/references/concept-map.provenance.yaml` will be auto-detected. No script changes needed.

## Success Criteria

(Same as plan.md — copied here for implementation agent convenience)

```gherkin
Given the restructured holistic-criteria.md with Form/Meaning/Function axes
When refactor --holistic runs cross-plugin analysis
Then 3 agents analyze Convention Compliance, Concept Integrity, and Workflow Coherence respectively
  And no finding legitimately belongs in two dimensions simultaneously

Given the restructured review-criteria.md with 8 criteria (merged 4+5, added Concept Integrity)
When refactor --skill <name> runs deep review
Then Agent A evaluates criteria 1-4 (Structural)
  And Agent B evaluates criteria 5-8 (Quality+Concept)
  And Criterion 8 verifies claimed concept composition against implementation

Given concept-map.provenance.yaml with skill_count=9
When a 10th skill is added to CWF
Then provenance-check.sh detects staleness in concept-map.md
```
