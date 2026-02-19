# Next Session — Deferred Action Closure (S260217-05 Follow-up)

## Context Files to Read

1. [AGENTS.md](../../../AGENTS.md) — repository invariants and execution rules.
2. [docs/plugin-dev-cheatsheet.md](../../../docs/plugin-dev-cheatsheet.md) — plugin workflow and verification habits.
3. [.cwf/cwf-state.yaml](../../cwf-state.yaml) — session registry and live pipeline state.
4. [plan.md](plan.md) — baseline plan and constraints for S260217-05.
5. [review-synthesis-code.md](review-synthesis-code.md) — code review closure and optional improvements.
6. [run-ambiguity-decisions.md](run-ambiguity-decisions.md) — deferred backlog IDs D1/D4/D5.
7. [retro.md](retro.md) — deep retrospective synthesis and deferred architecture actions.
8. [ship.md](ship.md) — current merge status and follow-up framing.
9. [impl-refactor-apply-round2.md](impl-refactor-apply-round2.md) — exact fixes applied in post-review round.

## Task Scope

Close all deferred actions from S260217-05 and leave no unresolved follow-up debt related to run/review orchestration integrity.

### What to Build

1. **D1 — Run/Review Gate Ownership Unification**
- Unify ownership and closure logic for review-related gates so `run` orchestration and deterministic gate scripts no longer duplicate or drift.

2. **D4 — Context-Recovery Registry**
- Introduce a machine-readable registry artifact for recovery-critical session outputs, ownership, freshness, and required checks.

3. **D5 — Plan→Handoff Ready Signal Automation**
- Add deterministic ready-signal generation and verification so handoff readiness is machine-checked, not prose-interpreted.

4. **Semantic Provenance Validator (deferred from review/retro)**
- Extend provenance checks beyond schema presence to semantic validity (Stage→Skill mapping, outcome enum, timestamp/duration shape, row coverage).

5. **Unattended-Path Contract for Interactive Branches (deferred from retro)**
- Define and enforce behavior for interactive branches (`explore-worktrees`, handoff missing-entry branches) when auto/unattended execution is requested.

6. **Refactor Provenance Escalation Policy (deferred from retro)**
- Upgrade `inform`-only stale provenance handling into threshold-based warn/block behavior.

7. **Decision Journal Persistence and Replay Gate (deferred from retro)**
- Persist gate-relevant decisions in `decision_journal` and add replay validation on resume/compact recovery.

8. **Concept-Provenance Drift Regression Check (deferred from retro)**
- Add a deterministic check to catch mismatch between declared concept-map provenance counters and live inventory.

### Key Design Points

- Deterministic scripts are pass/fail authority; prose only explains rationale.
- New contracts must be resumable from persisted artifacts after compact/restart.
- Interactive flows must explicitly define non-interactive fallback behavior.
- Each deferred action must end with a concrete verification command and expected pass condition.

## Don't Touch

- Do not modify unrelated skills or docs outside this closure scope.
- Do not rewrite historical session artifacts from other session directories.
- Do not change published behavior defaults without explicit contract entry + gate update.
- Do not remove existing guardrails that currently pass strict checks.

## Lessons from Prior Sessions

1. **Contract beats prose** (S260217-05): blocking issues close reliably only when converted to deterministic gates.
2. **Artifact-level traceability is mandatory** (S260217-05): per-stage/per-skill persisted outputs were required to keep review and retro auditable.
3. **Deferred debt must be explicit and finite** (S260217-05): D1/D4/D5 stayed non-blocking only because they were clearly recorded with follow-up intent.

## Success Criteria

### Behavioral (BDD)

```gherkin
Scenario: D1 gate ownership is unified
  Given run/review gates are executed in strict mode
  When review stages complete
  Then gate ownership and closure logic are resolved from a single deterministic authority

Scenario: D4 context recovery registry is enforced
  Given a resume or compact-recovery path
  When the session restarts
  Then recovery-critical artifacts are resolved from registry state and freshness checks pass

Scenario: D5 handoff readiness is deterministic
  Given plan artifacts are complete
  When handoff is requested
  Then a machine-readable ready signal is generated and validated before handoff registration

Scenario: provenance semantic validation works
  Given run-stage-provenance has malformed or inconsistent rows
  When ship-stage gate runs in strict mode
  Then gate fails with explicit semantic validation errors

Scenario: unattended-mode behavior is explicit
  Given auto/unattended execution path is selected
  When workflow reaches an interactive branch
  Then the configured fallback behavior runs deterministically without deadlock

Scenario: refactor stale provenance policy escalates correctly
  Given provenance deltas exceed configured threshold
  When refactor criteria are loaded
  Then gate behavior follows configured warn/block policy and records rationale

Scenario: decision journal replay is required
  Given key user/gate decisions were made
  When session resumes
  Then replay validation confirms decision_journal consistency before proceeding
```

### Qualitative

- New behavior contracts are understandable without session-memory context.
- Deferred action closure is auditable from files + scripts only.
- Added checks are minimal, non-duplicative, and aligned with existing gate architecture.

## Dependencies

- **Requires**:
  - Existing S260217-05 artifacts (`plan.md`, `review-synthesis-code.md`, `retro.md`, `ship.md`, `run-ambiguity-decisions.md`).
  - Current deterministic gate scripts and live-state helpers.
- **Blocks**:
  - Final retirement of S260217-05 deferred backlog.
  - Next round of pipeline-hardening cleanup that depends on D1/D4/D5 being closed.

## Dogfooding

Use CWF skills as first-class workflow units:
1. `cwf:clarify` for any remaining ambiguity in deferred action interpretation.
2. `cwf:plan` for closure plan + checkpoint matrix.
3. `cwf:review --mode plan` before implementation.
4. `cwf:impl` for scoped implementation.
5. `cwf:review --mode code` and `cwf:refactor` for closure.
6. `cwf:retro` and `cwf:ship` for finalization.

## Execution Contract (Mention-Only Safe)

If user input only mentions this file (with or without "start"), treat it as instruction to execute this handoff directly.

- Branch gate:
  - Before implementation edits, check current branch.
  - If on base branch (`main`, `master`, or repository primary branch), create/switch to a feature branch first.
- Commit gate:
  - Commit in meaningful units by deferred-action bundle (e.g., D1 bundle, D4 bundle, D5 bundle, provenance bundle).
  - After first completed bundle, run `git status --short`, confirm next boundary, and commit before proceeding.
- Staging policy:
  - Stage only intended files for current bundle.
  - Avoid broad staging patterns that may include unrelated edits.
- Verification gate:
  - Each bundle must include deterministic validation commands and pass evidence in session artifacts before continuing.

## Start Command

Execute this handoff in order: load context files, convert each deferred action into a checked work item, implement in bundle commits, and do not end the session until all deferred items (D1/D4/D5 + retro-deferred validator/automation items) are closed with strict gate evidence.
