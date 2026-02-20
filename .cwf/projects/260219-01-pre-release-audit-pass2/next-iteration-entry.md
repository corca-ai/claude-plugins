# Next Iteration Single Entry (Iteration 4)

Use this file as the only mention target when starting the next pre-release iteration.

## Single Mention Target

- [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry.md](next-iteration-entry.md)

## Mandatory Context Load Order

1. [Initial request and operating philosophy](project/initial-req.md)
2. [Iteration 3 master scenarios](iter3/master-scenarios.md)
3. [Iteration 3 progress](iter3/progress.md)
4. [Iteration 4 recommendations](iter3/iter4-recommendations.md)
5. [Lessons](lessons.md)
6. [Overall progress report](overall-progress-report.md)
7. [Iteration 3 retro](iter3/retro.md)

## Current Known Risks Before Main Merge

1. `cwf:retro --light` direct single-run timeout persists.
2. `cwf:setup` full still shows intermittent `NO_OUTPUT` in spot-check runs.
3. Primary worktree guard bypass was fixed, but metadata-all-missing boundary still lacks a dedicated alert path.
4. smoke classifier is stronger (`WAIT_INPUT`, `NO_OUTPUT`) but still relies on phrase coverage maintenance.

## Immediate Iteration Start Checklist

1. Re-validate deterministic local gate: `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`.
2. Re-check public gate on latest main: `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main`.
3. Re-run unresolved scenarios first (`K46`, `S10`, `W20`) and write evidence under `iter4/artifacts/`.
4. If behavior diverges from intended contract, stop that branch immediately and record discrepancy in both scenario file and master.
5. Finish with plan -> review -> impl -> review -> refactor -> retro artifacts and update `overall-progress-report.md`.

## Baseline Checkpoint (2026-02-20)

- Active branch: `iter3/260219-01-pre-release-audit-pass2`
- Latest stabilization commits:
  - `e5f921b` `fix(cwf): fail-close worktree guard + retro light fastpath`
  - `94806b5` `fix(setup): enforce wait-input fail-fast and smoke classifier coverage`
  - `6cb4b1b` `chore(sandbox): convert iter2 sandbox gitlinks to tracked directories`
  - `b464593` `chore(sandbox): convert iter1 sandbox gitlinks to tracked directories`
  - `e80496e` `chore(sandbox): preserve nested repo metadata backups for iter1 and iter2`
- Deterministic checks status in this branch:
  - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf` PASS
  - `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main` PASS
  - `bash scripts/tests/noninteractive-skill-smoke-fixtures.sh` PASS
  - `bash .claude/skills/plugin-deploy/scripts/check-consistency.sh cwf` => `gap_count: 0`

## Single-Mention Resume Contract

If a new session mentions only this file, treat it as a full resume trigger:

1. Load documents in the exact order above.
2. Assume this checkpoint as canonical unless newer evidence exists in linked artifacts.
3. Start Iteration 4 from unresolved risk scenarios without asking for extra bootstrap context.

## Operator Note

If only one document is mentioned, treat this file as canonical launch contract and follow its linked documents in order.
