# Lessons — Clarify v2

## Implementation Learnings

- **Source material reuse**: aggregation-guide.md and advisory-guide.md were nearly verbatim from deep-clarify — the original design was clean enough to port directly.
- **research-guide.md merge**: Combining codebase and bestpractice guides into one file with sections works well — single reference point instead of two.
- **questioning-guide.md is the real new content**: This is where interview's methodology (why-digging, tension detection) and clarify v1's ambiguity categories got merged into a cohesive methodology.
- **SKILL.md at 309 lines**: Well within 500-line budget. Progressive disclosure works — detail lives in reference files.
- **gather-context integration path**: The Path A/B split (with/without gather-context) keeps the SKILL.md readable. Key insight: Explore agent for codebase research, general-purpose for web research.
- **Advisory sub-agents use haiku model**: Cost-effective for opinion generation — they don't need the full model's capability.
- **README deprecation pattern**: Following the same pattern as web-search → gather-context deprecation. Consistent UX for users migrating.

## Testing Insights

- **`--plugin-dir` doesn't isolate**: Session's existing plugins still load alongside `--plugin-dir` plugins, so testing "without gather-context" requires a clean environment (no gather-context installed). Acceptable for validation since real users without gather-context simply won't see it in their system prompt.
- **`--print` mode for fast verification**: Using `claude --print` for non-interactive tests is efficient. Confirms skill loading, frontmatter parsing, and workflow understanding without full interactive sessions.
- **Phase 1 output quality**: Even with `--print`, the model produced a thorough 10-item ambiguity breakdown for "add caching" — shows the questioning-guide.md categories are being picked up correctly.

## Architecture Observations

- **Plugin consolidation payoff**: 3 plugins → 1 plugin reduces user confusion ("which clarify do I use?"). The `--light` flag preserves the lightweight path for users who want it.
- **Defensive gather-context check via system prompt inspection**: Checking "does `/gather-context` appear in available skills" is a clean runtime detection mechanism — no file system checks needed, works across installation methods.
- **4-reference-file architecture**: aggregation, advisory, research, questioning — each has a clear single responsibility. SKILL.md orchestrates, references provide depth.

## Collaboration

- **Plan execution mode**: When the user provides a full plan and says "Implement", execute without confirmation. Discrepancy handling → added to CLAUDE.md (record in lessons.md, report, ask for decision).
- **Post-implementation chain**: User expects "test → commit → lessons → retro" as a single chain, not separate requests. Follow through without waiting for intermediate confirmations.
