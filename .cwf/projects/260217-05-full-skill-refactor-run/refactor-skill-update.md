## Refactor Review: update skill

### Summary
- Word count: 382 (below warning thresholds).
- Line count: 112 (well below the 500-line guideline).
- Resources: 2 total files (`SKILL.md`, `README.md`), of which 1 is unreferenced from the SKILL.
- Duplication: none detected (no overlapping sections between SKILL and supplemental files).

### Findings
#### [low] README.md is effectively invisible to readers
**What**: `README.md` enumerates the directory contents but is never mentioned from `SKILL.md`, so readers may wonder why the file exists or miss the intended file map.
**Where**: `plugins/cwf/skills/update/README.md`
**Suggestion**: either cite the README from the SKILL (e.g., “See README.md for the file map”) or delete/merge it if it no longer adds value.

#### [medium] Phase 3 directions allow high variance in the change summary step
**What**: The instruction “list new/modified skills by comparing directory structure” lacks concrete commands or criteria, which can lead to inconsistent outputs and uncertain verification when aligning the changelog summary with the actual update delta.
**Where**: `plugins/cwf/skills/update/SKILL.md`, Phase 3: Changelog Summary.
**Suggestion**: add a deterministic example (for instance `git diff --name-only {old_state} {new_state} plugins/cwf/skills` or a helper script that lists the directories that changed between versions) so the change summary is repeatable.

### Suggested Actions
1. Link to or remove `README.md` so every supplementary file is intentional and discoverable (effort: small).
2. Formalize Phase 3’s diff step with an explicit command or short script snippet to reduce friction when summarizing new/modified skills (effort: small to medium).

<!-- AGENT_COMPLETE -->
