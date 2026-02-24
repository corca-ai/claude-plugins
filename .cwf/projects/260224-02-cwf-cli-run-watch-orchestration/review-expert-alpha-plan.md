## Expert Alpha Review

### Concerns (blocking)
- [high] Process is set to automate before key causes are operationally defined.
  - `## Evidence Gap List` explicitly leaves classification policy and watch cost policy unresolved, and `## Deferred Actions` repeats them as open.
  - At the same time, `### Step 5 — \`cwf watch\` Automatic Handling` and Decision Log #5 commit to immediate automatic handling.
  - Deming lens: this is dependence on downstream inspection/correction rather than building quality into the process definition first.
- [high] The plan lacks a method to separate common-cause variation from special-cause incidents.
  - `## Validation Plan` and `### Behavioral (BDD)` are primarily pass/fail checkpoints.
  - No section defines control metrics (e.g., stage duration distribution, gate-fail rate by stage, router misclassification rate, retry/rework frequency) or alert thresholds.
  - Deming lens: without process-behavior data, operators will treat every incident as special cause and tamper with the system.
- [high] Commit-count quota is treated as a quality control mechanism.
  - `## Scope Summary`, `### Step 3 — Six-Stage Loop with 4 Internal Substeps`, and `## Commit Strategy` enforce `<= 3` commits per stage.
  - Deming lens: numeric quotas without demonstrated process capability shift attention from quality of flow to compliance with a target, increasing hidden rework risk.

### Suggestions (non-blocking)
- Convert the open items in `## Evidence Gap List` / `## Deferred Actions` into mandatory entry criteria before enabling `### Step 5`.
  - Require a versioned classification rubric and a runner-cost guardrail policy as gate artifacts.
- Add a process-behavior baseline artifact to `## Validation Plan`.
  - Example artifact: `run-metrics.json` with per-stage cycle time, gate failure taxonomy, retries, and watch-router confusion matrix.
- Reframe the commit cap as a guardrail with explicit exception criteria.
  - Keep `<= 3` as default, but permit justified exceptions when system-level learning or rollback safety requires additional boundaries.
- Add a PDCA loop in `### Step 7 — Documentation and Lifecycle Checks`.
  - `Plan`: target variation bands; `Do`: run pilot cohort; `Study`: analyze variation; `Act`: update contract/gates.

### Behavioral Criteria Assessment
- BDD scenario 1 (`cwf run "<prompt>"`) and scenario 2 (`cwf run "<issue-url>"`): **Partially adequate**.
  - Functional behavior is clear, but no expected variation band is defined for timing, retries, or comment-update reliability.
- BDD scenario 3 (commit count limit): **Not quality-oriented**.
  - It controls quantity, not process capability or defect prevention.
- BDD scenario 4 (gate failure stop): **Good containment, incomplete diagnosis**.
  - Stop condition exists, but no required root-cause classification step is specified.
- BDD scenario 5 (`cwf watch` routing): **Insufficient for autonomous rollout**.
  - Needs measurable routing accuracy and cost-control criteria before first full automation.
- BDD scenario 6 (interactive skill regression): **Adequate** for migration safety.

Overall from a Deming lens: **Revise before implementation**. The plan should first define process quality in-system (operational definitions + variation measures), then automate.

### Provenance
- source: REAL_EXECUTION
- tool: codex-cli
- expert: W. Edwards Deming
- framework: systems thinking; common vs special cause variation; quality built into process
- grounding: Out of the Crisis (MIT Press, 1986), Point 3: cease dependence on inspection
- reviewed artifact: `/home/hwidong/codes/claude-plugins/.cwf/projects/260224-02-cwf-cli-run-watch-orchestration/plan.md`
- references used: `## Evidence Gap List`, `## Deferred Actions`, `### Step 3 — Six-Stage Loop with 4 Internal Substeps`, `### Step 5 — cwf watch Automatic Handling`, `## Validation Plan`, `### Behavioral (BDD)`

<!-- AGENT_COMPLETE -->
