---
name: handoff
description: |
  Auto-generate session handoff documents from cwf-state.yaml
  and session artifacts.
  Triggers: "cwf:handoff", "handoff", "핸드오프", "다음 세션"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# Handoff

Auto-generate session handoff documents (`next-session.md`) from project state and session artifacts. Reads `cwf-state.yaml` for session history and `master-plan.md` (when available) for next session scope.

**Language**: Write handoff documents in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:handoff                # Full: generate next-session.md + register
cwf:handoff --register     # Register current session in cwf-state.yaml only
```

---

## Phase 1: Read Current State

### 1.1 Load Project State

Read `cwf-state.yaml`:

- `workflow.current_stage` and `workflow.stages` — where we are
- `sessions` — full session history
- `session_defaults` — expected artifacts

### 1.2 Identify Current Session

Determine the current session by:

1. Check for a session directory matching today's date in `prompt-logs/`
2. Match against the most recent entry in `cwf-state.yaml` `sessions`
3. If ambiguous, use AskUserQuestion with candidates

### 1.3 Read Session Artifacts

Read the current session's artifacts (if they exist):

- `plan.md` — session scope and goals
  - Extract `## Deferred Actions` section if present (unchecked items: `- [ ]`)
- `lessons.md` — accumulated learnings
  - Identify entries with unimplemented proposals (keywords: "구현은 별도 세션", "스코프 밖", "future", "deferred", "separate session", "out of scope")
- `retro.md` — retrospective (if available)
  - Identify action items not yet addressed

---

## Phase 2: Determine Next Session

### 2.1 With master-plan.md

If `master-plan.md` exists (search via Glob in `prompt-logs/`):

1. Read the session roadmap section
2. Find the current session ID in the roadmap
3. Extract the next session's definition: title, scope, dependencies
4. Extract "Don't Touch" boundaries from master-plan context

### 2.2 Without master-plan.md

Fall back to `cwf-state.yaml` stages and user input:

1. Read `workflow.stages` for the stage progression
2. Determine what comes next based on current stage
3. Use AskUserQuestion to get:
   - Next session title
   - Task scope description
   - Key files to modify

`master-plan.md` is preferred but optional — the skill must work generically for any project using CWF.

---

## Phase 3: Generate next-session.md

Write `next-session.md` in the current session's prompt-logs directory. Follow the format defined in `plan-protocol.md` (Handoff Document section).

### 8 Required Sections

#### 1. Context Files to Read

List files the next session agent must read before starting:

```markdown
## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. {task-specific files from master-plan or plan.md}
```

Always include `CLAUDE.md`, `docs/plugin-dev-cheatsheet.md`, and `cwf-state.yaml` as standard entries. Add task-specific files based on the next session's scope.

#### 2. Task Scope

```markdown
## Task Scope

{Description of what the next session should accomplish}

### What to Build
{Specific deliverables with design points}

### Key Design Points
{Architectural decisions and constraints}
```

Source from master-plan session definition or user input (Phase 2).

#### 3. Don't Touch

```markdown
## Don't Touch

- {files/directories that must not be modified}
```

Infer conservatively from:

- Completed sessions' outputs (don't re-modify finished work)
- Master-plan session boundaries
- Explicit user constraints

#### 4. Lessons from Prior Sessions

```markdown
## Lessons from Prior Sessions

1. **{title}** ({session}): {takeaway}
2. **{title}** ({session}): {takeaway}
```

Aggregate selectively from:

- `cwf-state.yaml` session summaries
- Recent sessions' `lessons.md` files
- Only include lessons relevant to the next session's task

#### 5. Success Criteria

````markdown
## Success Criteria

```gherkin
Given {context}
When {action}
Then {expected outcome}
```
````

Use BDD Given/When/Then format. Criteria must be concrete — reference actual files, features, or behaviors. Avoid vague criteria like "code is clean."

#### 6. Dependencies

```markdown
## Dependencies

- Requires: {completed sessions or artifacts}
- Blocks: {future sessions that depend on this work}
```

Source from master-plan dependency graph or session history.

#### 7. Dogfooding Reminder

```markdown
## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.
```

Reference the discovery mechanism from `CLAUDE.md` Dogfooding section. Do not hardcode a list of specific skills.

#### 8. Start Command

````markdown
## Start Command

```text
{Natural language instruction to start the next session}
```
````

---

## Phase 4: Register in cwf-state.yaml

### 4.1 Update Current Session

If the current session entry exists in `cwf-state.yaml`:

- Add `next-session.md` to the `artifacts` list
- Update `summary` if not already set
- Set `completed_at` to today's date (via `date +%Y-%m-%d`)

### 4.2 Register-Only Mode

When `--register` flag is used, skip Phase 3 (generation) and only update the session entry in `cwf-state.yaml`.

---

## Phase 4b: Unresolved Items

Propagate unresolved items from the current session to `next-session.md` to prevent context loss across session boundaries.

### Sources

1. **From Deferred Actions** (`plan.md`): Extract unchecked items (`- [ ]`) from the `## Deferred Actions` section
2. **From Lessons** (`lessons.md`): Identify entries with unimplemented resolution proposals (keywords: "구현은 별도 세션", "스코프 밖", "future", "deferred", "separate session", "out of scope")
3. **From Retro** (`retro.md`): Identify action items not yet addressed in this session

### Output Format

Add a section to `next-session.md` after "Lessons from Prior Sessions":

```markdown
## Unresolved Items from {current session ID}

### From Deferred Actions

- [ ] {item 1}
- [ ] {item 2}

### From Lessons

- [ ] {lesson title}: {unimplemented proposal}

### From Retro

- [ ] {action item description}
```

### Scoping Rules

- Items relevant to the next session's scope: include directly
- Items outside the next session's scope: mark as "carry-forward" (e.g., `- [ ] [carry-forward] {item}`)
- If no unresolved items exist, omit this section entirely

---

## Phase 5: Lessons Checkpoint + Verify

### 5.1 Stage Checkpoints

Add `handoff` to `cwf-state.yaml` current session's `stage_checkpoints` list.

### 5.2 Run Verification

Execute the session artifact checker:

```bash
bash scripts/check-session.sh --impl
```

Report results. If any artifacts are missing, list them and suggest fixes.

---

## Rules

1. **Canonical template over recent example**: Read `plan-protocol.md` Handoff Document section for format. Do not copy-paste a recent `next-session.md` — derive from the protocol.
2. **master-plan.md is preferred but optional**: The skill must work for projects without a master plan by falling back to user input.
3. **Lessons aggregation is selective**: Only include lessons relevant to the next session's task. Do not dump all historical lessons.
4. **Dogfooding section references discovery mechanism**: Point to `skills/` directory, not a hardcoded skill list.
5. **Don't Touch inference is conservative**: When uncertain, include the boundary. Better to over-protect than under-protect.
6. **BDD criteria are concrete**: Reference actual files, features, or behaviors — not abstract qualities.
7. **cwf-state.yaml is SSOT**: Read before modifying. Edit, do not overwrite.
8. **Never overwrite existing files**: When a file already exists (e.g., `next-session.md` from a prior run), use Edit to update — not Write. Write replaces entire file contents and destroys prior work.
9. **All code fences must have language specifier**: Never use bare fences.
10. **Unresolved items MUST be propagated**: Deferred Actions, unimplemented lesson proposals, and unaddressed retro action items from the current session must appear in next-session.md. This prevents context loss across session boundaries.

## References

- [plan-protocol.md](../../references/plan-protocol.md) — Handoff Document format (lines 105-114)
- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
