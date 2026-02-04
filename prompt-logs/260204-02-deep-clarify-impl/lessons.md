# Lessons: deep-clarify Implementation

## Reference guide pattern: role → context → methodology → constraints → output

- **Expected**: Each reference guide needs unique structure tailored to its purpose
- **Actual**: The suggest-tidyings tidying-guide.md pattern (role statement → context → methodology → constraints → output format) works well for all four guides despite very different purposes (research, aggregation, advisory)
- **Takeaway**: When creating sub-agent instruction documents, the role → context → methodology → constraints → output pattern is a reliable skeleton

When writing sub-agent reference guides → start with the role/context/methodology/constraints/output skeleton, then customize

## SKILL.md as orchestrator vs executor

- **Expected**: SKILL.md would need detailed logic for each phase
- **Actual**: SKILL.md works best as a thin orchestrator that delegates to reference guides. The actual intelligence is in the guides — SKILL.md just sequences the phases and passes data between them. This kept SKILL.md at 230 lines (well under 500 limit) while the guides hold the domain knowledge.
- **Takeaway**: For multi-phase skills with sub-agents, SKILL.md should be a workflow coordinator, not an instruction manual

When designing multi-phase skills → keep SKILL.md as sequencer + data router, put domain knowledge in reference guides

## Advisory guide side-assignment needs to be deterministic

- **Expected**: Could just tell advisors "pick a side"
- **Actual**: Without deterministic side-assignment rules, both advisors might argue for the same side. The advisory-guide.md explicitly defines which side α and β take based on the conflict type (codebase vs best practice → α=codebase, β=best practice; both silent → α=conservative, β=innovative)
- **Takeaway**: When designing adversarial sub-agents, the conflict framing must be deterministic to guarantee genuine difference

When creating adversarial sub-agent pairs → define explicit, deterministic side-assignment rules based on the nature of the disagreement
