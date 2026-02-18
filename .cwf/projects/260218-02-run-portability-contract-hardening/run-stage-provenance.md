# Run Stage Provenance
| Stage | Skill | Args | Started At (UTC) | Finished At (UTC) | Duration (s) | Artifacts | Gate Outcome |
|---|---|---|---|---|---|---|---|
| gather | cwf:gather | repo audit for SoT + portability drift | 2026-02-18T06:32:00Z | 2026-02-18T06:40:00Z | 480 | plan draft inputs | pass |
| clarify | cwf:clarify | policy split for external-repo execution | 2026-02-18T06:40:00Z | 2026-02-18T06:48:00Z | 480 | run-ambiguity-decisions.md | pass |
| plan | cwf:plan | six-guardrail implementation contract | 2026-02-18T06:48:00Z | 2026-02-18T06:55:00Z | 420 | plan.md | pass |
| review-plan | cwf:review --mode plan | portability and policy consistency review | 2026-02-18T06:55:00Z | 2026-02-18T07:00:00Z | 300 | plan.md updates | pass |
| impl | cwf:impl --skip-clarify | contracts/scripts/hooks/docs implementation | 2026-02-18T07:00:00Z | 2026-02-18T07:25:00Z | 1500 | plugins/cwf/contracts/*.json, gate scripts, .githooks | pass |
| review-code | cwf:review --mode code | deterministic gate + regression execution | 2026-02-18T07:25:00Z | 2026-02-18T07:37:00Z | 720 | command transcripts in session notes | pass |
| refactor | cwf:refactor | docs/script-map consistency cleanup | 2026-02-18T07:37:00Z | 2026-02-18T07:45:00Z | 480 | docs/plugin-dev-cheatsheet.md, scripts/README.md | pass |
| retro | cwf:retro --from-run | capture decisions and prevention lessons | 2026-02-18T07:45:00Z | 2026-02-18T07:50:00Z | 300 | retro.md, lessons.md | pass |
| ship | cwf:ship | doc-only ship output (no GitHub mutation) | 2026-02-18T07:50:00Z | 2026-02-18T07:55:00Z | 300 | ship.md | pass |
