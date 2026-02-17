# Next Session — Post S260217-03

## Completed This Session

- Prevention Proposals A (deletion safety hook), B (broken-link triage), C (recommendation fidelity), E+G (workflow enforcement) implemented and reviewed
- Adaptive external CLI timeout added to cwf:review
- 8 commits on `feat/260217-03-review-prevention-impl` (base: `marketplace-v3`)
- Code review: Conditional Pass (6 moderate concerns, all addressed in refactor)
- Deep retro with Leveson (STAMP) + Dekker (drift into failure)

## Immediate Follow-Up

### Merge prevention branch
- Branch `feat/260217-03-review-prevention-impl` in worktree `/home/hwidong/codes/claude-plugins-wt-260217-run`
- 8 commits ready for PR against `marketplace-v3`
- Ship was skipped this session — create PR manually or via `/ship pr --base marketplace-v3`

### Retro persist proposals (from retro.md)
1. **Tier 2 (State)**: AskUserQuestion 응답을 cwf-live-state.sh decision_journal에 자동 persist
2. **Tier 3 (Doc)**: review SKILL.md에 >1200줄 프롬프트 시 외부 CLI 건너뛰기 cutoff
3. **Tier 1 (Eval/Hook)**: 훅 exit-code integration test — blocking path non-zero exit 검증

## Deferred Items (from plan.md)

- [ ] Proposal D: Script dependency graph in pre-push (P2)
- [ ] Proposal F: Session log cross-check in cwf:review (P2)
- [ ] Proposal H: README structure sync validation (P2)
- [ ] Proposal I: Shared reference extraction (P2)
- [ ] Add `deletion_safety` and `workflow_gate` to cwf:setup hook group selection UI
- [ ] Proposal C structural fix: modify triage output format to carry original recommendation inline
- [ ] Consolidate duplicated YAML parsing in workflow-gate.sh (source cwf-live-state.sh instead — 6/6 reviewers flagged)
- [ ] Hook matcher에 path-based filtering 추가 검토 (/tmp prompt 파일 대상 오발동 완화)

## Expert Insights to Carry Forward

- **Leveson**: STAMP 기반 훅 설계 템플릿 — controlled process, safety constraint, control action, actuator, feedback channel, fail mode, detection boundary
- **Dekker**: grep -rl 탐지 경계를 수동적 "잔여 위험"에서 능동적 운영 가이드로 재프레이밍. 삭제 허용 시 advisory 메시지로 normalization of deviance 방지.
- **Dekker**: 훅 exit-code integration test로 convention을 structure로 전환 — practical drift 방지
- **Perrow**: AWK/YAML 파서 중복은 common-mode failure 경로가 될 수 있으므로 공유 파서 계층으로 수렴 필요.

---

## Handoff Addendum — Post-Merge Hardening Pack (2026-02-17)

## Context Files to Read

1. `AGENTS.md` — shared project rules and protocols (cross-agent)
2. `docs/plugin-dev-cheatsheet.md` — plugin development/testing/deploy patterns
3. `.cwf/cwf-state.yaml` — current project/session state
4. `.cwf/projects/260217-03-refactor-review-prevention-impl/ship-summary-origin-marketplace-v3.md` — authoritative delta summary vs `origin/marketplace-v3`
5. `.cwf/projects/260217-03-refactor-review-prevention-impl/plan.md` — implemented proposal scope and deferred items
6. `.cwf/projects/260217-03-refactor-review-prevention-impl/lessons.md` — operational learnings and unresolved process gaps
7. `.cwf/projects/260217-03-refactor-review-prevention-impl/retro.md` — tool-gap and structural-risk analysis

## Task Scope

Implement the next hardening wave after prevention merge, with three ordered packs:

1. Pack A: linter-disable structural reduction
2. Pack B: hook exit-code integration tests
3. Pack C: compaction-immune user decision persistence

### What to Build

- Reduce avoidable `shellcheck`/markdownlint suppressions by eliminating root causes.
- Add deterministic tests that guarantee blocking hook paths exit non-zero.
- Persist user gate decisions into live state (`decision_journal`) and surface them in recovery flow.

### Key Design Points

- Prefer structural fixes over ignore directives.
- Keep fail-mode intent explicit: safety-critical guardrails stay fail-closed.
- New tests/gates must be deterministic, local-first, and CI/pre-push friendly.
- Preserve current run-gate behavior (`worktree consistency` + `review-code gate`) while extending observability.

## Don't Touch

- Do not rewrite historical session evidence under `.cwf/projects/260217-02-refactor-review-prevention-run/`.
- Do not delete merge-preserved snapshots under `.cwf/projects/260217-03-refactor-review-prevention-impl/merge-preserved/`.
- Do not remove existing prevention hooks:
  - `plugins/cwf/hooks/scripts/check-deletion-safety.sh`
  - `plugins/cwf/hooks/scripts/workflow-gate.sh`
- Do not bypass deterministic gates by weakening `check-growth-drift.sh` checks.

## Lessons from Prior Sessions

1. **Hook block semantics are exit-code driven** (S260217-03): JSON `decision` alone does not block; blocking paths must exit non-zero.
2. **Prompt-size variability is operationally significant** (S260217-03): external reviewer timeout needs adaptive policy and explicit cutoff behavior.
3. **Compaction loses implicit decisions** (S260217-03): user decisions must be persisted in state, not only conversation context.
4. **Worktree drift is a real execution hazard** (post-merge integration): run-stage protection must preserve worktree binding checks.

## Unresolved Items from S260217-03

### From Deferred Actions

- [ ] [carry-forward] Proposal D: script dependency graph automation in pre-push
- [ ] [carry-forward] Proposal F: session log cross-check integration in `cwf:review --mode code`
- [ ] [carry-forward] Proposal H: README structure sync deterministic checker
- [ ] [carry-forward] Proposal I: shared reference extraction for repeated patterns

### From Lessons

- [ ] Implement compaction-immune persistence for AskUserQuestion decisions (`decision_journal` append path).

### From Retro

- [ ] Add hook exit-code integration tests to convert convention into deterministic structure.
- [ ] Add >1200-line external-review cutoff rule (skip external CLIs, direct fallback).
- [ ] Reduce parser duplication risk (shared YAML parser strategy across hook/runtime scripts).

## Success Criteria

```gherkin
Given modified hook/runtime scripts
When shellcheck and markdownlint run
Then suppressions decrease or remain only with explicit rationale comments.

Given a blocking input for workflow/deletion hooks
When integration tests execute
Then each blocking path exits non-zero and test fails on regression.

Given a user decision from AskUserQuestion
When the session compacts/restarts
Then the decision is recoverable from live state decision_journal without re-asking.

Given review prompt line count exceeds 1200
When cwf:review computes external CLI policy
Then it skips external CLIs and records direct fallback provenance.
```

## Dependencies

- Requires:
  - `marketplace-v3` merged baseline containing prevention hooks and run-gate updates
  - `.cwf/projects/260217-03-refactor-review-prevention-impl/ship-summary-origin-marketplace-v3.md`
- Blocks:
  - Shipping a stable hardening release focused on linter policy and recovery reliability
  - Follow-up refactor proposals that depend on trusted gate/test baseline

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat it as an instruction to execute
the task scope directly.

- Branch gate:
  - Before implementation edits, check current branch.
  - If on a base branch (`main`, `master`, or repo primary branch), create/switch
    to a feature branch and continue.
- Commit gate:
  - Commit during execution in meaningful units (per work item or change pattern).
  - Avoid one monolithic end-of-session commit when multiple logical units exist.
  - After the first completed unit, run `git status --short`, confirm the next
    commit boundary, and commit before starting the next major unit.
- Staging policy:
  - Stage only intended files for each commit unit.
  - Do not use broad staging that may include unrelated changes.

## Start Command

```text
Use cwf:run in guided mode for this file's scope, then execute Pack A -> Pack B -> Pack C on marketplace-v3 with commit-per-pack and deterministic gate verification after each pack.
```
