# Plan & Lessons Protocol

Protocol for persisting planning artifacts and session learnings.

## Contents

- [Plan Document](#plan-document)
- [Lessons Document](#lessons-document)
- [Retro Document (optional)](#retro-document-optional)
- [Handoff Document (milestone sessions)](#handoff-document-milestone-sessions)

## Plan Document

### Location

`.cwf/projects/{YYMMDD}-{NN}-{title}/plan.md`

**Path rule**:
- If the user specifies a path, use it.
- Otherwise run `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh <title>` and use its output path as-is.
- Do not hand-calculate sequence numbers.
- `YYMMDD` is the directory creation date, not a guarantee that all later work in that session happened on the same day.

The `{title}` must reflect the current session's task, not a previous session's. Even if the input spec or reference document lives in an existing `.cwf/projects/` directory, always create a new directory named after the current task.

### Required Sections

**Success Criteria** — BDD-style acceptance tests using Given/When/Then:

<!-- markdownlint-disable MD040 -->
````
## Success Criteria

```gherkin
Given [context] When [action] Then [expected outcome]
```
````
<!-- markdownlint-enable MD040 -->

**Deferred Actions** — requests received during plan mode that cannot be handled immediately:

```markdown
## Deferred Actions

- [ ] {request description} (received during plan mode)
```

When starting implementation, check Deferred Actions first and handle the items.

### Language

Write the plan in English. The plan is primarily for the agent, not the user.

### Prior Art Search

Before finalizing the plan, search for frameworks, methodologies, or prior art relevant to the task. Someone has likely thought about this problem before. The cost of a quick search is low; the potential value of discovering a better approach is high.

Use `cwf:gather --search` or equivalent to find: established frameworks, best practices, common patterns, or cautionary tales related to the task domain.

### Timing

Create the plan document at session start, before implementation begins.

## Lessons Document

### Location

`.cwf/projects/{YYMMDD}-{NN}-{title}/lessons.md` — same directory as the plan.

### What to Record

- **Ping-pong learnings**: clarifications, corrected assumptions, revealed user preferences — things learned from conversation before and during implementation
- **Implementation learnings**: gaps between plan and execution, unexpected discoveries

### Format

```markdown
### {title}

- **Expected**: What was anticipated
- **Actual**: What actually happened
- **Takeaway**: Key point for future reference

When [situation] → [action]
```

The `When → do` action guideline is optional. Only add one when it fits naturally.

### Language

Write lessons in the user's language.

### Timing

Create lessons.md at the same time as plan.md — not after implementation. Learnings often emerge from pre-implementation conversation (e.g., corrected assumptions, revealed preferences), so the file must exist before implementation begins.

Accumulate incrementally throughout the session. Record learnings as they emerge from conversation and implementation.

## Retro Document (optional)

`.cwf/projects/{YYMMDD}-{NN}-{title}/retro.md` — produced by the `/retro` skill at session end.

While lessons are accumulated incrementally during a session, the retro is a comprehensive end-of-session review covering: user/org context, collaboration preferences, prompting feedback, learning resources, and skill discovery. See the `/retro` skill for details if available.

## Handoff Document (milestone sessions)

`.cwf/projects/{YYMMDD}-{NN}-{title}/next-session.md` — context transfer for the next session.

Create when the current session is part of a tracked sequence (e.g., sessions in `cwf-state.yaml`). Include: context files to read, task scope, don't-touch boundaries, lessons from prior sessions, success criteria, and a start command.

If using `cwf-state.yaml`, add `next-session.md` to the session's `artifacts` list.

### Execution Contract (Mention-Only Safe)

Every generated `next-session.md` MUST include an explicit execution contract section. Treat this as a runtime behavior contract, not optional prose.

Contract minimum:

1. **Mention-only execution**
   - If the user input only mentions `next-session.md` (with or without "start"),
     treat it as "execute this handoff", not as a request to summarize the file.
2. **Branch gate before implementation edits**
   - Before implementation edits, detect current branch.
   - If on a base branch (`main`, `master`, or repo primary branch), create/switch
     to a feature branch and continue execution.
3. **Commit gate during execution**
   - Commit in meaningful units while executing (per work item or change pattern).
   - Avoid one monolithic end-of-session commit when multiple logical units exist.
   - Add an explicit checkpoint after the first completed unit:
     run `git status --short`, decide the next commit boundary, and commit before
     continuing to the next major unit.
4. **Selective staging**
   - Stage only intended files for the current unit.
   - Do not use broad staging that can capture unrelated changes.

The contract must be concrete enough that an agent can follow it without extra user prompts.
