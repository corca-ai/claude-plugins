---
name: hitl
description: "Human-in-the-loop diff/chunk review to inject deliberate human judgment where automated review is insufficient, with resumable state, agreement-round kickoff, and rule propagation. Triggers: \"cwf:hitl\", \"hitl\", \"interactive review\", \"human review\", \"cwf:review --human\""
---

# HITL Review (cwf:hitl)

Insert deliberate human judgment into branch-diff review (`<base>...HEAD`) with resumable chunk state. Reviews file-by-file in meaningful chunks, pauses for user input each chunk, and persists state/rules so work can resume anytime.

**Language**: Write review outputs in the user's prompt language by default. If the user explicitly requests another language, follow that request.

## Quick Reference

```text
cwf:hitl [--base <branch>] [--scope docs|code|all]
cwf:hitl --resume
cwf:hitl --rule "<rule text>"
cwf:hitl --rules
cwf:hitl --state
cwf:hitl --close
# compatibility alias:
cwf:review --human [--base <branch>]
```

## State Model

Persist HITL runtime state under:

```text
.cwf/projects/{session-dir}/hitl/
  hitl-scratchpad.md
  state.yaml
  rules.yaml
  queue.json
  fix-queue.yaml
  events.log
```

`cwf-state.yaml` stores pointer metadata only:

```yaml
live:
  phase: hitl
  hitl:
    session_id: "Sxx-hitl"
    state_file: ".cwf/projects/{session-dir}/hitl/state.yaml"
    rules_file: ".cwf/projects/{session-dir}/hitl/rules.yaml"
    updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

`queue.json` tracks per-file/per-chunk status for resumable delta-review:

- file status: `pending | in_review | reviewed | stale`
- chunk status: `pending | reviewed | stale`
- each file entry stores `blob_sha` captured when the queue was built.
- `fix-queue.yaml` is an execution queue for concrete edits.
- `hitl-scratchpad.md` is the agreement/rationale log (decisions, open questions, and intent).

`state.yaml` must include intent resync gate fields:

```yaml
session_id: "Sxx-hitl"
status: "in_progress"
intent_resync_required: false
last_user_manual_edit_at: ""
last_intent_resync_at: ""
intent_resync_note: ""
```

## Phase 0: Resolve Target

1. Resolve base branch:
   - explicit `--base` wins
   - otherwise upstream default branch
   - fallback `main`
2. Resolve review scope (`docs|code|all`, default `all`).
3. Build diff target: `git diff --name-only <base>...HEAD`.
4. If `--resume`, load from `live.hitl.state_file` pointer in `cwf-state.yaml` (fallback: latest `.cwf/projects/*/hitl/`).

## Phase 0.5: Agreement Round (Default)

Before chunk review starts, run one agreement round in the same `cwf:hitl` flow (no extra mode/flag):

1. Collect major decision points from available ship artifacts first (issue/PR body, review summaries, merge notes).
2. Merge user-provided concerns/questions for this HITL run.
3. Record agreements in `hitl-scratchpad.md`:
   - agreed wording/policy decisions
   - rationale
   - open questions
   - pending implementation items
4. Apply high-impact agreed edits that should be reflected before chunk-by-chunk review.
5. Immediately update `hitl-scratchpad.md` again after edits:
   - mark items as `Applied` / `In progress`
   - note what was changed and what remains
   - refresh the `Updated` timestamp
6. Ask whether to start chunk review now.

When `--resume` is used, refresh the same scratchpad first (new agreements or changed priorities), then continue from cursor.

## Phase 0.75: Intent Resync Gate

This gate prevents stale intent from leaking into the next chunk.

1. If the user reports manual edits/overwrites (or HITL detects out-of-band file changes), set in `state.yaml`:
   - `intent_resync_required: true`
   - `last_user_manual_edit_at: {UTC timestamp}`
   - `intent_resync_note: {what changed}`
2. Before presenting any next chunk, check `intent_resync_required`.
3. If `true`, run resync first:
   - re-read the changed target files
   - summarize what changed and confirm updated intent with the user
   - update `hitl-scratchpad.md` with the confirmed intent delta
   - set `intent_resync_required: false` and `last_intent_resync_at: {UTC timestamp}`
4. Only continue chunk review after the flag is cleared.

## Phase 1: Build Deterministic Queue

1. Build file queue from diff files in stable sorted order.
2. Capture each file's `blob_sha` and set initial file status to `pending`.
3. Build chunk queue per file:
   - Markdown: heading/fence-safe semantic chunks (typically 60-120 lines)
   - Code/text: prefer git hunk boundaries; fallback fixed windows
4. Assign chunk IDs and initial chunk status `pending`.
5. Save queue to `queue.json`.
6. Initialize `state.yaml`, `fix-queue.yaml`, and `events.log`.

If high-impact edits were applied during Phase 0.5, build/rebuild queue after those edits so chunk boundaries and blob hashes are fresh.

## Phase 2: Chunk Review Loop

Before every chunk presentation, enforce Phase 0.75 gate (`intent_resync_required` must be `false`).

For each chunk, output exactly:

1. `Chunk` (`{file}:{start_line}-{end_line}` and EOF 여부)
2. `Excerpt`
3. `Meaning / Intent`
4. `Review Focus (Line-Anchored)` with at least 2 concrete points
5. `Link Syntax Check` (`[]()`) for docs chunks
6. `De-dup / What-Why Check`
7. `Discussion Prompt` (1-2 concrete questions)

Then pause and wait for user acknowledgement.

Before each pause, persist cursor/progress.

### Review-Fix Policy During Loop

1. Mark the current file/chunk as `in_review` while presenting it.
2. If the user asks to fix the currently open chunk, apply immediately (natural conversational flow).
3. If a fix targets an already reviewed file/chunk, default action is to append to `fix-queue.yaml` first (do not silently rewrite previously closed sections).
4. If the user explicitly requests immediate edit on a reviewed area, apply the edit and mark overlapping reviewed chunks as `stale`.
5. Stale chunks are revisited via delta-review before final close.

## Phase 3: Rule Capture and Propagation

When user gives an improvement rule:

1. Normalize rule text into a durable entry in `rules.yaml`.
2. Record scope (`docs` or `code`, path globs, severity/priority).
3. Scan remaining queue for candidate matches.
4. Propose concrete follow-up targets (`file/chunk + rationale`) before continuing.

All accepted rules are applied to remaining chunks in the same HITL session.

When a new rule affects already reviewed regions, add those targets to `fix-queue.yaml` and mark overlapping chunks `stale` only when an edit is actually applied.

## Phase 4: Resume and Close

### Resume

On `--resume`:

1. Read `state.yaml` cursor.
2. Validate queued file/chunk still exists.
3. Compare saved `blob_sha` with current file blob:
   - unchanged: preserve statuses
   - changed: mark previously `reviewed` overlapping chunks as `stale`
4. If lines drift, re-anchor by nearest previous heading/hunk.
5. Continue with same chunk contract, prioritizing `stale` before untouched `pending`.

### Close

On `--close` (or EOF completion):

1. Mark session state `completed` (or `closed_by_user`).
2. Keep rule history and event log immutable.
3. Update `cwf-state.yaml` pointer `updated_at`.
4. Output concise completion summary (`files/chunks reviewed`, `rules applied`, `fix-queue pending/applied`, `stale re-reviewed count`).

## Rules

1. Persist state before every user pause.
2. Never discard accepted rules within the active session.
3. Pointer-only policy: keep detailed HITL state in `.cwf/projects/{session-dir}/hitl/`; store only pointers in `cwf-state.yaml`.
4. During Phase 1 migration, do not move other skills' artifact paths automatically.
5. Maintain meaningful commit-unit boundaries when applying fixes during HITL.
6. Default policy: `in_review` fixes can be immediate; `reviewed` fixes go to `fix-queue` unless the user requests immediate application.
7. Any edit touching previously reviewed content must mark overlapping chunks `stale` and trigger delta-review before close.
8. Default entry behavior: start with the agreement round (Phase 0.5), then move to chunk review.
9. Keep artifacts separated by role: `fix-queue.yaml` for actionable edits, `hitl-scratchpad.md` for agreements/rationale.
10. After any agreed edit is applied, update `hitl-scratchpad.md` before continuing.
11. For comment-driven doc HITL (for example README reflection), present each item in this order: `Before` (current text), `After` (proposed text), `After Intent` (why this reflects the user's concern and any trade-off/opinion).
    - `Before`/`After` must include enough surrounding context for user judgment (for example, the full paragraph or subsection, not a single isolated sentence).
12. Do not ask a separate "proceed to next item?" question. When the current item is agreed, present the next pending item immediately; if not agreed, keep discussing the same item until agreement.
13. If user manual edits are detected/reported, set `intent_resync_required=true` immediately and record the trigger in `events.log`.
14. Never present a next chunk while `intent_resync_required=true`.
15. Clearing `intent_resync_required` requires both: (a) scratchpad intent update and (b) `last_intent_resync_at` timestamp update.
16. During active HITL doc review, document edits and scratchpad state must stay synchronized; post-run checks should flag missing scratchpad updates.
