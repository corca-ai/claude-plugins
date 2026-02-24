## Expert Beta Review

### Concerns (blocking)

1. Missing top-level hazard model before architecture lock-in.
- References: "Scope Summary", "Known Constraints", "Step 0 — Runner Contract and Safety Baseline", "Step 5 — `cwf watch` Automatic Handling".
- Issue: The plan defines functional constraints (branch/worktree, no hidden state) but not explicit system hazards/accidents and safety constraints. STPA requires explicit hazards first (for example: unintended repository mutation, incorrect PR automation, unbounded action loops, cross-issue contamination).
- Risk: Stage and watch controls can pass deterministic gates while still producing unsafe outcomes.
- Blocking expectation: Add `Hazards -> Safety Constraints -> Control Actions` artifact before Step 1 implementation.

2. Control structure is implied, not specified as a closed-loop controller design.
- References: "Step 3 — Six-Stage Loop with 4 Internal Substeps", "Step 4 — GitHub Integration in `run`", "Architecture Direction -> Target State #3/#4", "Migration Principle".
- Issue: `execute/review/refactor/gate` roles are mapped, but there is no formal loop contract (controller authority, controlled variables, required feedback channels, update rate, escalation/override conditions).
- Risk: Unsafe control actions can occur from stale/missing feedback (for example: advancing stage with misleading comments/artifacts; wrong branch state model).
- Blocking expectation: Define per-stage control loop contracts with required feedback artifacts and stop conditions before control actions are emitted.

3. `cwf watch` introduces autonomous external actuation without a safety envelope.
- References: "Step 5 — `cwf watch` Automatic Handling", "Evidence Gap List" (triage heuristic and runner cost policy unresolved), "Decision Log #5".
- Issue: Direct automation is planned while key classifier and cost guardrails remain unresolved/deferred.
- Risk: UCA categories are exposed: action provided when it should not, action not provided when needed, wrong timing/order, or action duration too long (runaway retries/concurrency).
- Blocking expectation: Move classification policy and cost/concurrency constraints from deferred items to prerequisite gates for Step 5.

4. Gate authority does not explicitly include "unsafe but syntactically valid" states.
- References: "Step 3 — ... deterministic gate -> pass/fail", "Validation Plan", "Qualitative".
- Issue: Deterministic gates are described as script checks, but no safety-specific checks are listed (for example: provenance consistency across issue/branch/session, actor authorization, loop-count/time-budget violation).
- Risk: System may continue under hazardous state while format/readiness checks still pass.
- Blocking expectation: Add safety gate set tied to STPA constraints, not only readiness/lint/smoke checks.

5. Success criteria are nominal-path heavy and do not test control disturbances.
- References: "Success Criteria -> Behavioral (BDD)", "Validation Plan", "Deferred Actions".
- Issue: Criteria validate expected flow but omit disturbance scenarios (dropped webhook, duplicate delivery, stale artifact replay, concurrent conflicting comments, delayed gate feedback).
- Risk: No evidence that control loops remain safe under asynchronous disturbances.
- Blocking expectation: Add failure-oriented BDD mapped to UCA categories before implementation approval.

### Suggestions (non-blocking)

1. Add a compact STPA appendix in the plan: accidents/losses, hazards, safety constraints, and a control-structure diagram.
2. For each stage in "Step 3", define a control contract: preconditions, emitted control action, mandatory feedback artifacts, timeout/retry envelope, escalation target, safe-stop behavior.
3. Extend `plugins/cwf/contracts/runner-contract.yaml` safety parameters: `max_parallel_runs`, `max_retries`, `max_runtime_per_stage`, `authorized_event_sources`, `allowed_branch_patterns`, `manual_override_required_conditions`.
4. Strengthen `watch` routing with explicit confidence + abstention policy (low confidence routes to question-response or human-required path).
5. Add a traceability matrix mapping each BDD criterion to hazards, safety constraints, and validating gates/scripts.

### Behavioral Criteria Assessment

- `Given a prepared repository ... executes six stages ...`
  - Assessment: Partial.
  - STPA lens: Missing constraints for when automation must refuse to start despite a "prepared" repository.

- `Given an existing GitHub issue URL ... no duplicate issue`
  - Assessment: Partial.
  - STPA lens: Duplicate suppression is present, but no control for stale/forged/mis-scoped issue references.

- `Given a stage is running ... <=3 commits ... non-empty diff`
  - Assessment: Partial.
  - STPA lens: Commit cap is operational, not safety-oriented; no criterion prevents unsafe transition with a valid diff.

- `Given stage gate checks fail ... stops and does not advance`
  - Assessment: Pass (narrow).
  - STPA lens: Good stop behavior, but gate scope must include safety-state checks.

- `Given cwf watch is enabled ... automatically routes ...`
  - Assessment: Fail (blocking).
  - STPA lens: Automation is required while classifier policy and cost/concurrency controls remain unresolved in "Evidence Gap List" and "Deferred Actions".

- `Given run-skill migration is complete ... other skills still operate`
  - Assessment: Pass (interface compatibility).
  - STPA lens: Compatibility is covered, but safety interaction between interactive and autonomous controllers is untested.

Required additions before implementation approval:
- At least 4 disturbance/failure BDD scenarios (duplicate webhook, out-of-order comments, gate timeout, concurrent issue contention).
- One abstention/human-escalation BDD scenario for low-confidence watch classification.
- One provenance-integrity BDD scenario linking issue/branch/session/artifact IDs.

### Provenance

- Reviewed artifact: `/home/hwidong/codes/claude-plugins/.cwf/projects/260224-02-cwf-cli-run-watch-orchestration/plan.md`
- Lens applied: Nancy Leveson STAMP/STPA (control loops, unsafe control actions, feedback adequacy, safety constraints).
- Sections explicitly referenced: "Evidence Gap List", "Architecture Direction", "Step 0 — Runner Contract and Safety Baseline", "Step 3 — Six-Stage Loop with 4 Internal Substeps", "Step 4 — GitHub Integration in `run`", "Step 5 — `cwf watch` Automatic Handling", "Validation Plan", "Success Criteria", "Deferred Actions".
<!-- AGENT_COMPLETE -->
