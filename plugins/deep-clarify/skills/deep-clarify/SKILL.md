---
name: deep-clarify
description: |
  Research-first requirement clarification. Autonomously resolves ambiguities
  through codebase exploration and best practice research. Only asks the human
  about genuinely subjective decisions — with informed advisory opinions.
  Triggers: "/deep-clarify", or when requirements need deep clarification.
allowed-tools:
  - Task
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

# Deep Clarify

Research-first requirement clarification. Instead of asking about every ambiguity,
autonomously resolve what can be resolved through research, and only ask the human
about genuinely subjective decisions.

**Language**: Adapt all outputs to match the user's prompt language.

## Quick Start

```text
/deep-clarify <requirement>
```

## Workflow

### Phase 1: Capture & Decompose

1. Record the original requirement verbatim
2. Decompose into concrete **decision points** — specific questions that need
   answers before implementation can begin
   - Frame as questions, not categories (e.g., "Which auth library should we use?"
     not "Authentication")
   - Be thorough but not exhaustive — focus on decisions that affect implementation
3. Present the decision points to the user before proceeding

Output:
```markdown
## Original Requirement
"{user's original request verbatim}"

## Decision Points
1. {specific question}
2. {specific question}
...
```

### Phase 2: Parallel Research

Launch two sub-agents **simultaneously** using the Task tool:

#### Sub-agent A: Codebase Researcher

```yaml
Task tool:
  subagent_type: general-purpose
  prompt: |
    Read the guide at {SKILL_DIR}/references/codebase-research-guide.md,
    then research the following decision points by exploring the codebase.

    Decision points:
    {list of decision points from Phase 1}

    Report your findings per the guide's output format.
```

#### Sub-agent B: Best Practice Researcher

```yaml
Task tool:
  subagent_type: general-purpose
  prompt: |
    Read the guide at {SKILL_DIR}/references/bestpractice-research-guide.md,
    then research the following decision points by searching the web for
    authoritative sources and expert perspectives.

    Decision points:
    {list of decision points from Phase 1}

    Report your findings per the guide's output format.
```

Both sub-agents run in parallel. Wait for both to complete before proceeding.

### Phase 3: Aggregate & Classify

Read `{SKILL_DIR}/references/aggregation-guide.md` for classification rules.

For each decision point, classify using this guiding principle:

> If you could arrive at a defensible answer through codebase exploration or
> best practice research, make the decision yourself. Only ask the human when
> reasonable people could disagree and no external evidence would settle it.

**Tier 1** — Codebase has clear evidence → decide autonomously, cite file paths
**Tier 2** — Best practice has clear consensus → decide autonomously, cite sources
**Tier 3** — Evidence conflicts, both silent, or inherently subjective → ask human

**Constructive tension**: When codebase and best practice conflict, that tension
itself is Tier 3 — present both sides to the human.

Present the classification:

```markdown
## Agent Decisions (Tier 1 & 2)

| # | Decision Point | Tier | Decision | Evidence |
|---|---------------|------|----------|----------|
| 1 | ... | T1 | ... | file paths |
| 2 | ... | T2 | ... | sources |

## Requires Human Decision (Tier 3)

| # | Decision Point | Reason |
|---|---------------|--------|
| 3 | ... | conflict / no evidence / subjective |
```

**If zero Tier 3 items**: Skip Phase 3.5 and Phase 4 entirely. Go to Phase 5.

### Phase 3.5: Advisory (Tier 3 only)

If Tier 3 items exist, launch two advisory sub-agents **simultaneously**:

#### Advisor α

```yaml
Task tool:
  subagent_type: general-purpose
  prompt: |
    Read the guide at {SKILL_DIR}/references/advisory-guide.md.
    You are Advisor α.

    Tier 3 decision points requiring human decision:
    {list of Tier 3 items}

    Research context from Phase 2:
    {codebase researcher findings for these items}
    {best practice researcher findings for these items}

    Argue for the first perspective per the guide's side-assignment rules.
```

#### Advisor β

```yaml
Task tool:
  subagent_type: general-purpose
  prompt: |
    Read the guide at {SKILL_DIR}/references/advisory-guide.md.
    You are Advisor β.

    Tier 3 decision points requiring human decision:
    {list of Tier 3 items}

    Research context from Phase 2:
    {codebase researcher findings for these items}
    {best practice researcher findings for these items}

    Argue for the opposing perspective per the guide's side-assignment rules.
```

Both advisors run in parallel. Wait for both to complete before proceeding.

### Phase 4: Human Questions (Tier 3 only)

For each Tier 3 item, ask the human using `AskUserQuestion`. Include:

1. **Research context**: What the codebase shows and what best practice says
2. **Advisor α's position**: Their argument and reasoning
3. **Advisor β's position**: Their argument and reasoning
4. **The question**: With concrete options derived from the advisory perspectives

Design questions following these principles:
- Provide 2-4 concrete options (not open-ended)
- Options should reflect the advisory perspectives
- Include enough context for an informed decision
- One question at a time

### Phase 5: Output

Present the complete clarified requirement:

```markdown
## Requirement Clarification Summary

### Before (Original)
"{original request verbatim}"

### After (Clarified)
**Goal**: {precise description}
**Scope**: {what is included and excluded}
**Constraints**: {limitations and requirements}

### All Decisions

| # | Decision Point | Decision | Decided By | Evidence |
|---|---------------|----------|------------|----------|
| 1 | ... | ... | Agent (T1) | file paths |
| 2 | ... | ... | Agent (T2) | sources |
| 3 | ... | ... | Human | advisory context |
```

Then ask: "Save this clarified requirement to a file?"
- If yes: save to a project-appropriate location (e.g., `requirements/`, `docs/`)
  with a descriptive filename

## Rules

1. **Research first, ask later**: Exhaust research before asking the human anything
2. **Principle over examples**: Use the guiding principle to classify, do not
   memorize categories of "what to ask" vs "what to decide"
3. **Cite evidence**: Every autonomous decision must include specific evidence
4. **Respect the tiers**: Do not ask about Tier 1/2 items; do not auto-decide Tier 3
5. **Constructive tension**: Conflicts between sources are signals, not problems
6. **Grounded experts**: Best practice research must cite real published work
7. **Honest advisors**: Advisory opinions must argue in good faith, not strawman

## References

- Codebase research: [references/codebase-research-guide.md](references/codebase-research-guide.md)
- Best practice research: [references/bestpractice-research-guide.md](references/bestpractice-research-guide.md)
- Aggregation rules: [references/aggregation-guide.md](references/aggregation-guide.md)
- Advisory guide: [references/advisory-guide.md](references/advisory-guide.md)
