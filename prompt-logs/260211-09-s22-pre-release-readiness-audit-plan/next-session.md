# Next Session: S24 — Interactive Step 4 Walkthrough + Final Go/No-Go

## Context

S23 completed concerns 1-3 with full pre-Step4 artifacts and an explicit blocker set.
The next session should execute concern 4 interactively with the user, then produce
`onboarding-scenario.md` and final `readiness-report.md`.

## Decision Locks (Confirmed in S23 Close)

The following decisions are fixed unless explicitly reopened by the user:

1. Release gate policy: **No-Go remains fixed until Concern 1-3 blockers are resolved**.
2. README scope for next implementation: **minimal framing patch first** (`is / is-not / assumptions / decisions+why` + inventory sync), not full rewrite.
3. Self-containment issue handling: **treat as release blocker** (not post-release debt).
4. PR handling for S23 package: **merge now** (documentation/audit package; no runtime behavior change).

## Context Files to Read First

1. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readiness-prestep4.md`
2. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/refactor-evidence.md`
3. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/skill-coverage-matrix.md`
4. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/script-coverage-matrix.md`
5. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readme-framing-audit.md`
6. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/discoverability-audit.md`
7. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/step4-interactive-prompt.md`
8. `README.md`
9. `README.ko.md`
10. `AGENTS.md`
11. `cwf-index.md`

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat that as an instruction to execute
S24 interactive onboarding walkthrough work immediately.

- Required strategy: user-collaborative walkthrough with evidence-backed decisions
- Branch gate:
  - Before implementation edits, check current branch.
  - If on `main`/`master` (or repo primary branch), create/switch to a feature branch and continue.
- Commit gate:
  - Commit in meaningful units during execution (not monolithic at the end).
  - After the first completed unit, run `git status --short`, confirm next commit boundary, and commit before the next major unit.
- Staging policy:
  - Stage only files for the current unit; avoid broad staging.
- Scope gate:
  - Treat Step 4 as explicitly interactive; ask user at branch decisions.
  - Do not auto-resolve subjective onboarding-path choices.
  - Apply the Decision Locks above by default during synthesis.
- Required outputs for this run:
  - `onboarding-scenario.md`
  - `readiness-report.md`
- Completion policy:
  - final Concern 1-4 status with explicit Go/No-Go
  - register session state and run `scripts/check-session.sh --impl`

## Task

Execute concern 4 as an interactive first-user walkthrough, then produce final
release-readiness decision artifacts.

## Success Criteria

```gherkin
Given S23 pre-Step4 blocker snapshot and evidence package
When S24 performs user-interactive onboarding walkthrough
Then onboarding-scenario.md captures command-level flow, forks, and friction with severity

Given all four concerns are complete after Step 4
When synthesis is finalized
Then readiness-report.md contains explicit Go/No-Go with blocker rationale
```

## Start Command

```text
@prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/next-session.md 시작합니다
```
