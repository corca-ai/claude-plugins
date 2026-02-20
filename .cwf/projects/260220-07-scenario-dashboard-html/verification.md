# Verification — scenario-dashboard-html

## Generated Artifact

- HTML: [scenario-dashboard.html](scenario-dashboard.html)
- Generator: [scripts/build-scenario-dashboard.mjs](scripts/build-scenario-dashboard.mjs)
- Source project: `../260219-01-pre-release-audit-pass2`

## Generator Check

Command:

```bash
node .cwf/projects/260220-07-scenario-dashboard-html/scripts/build-scenario-dashboard.mjs \
  --source .cwf/projects/260219-01-pre-release-audit-pass2 \
  --output .cwf/projects/260220-07-scenario-dashboard-html/scenario-dashboard.html
```

Observed output:

- `Scenarios: 69`
- `Iterations: iter1, iter2, iter3, iter4, iter5`
- `Status groups: DONE, FAIL, PARTIAL, PASS, SKIP`

## agent-browser Smoke

Target:

- `file:///home/hwidong/codes/claude-plugins/.cwf/projects/260220-07-scenario-dashboard-html/scenario-dashboard.html`

Checks:

1. Initial render confirmed controls and filter widgets.
2. Iteration select switched to `iter5`; table reduced to iter5 scenarios.
3. Search input `I5-B20` filtered to one row and detail panel updated.
4. PASS status checkbox toggle reduced results to zero as expected for iter5-only view.
5. Screenshot captured: [dashboard-smoke.png](dashboard-smoke.png)

## cwf:review Invocation (Requested)

Attempt 1:

```bash
timeout 300 claude --print "cwf:review --mode code" \
  --dangerously-skip-permissions --plugin-dir plugins/cwf
```

Attempt 2 (provider forced):

```bash
timeout 300 claude --print "cwf:review --mode code --correctness-provider claude --architecture-provider claude" \
  --dangerously-skip-permissions --plugin-dir plugins/cwf
```

Result:

- both attempts exited with `124` (timeout)
- output log remained empty (`review-cwf-review.log`, `0 bytes`)
- however, review sub-artifacts were produced in this project directory:
  - `review-security-code.md`
  - `review-ux-dx-code.md`
  - `review-correctness-code.md`
  - `review-expert-alpha-code.md`
  - `review-expert-beta-code.md`

Interpretation:

- `cwf:review` was invoked as requested, but did not complete in this non-interactive runtime path.
