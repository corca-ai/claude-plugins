# Scenario Dashboard Project

This project builds a single interactive HTML file that consolidates scenario-level test outcomes for:

- `.cwf/projects/260219-01-pre-release-audit-pass2`

## Files

- Generator: `scripts/build-scenario-dashboard.mjs`
- Output HTML: `scenario-dashboard.html`
- Browser smoke screenshot: `dashboard-smoke.png`
- Verification notes: `verification.md`

## Regenerate

```bash
node .cwf/projects/260220-07-scenario-dashboard-html/scripts/build-scenario-dashboard.mjs \
  --source .cwf/projects/260219-01-pre-release-audit-pass2 \
  --output .cwf/projects/260220-07-scenario-dashboard-html/scenario-dashboard.html
```
