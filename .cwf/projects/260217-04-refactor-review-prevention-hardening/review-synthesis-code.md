## Review Synthesis

### Verdict: Revise
The implementation direction is largely aligned with the hardening plan, but review identified fail-open control-path risks and incomplete dependency-edge coverage that must be corrected before closing the code-review gate.

### Behavioral Criteria Verification
- [x] Given hook blocking and allow scenarios, strict hook tests return non-zero for blocking paths and zero for allow paths — evidence from Security/UX-DX/Correctness/Architecture (`bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict`, pass).
- [x] Given parser dedup and `/tmp` path filtering, path-filter fixtures skip false positives and still block hazard-relevant cases — evidence from Security/UX-DX (`--suite path-filter`, pass).
- [x] Given AskUserQuestion tool_result, log-turn + compaction/restart simulation persists decisions with replay/idempotency controls — evidence from Security/UX-DX/Correctness/Architecture (`--suite decision-journal-e2e`, pass).
- [x] Given prompt line count is 1201+, external slots are skipped and cutoff evidence is retained — evidence from Security/UX-DX/Correctness/Architecture (`bash plugins/cwf/scripts/check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 --strict`, pass).
- [ ] Given runtime script references are broken, dependency check exits non-zero with complete broken-edge diagnostics — Correctness/Architecture reported coverage blind spots (`${PLUGIN_ROOT}` and local include edge extraction gaps) in `plugins/cwf/scripts/check-script-deps.sh`.
- [x] Given README heading structures diverge, structure checker exits non-zero with diagnostics — evidence from Security/UX-DX/Correctness/Architecture (`bash plugins/cwf/scripts/check-readme-structure.sh --strict`, pass).
- [x] Given code-mode review with session logs, synthesis includes deterministic `session_log_*` fields — contract present in `plugins/cwf/skills/review/SKILL.md` and included below.
- [x] Given shared output-persistence extraction, conformance checker enforces references and duplicate threshold — evidence from Security/UX-DX/Correctness/Architecture (`bash plugins/cwf/scripts/check-shared-reference-conformance.sh --strict`, pass).

### Concerns (must address)
- **Correctness** [moderate]: dependency-edge extraction in `check-script-deps` is incomplete, so strict mode may miss broken runtime references.
  `plugins/cwf/scripts/check-script-deps.sh`
- **Architecture** [moderate]: same dependency-edge blind spot (`${PLUGIN_ROOT}` / local include patterns) weakens deterministic coverage guarantee.
  `plugins/cwf/scripts/check-script-deps.sh`
- **Expert Alpha (Charles Perrow)** [high]: workflow-gate may fail open when live-state parsing degrades, creating common-mode bypass risk.
  `plugins/cwf/hooks/scripts/workflow-gate.sh`, `plugins/cwf/scripts/cwf-live-state.sh`
- **Expert Beta (Nancy Leveson)** [critical]: degraded sensing path allows unsafe control action (`allow`) when gate dependencies are unavailable.
  `plugins/cwf/hooks/scripts/workflow-gate.sh:13`, `plugins/cwf/hooks/scripts/workflow-gate.sh:20`

### Suggestions (optional improvements)
- Add strict query semantics for gate-critical live-state reads to distinguish missing/malformed keys from intentional empties.
- Improve decision journal failure visibility in `log-turn` (avoid silent suppression on append failure).
- Add deterministic tests for degraded workflow-gate dependencies (missing `jq`, missing live-state resolver) and malformed live-state key parsing.

### Commit Boundary Guidance
- `tidy`: extraction/readability-only changes (helper refactor, naming cleanup).
- `behavior-policy`: gate behavior, parser strictness, dependency-edge detection, recovery persistence semantics.
- Follow-up from this review is predominantly `behavior-policy`; keep it in dedicated commit unit(s).

### Confidence Note
- Base: `marketplace-v3` (explicit `--base`).
- External CLI skipped: `prompt_lines=3652 cutoff=1200 reason=prompt_lines_gt_1200`.
- Slot 3/4 were executed via deterministic fallback path by policy (not runtime CLI error fallback).
- Session-log cross-check fields:
  - `session_log_present: true`
  - `session_log_lines: 60`
  - `session_log_turns: 1`
  - `session_log_last_turn: ## Turn 1 [11:33:15 -> 11:34:40]`
  - `session_log_cross_check: PASS`

### Reviewer Provenance
| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | FALLBACK | claude-task-fallback | — |
| Architecture | FALLBACK | claude-task-fallback | — |
| Expert Alpha | REAL_EXECUTION | claude-task | — |
| Expert Beta | REAL_EXECUTION | claude-task | — |
