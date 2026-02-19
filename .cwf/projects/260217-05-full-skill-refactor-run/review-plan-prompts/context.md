# Review Context (Mode: plan)

Target file:
- .cwf/projects/260217-05-full-skill-refactor-run/plan.md

Behavioral criteria to verify:
1. Six-slot review-plan execution persists all reviewer artifacts with sentinels and synthesis.
2. Review-code stage includes mandatory session_log_* keys and passes gate.
3. Refactor stage runs holistic + all 13 per-skill --skill runs and passes gate.
4. Retro and ship artifacts are produced and final deterministic run checks pass.

Qualitative criteria:
- Resumable artifacts after compaction/restart.
- Stage-based commit readability/auditability.
- Deferred architecture debt documented explicitly.

Provider constraint:
- No Gemini.
