---
name: plan
description: |
  Agent-assisted plan drafting with parallel research, BDD success criteria,
  and cwf:review integration. Complements the plan-protocol hook (passive injection)
  with active, structured plan creation.
  Triggers: "cwf:plan", "plan this task"
allowed-tools:
  - Task
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

# Plan

Turn a task description into a structured, research-backed plan with BDD success criteria.

**Language**: Write all plan artifacts in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:plan <task description>
```

---

## Phase 0: Update Live State

Edit `cwf-state.yaml` `live` section: set `phase: plan`, `task` to the task summary.

## Phase 1: Parse & Scope

1. Record the task description verbatim
2. Identify what needs planning:
   - What is the goal?
   - What are the key decisions to make?
   - What are the known constraints?
3. Present a brief scope summary to the user before proceeding

```markdown
## Task
"{user's task description verbatim}"

## Scope Summary
- **Goal**: {what we're trying to achieve}
- **Key Decisions**: {decisions that affect the plan}
- **Known Constraints**: {limitations, boundaries}
```

## Phase 2: Parallel Research

Launch two sub-agents **simultaneously** using the Task tool.

### Sub-agent A: Prior Art Researcher

```yaml
Task tool:
  subagent_type: general-purpose
  prompt: |
    Research best practices, frameworks, and prior art relevant to this task.
    Use WebSearch and WebFetch to find:
    - Established methodologies or patterns for this type of work
    - Common pitfalls and how others avoided them
    - Relevant tools, libraries, or approaches
    Cite real sources with URLs. Report findings — do not make decisions.

    Task:
    {task description from Phase 1}

    Key decisions:
    {decisions from Phase 1}
```

### Sub-agent B: Codebase Analyst

```yaml
Task tool:
  subagent_type: Explore
  prompt: |
    Analyze the codebase for patterns, dependencies, and constraints relevant
    to this task. For each finding:
    - Cite file paths and line numbers
    - Assess impact on the plan (High/Medium/Low)
    - Note existing patterns that should be followed
    Report evidence only — do not make decisions.

    Task:
    {task description from Phase 1}

    Key decisions:
    {decisions from Phase 1}
```

Both sub-agents run in parallel. Wait for both to complete.

## Phase 3: Plan Drafting

Synthesize research from both sub-agents into a structured plan. Read `{SKILL_DIR}/../../references/plan-protocol.md` for protocol rules on location, sections, and format.

### Required Plan Sections

````markdown
# {Plan Title}

## Context
{Why this plan exists, background information}

## Goal
{Precise description of the desired outcome}

## Scope
{What is included and excluded}

## Steps
1. {Step with clear deliverable}
2. {Step with clear deliverable}
...

## Success Criteria

Two-layer format:

### Behavioral (BDD)

```gherkin
Given [context]
When [action]
Then [expected outcome]
```

### Qualitative

- {Quality attribute or non-functional requirement}
- {Maintainability, readability, or other quality concern}

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| ... | Create/Edit | ... |

## Don't Touch

- {Files or areas explicitly out of scope}

## Deferred Actions

- [ ] {Items to handle later}
````

### Success Criteria Format

Always use the **two-layer format**:

1. **Behavioral (BDD)** — concrete, testable scenarios in Given/When/Then
2. **Qualitative** — non-functional qualities that are important but harder to test mechanically (e.g., "Plan is understandable without prior context", "Solution follows existing codebase patterns")

### Research Integration

- Incorporate prior art findings into the plan rationale
- Note where codebase patterns inform implementation steps
- Flag conflicts between best practices and existing code as decision points

## Phase 4: Write Artifacts

Determine the session directory following plan-protocol.md location rules:

1. Resolve path via `scripts/next-prompt-dir.sh <title>`.
2. Ensure sequence is date-scoped (`{YYMMDD}-NN`) and resets to `01` when no
   directory exists for today.
3. Create `prompt-logs/{YYMMDD}-{NN}-{title}/`.

Do not derive `NN` from the most recent directory across previous days.

Write two files:

### plan.md

The complete plan from Phase 3, following all plan-protocol.md requirements.

### lessons.md

Initialize with any learnings from the planning process:

```markdown
# Lessons — {title}

### {learning title}

- **Expected**: {what was anticipated}
- **Actual**: {what was discovered}
- **Takeaway**: {key insight}
```

If no learnings yet, create with a header and note that learnings will be accumulated during implementation.

## Phase 5: Review Offer

After writing plan artifacts, suggest review:

```text
Plan drafted at prompt-logs/{dir}/plan.md.

For a multi-perspective review before implementation, run:
  cwf:review --mode plan
```

---

## Rules

1. **Research before drafting**: Always complete parallel research before writing the plan
2. **Two-layer criteria**: Success criteria must include both BDD and qualitative layers
3. **Cite evidence**: Reference specific files, URLs, or sources for plan decisions
4. **Follow protocol**: Adhere to plan-protocol.md for format and location
5. **Don't over-plan**: Keep steps actionable and concrete, avoid excessive detail
6. **Preserve task intent**: Refine the approach, don't redirect the goal

## References

- [plan-protocol.md](../../references/plan-protocol.md) — Plan & Lessons Protocol
