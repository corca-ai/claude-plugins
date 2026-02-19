# Impl Refactor Apply — Round 1

Date: 2026-02-17
Session: `.cwf/projects/260217-05-full-skill-refactor-run`
Stage: `impl`

## Scope
Applied medium-or-higher findings from per-skill deep refactor outputs:

- `refactor-skill-clarify.md`
- `refactor-skill-gather.md`
- `refactor-skill-handoff.md`
- `refactor-skill-hitl.md`
- `refactor-skill-impl.md`
- `refactor-skill-plan.md`
- `refactor-skill-refactor.md`
- `refactor-skill-retro.md`
- `refactor-skill-review.md`
- `refactor-skill-run.md`
- `refactor-skill-setup.md`
- `refactor-skill-update.md`

(`ship` had no structural change requirement)

## Implemented Changes (high level)

1. Clarify/Gather
- Added explicit `session_dir` resolution phase in `clarify` before `{session_dir}` artifact usage.
- Reduced duplicate research-method prose by routing prompt methodology to references.
- Added TOC to long clarify references.
- Tightened gather deterministic behavior for Generic URL fallback and `--local` Task output/provenance contract.

2. Handoff/HITL/Concept Map
- Collapsed duplicated handoff template prose to canonical `plan-protocol` reference usage.
- Added explicit missing-session-entry branch before `cwf-state.yaml` artifact updates.
- Extracted HITL schema details into dedicated reference and linked from SKILL.
- Added `hitl` concept mapping row and rationale in concept map.

3. Impl/Plan/Refactor/Run
- Added TOCs to impl references.
- Hardened impl plan discovery ranking (live-state pin → metadata timestamp → file mtime → dir-name tiebreaker).
- Moved duplicated plan structure to `plan-protocol` contract and expanded Decision Log metadata requirements.
- Added explicit provenance-sidecar verification steps and references in refactor SKILL.
- Added run-stage provenance checklist/log contract.
- Specified `review` verdict `Fail` handling and operationalized `explore-worktrees` mode.

4. Retro/Review/Setup/Update
- Linked retro expert-lens reference directly and added mandatory agreement/disagreement synthesis subsection.
- Moved retro dense gate/rules checklist into dedicated reference.
- Added TOCs to review reference files.
- Added setup post-install re-detection + `cwf-state.yaml` rewrite mandate.
- Trimmed setup Rules into invariant-oriented summaries.
- Made update changelog summary deterministic with concrete diff command sequence and README role note.

## Validation

- `npx --yes markdownlint-cli2` for 22 changed docs: **pass** (0 errors)
- `bash .claude/skills/plugin-deploy/scripts/check-consistency.sh cwf`: **gap_count 0**
- `bash plugins/cwf/scripts/provenance-check.sh --level inform --json`: **fresh 7/7**
- `bash plugins/cwf/scripts/check-run-gate-artifacts.sh --stage refactor --strict --session-dir .cwf/projects/260217-05-full-skill-refactor-run`: **pass 9 / warn 0 / fail 0**

## Notes

- Worker-generated exploratory plan artifacts were created under `.cwf/projects/260217-06-setup-update-scope-aware/` and kept untouched from this round's commits.
