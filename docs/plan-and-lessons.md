# Plan & Lessons Protocol

Protocol for persisting planning artifacts and session learnings.

## Plan Document

### Location

`prompt-logs/{YYMMDD}-{title}/plan.md`

Determine the path from the user's request. If the user specifies a path, use it.

### Required Sections

**Success Criteria** — BDD-style acceptance tests using Given/When/Then:

```markdown
## Success Criteria

```gherkin
Given [context]
When [action]
Then [expected outcome]
```
```

**Deferred Actions** — requests received during plan mode that cannot be handled immediately:

```markdown
## Deferred Actions

- [ ] {request description} (received during plan mode)
```

When starting implementation, check Deferred Actions first and handle the items.

### Timing

Create the plan document when entering plan mode, before implementation begins.

## Lessons Document

### Location

`prompt-logs/{YYMMDD}-{title}/lessons.md` — same directory as the plan.

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

### Timing

Accumulate incrementally throughout the session — not just at the end. Record learnings as they emerge from conversation and implementation.
