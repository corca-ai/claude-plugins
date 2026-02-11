# Next Session: S24 — Resolve No-Go Blockers First, Then Interactive Step 4

## Context

S23 produced a full pre-Step4 evidence package and confirmed Concern 1-3 blockers.
The next session must run in two phases:

1. **Phase A (first)**: detailed No-Go remediation discussion and actual implementation.
2. **Phase B (after A)**: interactive Step 4 walkthrough and final readiness synthesis.

This ordering is intentional: interactive validation should happen **after** blocker
reduction work is implemented.

## Decision Locks (Confirmed in S23 Close)

The following decisions are fixed unless explicitly reopened by the user:

1. Release gate policy: **No-Go remains fixed until Concern 1-3 blockers are resolved**.
2. README scope for next implementation: **minimal framing patch first** (`is / is-not / assumptions / decisions+why` + inventory sync), not full rewrite.
3. Self-containment issue handling: **treat as release blocker** (not post-release debt).
4. Phase ordering lock: **No-Go remediation implementation first, interactive walkthrough second**.

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
S24 phase-ordered work immediately (**Phase A -> Phase B**).

- Required strategy: blocker-first remediation, then user-interactive walkthrough
- Branch gate:
  - Before implementation edits, check current branch.
  - If on `main`/`master` (or repo primary branch), create/switch to a feature branch and continue.
- Commit gate:
  - Commit in meaningful units during execution (not monolithic at the end).
  - After the first completed unit, run `git status --short`, confirm next commit boundary, and commit before the next major unit.
- Staging policy:
  - Stage only files for the current unit; avoid broad staging.

### Phase A — No-Go Remediation (discussion + implementation)

- Required work:
  - produce a detailed remediation decision log (scope, trade-offs, acceptance gates)
  - implement agreed remediation changes for Concern 1-3 blockers (per Decision Locks)
  - re-check blocker status with file-level evidence
- Required outputs:
  - `no-go-remediation-plan.md`
  - `no-go-remediation-impl.md`
  - updated evidence docs if findings changed
- Phase gate:
  - after Phase A, present residual blocker status and ask user confirmation to proceed to Phase B.

### Phase B — Interactive Step 4

- Required work:
  - run first-user walkthrough interactively with user branch decisions
  - produce final synthesis using post-remediation state
- Required outputs:
  - `onboarding-scenario.md`
  - `readiness-report.md`

- Completion policy:
  - final Concern 1-4 status with explicit Go/No-Go
  - register session state and run `scripts/check-session.sh --impl`

## Task

Execute blocker-remediation discussion and implementation first, then run
interactive Step 4 walkthrough and produce final readiness artifacts.

## Success Criteria

```gherkin
Given S23 pre-Step4 blocker snapshot and decision locks
When S24 executes Phase A remediation discussion and implementation
Then no-go-remediation-plan.md and no-go-remediation-impl.md capture decisions, applied changes, and residual blocker status

Given Phase A output and updated repository state
When S24 executes Phase B interactively with the user
Then onboarding-scenario.md and readiness-report.md reflect post-remediation behavior and final Go/No-Go rationale
```

## Start Command

```text
@prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/next-session.md 시작합니다
```
