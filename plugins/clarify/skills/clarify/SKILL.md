---
name: clarify
description: |
  Unified requirement clarification. Default: research-first with autonomous
  decision-making and persistent questioning. --light: direct iterative Q&A.
  Triggers: "/clarify", "clarify this", "refine requirements"
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

# Clarify

Turn vague requirements into precise, actionable specifications.

**Language**: Match all output to the user's prompt language.

## Quick Start

```
/clarify <requirement>          # Research-first (default)
/clarify <requirement> --light  # Direct Q&A, no sub-agents
```

---

## Default Mode

### Phase 1: Capture & Decompose

1. Record the original requirement verbatim
2. Decompose into concrete **decision points** — specific questions that need
   answers before implementation can begin
   - Frame as questions, not categories ("Which auth library?" not "Authentication")
   - Focus on decisions that affect implementation
3. Present the decision points to the user before proceeding

```markdown
## Original Requirement
"{user's original request verbatim}"

## Decision Points
1. {specific question}
2. {specific question}
...
```

### Phase 2: Research

Launch two sub-agents **simultaneously** using the Task tool.

**Path A — gather-context available** (check if `/gather-context` appears in
available skills in the system prompt):

#### Sub-agent A: Codebase Researcher

```
Task tool:
  subagent_type: Explore
  prompt: |
    Explore the codebase and report evidence relevant to these decision points.
    For each point, search with Glob/Grep, read relevant files, and assess
    confidence (High/Medium/Low). Cite file paths and line numbers.
    Report evidence only — do not make decisions.

    Decision points:
    {list from Phase 1}
```

#### Sub-agent B: Web Researcher

```
Task tool:
  subagent_type: general-purpose
  prompt: |
    Research best practices for these decision points.
    Use the Bash tool to call the gather-context search script:
      bash {gather-context plugin dir}/skills/gather-context/scripts/search.sh "<query>"
    Or use WebFetch for specific URLs.
    For each point, find authoritative sources and expert perspectives.
    Cite real published work. Report findings — do not make decisions.

    Decision points:
    {list from Phase 1}
```

**Path B — gather-context NOT available** (fallback):

#### Sub-agent A: Codebase Researcher

```
Task tool:
  subagent_type: Explore
  prompt: |
    Read {SKILL_DIR}/references/research-guide.md Section 1,
    then research these decision points by exploring the codebase.

    Decision points:
    {list from Phase 1}
```

#### Sub-agent B: Web Researcher

```
Task tool:
  subagent_type: general-purpose
  prompt: |
    Read {SKILL_DIR}/references/research-guide.md Section 2,
    then research these decision points using WebSearch and WebFetch.

    Decision points:
    {list from Phase 1}
```

Both sub-agents run in parallel. Wait for both to complete.

### Phase 3: Classify & Decide

Read `{SKILL_DIR}/references/aggregation-guide.md` for full classification rules.

For each decision point, classify:

- **T1 (Codebase-resolved)** — codebase has clear evidence → decide autonomously, cite files
- **T2 (Best-practice-resolved)** — best practice consensus → decide autonomously, cite sources
- **T3 (Requires human)** — evidence conflicts, both silent, or subjective → queue

**Constructive tension**: When codebase and best practice conflict, classify as T3.

Present the classification:

```markdown
## Agent Decisions (T1 & T2)

| # | Decision Point | Tier | Decision | Evidence |
|---|---------------|------|----------|----------|
| 1 | ... | T1 | ... | file paths |
| 2 | ... | T2 | ... | sources |

## Requires Human Decision (T3)

| # | Decision Point | Reason |
|---|---------------|--------|
| 3 | ... | conflict / no evidence / subjective |
```

**If zero T3 items**: Skip Phases 3.5 and 4 entirely. Go to Phase 5.

### Phase 3.5: Advisory (T3 only)

Launch two advisory sub-agents **simultaneously**:

#### Advisor α

```
Task tool:
  subagent_type: general-purpose
  model: haiku
  prompt: |
    Read {SKILL_DIR}/references/advisory-guide.md. You are Advisor α.

    Tier 3 decision points:
    {list of T3 items}

    Research context:
    {codebase findings for these items}
    {web research findings for these items}

    Argue for the first perspective per the guide's side-assignment rules.
```

#### Advisor β

```
Task tool:
  subagent_type: general-purpose
  model: haiku
  prompt: |
    Read {SKILL_DIR}/references/advisory-guide.md. You are Advisor β.

    Tier 3 decision points:
    {list of T3 items}

    Research context:
    {codebase findings for these items}
    {web research findings for these items}

    Argue for the opposing perspective per the guide's side-assignment rules.
```

Both advisors run in parallel. Wait for both to complete.

### Phase 4: Persistent Questioning (T3 only)

Read `{SKILL_DIR}/references/questioning-guide.md` for full methodology.

For each T3 item, use `AskUserQuestion` with:

1. **Research context**: What codebase and web research found
2. **Advisor α's position**: Their argument (brief)
3. **Advisor β's position**: Their argument (brief)
4. **The question**: With 2-4 concrete options from advisory perspectives

After each answer:
- **Why-dig** 2-3 times on surface-level answers (see questioning-guide.md)
- **Detect tensions** between this answer and previous answers
- **Check for new ambiguities** revealed by the answer → classify → repeat if T3

### Phase 5: Output

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
If yes: save to a project-appropriate location with a descriptive filename.

---

## --light Mode

Fast, direct clarification without sub-agents. The original clarify behavior
with added persistence.

### Phase 1: Capture

1. Record the requirement verbatim
2. Identify ambiguities using the categories in questioning-guide.md

### Phase 2: Iterative Q&A

Read `{SKILL_DIR}/references/questioning-guide.md` for methodology.

Loop using `AskUserQuestion`:

```
while ambiguities remain:
    pick most critical ambiguity
    ask with 2-4 concrete options
    why-dig on surface-level answers (2-3 levels)
    detect tensions with prior answers
    check for new ambiguities
```

### Phase 3: Output

```markdown
## Requirement Clarification Summary

### Before (Original)
"{original request verbatim}"

### After (Clarified)
**Goal**: {precise description}
**Reason**: {the ultimate purpose or jobs-to-be-done}
**Scope**: {what is included and excluded}
**Constraints**: {limitations, requirements, preferences}
**Success Criteria**: {how to verify correctness}

### Decisions Made

| Question | Decision |
|----------|----------|
| ... | ... |
```

Then offer to save.

---

## Rules

1. **Research first, ask later** (default mode): Exhaust research before asking
2. **Cite evidence**: Every autonomous decision must include specific evidence
3. **Respect the tiers**: Do not ask about T1/T2; do not auto-decide T3
4. **Constructive tension**: Conflicts between sources are signals, not problems
5. **Persistent but not annoying**: Why-dig on vague answers, accept clear ones
6. **Preserve intent**: Refine the requirement, don't redirect it
7. **Grounded experts**: Best practice research must cite real published work
8. **Honest advisors**: Advisory opinions argue in good faith, not strawman

## References

- [references/research-guide.md](references/research-guide.md) — Fallback research methodology
- [references/aggregation-guide.md](references/aggregation-guide.md) — Tier classification rules
- [references/advisory-guide.md](references/advisory-guide.md) — Advisor α/β methodology
- [references/questioning-guide.md](references/questioning-guide.md) — Persistent questioning
