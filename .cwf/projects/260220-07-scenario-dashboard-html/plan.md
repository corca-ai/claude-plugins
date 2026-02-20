# Plan — scenario-dashboard-html

## Goal

Create a single interactive HTML dashboard that consolidates scenario-branch test results from:

- `.cwf/projects/260219-01-pre-release-audit-pass2/iter*/master-scenarios.md`
- `.cwf/projects/260219-01-pre-release-audit-pass2/iter*/scenarios/*.md`
- linked evidence under `iter*/artifacts/`

## Scope

1. Add a generator script inside this dedicated project:
   - `scripts/build-scenario-dashboard.mjs`
2. Generate a single file HTML artifact:
   - `scenario-dashboard.html`
3. Verify interaction behavior in browser:
   - iteration filter
   - status filter
   - text search
   - scenario detail rendering
   - artifact link visibility
4. Run `cwf:review` attempt logs as requested.

## Execution Notes

- Dashboard is static/self-contained (single HTML file with embedded data and JS).
- No external npm dependency is introduced.
- The source project remains read-only from dashboard generation path.
