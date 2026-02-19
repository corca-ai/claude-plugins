## Correctness Review
### Concerns (blocking)
- **[C1]** Refactor gate does not verify the plan’s required scope (holistic + 13/13 per-skill runs). Current gate can pass with only one artifact, which contradicts the behavioral criterion.  
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:22`, `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:48`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:11`, `plugins/cwf/scripts/check-run-gate-artifacts.sh:195`  
  Severity: critical
- **[C2]** Per-skill refactor artifact persistence is underspecified and currently collision-prone: deep review writes fixed filenames, so 13 runs overwrite each other; holistic report is written outside the active session directory.  
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:26`, `plugins/cwf/skills/refactor/SKILL.md:175`, `plugins/cwf/skills/refactor/SKILL.md:176`, `plugins/cwf/skills/refactor/SKILL.md:301`  
  Severity: critical
- **[C3]** Review-plan/final verification snippets are fail-open. The `for` loop does not aggregate failures, and final completion uses `;` chaining, so earlier command failure can be masked by later success.  
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:6`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:7`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:18`  
  Severity: critical
- **[C4]** “No Gemini” is a hard constraint in plan text but not deterministically enforced by command/criteria. Review providers default to `auto` (can select Gemini), and matrix checks do not validate provenance tool values.  
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:8`, `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:17`, `plugins/cwf/skills/review/SKILL.md:63`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:9`  
  Severity: critical
- **[C5]** Final deterministic checks are scheduled before plugin lifecycle verification; any mutations from `plugin-deploy` can bypass the final gate snapshot.  
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:29`, `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:32`  
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** Add explicit per-skill artifact naming (e.g., `refactor-<skill>-deep-structural.md`, `refactor-<skill>-deep-quality.md`) and make refactor gate require 13/13 + holistic files.
- **[S2]** Make matrix commands strict/fail-fast (`set -euo pipefail`, `&&`, explicit section/verdict assertions).
- **[S3]** Re-run deterministic gates after `plugin-deploy` (or move `plugin-deploy` before Step 8).
- **[S4]** For performance, define bounded parallel batches for the 13 per-skill refactor runs and persist per-batch checkpoints.

### Behavioral Criteria Assessment
- [ ] `review-plan` criterion is deterministically enforced without fail-open paths.
- [x] `review-code` criterion includes deterministic `session_log_*` checks and stage gate command coverage.
- [ ] Refactor criterion (“holistic + all 13 per-skill outputs persisted”) is enforceable by current gate contracts.
- [x] Retro/ship criteria have explicit deterministic gate commands.

### Provenance
source: REAL_EXECUTION  
tool: codex  
reviewer: Correctness  
duration_ms: —  
command: codex exec --sandbox read-only -c model_reasoning_effort='high' -
[cwf:codex post-run] live session-state check
[cwf:codex post-run] post-run checks passed (3 checks)

<!-- AGENT_COMPLETE -->
