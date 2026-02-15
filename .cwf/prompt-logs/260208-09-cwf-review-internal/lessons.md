# S5a Lessons: cwf:review Internal Reviewers

## Session Info

- **Date**: 2026-02-08
- **Branch**: marketplace-v3
- **Goal**: Implement `/review` skill with Security + UX/DX internal reviewers

## Takeaways

1. **Self-review works well as dogfooding** — running the newly created `/review` skill
   on itself immediately caught 3 concrete issues (hardcoded branch, missing Write tool,
   undefined --scenarios flag). This validates the "deliberate naivete" principle.

2. **Security + UX/DX perspectives are complementary** — Security found no blocking issues
   (prompt orchestration has minimal attack surface), while UX/DX caught usability gaps.
   Both perspectives are necessary even for "safe" code.

3. **Severity definitions matter** — without explicit definitions for `critical/security/moderate`,
   reviewers assigned severity inconsistently. Adding definitions to prompts.md fixed this.

4. **Base branch hardcoding is fragile** — `marketplace-v3` will be deleted after merge.
   Dynamic detection via `git symbolic-ref` or branch existence check is more robust.

## Mistakes & Corrections

1. **Initially omitted `Write` from allowed-tools** — Rule 5 says "don't write unless asked"
   but the skill needs the capability when the user does ask. Fixed by adding `Write`.

2. **`--scenarios` in error table without context** — mentioned "S10+" which is opaque
   internal milestone jargon. Fixed by describing the feature purpose.

## Patterns Discovered

1. **Prompt template with XML structure** — reviewer output format with explicit sections
   (Concerns/Suggestions/Criteria/Provenance) produces well-structured sub-agent output.
   Both reviewers followed the format consistently.

2. **Review-driven development** — creating the skill, then immediately reviewing it with
   the skill itself creates a tight feedback loop. The review findings directly improved
   the implementation quality.

3. **Parallel Task agents work reliably** — launching two `general-purpose` sub-agents
   in a single message produced parallel execution. Total review completed in ~65s
   (wall clock of the slower agent).
