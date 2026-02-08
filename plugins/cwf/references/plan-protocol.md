# Plan & Lessons Protocol

Protocol for persisting planning artifacts and session learnings.

## Plan Document

### Location

`prompt-logs/{YYMMDD}-{NN}-{title}/plan.md`

**Date**: Run `date +%y%m%d` to get the system date. Do not infer the date from
your training data or conversation context — always use the system command.

**Sequence number**: Scan existing `prompt-logs/` directories matching today's
date (`{YYMMDD}-*`) and pick the next number. If none exist, start at `01`.
Examples: `260204-01-auth-design`, `260204-02-auth-impl`.

The `{title}` must reflect the current session's task, not a previous session's.
Even if the input spec or reference document lives in an existing `prompt-logs/`
directory, always create a new directory named after the current task.

Determine the path from the user's request. If the user specifies a path, use it.

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

Use `cwf:gather --search` or equivalent to find: established frameworks, best practices, common patterns, or cautionary tales related to the task domain.

### Timing

Create the plan document when entering plan mode, before implementation begins.

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

Create lessons.md at the same time as plan.md — not after implementation. Learnings often emerge from pre-plan-mode conversation (e.g., corrected assumptions, revealed preferences), so the file must exist before implementation begins.

Accumulate incrementally throughout the session. Record learnings as they emerge from conversation and implementation.

## Retro Document (optional)

`prompt-logs/{YYMMDD}-{NN}-{title}/retro.md` — produced by the `/retro` skill at session end.

While lessons are accumulated incrementally during a session, the retro is a comprehensive end-of-session review covering: user/org context, collaboration preferences, prompting feedback, learning resources, and skill discovery. See the `/retro` skill for details if available.
