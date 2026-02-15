# Lessons — S11a: Migrate retro → cwf:retro

## Session Learnings

### 1. Skill migration is straightforward when conventions are established

By S11a, the CWF skill migration pattern is well-established from S7-S10. The frontmatter convention (name, description with Triggers, allowed-tools), directory structure, and reference file organization are consistent. This made the migration mostly mechanical — the real value was in the two enhancements.

### 2. 2-batch design follows from reference file constraints

The Expert Lens guide explicitly states "Sections 1-4 provided by orchestrator" — this creates a hard dependency on CDM (Section 4) completing before Expert Lens can start. CDM and Learning Resources have no such dependency → Batch 1. Expert α and β both need CDM → Batch 2. The batch design emerges naturally from reading the reference docs carefully.

### 3. Persist hierarchy (eval > state > doc) inverts the natural tendency

The natural instinct is to persist findings as doc rules (add to CLAUDE.md or project-context.md). The eval > state > doc hierarchy forces asking "can a script catch this?" first, which produces more durable enforcement. This is a fundamental shift from document-first to automation-first thinking.
