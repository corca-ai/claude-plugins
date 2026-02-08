# S5b Lessons

## Implementation Notes

- **SKILL.md stays under 500 lines** (351 lines after adding all 4 phases) by delegating external reviewer details to `references/external-review.md` (221 lines). This follows the cheatsheet's "move details to references/" pattern.
- **Phase structure simplification**: The plan's 7 steps collapsed into a cleaner 4-phase flow in SKILL.md (Gather → Launch All → Collect → Synthesize) rather than having separate steps for each concern. This is more natural for the executing agent.
- **Provenance format unified**: Adding `duration_ms` and `command` to internal reviewer provenance (even as `—`) creates a consistent format across all 4 reviewers, simplifying synthesis template logic.
- **Bash command wrapping for external CLIs**: Using `START_MS/END_MS` pattern with meta files (`codex-meta.txt`) lets us capture both exit codes and timing without complex parsing. The `timeout 280` inside `Bash(timeout=300000)` gives a buffer for the outer timeout.
- **No code touched** in Phase 1 (gather target), internal reviewer prompts (Security/UX/DX role text), or verdict algorithm logic — as specified in the plan's "Do NOT touch" section.
- **Rule numbering**: Added Rule 7 (graceful degradation) without renumbering existing rules, maintaining backward compatibility with any references to Rule 1-6.
