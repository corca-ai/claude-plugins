# Lessons: 260216-03-hitl-readme-restart

> Recorded at: 2026-02-16

## Key Learnings

1. Missing dependency handling should be interactive by default: ask install/configure now, apply on approval, then retry once.
2. Session-log path conventions must be resolver-driven to avoid drift between wrapper/hook/docs.
3. `check-session` should accept both session-id and session-dir selectors for practical debugging.
4. Direct `retro` invocation should always return an actionable summary and persistence proposals.

## Structural Follow-up

- Keep `.cwf/sessions` as preferred log target and preserve `.cwf/projects/sessions` compatibility.
- Continue using deterministic validation (`shellcheck`, link checks, live-state checks) before closing sessions.

## Post-Retro Addendum

1. Path migration work must include deterministic gate migration in the same change unit (lint filters, hook filters, post-run checks).
2. Session tooling should prioritize operator ergonomics (`--help`, path selectors, explicit error messages) to reduce diagnosis loops.
3. If session artifacts are contract-required, backfill should be immediate and explicit rather than deferred.
4. Generated runtime logs should not silently become commit blockers due policy drift; gate scope must match artifact intent.
