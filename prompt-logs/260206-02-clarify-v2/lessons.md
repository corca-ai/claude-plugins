# Lessons — Clarify v2

## Implementation Learnings

- **Source material reuse**: aggregation-guide.md and advisory-guide.md were nearly verbatim from deep-clarify — the original design was clean enough to port directly.
- **research-guide.md merge**: Combining codebase and bestpractice guides into one file with sections works well — single reference point instead of two.
- **questioning-guide.md is the real new content**: This is where interview's methodology (why-digging, tension detection) and clarify v1's ambiguity categories got merged into a cohesive methodology.
- **SKILL.md at 309 lines**: Well within 500-line budget. Progressive disclosure works — detail lives in reference files.
- **gather-context integration path**: The Path A/B split (with/without gather-context) keeps the SKILL.md readable. Key insight: Explore agent for codebase research, general-purpose for web research.
- **Advisory sub-agents use haiku model**: Cost-effective for opinion generation — they don't need the full model's capability.
- **README deprecation pattern**: Following the same pattern as web-search → gather-context deprecation. Consistent UX for users migrating.
