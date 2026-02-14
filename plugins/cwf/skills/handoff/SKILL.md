---
name: handoff
description: "Auto-generate session or phase handoff documents from cwf-state.yaml and session artifacts. --phase mode generates phase-to-phase context transfer (HOW) separate from plan.md (WHAT). Triggers: \"cwf:handoff\", \"cwf:handoff --phase\", \"handoff\", \"핸드오프\", \"다음 세션\", \"phase handoff\""
---

# Handoff

Auto-generate session handoff documents (`next-session.md`) or phase handoff documents (`phase-handoff.md`) from project state and session artifacts. Reads `cwf-state.yaml` for session history and `master-plan.md` (when available) for next session scope.

**Language**: Write handoff documents in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:handoff                # Full: generate next-session.md + register
cwf:handoff --register     # Register current session in cwf-state.yaml only
cwf:handoff --phase        # Generate phase-handoff.md (HOW context for next phase)
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
- Runtime session logs (optional but recommended when available)
  - Canonical unified path: `prompt-logs/sessions/*.claude.md`, `prompt-logs/sessions/*.codex.md`
  - Legacy compatibility reads: `prompt-logs/sessions/*.md`, `prompt-logs/sessions-codex/*.md`
  - Use these as additional evidence when extracting unresolved items and collaboration signals

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

### 9 Required Sections

#### 1. Context Files to Read

List files the next session agent must read before starting:

```markdown
## Context Files to Read

1. `AGENTS.md` — shared project rules and protocols (cross-agent)
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/sessions/*.claude.md` / `*.codex.md` (or legacy `sessions-codex/*.md`) — runtime conversation evidence when available
5. {task-specific files from master-plan or plan.md}
```

Always include AGENTS.md, docs/plugin-dev-cheatsheet.md, and `cwf-state.yaml` as standard entries. Add task-specific files based on the next session's scope. Include CLAUDE.md only when Claude runtime-specific behavior is relevant.

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

Reference the discovery mechanism from AGENTS.md Dogfooding section. Do not hardcode a list of specific skills.

#### 8. Execution Contract (Mention-Only Safe)

```markdown
## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat it as an instruction to execute
the task scope directly.

- Branch gate:
  - Before implementation edits, check current branch.
  - If on a base branch (`main`, `master`, or repo primary branch), create/switch
    to a feature branch and continue.
- Commit gate:
  - Commit during execution in meaningful units (per work item or change pattern).
  - Avoid one monolithic end-of-session commit when multiple logical units exist.
  - After the first completed unit, run `git status --short`, confirm the next
    commit boundary, and commit before starting the next major unit.
- Staging policy:
  - Stage only intended files for each commit unit.
  - Do not use broad staging that may include unrelated changes.
```

This section is mandatory for `next-session.md`.

#### 9. Start Command

````markdown
## Start Command

```text
{Natural language instruction to start the next session}
```
````

---

## Phase 3b: Generate phase-handoff.md (--phase mode)

When `--phase` flag is used, generate a phase-to-phase context transfer document instead of `next-session.md`. Phase handoff captures HOW (protocols, rules, must-reads, constraints) while `plan.md` captures WHAT (spec, steps, files).

**Prerequisite flow**: Phase 1.1 (Load Project State) and Phase 1.2 (Identify Current Session) execute normally. Phase 1.3 reads only `lessons.md` for protocol-relevant entries. Phase 2 is skipped entirely.

### 3b.1 Determine Phase Transition

Identify the source and target phases from context:

- **Source phase**: The current workflow phase (typically clarify, gather, or design discussion)
- **Target phase**: The next workflow phase (typically implementation)

If ambiguous, use AskUserQuestion:

```text
What phase are you transitioning from and to?
Example: "clarify + design → implementation"
```

### 3b.2 Gather HOW Context

The agent executing this skill holds the clarify/gather context in its active conversation. Extract the following from conversation history and session artifacts:

1. **Context Files**: Which files must the next phase agent read? Always include AGENTS.md and `cwf-state.yaml`. Add files that emerged as critical during the clarify/gather phase. Include CLAUDE.md only if runtime-specific behavior matters.
   - When available, include runtime logs from canonical/legacy patterns:
     `prompt-logs/sessions/*.claude.md`, `prompt-logs/sessions/*.codex.md`,
     `prompt-logs/sessions/*.md`, `prompt-logs/sessions-codex/*.md`
2. **Design Decisions**: Key choices made during clarify/gather with rationale. Source from clarification summaries, user decisions, and discussion outcomes
3. **Protocols**: Rules and behavioral protocols discovered or established during the current phase. Source from `lessons.md` entries and explicit user instructions
4. **Prohibitions**: Explicit "do not" constraints. Source from user instructions, clarify decisions, and scope boundaries
5. **Implementation Hints**: Practical guidance for the implementer — insertion points, patterns to follow, gotchas
6. **Success Criteria**: BDD-format criteria. May reference `plan.md` criteria or add phase-specific ones

### 3b.3 Generate phase-handoff.md

Write to `prompt-logs/{session-dir}/phase-handoff.md`:

````markdown
# Phase Handoff: {source phase} → {target phase}

> Source phase: {e.g., clarify + design discussion}
> Target phase: {e.g., implementation}
> Written: {date via `date +%Y-%m-%d`}

## Context Files to Read

1. `AGENTS.md` — shared project rules and protocols (cross-agent)
2. `cwf-state.yaml` — current project state
3. {additional files from 3b.2}

## Design Decision Summary

{Key design choices with rationale from 3b.2}

## Protocols to Follow

{Numbered list of rules and behavioral protocols from 3b.2}

## Do NOT

{Bulleted list of explicit prohibitions from 3b.2}

## Implementation Hints

{Practical guidance from 3b.2}

## Success Criteria

```gherkin
{BDD criteria from 3b.2}
```
````

### 3b.4 User Review

Present the generated document to the user and ask for confirmation:

```text
Phase handoff generated. Review the document above.
```

Use `AskUserQuestion` with options: "Confirm", "Edit and regenerate", "Cancel".

If "Edit and regenerate": apply user feedback, regenerate, and re-confirm.

---

## Phase 4: Register in cwf-state.yaml

### 4.1 Update Current Session

If the current session entry exists in `cwf-state.yaml`:

- Add `next-session.md` to the `artifacts` list
- Update `summary` if not already set
- Set `completed_at` to today's date (via `date +%Y-%m-%d`)
- Clear `live` section: set all scalar fields to `""` and lists to `[]`

### 4.1b Register Phase Handoff (--phase mode)

When `--phase` flag is used:

- Add `phase-handoff.md` to the current session's `artifacts` list in `cwf-state.yaml`
- Do NOT set `completed_at` — the session continues into the next phase
- Do NOT update `summary` — the session is not finished
- Skip Phase 4b (Unresolved Items) — phase handoff is intra-session, not inter-session
- Skip Phase 5 (Checkpoint + Verify) — `check-session.sh` checks session-end artifacts, not mid-session artifacts

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
bash {SKILL_DIR}/../../scripts/check-session.sh --impl
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
11. **Phase handoff captures HOW, not WHAT**: Do not duplicate plan.md content (steps, files to modify, goal). Focus on protocols, rules, constraints, and context files.
12. **Phase handoff is written by the phase that has context**: The clarify/gather agent writes the phase handoff because it holds the HOW context. Do not defer to a later phase.
13. **Phase handoff is intra-session**: It transfers context between phases within the same session. `completed_at` is not set and Phase 4b/5 are skipped.
14. **Draft-then-review**: Always present the generated `phase-handoff.md` to the user for review before finalizing.
15. **Execution contract is required**: `next-session.md` must include "Execution Contract (Mention-Only Safe)".
16. **Contract must include branch+commit gates**: Mention-only execution must define base-branch escape and meaningful commit unit rules.

## References

- [plan-protocol.md](../../references/plan-protocol.md) — Handoff Document format (lines 105-114)
- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
