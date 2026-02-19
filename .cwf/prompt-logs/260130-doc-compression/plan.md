# Plan: Documentation Compression

## Success Criteria

```gherkin
Given the documentation follows "less is more" and progressive disclosure principles
When I compare before/after line counts of modified files
Then net deletion is ~227+ lines without losing any script invocation details, env vars, or prerequisites
```

## Scope

P1 (gather-context dedup), P3 (clarify example), P5 (interview flow), P6 (retro sections), P7 (slack-to-md prereqs), P8 (skills-guide rename).

Excluded: P2 (README.md — intentional duplication for usability), P4 (CLAUDE.md — user preference).

## Result

Net 238 lines deleted (41 insertions, 279 deletions). All script invocation commands, env vars, and prerequisite info preserved.

## Deferred Actions

- [ ] None
