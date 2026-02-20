# Iteration 4 Recommendations

## Objective

Close the remaining non-interactive reliability gaps and finalize merge-ready evidence for public release.

## Priority Order

1. Fix `cwf:retro --light` direct timeout at runtime path level.
2. Remove intermittent `NO_OUTPUT` from `cwf:setup` full and force explicit `WAIT_INPUT` output.
3. Add a lightweight alert path for the worktree guard when both session-map and live metadata are missing.
4. Keep smoke classifier coverage synchronized with new phrasing and failure modes.

## What Was Already Improved Before Iteration 4

1. `iter1`/`iter2` sandbox gitlink boundaries were converted to tracked directories.
2. Nested repo `.git` metadata was preserved as tracked backup snapshots under sandbox.
3. Missing initial request path was restored by creating `project/initial-req.md`.

## Suggested Scenario Seeds

1. `I4-K46`: `cwf:retro --light` single-run direct path (expect non-timeout explicit outcome).
2. `I4-S10`: `cwf:setup` full repeated runs (expect no `NO_OUTPUT` recurrence).
3. `I4-W20`: metadata-all-missing guard path (expect warning or block evidence).
4. `I4-G01/I4-G02`: premerge/predeploy gates must remain PASS.

## Completion Criteria

1. `cwf:retro --light` no longer returns `FAIL(TIMEOUT)` in direct non-interactive run.
2. setup full produces explicit classification output on every run (`WAIT_INPUT` or deterministic outcome).
3. deterministic gates remain PASS after fixes:
   - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`
   - `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main`
