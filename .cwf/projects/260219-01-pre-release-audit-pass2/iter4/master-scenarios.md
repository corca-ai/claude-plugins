# Iteration 4 Master Scenarios

## Objective

Resolve the remaining non-interactive reliability risks and finalize merge-ready evidence.

## Working Rules

- Record per-scenario notes under `iter4/scenarios/`.
- If behavior diverges from intended contract, stop immediately and log evidence first.
- Re-run deterministic gates at iteration start and after each meaningful code change.

## Shared Environment

- Execution branch: `iter3/260219-01-pre-release-audit-pass2`
- Reference branch: `main`
- Canonical resume entry: [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry.md](../next-iteration-entry.md)

## Scenario Table

| ID | Category | Goal | Status | Notes |
|---|---|---|---|---|
| I4-S00 | bootstrap | capture baseline checkpoint and gate evidence | PENDING | premerge/predeploy re-run |
| I4-G01 | gate | verify premerge deterministic gate remains PASS | PENDING | `scripts/premerge-cwf-gate.sh --mode premerge` |
| I4-G02 | gate | verify predeploy/public marketplace gate remains PASS | PENDING | `scripts/premerge-cwf-gate.sh --mode predeploy` |
| I4-K46 | retro | remove `cwf:retro --light` direct timeout path | PENDING | require explicit non-timeout result |
| I4-S10 | setup/full | eliminate intermittent `NO_OUTPUT` and force explicit output | PENDING | repeated non-interactive runs |
| I4-W20 | worktree/guard | add metadata-all-missing alert path evidence | PENDING | warning or block must be observable |

## Initial Execution Order

1. `I4-S00` -> `I4-G01` -> `I4-G02`
2. `I4-K46` (highest risk)
3. `I4-S10`
4. `I4-W20`
