# Run Stage Provenance
| Stage | Skill | Args | Started At (UTC) | Finished At (UTC) | Duration (s) | Artifacts | Gate Outcome |
|---|---|---|---|---|---|---|---|
| gather | cwf:gather | --local concept-governance-yaml-unification | 2026-02-24T00:19:08Z | 2026-02-24T00:21:08Z | 120 | .cwf/projects/260224-01-concept-governance-yaml-unification/gather.md | Proceed (user directive) |
| clarify | cwf:clarify | --light | 2026-02-24T00:21:17Z | 2026-02-24T00:22:17Z | 60 | .cwf/projects/260224-01-concept-governance-yaml-unification/clarify-result.md | Proceed (user directive) |
| plan | cwf:plan | from clarify baseline | 2026-02-24T00:21:12Z | 2026-02-24T00:23:12Z | 120 | .cwf/projects/260224-01-concept-governance-yaml-unification/plan.md,.cwf/projects/260224-01-concept-governance-yaml-unification/lessons.md | Proceed (user directive) |
| review-plan | cwf:review | --mode plan | 2026-02-24T00:22:43Z | 2026-02-24T00:23:43Z | 60 | .cwf/projects/260224-01-concept-governance-yaml-unification/review-synthesis-plan.md | Conditional Pass |
| impl | cwf:impl | --skip-clarify | 2026-02-24T00:10:26Z | 2026-02-24T00:35:26Z | 1500 | commits:d3643fe,b1e8a08,8f0f334,edd7504 | completed |
| review-code | cwf:review | --mode code | 2026-02-24T00:30:56Z | 2026-02-24T00:36:56Z | 360 | .cwf/projects/260224-01-concept-governance-yaml-unification/review-synthesis-code.md | Pass |
| refactor | cwf:refactor | default | 2026-02-24T00:35:20Z | 2026-02-24T00:37:20Z | 120 | .cwf/projects/260224-01-concept-governance-yaml-unification/refactor-summary.md | completed |
| retro | cwf:retro | --from-run | 2026-02-24T00:36:38Z | 2026-02-24T00:37:38Z | 60 | .cwf/projects/260224-01-concept-governance-yaml-unification/retro.md | completed |
| ship | cwf:ship | default | 2026-02-24T00:37:36Z | 2026-02-24T00:38:36Z | 60 | .cwf/projects/260224-01-concept-governance-yaml-unification/ship.md | completed |
