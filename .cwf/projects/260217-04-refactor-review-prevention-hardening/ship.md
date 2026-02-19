# Ship Draft (Document-Only)

- Mode: document-only (no GitHub issue/PR/merge actions executed)
- Requested by user: skip live issue creation and keep ship output as artifact text.

## Branch Context

- base branch: `marketplace-v3`
- working branch: `feat/260217-04-hardening-deferred-all`
- pushed commit head: `f36eb05`
- ahead commits vs base:
  1. `19baa9b` hardening: align triage contract and review/setup policy
  2. `ae211ac` hardening: dedupe live-state reads and tighten hook path filters
  3. `70f3110` hardening: add manifest-driven hook exit regression suites
  4. `d566995` hardening: persist decision journal across compact recovery
  5. `defe3d8` hardening: add strict pre-push gates for script deps and readme parity
  6. `a597e38` hardening: add review routing and shared-reference conformance gates
  7. `f36eb05` chore(cwf): commit session 260217-04 artifacts and logs

## Additional Local (Not Yet Committed)

- behavior-policy follow-up fixes:
  - `plugins/cwf/hooks/scripts/workflow-gate.sh`
  - `plugins/cwf/hooks/scripts/log-turn.sh`
  - `plugins/cwf/scripts/check-script-deps.sh`
- session artifacts:
  - code review outputs (`review-*-code.md`)
  - synthesis docs (`review-synthesis-code.md`, `review-synthesis-code-followup.md`)
  - refactor outputs (`refactor-summary.md`, `refactor-quick-scan.json`)
  - retro outputs (`retro-evidence.md`, `retro.md`)

## Draft PR Title

`S260217-04: Hardening deferred-inclusive prevention/review/recovery controls`

## Draft PR Purpose

Deliver deterministic hardening for workflow prevention/review/recovery:
- strict review routing and cutoff behavior
- hook exit-code regression coverage
- decision journal persistence across compaction/restart
- deterministic pre-push gates for dependency/readme/conformance checks
- post-review fail-open remediation for workflow gate and dependency-edge detection

## Draft Verification Checklist

```text
bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict
bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite decision-journal-e2e
bash plugins/cwf/scripts/check-script-deps.sh --strict
bash plugins/cwf/scripts/check-readme-structure.sh --strict
bash plugins/cwf/scripts/check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 --strict
bash plugins/cwf/scripts/check-shared-reference-conformance.sh --strict
shellcheck -x plugins/cwf/hooks/scripts/workflow-gate.sh plugins/cwf/hooks/scripts/log-turn.sh plugins/cwf/scripts/check-script-deps.sh
```

## Human Judgment Required

- Review expected control behavior for dependency-degraded `workflow-gate` paths (blocked protected actions, warning on non-protected prompts).
- Confirm whether any additional degraded-path fixtures should be promoted into strict default suites.

## Execution Status

- `gh issue create`: not executed
- `gh pr create`: not executed
- `gh pr merge`: not executed

