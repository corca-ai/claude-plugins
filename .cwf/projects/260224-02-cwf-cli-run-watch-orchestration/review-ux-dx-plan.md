## UX/DX Review

### Concerns (blocking)
- **Config precedence is undefined, which makes behavior non-predictable for operators and maintainers.** In `Implementation Steps > Step 0 — Runner Contract and Safety Baseline`, the plan defines contract schema/defaults, but it does not define precedence and conflict rules across contract file, environment variables, CLI flags, and setup-time defaults. This conflicts with `Architecture Direction > Migration Principle` (shell runner as SSOT) and `Success Criteria > Qualitative` (behavior understandable from contract + logs).
- **Failure UX is under-specified for recovery.** `Implementation Steps > Step 0` and `Step 3` require fail-fast and deterministic gate stop, and `Success Criteria > Behavioral` requires deterministic failure output; however, there is no explicit error contract (exit codes, stage/substep identifiers, failed command, remediation hint, artifact pointer). Without that, “actionable without reading source code” in `Success Criteria > Qualitative` is not enforceable.
- **`cwf watch` ships with unresolved routing/cost policy, creating operator trust and safety risk.** `Scope Summary` chooses direct automatic handling, but `Evidence Gap List` and `Deferred Actions` explicitly leave classification heuristic and runner cost guardrails unresolved. This makes `Implementation Steps > Step 5 — cwf watch Automatic Handling` operationally ambiguous and high-friction.
- **Resume/retry UX is missing for the staged loop.** `Scope Summary` says restart recovery must come from files and `Implementation Steps > Step 3` enforces strict stage/substep gates, but there is no explicit resume/retry behavior (where to restart, when to require manual intervention, how to acknowledge partial stage completion). This is a DX blocker for long-running automation.

### Suggestions (non-blocking)
- In `Implementation Steps > Step 1 — CLI Entrypoint and Setup Integration`, add a command UX contract: `--help` examples, canonical invocation matrix, and explicit “next-step” guidance for common misuses.
- In `Implementation Steps > Step 4 — GitHub Integration in run`, define a comment strategy (single updatable status comment vs per-stage comments) to reduce notification noise and improve audit readability.
- In `Implementation Steps > Step 3 — Six-Stage Loop with 4 Internal Substeps`, standardize stage/substep IDs for logs/artifacts (e.g., `stage=plan`, `substep=review`) so users can map CLI output to files and GitHub comments consistently.
- In `Validation Plan`, add UX smoke checks for failure paths (invalid contract, dirty working tree, missing dependency) and verify remediation hints are present.
- In `Step 1` and docs updates (`Step 7`), add onboarding diagnostics output that clearly lists required tools (`gh`, `codex`, `claude`) and current detection status.

### Behavioral Criteria Assessment
- **Given `cwf run "<prompt>"`** (`Success Criteria > Behavioral`): **Partial**. Core flow is clear, but output/feedback design for long-running progress and user recovery is not yet specified.
- **Given `cwf run "<issue-url>"`**: **Pass (conditional)**. Behavior is coherent, but only if URL parsing errors and permission failures get explicit remediation output.
- **Given stage substeps complete with commit cap**: **Pass (technical), Partial (UX)**. Commit limit is clear; user-facing explanation when commits are skipped/blocked is missing.
- **Given gate check failure**: **Partial**. Stop behavior exists, but deterministic failure output is not sufficiently defined to be actionable.
- **Given `cwf watch` event routing**: **Fail (until resolved)**. Required classification and cost-control policies are still deferred (`Evidence Gap List`, `Deferred Actions`).
- **Given run-skill migration complete**: **Partial**. Compatibility intent exists, but onboarding and transition guidance for operators is not explicit enough yet.

### Provenance
- Reviewed source: `/home/hwidong/codes/claude-plugins/.cwf/projects/260224-02-cwf-cli-run-watch-orchestration/plan.md`
- Primary sections used:
  - `Scope Summary`
  - `Evidence Gap List`
  - `Architecture Direction > Target State`
  - `Architecture Direction > Migration Principle`
  - `Implementation Steps > Step 0` through `Step 7`
  - `Validation Plan`
  - `Success Criteria > Behavioral (BDD)`
  - `Success Criteria > Qualitative`
  - `Deferred Actions`
<!-- AGENT_COMPLETE -->
