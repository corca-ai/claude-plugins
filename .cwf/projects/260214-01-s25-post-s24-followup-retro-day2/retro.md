# Retro — HITL Path Relocation and Setup Hardening

## Context Worth Remembering

- HITL runtime state path was relocated from `.cwf/hitl/sessions/<id>/` to `.cwf/projects/<session-dir>/hitl/`.
- Active pointer fields in `.cwf/cwf-state.yaml` now reference project-scoped HITL state files.
- `cwf:setup` now includes an explicit env migration phase for legacy keys.
- Lint/gate rules now exclude `.cwf/prompt-logs/` archives to avoid blocking active work.

## What Worked

- Path migration was low-risk because the live pointer model already decoupled runtime files from review flow.
- Existing checks (`markdownlint`, `check-links`, `check-session --live`) were enough to validate the transition.
- Prompt-log archive exclusion removed a frequent source of commit friction.

## What Did Not Work Well

- Live `dir` in state and actual on-disk session artifact layout had drift.
- HITL state location policy was documented, but not anchored to per-session project directories.
- Documentation updates and runtime-file moves were not performed in one step initially.

## Decisions

1. **Project-scoped HITL state is canonical**
   - Store HITL machine state under `.cwf/projects/<session-dir>/hitl/`.
2. **Pointer-only live metadata remains**
   - Keep only `session_id`, state/rules pointers, and timestamp in `.cwf/cwf-state.yaml`.
3. **Archive docs are non-gating**
   - Keep `.cwf/prompt-logs/` as historical artifacts, excluded from markdown quality gates.

## Follow-up Actions

- Align any remaining HITL automation scripts (if later added) to resolve paths from `live.hitl.state_file` first.
- Add a deterministic check that validates `live.dir` exists and contains expected per-session artifacts.
- Continue README/README.ko polish on wording and structure.
