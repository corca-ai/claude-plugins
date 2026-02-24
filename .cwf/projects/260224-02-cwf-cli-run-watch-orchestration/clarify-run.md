# Requirement Clarification Summary — cwf run

## Before (Original)
"Move long-running `cwf:run` orchestration to shell-based `cwf run`, keep six stages and per-stage loop (`execute -> review -> refactor -> gate`), remove `cwf:run` skill now, and keep deterministic contract/gate behavior. In this session, focus only on `cwf run` (split `cwf watch`), and clarify plan assumptions against user prompts from Codex log."

Primary evidence source: `user-req.md` in this project session.

## After (Clarified)
**Goal**: Define a run-only v1 plan where `cwf run` becomes the single end-to-end orchestrator with deterministic restart and gate authority.

**Reason**: Reduce context-compression drift from long interactive sessions and preserve contract adherence via script- and file-driven execution.

**Scope**:
- Included:
  - `cwf run "<prompt>"`
  - `cwf run "<issue-url>"`
  - Stage chain: `gather -> clarify -> plan -> impl -> retro -> ship`
  - Stage substep loop: `execute -> review -> refactor -> gate`
  - Remove `plugins/cwf/skills/run/`
  - Keep `review` and `refactor` skills available for loop internals
  - Setup/update wiring for user-scope `cwf` command
- Excluded:
  - `cwf watch` implementation (separate planning track)
  - Backward compatibility for old `cwf:run` behavior in this phase

**Constraints**:
- `cwf` command exposure is user-scope shell wiring (`zshrc`/`PATH`), not repository-local-only command exposure.
- Avoid npm packaging for this runner.
- Agent execution in run loop is non-interactive (`claude -p`, `codex exec`) with contract-driven model/reasoning settings.
- First run must perform readiness/setup checks, auto-apply script-level setup when possible, and stop with actionable manual steps when not fully ready.
- Stage progression depends on deterministic gates; prose judgments never override gate outcomes.
- Runtime commit cap is max 3 commits per stage, with empty-commit skip.
- Worktree cleanliness is enforced before substep/stage transitions.

**Success Criteria**:
- `plan.md` reflects user-scope install/update wiring explicitly.
- `plan.md` contains no run/watch scope mixing for this session.
- `plan.md` preserves six-stage model and run-only deletion path for `cwf:run` skill.
- Clarified decisions are traceable to Codex log prompts in `user-req.md`.

## Decisions Made

| Question | Decision |
|---|---|
| Should `cwf:run` remain as a skill for now? | No. Remove now; compatibility deferred. |
| How many pipeline stages are fixed? | Six stages only: gather/clarify/plan/impl/retro/ship. |
| What executes inside each stage? | `execute -> review -> refactor -> gate` loop. |
| How many commits are allowed per stage at runtime? | Maximum 3, skip empty commits. |
| What is "worktree cleanliness" in this plan? | No tracked dirty changes (staged or unstaged) before substep/stage transitions; deterministic failure on violation. |
| Should this session include `cwf watch` design/implementation? | No. Split out to separate watch plan. |
| Should command install be repo-local or user-scope? | User-scope shell wiring is authoritative. |
| Where should install/update responsibility live? | `cwf:setup` wires command; `cwf:update` reconciles stale target paths. |
| Should setup auto-fix partial prerequisites? | Yes, for shell-script-level fixes; otherwise output remaining manual actions and stop. |
| Should run loop update global `cwf-state` each substep? | No; use run-specific state/artifacts for loop progression authority. |

## Plan Comparison Outcome
- Mismatch found: `plan.md` used "repository-local executable" wording.
- Clarified resolution: switched to user-scope shell command wiring and added update-time path reconciliation.
- Follow-up needed during implementation: define deterministic shell-rc patch strategy (append/update/remove block markers).
