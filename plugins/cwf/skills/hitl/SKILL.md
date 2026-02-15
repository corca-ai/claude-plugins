---
name: hitl
description: "Human-in-the-loop diff/chunk review with resumable state and rule propagation. Triggers: \"cwf:hitl\", \"hitl\", \"interactive review\", \"human review\", \"cwf:review --human\""
---

# HITL Review (cwf:hitl)

Interactive, resumable review over branch diff (`<base>...HEAD`). Reviews file-by-file in meaningful chunks, pauses for user input each chunk, and persists review state/rules so work can resume anytime.

**Language**: Write review outputs in English. Communicate with the user in their prompt language.

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
.cwf/hitl/sessions/{session_id}/
  state.yaml
  rules.yaml
  queue.json
  events.log
```

`cwf-state.yaml` stores pointer metadata only:

```yaml
live:
  phase: hitl
  hitl:
    session_id: "Sxx-hitl"
    state_file: ".cwf/hitl/sessions/Sxx-hitl/state.yaml"
    rules_file: ".cwf/hitl/sessions/Sxx-hitl/rules.yaml"
    updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

## Phase 0: Resolve Target

1. Resolve base branch:
   - explicit `--base` wins
   - otherwise upstream default branch
   - fallback `main`
2. Resolve review scope (`docs|code|all`, default `all`).
3. Build diff target: `git diff --name-only <base>...HEAD`.
4. If `--resume`, load the latest active state from `.cwf/hitl/sessions/`.

## Phase 1: Build Deterministic Queue

1. Build file queue from diff files in stable sorted order.
2. Build chunk queue per file:
   - Markdown: heading/fence-safe semantic chunks (typically 60-120 lines)
   - Code/text: prefer git hunk boundaries; fallback fixed windows
3. Save queue to `queue.json`.
4. Initialize `state.yaml` and `events.log`.

## Phase 2: Chunk Review Loop

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

## Phase 3: Rule Capture and Propagation

When user gives an improvement rule:

1. Normalize rule text into a durable entry in `rules.yaml`.
2. Record scope (`docs` or `code`, path globs, severity/priority).
3. Scan remaining queue for candidate matches.
4. Propose concrete follow-up targets (`file/chunk + rationale`) before continuing.

All accepted rules are applied to remaining chunks in the same HITL session.

## Phase 4: Resume and Close

### Resume

On `--resume`:

1. Read `state.yaml` cursor.
2. Validate queued file/chunk still exists.
3. If lines drift, re-anchor by nearest previous heading/hunk.
4. Continue with same chunk contract.

### Close

On `--close` (or EOF completion):

1. Mark session state `completed` (or `closed_by_user`).
2. Keep rule history and event log immutable.
3. Update `cwf-state.yaml` pointer `updated_at`.
4. Output concise completion summary (`files/chunks reviewed`, `rules applied`).

## Rules

1. Persist state before every user pause.
2. Never discard accepted rules within the active session.
3. Pointer-only policy: keep detailed HITL state in `.cwf/hitl/**`; store only pointers in `cwf-state.yaml`.
4. During Phase 1 migration, do not move other skills' artifact paths automatically.
5. Maintain meaningful commit-unit boundaries when applying fixes during HITL.
