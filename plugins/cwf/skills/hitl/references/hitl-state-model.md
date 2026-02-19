# HITL State Model

Canonical persistence model for `cwf:hitl`.

[SKILL.md](../SKILL.md) defines workflow behavior; this document is the single source of truth for runtime artifact schemas and state transitions.

## 1. Runtime Artifact Layout

Persist detailed HITL state under:

```text
.cwf/projects/{session-dir}/hitl/
  hitl-scratchpad.md
  state.yaml
  rules.yaml
  queue.json
  fix-queue.yaml
  events.log
```

`cwf-state.yaml` keeps pointer metadata only:

```yaml
live:
  phase: hitl
  hitl:
    session_id: "Sxx-hitl"
    state_file: ".cwf/projects/{session-dir}/hitl/state.yaml"
    rules_file: ".cwf/projects/{session-dir}/hitl/rules.yaml"
    updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

## 2. queue.json Contract

`queue.json` tracks resumable review progress at file and chunk granularity.

- File status enum: `pending | in_review | reviewed | stale`
- Chunk status enum: `pending | reviewed | stale`
- Each file entry stores `blob_sha` captured when the queue was built
- Reopen logic compares current blob to saved `blob_sha` and marks overlaps
  `stale` when drift is detected

## 3. state.yaml Contract

`state.yaml` stores run-level progress and intent-resync gate fields.

```yaml
session_id: "Sxx-hitl"
status: "in_progress"
intent_resync_required: false
last_user_manual_edit_at: ""
last_intent_resync_at: ""
intent_resync_note: ""
```

Field intent:

- `session_id`: HITL run identifier
- `status`: run state (`in_progress`, `completed`, or `closed_by_user`)
- `intent_resync_required`: hard gate before presenting the next chunk
- `last_user_manual_edit_at`: UTC timestamp for latest out-of-band/manual edit
- `last_intent_resync_at`: UTC timestamp when intent resync was confirmed
- `intent_resync_note`: short note describing what changed

The file may include additional cursor/progress fields needed for `--resume`. Those fields are implementation-defined but must be persisted before every user pause.

## 4. Intent-Resync Lifecycle

Operational contract used by Phase 0.75:

1. **Trigger set**: manual edit or out-of-band change detected
2. **Gate on**: set `intent_resync_required: true`, write
   `last_user_manual_edit_at`, and record `intent_resync_note`
3. **Resync before next chunk**:
   - re-read changed files
   - confirm updated intent with the user
   - update `hitl-scratchpad.md` with the intent delta
4. **Gate clear**: set `intent_resync_required: false` and write
   `last_intent_resync_at`

Do not present the next chunk while the gate is active.

## 5. Other Artifact Roles

- `fix-queue.yaml`: actionable edit queue, especially for edits requested on
  already reviewed regions
- `rules.yaml`: normalized rule set that must propagate to remaining chunks
- `hitl-scratchpad.md`: agreement/rationale log and intent delta record
- `events.log`: immutable operational event log (gate triggers, major state
  transitions)
