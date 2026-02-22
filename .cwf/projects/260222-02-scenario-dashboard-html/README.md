# Scenario Dashboard Project

This project builds a single interactive HTML file that consolidates scenario-level test outcomes for:

- `.cwf/projects/260219-01-pre-release-audit-pass2`

## Files

- Generator: `scripts/build-scenario-dashboard.mjs`
- Refresh helper: `scripts/refresh-scenario-dashboard.sh`
- Output HTML: `scenario-dashboard.html`
- Verification notes: `verification.md`

## Regenerate

```bash
node .cwf/projects/260222-02-scenario-dashboard-html/scripts/build-scenario-dashboard.mjs \
  --source .cwf/projects/260219-01-pre-release-audit-pass2 \
  --output .cwf/projects/260222-02-scenario-dashboard-html/scenario-dashboard.html \
  --compare-mode previous-iteration
```

## Refresh Workflow (Recommended)

```bash
bash .cwf/projects/260222-02-scenario-dashboard-html/scripts/refresh-scenario-dashboard.sh
```

This does a dashboard refresh with delta comparison against the previous iteration for
the same scenario key suffix (for example `K46`, `R60`, `S10`).

## Compare Against Older Baseline Project

```bash
bash .cwf/projects/260222-02-scenario-dashboard-html/scripts/refresh-scenario-dashboard.sh \
  --source .cwf/projects/260223-01-pre-release-audit-pass3 \
  --compare-mode baseline-project \
  --baseline-source .cwf/projects/260219-01-pre-release-audit-pass2 \
  --output .cwf/projects/260223-01-pre-release-audit-pass3/scenario-dashboard.html
```

## Refresh After Running Deterministic Gates

```bash
bash .cwf/projects/260222-02-scenario-dashboard-html/scripts/refresh-scenario-dashboard.sh \
  --run-gates \
  --runtime-mode strict
```

By default, gate failures do not block dashboard generation (for visual diff first).
If you need strict CI-style failure, add:

```bash
--fail-on-gate-error
```
