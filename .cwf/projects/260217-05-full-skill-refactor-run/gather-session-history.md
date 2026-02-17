# Session History — 260217-05 Full Skill Refactor Run

## Reusable wins
- The fail-closed deletion safety PreToolUse hook, the workflow gate UserPromptSubmit hook, and the new `cwf-live-state.sh` list helpers (260217-02 → 260217-03) now form a mature guardrail stack that catches deletions with callers, enforces `remaining_gates`, and survives compaction. Future refactors can reuse these scripts and the `run` skill state updates without re-deriving the decision-point logic.
- The adaptive CLI-timeout table plus external-slot routing logic (260217-03 + 260217-04) proved the high-prompt plan review path; we now have deterministic thresholds for `<300`, `300‑800`, and `>1200` lines, letting long specs run without hitting hard 120s timeouts.
- Shared references for the expert roster, Broken Link Triage Protocol, and triage/decision persistence lessons (260216 + 260217-03/04) have centralized previously duplicated prose, making it safe to point new skills at those documents instead of re-baking the same paragraph sets.
- `test-hook-exit-codes.sh`, `check-script-deps.sh`, `check-readme-structure.sh`, and `check-review-routing.sh` (260217-04) now form a repeatable hardening pipeline; any future change can simply run those suites to cover blocking behavior, dependency edges, README alignment, and routing cutoffs.

## Known failure patterns
- Hooks that signal a block by emitting JSON but keep exiting `0` yield nothing but noise; the learnings from 260217-03 are explicit—every blocking path must return exit code 1, otherwise the gate never fires.
- When a plan leaves the deterministic gate matrix underspecified (260217-04 plan review), reviewers converge on “Revise” verdicts because the behavior policy lacks executable steps, not because the idea is wrong.
- Decisions are getting lost in compaction unless they are persisted (260217-03 lessons on decision-journal gaps). Re-asking the user is expensive and risks backtracking, so failure to record AskUserQuestion outputs is a repeating mistake.
- Automation‑vs‑doc mismatches (CORCA003 vs `skill-conventions.md`, ship skill language defaults) from 260216 keep resurfacing because there is no SSOT guardrail connecting lint rules back to the prose conventions.

## Guardrails to preserve
- Keep `remaining_gates`, `active_pipeline`, override reason, and `decision_journal` updates in `run` and `workflow-gate.sh` (260217-02/03); they are the shared state Machine that keeps the pipeline-from-stepping-out of order.
- Preserve the Broken Link Triage Protocol reference in `check-links-local.sh` plus the recommendation-fidelity guidance in `impl/SKILL.md` (260217-02/03) so triage errors always link back to the same canonical advice instead of drifting per skill.
- Continue running the deterministic suites introduced in 260217-04 (`test-hook-exit-codes`, `check-script-deps`, `check-readme-structure`, `check-review-routing`, `check-shared-reference-conformance`) whenever hooks, dependency graphs, or review policies change.
- Maintain the adaptive CLI-timeout thresholds and the >1200-line external-slot bypass rule (260217-03/04) so review code runs keep their timing contracts.
- Enforce exit-code conventions (block = exit 1, allow = exit 0) across all new hooks, especially when shared parser helpers are refactored (260217-03 + 260217-04 follow-up).

## Candidate simplifications now safe
- Given the existing hardening scripts, future plans can reference `bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict` and similar gates instead of re-describing the block/allow expectations in prose.
- With `cwf-live-state.sh` now handling list-set/remove plus gate validation, `run` and related skills can trust that `remaining_gates` is YAML-managed, meaning we no longer need bespoke list serialization logic in downstream tools.
- Having persistent decision journals, adaptive CLI routing, and a documented triage reference allows downstream tasks to cite those artifacts instead of re-deriving the same protocols resource-by-resource.
- The most recent ship preparation (260217-04 ship draft) proved a document-only ship stage is sufficient when GH actions are intentionally skipped, so future runs can record the same artifact without running `gh pr` commands when the user requests a dry path.

## Risks if unchanged
- If exit-code conventions and hook regression suites slip, the deletion and workflow gates become advisory again—deletions with live callers will still proceed and `cwf:ship` can fire before `review-code` completes (260217-03/04 warnings).
- Sticking with static timeout defaults means any plan review with 300+ lines will keep timing out the external CLI slots, forcing repeated manual reruns (260217-03 lessons and 260217-04 retro recommendations).
- Without the decision-journal persistence, compaction will keep replaying user answers, wasting tokens and risking inconsistent behavior when multiple runs hit the same question (260217-03 lessons).
- Letting documentation vs lint mismatch continue (CORCA003 vs `skill-conventions`, ship hardcodes from 260216) invites future reviewers to experience the same confusion and increases the chance of conflicting “SSOT” definitions.
