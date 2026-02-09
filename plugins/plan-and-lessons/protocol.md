# Plan & Lessons Protocol

Protocol for persisting planning artifacts and session learnings.

## Plan Document

### Location

`prompt-logs/{YYMMDD}-{NN}-{title}/plan.md`

**Automated**: Run `scripts/next-prompt-dir.sh <title>` to get the correct path.
The script determines today's date, scans existing directories, and outputs the
next available path (e.g., `prompt-logs/260204-03-auth-impl`).

If the user specifies a path, use it instead of the script output.

The `{title}` must reflect the current session's task, not a previous session's.
Even if the input spec or reference document lives in an existing `prompt-logs/`
directory, always create a new directory named after the current task.

### Required Sections

**Success Criteria** — BDD-style acceptance tests using Given/When/Then:

<!-- markdownlint-disable MD040 -->
````
## Success Criteria

```gherkin
Given [context]
When [action]
Then [expected outcome]
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

Use `/gather-context --search` or equivalent to find: established frameworks, best practices, common patterns, or cautionary tales related to the task domain.

### Timing

Create the session directory and both files (plan.md, lessons.md) **before**
entering plan mode. Use `scripts/next-prompt-dir.sh <title>` to determine the
directory path.

1. Run `scripts/next-prompt-dir.sh <title>` → get session dir path
2. `mkdir -p` the directory
3. Create empty `plan.md` and `lessons.md` with headers
4. Enter plan mode — plan mode only validates structure, not creates it

## Lessons Document

### Location

`prompt-logs/{YYMMDD}-{NN}-{title}/lessons.md` — same directory as the plan.

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

Created alongside plan.md **before** entering plan mode (see Plan Document →
Timing). Learnings often emerge from pre-plan-mode conversation (e.g., corrected
assumptions, revealed preferences), so the file must exist before plan mode.

Accumulate incrementally throughout the session. Record learnings as they emerge
from conversation and implementation.

## Retro Document (optional)

`prompt-logs/{YYMMDD}-{NN}-{title}/retro.md` — produced by the `/retro` skill at session end.

While lessons are accumulated incrementally during a session, the retro is a comprehensive end-of-session review covering: user/org context, collaboration preferences, prompting feedback, learning resources, and skill discovery. See the `/retro` skill for details if available.

## Handoff Document (milestone sessions)

`prompt-logs/{YYMMDD}-{NN}-{title}/next-session.md` — context transfer for the next session.

Create when the current session is part of a tracked sequence (e.g., sessions in `cwf-state.yaml`).
Include: context files to read, task scope, don't-touch boundaries, lessons from prior sessions,
success criteria, and a start command.

If using `cwf-state.yaml`, add `next-session.md` to the session's `artifacts` list.
