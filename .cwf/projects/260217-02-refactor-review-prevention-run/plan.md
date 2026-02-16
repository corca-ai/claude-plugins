# Plan — Run Review & Prevention Controls

## Context
A prior refactoring session introduced runtime breakage by deleting a script that still had callers. The source review recommends deterministic prevention gates and stronger workflow-state enforcement.

## Goal
Implement high-priority guardrails (`A`, `B`, `C`, `E+G`) so deletion safety, broken-link triage, recommendation fidelity, and run-stage gating are enforced by runtime checks rather than prose-only guidance.

## Steps
1. Add deletion safety PostToolUse hook script and register it in hooks manifest.
2. Add workflow gate UserPromptSubmit hook script with fail-closed gating and override path.
3. Extend `cwf-live-state.sh` to support YAML list upsert/removal and gate-name validation for `remaining_gates`.
4. Update `run` skill contract to write `active_pipeline`, `remaining_gates`, `user_directive`, and `pipeline_override_reason` during stage transitions.
5. Add broken-link triage protocol to shared agent patterns and update broken-link hook message to point to the protocol.
6. Add recommendation-fidelity rule to `impl` skill rules section.
7. Update hook map docs and run deterministic checks including plugin lifecycle consistency flow.

## Files to Create/Modify
- Create: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`
- Create: `plugins/cwf/hooks/scripts/workflow-gate.sh`
- Modify: `plugins/cwf/hooks/hooks.json`
- Modify: `plugins/cwf/scripts/cwf-live-state.sh`
- Modify: `plugins/cwf/skills/run/SKILL.md`
- Modify: `plugins/cwf/references/agent-patterns.md`
- Modify: `plugins/cwf/hooks/scripts/check-links-local.sh`
- Modify: `plugins/cwf/skills/impl/SKILL.md`
- Modify: `plugins/cwf/hooks/README.md`

## Success Criteria — Behavioral (BDD)
1. Given a deleted file with callers, when deletion is attempted through Edit/Write/Bash, then hook blocks with explicit caller list.
2. Given a deleted file without callers, when deletion check runs, then hook allows silently.
3. Given `active_pipeline=cwf:run` and `remaining_gates` includes `review-code`, when user prompt requests ship/push/commit, then UserPromptSubmit hook blocks.
4. Given `pipeline_override_reason` is populated, when otherwise blocked prompt is submitted, then hook warns and allows.
5. Given run stage transition updates gates, when `remaining_gates` changes, then it is persisted as YAML list in live state file.
6. Given broken-link hook blocks, when reason is printed, then it references the Broken Link Triage protocol section.
7. Given triage item contradicts source recommendation, when impl follows rules, then original recommendation takes precedence.

## Success Criteria — Qualitative
- Deterministic-gate-first design remains explicit and self-documenting.
- Changes are backward compatible with existing live-state scalar set flow.
- Hook scripts are Bash 3.2 compatible and fail with actionable reasons.

## Don't Touch
- Runtime behavior of unrelated hooks (attention/log/read/compact) beyond required manifest additions.
- Existing session artifacts outside `.cwf/projects/260217-02-refactor-review-prevention-run/`.

## Deferred Actions
- `D`: script dependency graph checker
- `F`: session-log cross-check in review mode
- `H`: README structure sync checker
- `I`: shared reference extraction wave
