# Next Iteration Single Entry

Use this file as the only mention target when starting the next pre-release iteration.

## Single Mention Target

- [project/next-iteration-entry.md](next-iteration-entry.md)

## Mandatory Context Load Order

1. [Initial request and operating philosophy](initial-req.md)
2. [Iteration 1 master scenarios](../.cwf/projects/260219-01-pre-release-audit-pass2/iter1/master-scenarios.md)
3. [Iteration 1 progress](../.cwf/projects/260219-01-pre-release-audit-pass2/iter1/progress.md)
4. [Iteration 2 recommendations](../.cwf/projects/260219-01-pre-release-audit-pass2/iter1/iter2-recommendations.md)
5. [Overall progress report](../.cwf/projects/260219-01-pre-release-audit-pass2/overall-progress-report.md)

## Current Known Risks Before Main Merge

1. Public marketplace entry for `cwf` is still missing on `corca-ai/claude-plugins@main` (`predeploy` gate fails with `MISSING_ENTRY`).
2. `cwf:retro --light` still times out in non-interactive smoke.
3. Interactive prompt exits must be treated as `WAIT_INPUT` (already fixed in smoke classifier; keep enforcing this).

## Immediate Iteration Start Checklist

1. Re-validate deterministic local gate: `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`.
2. Re-check public gate only when main is updated: `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main`.
3. Restart scenario loop from master and update scenario scratchpads under `.cwf/projects/260219-01-pre-release-audit-pass2/iter*/scenarios`.
4. If behavior diverges from intent, stop that branch immediately and record in both scenario file and master.
5. Finish iteration with plan -> review -> impl -> review -> refactor -> retro artifacts, then update overall progress report.

## Operator Note

If only one document is mentioned, treat this file as the canonical launch contract and follow its linked documents in order.
