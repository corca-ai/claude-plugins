# Next Session: S26 — Interactive Documentation Review (Post-S25 Day 2)

## Context Files to Read

1. `AGENTS.md` — operating invariants and document routing baseline
2. `docs/documentation-guide.md` — documentation principles and scope ownership
3. `docs/interactive-doc-review-protocol.md` — interactive review flow and chunking expectations
4. `plugins/cwf/skills/refactor/references/docs-criteria.md` — deterministic-vs-prose classification criteria
5. `docs/project-context.md` — project conventions and dependency-direction policy
6. `prompt-logs/260214-01-s25-post-s24-followup-retro-day2/retro.md` — deep retro conclusions and execution priorities
7. `prompt-logs/260214-01-s25-post-s24-followup-retro-day2/lessons.md` — latest session learnings
8. `README.md`, `README.ko.md`, `AI_NATIVE_PRODUCT_TEAM.md`, `AI_NATIVE_PRODUCT_TEAM.ko.md` — high-impact user-facing docs

## Task Scope

Continue repository documentation hardening via interactive review, starting from high-impact non-`prompt-logs` documents and applying the same review protocol used in S25 Day 2.

### What to Build

- Interactive review progress log (chunk-level): `prompt-logs/{new-session-dir}/interactive-doc-review-log.md`
- Prioritized doc change backlog with rationale and gate classification: `prompt-logs/{new-session-dir}/doc-change-backlog.md`
- Approved documentation edits and deterministic-gate updates in small, meaningful commits

### Key Design Points

- Review by meaningful chunks, not full-file dumps.
- For each chunk: capture intent, reviewer focus points, and change-risk notes.
- Classify findings first: `AUTO_EXISTING`, `AUTO_CANDIDATE`, `NON_AUTOMATABLE`.
- Keep `plugin -> repo` link coupling disallowed.
- Preserve `less is more` and `what/why > how` principles in always-loaded docs.

## Don't Touch

- Historical `prompt-logs/` artifacts (except writing the current session outputs)
- Generated index blocks unless explicitly regenerating via `cwf:setup`
- Runtime log exports under `prompt-logs/sessions*`

## Lessons from Prior Sessions

1. **Deterministic checks over prose reminders** (S25): recurring policy violations should be moved to lint/hooks/scripts, not restated in docs.
2. **Scope consistency matters** (S25): “lint passed” is unreliable unless manual checks and hook scopes match.
3. **Date rollover needs explicit handling** (S25 Day 2): session continuity and date-prefix semantics must be treated as protocol, not ad-hoc exceptions.
4. **Single-entry onboarding reduces drift** (S25 Day 2): `cwf:setup` should ask required choices instead of relying on user flag memory.

## Unresolved Items from S25 (Carry-Over)

- [ ] Define and document provenance freshness policy (`inform` vs `warn/stop`) for routine pushes
- [ ] Add deterministic fixture tests for date rollover and boundary-time semantics
- [ ] Decide whether to add `cwf:setup --audit-gates` mode for gate-state reporting
- [ ] Formalize commit-boundary split rule (`tidy` vs `behavior/policy`) in the review workflow
- [ ] Complete interactive review for remaining high-impact docs outside `prompt-logs`

## Success Criteria

```gherkin
Given the interactive review protocol and S25 retro priorities
When S26 reviews target docs in chunked order with explicit per-chunk discussion
Then each accepted change is classified as AUTO_EXISTING, AUTO_CANDIDATE, or NON_AUTOMATABLE before implementation

Given documentation findings that are automatable
When changes are implemented
Then enforcement is added/updated in deterministic gates (lint/hooks/scripts) rather than duplicated in prose

Given completion of the S26 review wave
When final validation runs
Then markdown lint, local link checks, and index coverage checks pass without regressions
```

## Dependencies

- Requires: S25 Day 2 retro outputs in `prompt-logs/260214-01-s25-post-s24-followup-retro-day2/`
- Blocks: broader documentation stabilization and subsequent release-readiness review

## Dogfooding

Discover available CWF skills via the plugin `skills/` directory and trigger descriptions, and use CWF skills for workflow stages instead of manual ad-hoc execution.

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat it as an instruction to execute this task scope directly.

- Branch gate:
  - Before implementation edits, check current branch.
  - If on a base branch (`main`, `master`, or repo primary branch), create/switch to a feature branch and continue.
- Commit gate:
  - Commit during execution in meaningful units (per work item or change pattern).
  - Avoid one monolithic end-of-session commit when multiple logical units exist.
  - After the first completed unit, run `git status --short`, confirm next commit boundary, and commit before starting the next major unit.
- Staging policy:
  - Stage only intended files for each commit unit.
  - Do not use broad staging that may include unrelated changes.

## Start Command

```text
@prompt-logs/260214-01-s25-post-s24-followup-retro-day2/next-session.md 시작합니다
```
