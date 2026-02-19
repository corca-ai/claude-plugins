# Plan — Deferred-Inclusive Hardening Wave (Rev-2)

## Context

Source handoff: `.cwf/projects/260217-03-refactor-review-prevention-impl/next-session.md`.
This revision incorporates full deferred scope plus plan-review findings.

## Goal

Ship a deterministic hardening set where prevention/review/recovery controls are executable and regression-tested.

## Scope

### In Scope

- Pack A: linter-disable structural reduction
- Pack B: hook exit-code integration tests
- Pack C: compaction-immune decision persistence
- Proposal D: script dependency graph automation in pre-push
- Proposal F: session-log cross-check integration in `cwf:review --mode code`
- Proposal H: README structure sync deterministic checker
- Proposal I: shared reference extraction for repeated patterns
- setup hook-group parity: `deletion_safety`, `workflow_gate`
- triage structural fix: carry original recommendation inline
- parser dedup in `workflow-gate.sh` (shared reader)
- path-based filtering improvements for `/tmp` prompt artifacts
- review policy hardening: `>1200` prompt lines skip external CLI directly

### Out of Scope

- Unrelated feature additions outside prevention/review/recovery
- Historical artifact rewrites under protected session directories

## Commit Strategy

- Commit 1: policy/schema scaffolding (setup/review/impl/agent-patterns)
- Commit 2: Pack A + parser dedup + `/tmp` path-filter hardening
- Commit 3: Pack B deterministic hook tests (run immediately after Commit 2)
- Commit 4: Pack C decision persistence + compaction/restart E2E checks
- Commit 5: Proposal D + H scripts and pre-push integration
- Commit 6: Proposal F + I integrations and conformance checks

Boundary rule:
- After each commit, run deterministic checks, then `git status --short`, then start the next unit.

## Steps

### Step 0 — Plan Review Gate (Strict)

1. Run 6-slot `--mode plan` review (internal2 + external2 + expert2).
2. Persist outputs + synthesis.
3. Proceed only after all `critical/security/moderate` concerns are reflected in plan text.

### Step 1 — Structural Policy Alignment

Deliverables:
- Replace stopgap-only fidelity rule with structural triage contract.
- Extend setup hook-group selection to include `deletion_safety` and `workflow_gate`.
- Add executable-routing rule for `>1200` cutoff in `cwf:review`.

Primary files:
- `plugins/cwf/references/agent-patterns.md`
- `plugins/cwf/skills/impl/SKILL.md`
- `plugins/cwf/skills/setup/SKILL.md`
- `plugins/cwf/skills/review/SKILL.md`
- `.cwf/cwf-state.yaml`

### Step 2 — Pack A + Parser Dedup + Path Filtering

Deliverables:
- Remove avoidable suppressions by structural fixes.
- Eliminate duplicated live-state parsing in `workflow-gate.sh` via shared reader helpers.
- Add `/tmp` path filtering with explicit allow/deny fixture coverage.

Primary files:
- `plugins/cwf/hooks/scripts/workflow-gate.sh`
- `plugins/cwf/hooks/scripts/check-deletion-safety.sh`
- `plugins/cwf/hooks/scripts/check-markdown.sh`
- `plugins/cwf/hooks/scripts/check-shell.sh`
- `plugins/cwf/hooks/scripts/check-links-local.sh`
- `plugins/cwf/scripts/cwf-live-state.sh`

### Step 3 — Pack B Hook Exit-Code Tests (A→B→C order lock)

Deliverables:
- Single strict entrypoint for hook block/allow regression tests.
- Manifest-driven target discovery (avoid stale coverage drift).

Primary files:
- `plugins/cwf/scripts/test-hook-exit-codes.sh` (new)
- `plugins/cwf/scripts/check-growth-drift.sh`
- `plugins/cwf/scripts/README.md`

### Step 4 — Pack C Decision Persistence

Deliverables:
- Persist AskUserQuestion answers into `live.decision_journal`.
- Guarantee compaction/restart recoverability.
- Enforce schema + replay controls.

`decision_journal` schema (minimum):
- `decision_id`
- `ts`
- `session_id`
- `question`
- `answer`
- `source_hook`
- `state_version`
- `supersedes` (optional)
- `expires_at` (optional)

Security constraints:
- redact secrets in stored text
- bounded retention
- idempotent append by `decision_id`

Primary files:
- `plugins/cwf/hooks/scripts/log-turn.sh`
- `plugins/cwf/hooks/scripts/compact-context.sh`
- `plugins/cwf/scripts/cwf-live-state.sh`
- `plugins/cwf/references/context-recovery-protocol.md`

### Step 5 — Proposal D + H Deterministic Scripts

Deliverables:
- Runtime script dependency validator.
- README structure sync checker.
- Strict pre-push integration in generated hooks.

Primary files:
- `plugins/cwf/scripts/check-script-deps.sh` (new)
- `plugins/cwf/scripts/check-readme-structure.sh` (new)
- `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh`
- `.githooks/pre-push`
- `plugins/cwf/scripts/README.md`

### Step 6 — Proposal F + I Integration

Deliverables:
- Session-log cross-check in review code mode with deterministic reporting keys.
- Shared reference extraction for repeated output-persistence blocks.
- Conformance threshold check for extraction completeness.

Primary files:
- `plugins/cwf/skills/review/SKILL.md`
- `plugins/cwf/references/agent-patterns.md`
- `plugins/cwf/skills/plan/SKILL.md`
- `plugins/cwf/skills/clarify/SKILL.md`
- `plugins/cwf/skills/retro/SKILL.md`
- `plugins/cwf/skills/refactor/SKILL.md`

## Deterministic Gate Matrix

| Step | Command | Expected |
|------|---------|----------|
| 2 | `shellcheck -x plugins/cwf/hooks/scripts/workflow-gate.sh plugins/cwf/hooks/scripts/check-deletion-safety.sh plugins/cwf/scripts/cwf-live-state.sh` | `0` |
| 2 | `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite path-filter` | `0` |
| 3 | `bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict` | `0` |
| 3 | `bash plugins/cwf/scripts/check-growth-drift.sh --level warn --strict-hooks` | `0` |
| 4 | `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite decision-journal-e2e` | `0` |
| 5 | `bash plugins/cwf/scripts/check-script-deps.sh --strict` | `0` |
| 5 | `bash plugins/cwf/scripts/check-readme-structure.sh --strict` | `0` |
| 6 | `bash plugins/cwf/scripts/check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 --strict` | `0` |
| 6 | `bash plugins/cwf/scripts/check-shared-reference-conformance.sh --strict` | `0` |

## Success Criteria

### Behavioral (BDD)

```gherkin
Given hook blocking and allow scenarios
When strict hook tests run
Then each blocking path exits non-zero
And each allow path exits zero.

Given parser dedup and /tmp path filtering changes are applied
When path-filter fixtures run
Then false-positive cases are skipped
And hazard-relevant cases still block.

Given AskUserQuestion tool_result data is produced
When log-turn processing and compaction/restart simulation run
Then decisions are persisted in live.decision_journal
And replay/idempotency rules prevent stale duplicate decisions.

Given review prompt line count is 1201+
When provider routing resolves external slots
Then external CLI slots are skipped
And provenance contains cutoff reason and line count.

Given runtime script references are broken
When script dependency check runs
Then it exits non-zero with broken-edge diagnostics.

Given README.ko.md and README.md heading structures diverge
When structure checker runs
Then it exits non-zero with missing/extra/reordered diagnostics.

Given review mode code and session logs exist
When synthesis is generated
Then confidence note includes session-log cross-check findings with deterministic field keys.

Given output-persistence instructions were extracted to shared reference
When conformance checker runs
Then composing skills reference shared instructions
And inline duplicate blocks are below threshold.
```

### Qualitative

- Deterministic gates remain pass/fail authority.
- Safety-critical controls remain fail-closed by default.
- Deferred items are completed in this session without scope leakage.
- Shared-reference extraction reduces duplication while preserving readability.

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `plugins/cwf/scripts/test-hook-exit-codes.sh` | Create | Hook block/allow deterministic tests |
| `plugins/cwf/scripts/check-script-deps.sh` | Create | Runtime script dependency graph check |
| `plugins/cwf/scripts/check-readme-structure.sh` | Create | README structure sync gate |
| `plugins/cwf/scripts/check-review-routing.sh` | Create | >1200 review-routing deterministic check |
| `plugins/cwf/scripts/check-shared-reference-conformance.sh` | Create | Shared-reference extraction conformance gate |
| `plugins/cwf/hooks/scripts/workflow-gate.sh` | Edit | Shared parser + gate robustness |
| `plugins/cwf/hooks/scripts/log-turn.sh` | Edit | AskUserQuestion decision persistence |
| `plugins/cwf/scripts/cwf-live-state.sh` | Edit | decision_journal helpers + replay-safe writes |
| `plugins/cwf/skills/review/SKILL.md` | Edit | >1200 cutoff and session-log cross-check contract |
| `plugins/cwf/skills/setup/SKILL.md` | Edit | Hook group parity update |
| `plugins/cwf/skills/impl/SKILL.md` | Edit | Structural triage fidelity contract |
| `plugins/cwf/references/agent-patterns.md` | Edit | Triage format + shared reference policy |
| `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh` | Edit | Pre-push gate generation updates |
| `.githooks/pre-push` | Edit | Strict deterministic gate parity |
| `plugins/cwf/scripts/README.md` | Edit | New script map entries |
| `.cwf/cwf-state.yaml` | Edit | Hook-group state parity |

## Don't Touch

- `.cwf/projects/260217-02-refactor-review-prevention-run/**`
- `.cwf/projects/260217-03-refactor-review-prevention-impl/merge-preserved/**`

## Deferred Actions

- [ ] None (deferred-inclusive execution for this session)
