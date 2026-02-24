## Architecture Review

### Concerns (blocking)
- **[C1] Core orchestration and GitHub transport are not separated, creating a high-risk coupling point.**
  Severity: moderate
  - The plan mixes domain orchestration (`run` stage engine) and GitHub side effects (issue creation, reactions, stage comments, PR creation) in one flow without an explicit boundary contract between them.
  - This appears in `## Architecture Direction > ### Target State` (items 3-4), `## Implementation Steps > ### Step 2 — cwf run Core Orchestration`, and `### Step 4 — GitHub Integration in run`.
  - Without a port/adapter boundary, migration and future transport changes (e.g., non-GitHub backends, dry-run/offline mode) will likely require editing the core runner logic, increasing regression risk.

- **[C2] Restart/idempotency architecture is underspecified for `cwf run`, despite deterministic recovery being a stated invariant.**
  Severity: moderate
  - `## Scope Summary` declares "No hidden state dependence: restart must recover from files," but the plan defines explicit idempotency markers only for watch events (`## Implementation Steps > ### Step 5 — cwf watch Automatic Handling`).
  - `### Step 2` and `### Step 3` do not define a persisted run-state machine (stage/substep status, external IDs, retry markers, comment dedupe keys).
  - This is an architectural gap because deterministic replay/partial restart behavior cannot be guaranteed without a run-state SSOT artifact.

- **[C3] Migration sequencing enables automatic `watch` before resolving known classification and cost-control gaps.**
  Severity: moderate
  - `## Evidence Gap List` and `## Deferred Actions` explicitly state unresolved triage heuristic and runner-cost policy.
  - However, `## Scope Summary` chooses direct automatic watch rollout, and `## Implementation Steps > ### Step 5` operationalizes it immediately.
  - This sequence makes the production architecture unstable at rollout time (unbounded automation semantics, unclear routing contract), which should be gated before enabling autonomous event handling.

### Suggestions (non-blocking)
- **[S1] Introduce explicit module boundaries in shell layout before implementation.**
  - Reference: `## Files to Create/Modify > ### Create`, `## Migration Principle`.
  - Suggested split: `core` (stage engine/state transitions), `adapters/git`, `adapters/github`, `adapters/agents`, `gates` (deterministic checks only), `cli` (argument parsing/dispatch).

- **[S2] Promote runner contract to include orchestration semantics, not only agent defaults.**
  - Reference: `## Implementation Steps > ### Step 0 — Runner Contract and Safety Baseline`.
  - Add fields for stage graph version, retry/backoff policy, idempotency strategy, and side-effect policy (issue/comment/PR behavior) to keep dependency direction configuration-driven.

- **[S3] Insert a migration gate between Step 4 and Step 5.**
  - Reference: `## Implementation Steps`, `## Evidence Gap List`, `## Deferred Actions`.
  - Require a "watch-readiness" checkpoint (classification rules + cost guardrails + replay tests) before enabling automatic issue/comment handling.

- **[S4] Clarify generated-vs-source ownership for `.github/workflows/cwf-watch.yml`.**
  - Reference: `## Files to Create/Modify > ### Create` and `### Step 5 — cwf watch Automatic Handling`.
  - Specify whether the workflow is committed template source, generated artifact, or both; this prevents drift and ownership confusion in long-term maintenance.

### Behavioral Criteria Assessment
- [ ] `Given a prepared repository with setup readiness ... Then it creates an initial issue, writes initial-req.md, and executes six stages with stage progress comments` — Partially specified across `### Step 2` and `### Step 4`, but ordering/idempotent comment semantics are not architecturally fixed.
- [x] `Given an existing GitHub issue URL ... Then it uses the issue as initial request source ...` — Explicit in `### Step 4` (`cwf run "<issue-url>"` path).
- [x] `Given a stage is running ... Then no more than 3 commits ... non-empty diff` — Explicit in `### Step 3` and `## Commit Strategy`.
- [x] `Given stage gate checks fail ... Then cwf run stops ...` — Explicit in `### Step 3` (deterministic gate pass/fail) and BDD alignment.
- [ ] `Given cwf watch is enabled ... Then workflow automatically routes event ...` — Functional intent exists in `### Step 5`, but plan keeps classification/cost policies unresolved in `## Evidence Gap List` and `## Deferred Actions`.
- [x] `Given run-skill migration is complete ... Then interactive users invoke other skills directly ...` — Supported by `### Step 6`, `### Step 7`, and `## Validation Plan` regression item.

### Provenance
source: REAL_EXECUTION
tool: codex-cli
reviewer: Architecture (Slot 4, plan mode)
duration_ms: —
command: Manual architectural review of `plan.md` with section-referenced findings
<!-- AGENT_COMPLETE -->
