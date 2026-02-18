# Review — Code Mode

## Scope

Review target: current uncommitted diff from pre-release audit implementation.

Review lenses applied:
- Correctness
- Architecture/Maintainability
- Security/Reliability
- Portability/UX-DX

## Findings

### Initial blocking/major findings (resolved)

1. Run completion gate provenance parser used wrong table column for `Gate Outcome`, which could force-validate skipped closing stages.
- Fixed in: `plugins/cwf/skills/run/SKILL.md`

2. Workflow gate blocked protected actions only when `review-code` was pending, not when other run-closing gates were pending.
- Fixed in: `plugins/cwf/hooks/scripts/workflow-gate.sh`

3. Compact recovery could fail hard when `jq` was unavailable.
- Fixed in: `plugins/cwf/hooks/scripts/compact-context.sh`

4. Project-root resolution hardening in `next-prompt-dir.sh` temporarily removed script-location fallback and could break external invocation.
- Fixed by restoring compatibility fallback with cwd-first priority and explicit `CWF_PROJECT_ROOT` override.
- Fixed in: `plugins/cwf/scripts/next-prompt-dir.sh`

### Remaining blocking findings

- None.

## Residual Risks (non-blocking)

- Hook template rendering and script-source SHA now have degraded-mode fallbacks, but environments missing common tooling (`perl`, `sha256sum`/`shasum`) should still be surfaced early in setup output for operator clarity.

## Verdict

- **PASS** (no unresolved blocking concerns after fixes).
