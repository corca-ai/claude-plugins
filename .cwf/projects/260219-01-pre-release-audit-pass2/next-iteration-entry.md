# Next Iteration Single Entry (Post-Iteration 4)

Use this file as the only mention target when starting the next pre-release iteration.

## Superseded Entry

- Latest single-entry contract for runtime hardening:
  - [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry-iter5-runtime-hardening.md](next-iteration-entry-iter5-runtime-hardening.md)

## Single Mention Target

- [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry.md](next-iteration-entry.md)

## Mandatory Context Load Order

1. [Initial request and operating philosophy](project/initial-req.md)
2. [Iteration 3 progress](iter3/progress.md)
3. [Iteration 4 recommendations](iter3/iter4-recommendations.md)
4. [Iteration 4 master scenarios](iter4/master-scenarios.md)
5. [Iteration 4 progress](iter4/progress.md)
6. [Lessons](lessons.md)
7. [Overall progress report](overall-progress-report.md)
8. [Iteration 4 retro](iter4/retro.md)

## Current Known Risks Before Main Merge

1. `cwf:retro --light` direct single-run timeout persists.
2. `cwf:setup` full still shows intermittent `NO_OUTPUT` in spot-check runs.
3. smoke classifier is stronger (`WAIT_INPUT`, dashboard-style prompts), but phrase coverage maintenance remains ongoing.
4. metadata-all-missing worktree boundary is fixed in hooks, but direct runtime residuals(`K46`, `S10`) still require release decision.

## Immediate Iteration Start Checklist

1. Re-validate deterministic local gate: `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`.
2. Re-check public gate on latest main: `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main`.
3. Re-run unresolved scenarios first (`K46`, `S10`) and write evidence under `iter4/artifacts/`.
4. If behavior diverges from intended contract, stop that branch immediately and record discrepancy in both scenario file and master.
5. Confirm release decision for residual risks, then update `overall-progress-report.md` and `lessons.md`.

## Baseline Checkpoint (2026-02-20)

- Active branch: `main`
- Latest stabilization commits:
  - `3a9524d` `docs(iter4): add retro artifact and closeout notes`
  - `08e6997` `chore(cwf): bump version to 0.8.3`
  - `da2e6cc` `docs(cwf): harden non-interactive guidance and record iter4 evidence`
  - `04dd01f` `test(smoke): classify dashboard-style wait prompts`
  - `e3f03d8` `fix(hooks): alert on missing worktree binding metadata`
- Deterministic checks status in this branch:
  - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf` PASS
  - `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main` PASS
  - `bash scripts/tests/noninteractive-skill-smoke-fixtures.sh` PASS
  - `bash .claude/skills/plugin-deploy/scripts/check-consistency.sh cwf` => `gap_count: 0`

## Single-Mention Resume Contract

If a new session mentions only this file, treat it as a full resume trigger:

1. Load documents in the exact order above.
2. Assume this checkpoint as canonical unless newer evidence exists in linked artifacts.
3. Start from unresolved risk scenarios (`K46`, `S10`) and release-decision framing without asking for extra bootstrap context.

## Operator Note

If only one document is mentioned, treat this file as canonical launch contract and follow its linked documents in order.
