## UX/DX Review
### Concerns (blocking)
- **[C1]** Step 2 calls for running `review-plan` with six reviewer slots and forbids Gemini, but the plan never mentions the artifact expectations recorded in the checkpoint matrix (the `<!-- AGENT_COMPLETE -->` sentinels or the mandatory sections in `review-synthesis-plan.md`). Operators therefore have no local guidance on what qualifies as a complete UX artifact, which makes it easy to miss a matrix requirement and causes the gate script to fail even when the review ran. Severity: moderate
- **[C2]** Step 5 asks to run `cwf:refactor --skill --holistic` once and then each of the 13 skills, persisting per-skill outputs and a consolidated summary, yet it never names those artifacts or their required shape (e.g., `refactor-quick-scan.json` must expose `.total_skills`/`.results` and any deep/tidy output must end with `<!-- AGENT_COMPLETE -->`). Without those conventions the operator cannot be sure that `check-run-gate-artifacts.sh --stage refactor` will pass, making the refactor gate brittle. Severity: moderate
### Suggestions (non-blocking)
- **[S1]** Include in the plan a compact artifact table (stage → expected files → verification command) that mirrors the plan-checkpoint-matrix rows so operators do not have to open a separate file to know which sections, sentinels, and gate commands they must satisfy for each stage.
- **[S2]** Spell out the naming, persistence location, and format rules for the refactor outputs: how to generate `refactor-quick-scan.json`, what fields it must include, and how deep/tidy artifacts should be terminated with `<!-- AGENT_COMPLETE -->`. Explicit guidance will keep per-skill runs consistent and aligned with the gate script.
### Behavioral Criteria Assessment
- [ ] Given plan review inputs, when six-slot `review-plan` runs with no Gemini providers, then six reviewer artifacts and `review-synthesis-plan.md` are persisted with completion sentinels — The plan says to run the review with the prescribed providers, but it does not surface the required sentinels/sections from the checkpoint matrix, so it is unclear what proof is needed to satisfy this criterion.
- [ ] Given implementation changes, when six-slot `review-code` runs, then `review-synthesis-code.md` includes the mandatory `session_log_*` fields and the stage gate passes — The plan lists `review-code` as a goal, but it never calls out the `session_log_*` requirements from the matrix, leaving UX operators without the checklist needed to guarantee the gate succeeds.
- [ ] Given refactor stage execution, when holistic and all 13 per-skill refactor passes complete, then per-skill outputs are persisted and the refactor gate passes — The steps mention persisting outputs and summaries but do not define the artifact names, sentinel usage, or schema expectations that `check-run-gate-artifacts.sh` enforces, so this criterion remains at risk.
- [ ] Given retro and ship artifacts, when run-closing checks execute, then `retro`/`ship` gates pass and the final run-wide gate check succeeds — Retro and ship are both in scope, yet there is no reference to required lines such as `- Mode:` or `mode:`/`blocking_open_count`/`merge_allowed`, so operators cannot tell if the artifacts they produce will satisfy the gate check.
### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: —
command: —
<!-- AGENT_COMPLETE -->
