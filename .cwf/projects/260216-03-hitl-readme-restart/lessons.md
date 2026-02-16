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
