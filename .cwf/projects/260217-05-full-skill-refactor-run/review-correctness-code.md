## Correctness Review
### Concerns (blocking)
- **[C1]** `run` stage provenance has a fail/skip branch contradiction that can violate its own mandatory gate.
  Severity: moderate  
  Evidence: `plugins/cwf/skills/run/SKILL.md:267` says gate failure must stop immediately, but provenance append is defined later at `plugins/cwf/skills/run/SKILL.md:302`, while rules require every stage row at `plugins/cwf/skills/run/SKILL.md:443`. The spec does not define a guaranteed provenance write on early-stop/skip paths.

- **[C2]** `handoff` missing-session flow introduces an unhandled user option.
  Severity: moderate  
  Evidence: `plugins/cwf/skills/handoff/SKILL.md:232` offers `"Edit fields first"`, but only Confirm/Cancel outcomes are defined at `plugins/cwf/skills/handoff/SKILL.md:234` and `plugins/cwf/skills/handoff/SKILL.md:235`. This leaves an undefined execution path in a deterministic gate section.

- **[C3]** `update` current-vs-latest baseline can alias to the same cache tree, producing false comparison/changelog results and unsafe “up-to-date” outcomes.
  Severity: critical  
  Evidence: current is resolved from newest cache entry (`plugins/cwf/skills/update/SKILL.md:28`), latest is resolved the same way after marketplace update (`plugins/cwf/skills/update/SKILL.md:52`), and changelog diff compares those roots (`plugins/cwf/skills/update/SKILL.md:105`). If cache reuse or pre-population occurs, `current_plugin_root == latest_plugin_root`, collapsing diff evidence.

### Suggestions (non-blocking)
- **[S1]** In `run`, add an explicit “always append provenance row” branch for `Skipped`, `Fail`, and `User Stop` before any early return.
- **[S2]** In `handoff`, define the `"Edit fields first"` loop (editable fields, re-confirm step, and cancellation semantics).
- **[S3]** In `update`, snapshot pre-update state (or resolve active installed manifest path) before marketplace refresh, then diff against a guaranteed distinct post-update tree.

### Behavioral Criteria Assessment
- [ ] No behavioral regression / contradiction risk in changed contracts
- [ ] Deterministic gates have complete failure/decision branches
- [ ] Script/skill contracts avoid unsafe defaults and ambiguous baselines

### Provenance
source: REAL_EXECUTION  
tool: codex  
reviewer: Correctness  
duration_ms: —  
command: codex exec --sandbox read-only -c model_reasoning_effort='high' -

<!-- AGENT_COMPLETE -->
