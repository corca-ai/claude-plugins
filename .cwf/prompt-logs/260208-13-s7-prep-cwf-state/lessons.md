# S7-prep Lessons

## Schema Evolution Decisions

### `dir` replaces `artifacts[]`
- Master plan originally specified `artifacts: [dir1, dir2]` for session entries
- In practice, every session has exactly one directory under `prompt-logs/`
- Single `dir` field is simpler, less maintenance, and sufficient for all current sessions
- If a session ever needs multiple artifact dirs, can add `extra_dirs[]` later

### `branch` added
- Not in original master-plan target schema
- Useful for merge topology context — most sessions on `main`, S6b on `marketplace-v3`
- Helps next session agent understand if there's an open feature branch

### `stage` omitted from session entries
- Master plan target had `stage` per session entry
- Redundant: `workflow.stages` map already shows which sessions belong to which stage
- Sessions are building CWF, not running through CWF workflow stages

### `review_notes` omitted
- Each session dir already contains `retro.md` which serves this purpose
- Duplicating review notes in YAML would create sync issues

## Year Typo Fix

- `started_at` was `"2025-02-08"` — should be `"2026-02-08"`
- Root cause: original cwf-state.yaml was created during S4 scaffold, likely auto-completed wrong year
- Fixed as part of this session's updates

## S5b Directory Naming Anomaly

- S5b dir is `260208-03-s5b-external-reviewers` (sequence `03` reused from S0's dir)
- This is not a bug — the `03` prefix was already taken by S0, but S5b was created in a separate context
- Recorded here for future reference; no action needed since `dir` field is explicit
