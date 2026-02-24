# Plan — cwf-cli-run-orchestration

## Task
"Replace `cwf:run` skill with a shell-based `cwf run` command, preserve interactive skill workflows, and keep deterministic artifact/state discipline."

## Scope Summary
- **Goal**: Move end-to-end run orchestration from skill runtime to shell runtime.
- **In Scope**:
  - `cwf run "<prompt>"`
  - `cwf run "<issue-url>"`
  - six stages: `gather -> clarify -> plan -> impl -> retro -> ship`
  - substep loop: `execute -> review -> refactor -> gate`
  - remove `plugins/cwf/skills/run/`
- **Key Decisions**:
  - Agent mapping: `execute=codex exec`, `review=claude -p`, `refactor=codex exec`, `gate=deterministic scripts`.
  - Commit policy: max 3 commits per stage, skip empty commits.
  - `cwf:run` skill is removed now (no compatibility layer).
- **Known Constraints**:
  - Backward compatibility is intentionally out of scope.
  - Restart/recovery must be file-driven, not chat-memory-driven.
  - Branch/worktree safety must be deterministic.

## Evidence Baseline
- Existing run flow is skill-coupled at `plugins/cwf/skills/run/`.
- Setup already has stable wrapper/install patterns reusable for `cwf` command setup.
- Existing deterministic scripts for readiness/gates can be reused by shell runner.
- Review findings require explicit contracts for idempotency, branch/worktree transitions, and gate authority.

## Architecture Direction

### Target State
1. A user-scope shell command `cwf` (wired by setup via shell rc/PATH) supports:
   - `cwf run "<prompt>"`
   - `cwf run "<issue-url>"`
2. `cwf:setup` installs/updates shell-accessible `cwf` command.
3. `cwf:update` reconciles shell wiring when plugin-cache command paths change.
4. `cwf run` is the only end-to-end orchestrator.
5. `plugins/cwf/skills/run/` is removed.

### Separation of Concerns
- `run core`: stage state machine, restart logic, branch/worktree policy.
- `agent adapter`: codex/claude command execution.
- `github adapter`: issue/comment/pr side effects for run path only.
- `gate adapter`: deterministic checks and stop/proceed decisions.

## Run-State SSOT Contract

### State File
- Path: `.cwf/projects/{session}/run-state.yaml`
- Created at run bootstrap.
- Updated after every substep and side effect.

### Required Fields
- `run_id`
- `request_source` (`prompt|issue_url`)
- `initial_issue_ref`
- `stage`
- `substep`
- `stage_status`
- `branch`
- `base_branch`
- `worktree_root`
- `last_gate`
- `side_effects`:
  - `issue_created`
  - `issue_comments`
  - `pr_ref`
  - `reaction_ids`
- `checkpoints`:
  - `last_clean_commit`
  - `last_stage_passed`
  - `last_substep_completed`

### Idempotency Rules
- Issue creation key: `run:{run_id}:initial-issue`.
- Stage comment key: `run:{run_id}:stage:{stage}:comment`.
- PR creation key: `run:{run_id}:ship:pr`.
- Resume always uses `run-state.yaml` as authority.

## Branch/Worktree Transition Policy

| Condition | Action | Exit |
|---|---|---|
| On base branch, clean tracked tree | create/switch run branch | continue |
| On non-base branch, clean tracked tree | keep current branch | continue |
| Tracked dirty | stop with remediation output | fail |
| Detached HEAD | stop with branch recovery output | fail |
| Worktree root mismatch vs state | stop; require explicit override reason | fail |
| Run branch collision | deterministic suffix and continue | continue |

Tracked cleanliness checks:
- `git diff --quiet --exit-code`
- `git diff --cached --quiet --exit-code`

Untracked policy:
- Allow only current session artifact subtree.
- Any other untracked path fails stage progression.

## Deterministic Gate Matrix

| Stage | Required Gate(s) | Required Artifacts | Failure Behavior |
|---|---|---|---|
| gather | gather output integrity | gather artifact + metadata | stop |
| clarify | clarify output + ambiguity sync | clarify result + ambiguity ledger | stop |
| plan | plan protocol check | plan.md + lessons.md | stop |
| impl | tracked cleanliness + impl completion | code diff + impl artifacts | stop |
| retro | retro artifact contract | retro.md + required side artifacts | stop |
| ship | ship contract + unresolved blocking debt check | ship.md + issue/pr refs + debt status | stop |

Substep invariants:
- `execute/review/refactor` require prior substep tracked-clean state.
- `gate` substep is mandatory for stage closure.

## Files to Create/Modify

### Create
- `plugins/cwf/scripts/cwf` (main shell CLI)
- `plugins/cwf/scripts/cwf-run.sh` (run orchestration helpers)
- `plugins/cwf/scripts/cwf-install.sh` (install/status/disable)
- `plugins/cwf/scripts/cwf-run-contract.sh` (contract loader/validator)
- `plugins/cwf/contracts/runner-contract.yaml` (runner profile contract)
- `.cwf/projects/{session}/run-state.yaml` (runtime state file)

### Modify
- `plugins/cwf/skills/setup/SKILL.md`
- `plugins/cwf/skills/setup/README.md`
- `plugins/cwf/skills/setup/references/runtime-and-index-phases.md`
- `plugins/cwf/scripts/check-setup-readiness.sh`
- `plugins/cwf/hooks/scripts/workflow-gate.sh`
- `plugins/cwf/scripts/README.md`
- `README.md`
- `README.ko.md`
- `AGENTS.md` managed index block
- run-related scripts/docs that are strictly `cwf:run`-only (decommission or repurpose)

### Remove
- `plugins/cwf/skills/run/` (SKILL + references + README)
- run-only references made obsolete by shell runner

## Implementation Steps

### Step 0 — Runner Contract Baseline
- Define contract schema/defaults for agent commands, effort, timeouts, gate policy, and restart semantics.
- Add validator and fail-fast behavior.

### Step 1 — CLI Entrypoint + Setup Wiring
- Implement `cwf` dispatcher (`run` subcommand in scope).
- Implement user-scope install/status/disable flow and setup integration (`zshrc`/`PATH` wiring).
- Add update-path reconciliation so `cwf:update` rewrites stale command target paths deterministically.
- Extend readiness check for runner contract + `cwf` command availability.

### Step 2 — Run Bootstrap
- Parse prompt vs issue URL input.
- Classify branch/worktree and apply transition policy.
- Bootstrap session dir + `initial-req.md` + `run-state.yaml`.
- Create initial commit.

### Step 3 — Six-Stage Loop
- Execute `execute/review/refactor/gate` per stage.
- Enforce tracked-clean requirement between substeps/stages.
- Enforce commit cap (`<= 3`) and empty-commit skip.
- Persist checkpoints after each substep and gate.

### Step 4 — Run-Path GitHub Side Effects (Idempotent)
- Prompt input path: create initial issue + stage comments.
- Issue URL path: reuse issue and avoid duplicate creation.
- Ship path: include retro summary and create PR once.
- Persist all side effects with idempotency keys.

### Step 5 — Remove `cwf:run` Skill and Slim Run-Specific Coupling
- Delete run skill files and references.
- Keep only runner-relevant gate logic and script dependencies.
- Ensure interactive skills remain independently usable.

### Step 6 — Documentation + Lifecycle Verification
- Update README/README.ko and AGENTS index references.
- Run deterministic checks and plugin lifecycle checks.

## Commit Strategy
- Migration commit units:
  1. runner contract + setup/install integration
  2. `cwf run` engine + run-state integration
  3. run-path github idempotency flow
  4. run-skill deletion + gate slimming
  5. docs/index cleanup
- Runtime policy for `cwf run`: max 3 commits per stage.

## Validation Plan
1. Static checks
   - shellcheck for new/modified scripts
   - markdown/link checks for docs
2. Runtime dry checks
   - `cwf --help`, `cwf run --help`
   - readiness check with runner contract
   - setup/update roundtrip keeps a valid `cwf` command target in shell rc
3. Functional smoke
   - `cwf run "test prompt"` dry-run fixture
   - `cwf run "<issue-url>"` with mocked `gh`
4. Disturbance/replay tests
   - crash between side effect and checkpoint
   - resume from `run-state.yaml` without duplicate side effects
   - branch/worktree mismatch failure path
5. Regression
   - interactive skills still work without `cwf:run`

## Decision Log

| # | Decision Point | Evidence / Source | Alternatives | Resolution | Status |
|---|----------------|-------------------|-------------|------------|--------|
| 1 | Orchestrator placement | user directive + run coupling analysis | skill-run vs shell-run | shell-run SSOT | resolved |
| 2 | Stage model | user directive | 9-stage vs 6-stage | 6-stage fixed | resolved |
| 3 | Agent mapping | user directive | single-agent vs mixed | codex/claude mixed | resolved |
| 4 | Commit policy | user directive | fixed 3 vs max 3 | max 3 + empty-skip | resolved |
| 5 | `watch` scope | user directive (split) | integrated plan vs split plan | split into separate `watch-plan.md` | resolved |
| 6 | Command install scope | latest user directive | repo-local entrypoint vs user-scope shell wiring | user-scope shell wiring + update-time path reconciliation | resolved |

## Success Criteria

### Behavioral (BDD)

```gherkin
Given a prepared repository with setup readiness
When `cwf run "<prompt>"` is executed
Then it creates an initial issue, writes `initial-req.md`, and executes six stages with stage progress comments

Given an existing GitHub issue URL
When `cwf run "<issue-url>"` is executed
Then it uses the issue as initial request source and executes the same six-stage flow without creating a duplicate issue

Given a stage is running
When execute/review/refactor substeps complete
Then no more than 3 commits are created for that stage and each commit has non-empty diff

Given stage gate checks fail
When gate step runs
Then `cwf run` stops with deterministic failure output and does not advance to next stage

Given a crash occurs after partial side effects
When the runner resumes
Then it restores from `run-state.yaml` and avoids duplicate issue/comment/PR side effects

Given run-skill migration is complete
When interactive users invoke other CWF skills directly
Then those skills still operate normally without dependency on `cwf:run`
```

### Qualitative
- Runner behavior is understandable from contract + logs.
- Failures are actionable without reading source code.
- Stage progression remains deterministic across restart/resume.

## Deferred Actions
- [ ] Implement and review `watch-plan.md` before any `cwf watch` code is written.
- [ ] User manual review of this revised run plan before implementation start.
