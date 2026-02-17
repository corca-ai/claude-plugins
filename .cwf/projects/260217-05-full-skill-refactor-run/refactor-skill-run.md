# Refactor Review: run skill

## Executive Summary
- `run` keeps its SKILL.md within the progressive-disclosure guardrails (1,930 words / 366 lines, frontmatter limited to `name` + `description`), and only references `agent-patterns.md` + `plan-protocol.md`, so there are no unused bundled resources.
- The stage table and Phase guards clearly describe the default pipeline, but some of the workflow-level behaviors that tie the pipeline together remain under-specified (Ambiguity `explore-worktrees`, review verdict failure handling, and per-stage provenance logging).
- Because `run` composes the Agent Orchestration concept per `plugins/cwf/references/concept-map.md`, filling these gaps will keep the orchestrator accountable for the work-item decomposition, team behavior, and provenance that downstream skills rely on.

## Evaluation Metrics
- Word count: `1,930` (Criterion 1 warning threshold: 3,000).
- Line count: `366` (Criterion 1 warning threshold: 500).
- Resource files referenced: `plugins/cwf/skills/run/SKILL.md` only cites `agent-patterns.md` and `plan-protocol.md`; no scripts/assets exist, so there are no unused-resource flags under Criterion 4.

## Findings

### Structural / Duplication (Criteria 1–4)
1. **Medium — The `explore-worktrees` ambiguity mode is only described at a conceptual level.** The “Ambiguity Modes (Clarify T3 Policy)” table (`plugins/cwf/skills/run/SKILL.md:119-136`) says the mode should “Implement alternatives in separate worktrees, then pick baseline,” but there is no follow-on text describing how to create/manage those worktrees, how to record which branch/worktree is the baseline, or how to clean them up when the pipeline resumes. That leaves agents without the low-level workflow they need to satisfy the claimed behavior and undermines progressive disclosure (Criterion 2) by promising a capability without showing the concrete steps. Documenting the worktree commands (`git worktree add ...`), naming conventions, and a cleanup/merge strategy is needed so the mode can actually be followed.

### Quality / Degrees of Freedom & Concept (Criteria 5–8)
1. **Medium — Review failures that return `Fail` are unhandled.** Review-failure handling (`plugins/cwf/skills/run/SKILL.md:233-251`) only covers `Revise` verdicts, with one auto-fix retry then escalation. If a review returns `Fail` (or an equally high-severity verdict), the skill does not say whether to halt, ask the user, or attempt the same retry loop. That ambiguity leaves the auto-run pipeline uncertain about whether to stop before `ship` or behave like `Revise`, which undermines the deterministic gate discipline described elsewhere. Add a paragraph describing the treatment for `Fail` (e.g., halt, summarize concerns, request user direction) so implementers know how to proceed when an absolute block is issued.
2. **Medium — Agent Orchestration concept lacks provenance/state guidance.** `plugins/cwf/references/concept-map.md` marks `run` as composing Agent Orchestration, whose required state includes a “Provenance metadata (source, tool, duration per output)” and whose required actions include “Collect and verify results.” The SKILL currently describes the stage loop (Phase 2) but never instructs how to record which sub-skill produced which artifact, how long each stage ran, or how to persist that metadata to `cwf-state`/session logs for downstream traceability. Without that guidance, a future agent cannot prove that `run` kept the “distinct agent outputs with provenance” invariants the concept demands. Add a short checklist or log template (e.g., `session-log.md` entries or live-state keys) that captures the stage name, invoked skill + args, start/stop timestamps, gate outcome, and artifact references so the orchestrator’s provenance requirements are satisfiable.

## Suggested Actions
1. Expand the Ambiguity Modes section with concrete steps for `explore-worktrees`: describe how to add worktrees, name/track them, document the variants explored, and reconcile to a baseline before continuing the pipeline.
2. Document the treatment for `Fail` verdicts from any review stage (plan/code); include whether the pipeline halts, how to summarize the block to the user, and when/if another review attempt is allowed.
3. Introduce a provenance/telemetry checklist for each stage (skill name, args, gate result, artifacts produced, duration) and prescribe where to persist it (e.g., `session-log.md`, `cwf-state.yaml`, or a dedicated artifact) so the Agent Orchestration concept has the required state and actions.

## Next Steps
1. Update `plugins/cwf/skills/run/SKILL.md` with the suggested clarifications so the run orchestrator can be executed deterministically in every ambiguity mode and verdict scenario.
2. Rerun `cwf:refactor --skill run` to verify that no new flags appear and that the provenance checklist is referenced by downstream gate scripts.

<!-- AGENT_COMPLETE -->
