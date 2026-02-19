## Refactor Review: impl

### Summary
- Word count: 2,456 (well below the 3,000-word warning threshold)
- Line count: 446 (below the 500-line warning threshold)
- Resources: 2 total (references/agent-prompts.md, references/impl-gates.md); both are explicitly referenced by the SKILL
- Duplication: no overlapping guidance detected between SKILL.md and the companion references

### Findings
#### [medium] Add navigation aids to the reference files
**What**: `references/agent-prompts.md` (146 lines) and `references/impl-gates.md` (172 lines) both exceed the 100-line Resource Health threshold in `plugins/cwf/skills/refactor/references/review-criteria.md` Sect. 4 but lack a table-of-contents or section summary at the top, which makes it harder for implementers to jump directly to the implementation template, domain table, or each gate description. 
**Where**: `plugins/cwf/skills/impl/references/agent-prompts.md`, `plugins/cwf/skills/impl/references/impl-gates.md`
**Suggestion**: Add a brief TOC or quick section list (with anchors) to each file, so readers can navigate to the Implementation Agent Prompt Template, Domain Signal Table, Branch Gate, Clarify Gate, Commit Gate, etc., without scrolling through 150+ lines.

#### [medium] Plan discovery is brittle because it sorts by directory name
**What**: Phase 1.1 currently chooses the latest plan by sorting `.cwf/projects/*/plan.md` by directory name and picking the last entry, which assumes every project directory encodes a sortable date sequence. Repositories often create session folders with custom suffixes (e.g., `260217-05-full-skill-refactor-run`), so lexicographic ordering does not guarantee the truly most recent plan and can accidentally load an older or unrelated session.
**Where**: `plugins/cwf/skills/impl/SKILL.md:74-103`
**Suggestion**: Derive “most recent” from actual timestamps (plan frontmatter, `plan.md` metadata, or the directory’s modification time) or record the intended plan in the live-state/session-state and prefer that, falling back to directory naming only when the chronological signal is unambiguous.

### Suggested Actions
1. Add tables of contents (with anchors) to `references/agent-prompts.md` and `references/impl-gates.md` so readers can jump straight to the sections referenced in the SKILL (effort: small).
2. Strengthen Phase 1.1’s plan selection logic by relying on timestamps or live-state metadata rather than directory-name sorting; document the selection priority and fail fast when the chronological signal is ambiguous (effort: medium).

<!-- AGENT_COMPLETE -->
