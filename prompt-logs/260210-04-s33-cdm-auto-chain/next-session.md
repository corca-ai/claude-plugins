# Next Session: S14 — Integration Test + Main Merge

## Context

- Read: `cwf-state.yaml` (session history, live state)
- Read: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` (full roadmap, S14 row)
- Read: `docs/project-context.md` (design principles, process heuristics)
- Branch: `marketplace-v3`

## Task

Integration test the full CWF plugin, produce v3 migration decisions doc,
and merge marketplace-v3 to main.

## Scope

1. **End-to-end workflow test**: Run `cwf:run` on a small real task to verify
   the full pipeline (gather → clarify → plan → review → impl → review → retro → ship)

2. **cwf:run smoke test**: Verify `--from`, `--skip` flags, user gate behavior,
   and review failure handling

3. **Compact recovery test**: Simulate auto-compaction during impl phase,
   verify decision journal and plan.md content are injected

4. **Review fail-fast test**: Trigger a CAPACITY error scenario (if possible)
   or verify the error-type classification logic manually

5. **Produce `docs/v3-migration-decisions.md`**: Synthesize key decisions and
   lessons from S0-S33 into a single reference document

6. **Final cleanup**:
   - Check for any remaining references to deleted standalone plugins
   - Verify all cross-references between skills are valid
   - Run `cwf:refactor --holistic` as final quality gate

7. **Merge to main**: Create PR with comprehensive body, merge marketplace-v3

## Don't Touch

- Plugin implementations that are already working — only fix issues found
  during integration testing
- External files outside the repository

## Success Criteria — Behavioral (BDD)

- Given cwf:run with a task description, When the pipeline executes,
  Then all 8 stages complete (or are explicitly skipped) without errors
- Given a compact recovery during impl phase, When the hook fires,
  Then decision journal entries appear in the recovery context
- Given the marketplace-v3 branch, When merged to main,
  Then no broken cross-references remain and markdownlint reports 0 errors

## Success Criteria — Qualitative

- v3-migration-decisions.md is useful as a standalone reference for
  understanding the CWF architecture decisions
- The merge PR body accurately summarizes the full S0-S33 journey
- No regressions in existing skill functionality

## Dependencies

- Requires: S33 completed (CDM improvements + auto-chaining)
- Blocks: Nothing — this is the final session for marketplace-v3

## After Completion

1. Write plan.md, lessons.md, retro.md in session dir
2. Update `cwf-state.yaml`: add S14 session entry, set workflow.current_stage to "launch"
3. Update master-plan.md S14 row to "(done)"
4. Merge marketplace-v3 → main

## Start Command

```text
@prompt-logs/260210-04-s33-cdm-auto-chain/next-session.md 시작합니다
```
