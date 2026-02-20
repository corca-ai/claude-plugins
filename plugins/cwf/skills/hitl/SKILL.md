---
name: hitl
description: "Human-in-the-loop diff/chunk review to inject deliberate human judgment where automated review is insufficient, with resumable state, agreement-round kickoff, and rule propagation. Triggers: \"cwf:hitl\", \"hitl\", \"interactive review\", \"human review\""
---

# HITL Review (cwf:hitl)

Insert deliberate human judgment into branch-diff review (`<base>...HEAD`) with resumable chunk state. Reviews file-by-file in meaningful chunks, pauses for user input each chunk, and persists state/rules so work can resume anytime.

Every chunk review must be presented as: `Primary Chunk + Related Context + Causal Lens`. Do not present isolated chunks.

## Quick Reference

```text
cwf:hitl [--base <branch>] [--scope docs|code|all]
cwf:hitl --resume
cwf:hitl --rule "<rule text>"
cwf:hitl --rules
cwf:hitl --state
cwf:hitl --close
```

## State Model

Persist HITL runtime state under `.cwf/projects/{session-dir}/hitl/` and keep `cwf-state.yaml` as pointer metadata only.

Canonical schema details (field contracts, status enums, and intent-resync state transitions) live in:

- [hitl-state-model.md](references/hitl-state-model.md)

At minimum, keep these runtime artifacts:

```text
.cwf/projects/{session-dir}/hitl/
  hitl-scratchpad.md
  state.yaml
  rules.yaml
  queue.json
  fix-queue.yaml
  events.log
```

## Phase 0: Resolve Target

1. Resolve base branch:
   - explicit `--base` wins
   - otherwise upstream default branch
   - fallback `main`
2. Resolve review scope (`docs|code|all`, default `all`).
3. Build diff target: `git diff --name-only <base>...HEAD`.
4. If `--resume`, load from `live.hitl.state_file` pointer in `cwf-state.yaml`.
   - If pointer is missing, fallback to latest `.cwf/projects/*/hitl/`.
   - If both are missing, bootstrap HITL state interactively:
     - ask whether to initialize under current `live.dir` (recommended) or a new session dir
     - create `.cwf/projects/{session-dir}/hitl/` artifacts
     - persist the resolved pointer back to `cwf-state.yaml` `live.hitl.state_file`

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

1. Trigger condition: the user reports manual edits/overwrites, or HITL detects out-of-band file changes.
2. On trigger, update the intent-resync fields in `state.yaml` using the contract in [hitl-state-model.md](references/hitl-state-model.md), and append the trigger to `events.log`.
3. Before presenting any next chunk, check `intent_resync_required`.
4. If `true`, run resync first:
   - re-read the changed target files
   - summarize what changed and confirm updated intent with the user
   - update `hitl-scratchpad.md` with the confirmed intent delta
   - clear the resync gate and set `last_intent_resync_at` per state model contract
5. Only continue chunk review after the flag is cleared.

## Phase 1: Build Deterministic Queue

1. Build file queue from diff files in stable sorted order.
2. Capture each file's `blob_sha` and set initial file status to `pending`.
3. Build chunk queue per file:
   - Markdown: heading/fence-safe semantic chunks (typically 60-120 lines)
   - Code/text: prefer git hunk boundaries; fallback fixed windows
4. Assign chunk IDs and initial chunk status `pending`.
5. Seed deterministic `context_refs` per chunk and save to `queue.json`.
   - Code chunks: prefer call sites, definitions, tests, then adjacent fallback chunk.
   - Docs chunks: prefer referenced/ referring sections, governing policy docs, then adjacent heading fallback chunk.
6. Initialize `state.yaml`, `fix-queue.yaml`, and `events.log`.

If high-impact edits were applied during Phase 0.5, build/rebuild queue after those edits so chunk boundaries and blob hashes are fresh.

## Phase 2: Chunk Review Loop

Before every chunk presentation, enforce Phase 0.75 gate (`intent_resync_required` must be `false`).

For each chunk, output exactly:

1. `Primary Chunk` (`{file}:{start_line}-{end_line}` and EOF 여부)
2. `Primary Excerpt`
3. `Related Context` (at least 1 context excerpt with path/line anchors + relation)
4. `Causal Lens` (symptom, likely root cause, guardrail/invariant)
5. `Review Focus (Line-Anchored)` with at least 2 concrete points
6. `Consistency Check`:
   - docs: link syntax + reference integrity checks
   - code: call-path/definition-path impact checks
7. `Root-Cause Discussion Prompt` (1-2 concrete questions)

Then pause and wait for user acknowledgement.

Before each pause, persist cursor/progress.

### Related Context Resolution (Required, Always-On)

1. Resolve related context before presenting the chunk and persist the selected `context_refs`.
2. Keep the same context refs stable across retries/resume unless file drift invalidates anchors.
3. If semantic matches are not found, use structural fallback context (adjacent chunk/heading) and mark relation as `adjacent_fallback`.
4. Never present a chunk without at least one related context reference.

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
11. No isolated chunk reviews: every presented chunk must include `Related Context`.
12. For both code and docs, use one principle: `Primary Chunk + Related Context + Causal Lens`.
13. `Root-Cause Discussion Prompt` must focus on cause validation, not symptom restatement.
14. For comment-driven doc HITL (for example README reflection), keep the same chunk contract and include `Before`, `After`, `After Intent` within the `Primary Chunk` section.
    - `Before`/`After` must include enough surrounding context for user judgment (for example, the full paragraph or subsection, not a single isolated sentence).
15. Do not ask a separate "proceed to next item?" question. When the current item is agreed, present the next pending item immediately; if not agreed, keep discussing the same item until agreement.
16. If user manual edits are detected/reported, trigger Phase 0.75 immediately (set `intent_resync_required=true` and append trigger to `events.log`).
17. While `intent_resync_required=true`, apply the Phase 0.75 block rule (no next chunk presentation).
18. Clear `intent_resync_required` only through the Phase 0.75 completion contract (`hitl-scratchpad.md` intent delta + `last_intent_resync_at` update).
19. During active HITL doc review, document edits and scratchpad state must stay synchronized; post-run checks should flag missing scratchpad updates.
20. **Language override**: review-facing HITL outputs follow the user's language by default unless the user explicitly requests another language.

## References

- [hitl-state-model.md](references/hitl-state-model.md) — canonical schema and lifecycle for `state.yaml`, `queue.json`, `fix-queue.yaml`, and HITL pointer metadata
