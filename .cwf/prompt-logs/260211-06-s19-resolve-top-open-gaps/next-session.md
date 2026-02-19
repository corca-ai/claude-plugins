# Next Session: S20 — Close Remaining Open Gap Set

## Context Files to Read
1. `prompt-logs/260211-06-s19-resolve-top-open-gaps/plan.md`
2. `prompt-logs/260211-06-s19-resolve-top-open-gaps/impl-validation.md`
3. `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md`
4. `prompt-logs/260211-05-s18-v3-gap-analysis-execution/discussion-backlog.md`
5. `cwf-state.yaml`

## Task Scope
Close the next unresolved decision-backed backlog items after BL-001/002/003 completion, prioritizing semantic closure quality over artifact-only completion.

### What to Build
- GAP-003 dedicated closure trace (DEC-003)
- GAP-006 hybrid sub-agent persistence gate implementation status check (DEC-006)
- GAP-014 minimal semantic extension for `check-session.sh` (DEC-007)

### Key Design Points
- Keep DEC-004 as policy-level only (no hard gate unless explicitly changed).
- Preserve backward compatibility while adding semantic checks incrementally.

## Don't Touch
- Already-resolved BL-001/002/003 behavior unless regression is found.
- Historical prompt logs outside S18/S19 evidence scope.

## Lessons from Prior Sessions
1. **Artifact flow fixes require both ends** (S19): producer/consumer mismatch leaves hidden blind spots.
2. **Mention-only can be executable** (S19): next-session contracts may be command-like, not informational.

## Success Criteria

```gherkin
Given GAP-003/006/014 are still open after S19
When S20 executes decision-backed closure work
Then each item is either resolved with explicit evidence or kept open with concrete, testable next action
```

## Dependencies
- Requires: S19 implementation artifacts and validations
- Blocks: v3 merge confidence sign-off for remaining open gaps

## Dogfooding
Discover available CWF skills via `plugins/cwf/skills/*/SKILL.md` and use CWF stages instead of ad-hoc execution.

## Start Command

```text
@prompt-logs/260211-06-s19-resolve-top-open-gaps/next-session.md 시작합니다
```
