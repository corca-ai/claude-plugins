# S14 — Integration Test + Final Cleanup

## Context

Final verification session for marketplace-v3 branch (S0-S33, 24 sessions).
Merge to main is deferred — user has additional pre-merge work.

## Goal

Verify all CWF skills and hooks work correctly, produce migration decisions
document, and clean up any remaining issues.

## Scope

Items #1-6 from next-session.md. Merge (#7) excluded per user request.

## Commit Strategy

Per change pattern — group by logical unit:
1. Cleanup fixes (if any) → one commit
2. v3-migration-decisions.md → one commit
3. Session artifacts → one commit

## Steps

### Step 1: S33 CDM Action Item Verification

Static verification of 5 CDM items applied in S33:

1. **Clarify depth heuristic** — verify Mode Selection section in clarify/SKILL.md
2. **Plan Commit Strategy** — verify required section in plan/SKILL.md
3. **Preparatory refactoring check** — verify 300+/3+ threshold in plan/SKILL.md
4. **check-session.sh gate** — verify in impl/SKILL.md Phase 4.5 and run/SKILL.md Phase 3
5. **Web Research Protocol** — verify shared protocol reference exists

### Step 2: cwf:run Logic Verification

Static verification of run/SKILL.md:
- Stage definition table (8 stages, correct skill invocations)
- `--from` flag: prerequisite checks
- `--skip` flag: composability with `--from`
- User gates (pre-impl) vs auto gates (post-impl) — Decision #19
- Review failure handling (max 1 auto-fix attempt)

### Step 3: Compact Recovery Test

Run compact-context.sh with current cwf-state.yaml live section:
- Verify JSON output contains session_id, phase, task, key_files
- Verify phase-aware enrichment (plan.md injection when phase=impl)
- Verify decision journal injection

### Step 4: Review Fail-Fast Verification

Verify error-type classification logic in review/SKILL.md:
- CAPACITY patterns: 429, ResourceExhausted, quota
- INTERNAL patterns: 500, InternalError
- AUTH patterns: 401, UNAUTHENTICATED
- Correct action per type (fail-fast, retry, abort)

### Step 5: Cross-Reference and Cleanup Check

- Check for remaining references to deleted standalone plugins
- Verify all cross-references between skills are valid
- Check marketplace.json consistency

### Step 6: Produce docs/v3-migration-decisions.md

Synthesize key decisions from S0-S33 into a standalone reference document.
Source: master-plan.md decisions #1-#20, session lessons, cwf-state.yaml history.

## Success Criteria

### Behavioral (BDD)

```gherkin
Given the clarify/SKILL.md Mode Selection section
When input has all 3 specificity markers (files + changes + criteria)
Then depth is "AskUserQuestion only"

Given cwf:run with --from impl --skip retro
When the pipeline initializes
Then impl starts (skipping gather/clarify/plan/review-plan) and retro is skipped

Given compact-context.sh with populated live section (phase=impl)
When the hook executes
Then output JSON contains plan summary and decision journal entries

Given review/SKILL.md error-type classification
When stderr contains "429" or "ResourceExhausted"
Then action is CAPACITY: fail-fast, immediate fallback, no retry

Given the marketplace-v3 branch
When checked for deleted plugin references
Then no broken cross-references remain
```

### Qualitative

- v3-migration-decisions.md is useful as a standalone reference
- All CDM action items from S33 are properly integrated
- No regressions in skill SKILL.md content

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| docs/v3-migration-decisions.md | Create | Migration decisions reference |
| prompt-logs/260211-01-s14-integration-test/plan.md | Create | This plan |
| prompt-logs/260211-01-s14-integration-test/lessons.md | Create | Session learnings |

## Don't Touch

- Plugin skill implementations that are already working (only report issues)
- External files outside the repository
