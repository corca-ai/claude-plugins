---
name: clarify
description: "Unified requirement clarification to prevent downstream implementation churn by resolving ambiguity early. Default: research-first with autonomous decision-making and persistent questioning. --light: direct iterative Q&A. Triggers: \"cwf:clarify\", \"clarify this\", \"refine requirements\""
---

# Clarify

Resolve ambiguity before planning so implementation starts from explicit decisions, not assumptions.

**Language**: Write clarification artifacts in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:clarify <requirement>          # Research-first (default)
cwf:clarify <requirement> --light  # Direct Q&A, no sub-agents
```

---

## Mode Selection

Before entering Default or --light mode, assess **clarify depth** based on input specificity:

1. Read `next-session.md` or the user's task description
2. Check if the input provides: **target file paths**, **expected changes per file**, and **BDD-style success criteria**
3. Apply this heuristic:

| Input specificity | Clarify depth | Rationale |
|-------------------|---------------|-----------|
| All 3 present (files + changes + criteria) | **AskUserQuestion only** — ask 2-3 binary/choice questions for remaining ambiguities, skip Phases 2-2.5 | Prior session retro effectively served as clarify |
| 1-2 present | **--light mode** — iterative Q&A without sub-agents | Partial clarity, direct questions suffice |
| None present (vague requirement) | **Default mode** — full research + expert analysis | Scope is open, exploration needed |

This heuristic can be overridden by explicit `--light` flag or user instruction.

---

## Default Mode

### Phase 0: Update Live State

Edit `cwf-state.yaml` `live` section: set `phase: clarify`, `task` to the requirement summary, and `key_files` to files relevant to the requirement.

### Phase 1: Capture & Decompose

1. Record the original requirement verbatim
2. Decompose into concrete **decision points** — specific questions that need answers before implementation can begin
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

#### Context recovery (before launching)

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

- `{session_dir}/clarify-codebase-research.md`
- `{session_dir}/clarify-web-research.md`

Launch sub-agents **simultaneously** using the Task tool (only for missing or invalid results).

#### Sub-agent A: Codebase Researcher

```yaml
Task tool:
  subagent_type: Explore
  max_turns: 20
  prompt: |
    Explore the codebase and report evidence relevant to these decision points.
    For each point, search with Glob/Grep, read relevant files, and assess
    confidence (High/Medium/Low). Cite file paths and line numbers.
    Report evidence only — do not make decisions.

    Decision points:
    {list from Phase 1}

    Write your complete findings to: {session_dir}/clarify-codebase-research.md
    The file MUST exist when you finish. End your output file with the exact
    line `<!-- AGENT_COMPLETE -->` as the last line.
```

#### Sub-agent B: Web Researcher

```yaml
Task tool:
  subagent_type: general-purpose
  max_turns: 20
  prompt: |
    Research best practices for these decision points.

    ## Web Research Protocol
    Read the "Web Research Protocol" section of
    {CWF_PLUGIN_DIR}/references/agent-patterns.md and follow it exactly.
    Key points: discover URLs via WebSearch first (never guess URLs),
    use WebFetch then fall back to agent-browser for JS-rendered pages,
    skip failed domains, budget turns for writing output.
    You have Bash access for agent-browser CLI commands.

    For each point, find authoritative sources and expert perspectives.
    Cite real published work. Report findings — do not make decisions.

    Decision points:
    {list from Phase 1}

    Write your complete findings to: {session_dir}/clarify-web-research.md
    The file MUST exist when you finish. End your output file with the exact
    line `<!-- AGENT_COMPLETE -->` as the last line.
```

Both sub-agents run in parallel. Wait for both to complete. Read the output files from session dir (not the in-memory Task return values).

### Phase 2.5: Expert Analysis

#### Context recovery (before launching)

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

- `{session_dir}/clarify-expert-alpha.md`
- `{session_dir}/clarify-expert-beta.md`

Launch two domain expert sub-agents **simultaneously** using the Task tool (only for missing or invalid results).

**Expert selection**:

1. Read `expert_roster` from `cwf-state.yaml`
2. Analyze decision points for domain keywords; match against each roster entry's `domain` field
3. Select 2 experts with **contrasting frameworks** — different analytical lenses on the same problem
4. If roster has < 2 domain matches, fill remaining slots via independent selection (prioritize well-known figures with contrasting methodological approaches)

#### Expert α

```yaml
Task tool:
  subagent_type: general-purpose
  max_turns: 12
  prompt: |
    Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md.
    You are Expert α, operating in **clarify mode**.

    Your identity: {selected expert name}
    Your framework: {expert's domain from roster or independent selection}

    Decision points:
    {list from Phase 1}

    Research findings summary:
    {summarized outputs from Phase 2 codebase + web research}

    Analyze which decisions are most critical through your published framework.
    Use web search to verify your expert identity and cite published work.
    Output your analysis in the clarify mode format from the guide.

    Write your complete findings to: {session_dir}/clarify-expert-alpha.md
    The file MUST exist when you finish. End your output file with the exact
    line `<!-- AGENT_COMPLETE -->` as the last line.
```

#### Expert β

```yaml
Task tool:
  subagent_type: general-purpose
  max_turns: 12
  prompt: |
    Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md.
    You are Expert β, operating in **clarify mode**.

    Your identity: {selected expert name — contrasting framework from Expert α}
    Your framework: {expert's domain from roster or independent selection}

    Decision points:
    {list from Phase 1}

    Research findings summary:
    {summarized outputs from Phase 2 codebase + web research}

    Analyze which decisions are most critical through your published framework.
    Use web search to verify your expert identity and cite published work.
    Output your analysis in the clarify mode format from the guide.

    Write your complete findings to: {session_dir}/clarify-expert-beta.md
    The file MUST exist when you finish. End your output file with the exact
    line `<!-- AGENT_COMPLETE -->` as the last line.
```

Both expert sub-agents run in parallel. Wait for both to complete. Read the output files from session dir (not the in-memory Task return values).

**--light mode**: Phase 2.5 is skipped (consistent with --light skipping all sub-agents).

### Phase 3: Classify & Decide

Read `{SKILL_DIR}/references/aggregation-guide.md` for full classification rules.

For each decision point, classify using **three evidence sources**: codebase research (Phase 2), web research (Phase 2), and expert analysis (Phase 2.5).

- **T1 (Codebase-resolved)** — codebase has clear evidence → decide autonomously, cite files
- **T2 (Best-practice-resolved)** — best practice consensus → decide autonomously, cite sources
- **T3 (Requires human)** — evidence conflicts, all silent, or subjective → queue

**Constructive tension**: When sources conflict, classify as T3. Expert analysis provides additional signal but does not override direct codebase or best-practice evidence.

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

#### Context recovery (before launching)

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

- `{session_dir}/clarify-advisor-alpha.md`
- `{session_dir}/clarify-advisor-beta.md`

Launch two advisory sub-agents **simultaneously** (only for missing or invalid results):

#### Advisor α

```yaml
Task tool:
  subagent_type: general-purpose
  model: haiku
  max_turns: 12
  prompt: |
    Read `{SKILL_DIR}/references/advisory-guide.md`. You are Advisor α.

    Tier 3 decision points:
    {list of T3 items}

    Research context:
    {codebase findings for these items}
    {web research findings for these items}

    Argue for the first perspective per the guide's side-assignment rules.

    Write your complete findings to: {session_dir}/clarify-advisor-alpha.md
    The file MUST exist when you finish. End your output file with the exact
    line `<!-- AGENT_COMPLETE -->` as the last line.
```

#### Advisor β

```yaml
Task tool:
  subagent_type: general-purpose
  model: haiku
  max_turns: 12
  prompt: |
    Read `{SKILL_DIR}/references/advisory-guide.md`. You are Advisor β.

    Tier 3 decision points:
    {list of T3 items}

    Research context:
    {codebase findings for these items}
    {web research findings for these items}

    Argue for the opposing perspective per the guide's side-assignment rules.

    Write your complete findings to: {session_dir}/clarify-advisor-beta.md
    The file MUST exist when you finish. End your output file with the exact
    line `<!-- AGENT_COMPLETE -->` as the last line.
```

Both advisors run in parallel. Wait for both to complete. Read the output files from session dir (not the in-memory Task return values).

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

### Expert Analysis
(Only in default mode, omitted in --light)

| Expert | Framework | Key Insight |
|--------|-----------|-------------|
| {Expert α name} | {framework} | {1-line summary of analysis} |
| {Expert β name} | {framework} | {1-line summary of analysis} |

### All Decisions

| # | Decision Point | Decision | Decided By | Evidence |
|---|---------------|----------|------------|----------|
| 1 | ... | ... | Agent (T1) | file paths |
| 2 | ... | ... | Agent (T2) | sources |
| 3 | ... | ... | Human | advisory context |
```

Then ask: "Save this clarified requirement to a file?" If yes: save to a project-appropriate location with a descriptive filename.

**Completion tracking** (after saving the summary file):

1. Edit `cwf-state.yaml` → set `live.clarify_completed_at` to current
   ISO 8601 timestamp (e.g., `"2026-02-10T14:30:00Z"`)
2. Edit `cwf-state.yaml` → set `live.clarify_result_file` to the path of
   the saved clarification summary file

This state is what `cwf:impl` Phase 1.0 checks as a pre-condition.

**Follow-up suggestions** (when CWF plugin is loaded):

1. `cwf:review --mode clarify` — Multi-perspective review of the clarified requirement before implementation
2. `cwf:handoff --phase` — Generate a phase handoff document that captures HOW context (protocols, rules, must-read references, constraints) for the implementation phase. Recommended when context will be cleared before implementation, as `plan.md` carries WHAT but not HOW.

Present both suggestions. If context is getting large or the user is about to clear context, emphasize the phase handoff suggestion.

---

## --light Mode

Fast, direct clarification without sub-agents. The original clarify behavior with added persistence.

### Phase 1: Capture

1. Record the requirement verbatim
2. Identify ambiguities using the categories in questioning-guide.md

### Phase 2: Iterative Q&A

Read `{SKILL_DIR}/references/questioning-guide.md` for methodology.

Loop using `AskUserQuestion`:

```text
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

**Completion tracking** (after saving the summary file):

1. Edit `cwf-state.yaml` → set `live.clarify_completed_at` to current
   ISO 8601 timestamp (e.g., `"2026-02-10T14:30:00Z"`)
2. Edit `cwf-state.yaml` → set `live.clarify_result_file` to the path of
   the saved clarification summary file

This state is what `cwf:impl` Phase 1.0 checks as a pre-condition.

**Follow-up** (when CWF plugin is loaded): Suggest `cwf:handoff --phase` if the user plans to clear context before implementation.

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
9. **Expert evidence is supplementary**: Expert analysis enriches classification but does not override direct codebase or best-practice evidence

## References

- [references/research-guide.md](references/research-guide.md) — Fallback research methodology
- [references/aggregation-guide.md](references/aggregation-guide.md) — Tier classification rules
- [references/advisory-guide.md](references/advisory-guide.md) — Advisor α/β methodology
- [references/questioning-guide.md](references/questioning-guide.md) — Persistent questioning
- [expert-advisor-guide.md](../../references/expert-advisor-guide.md) — Expert sub-agent identity, grounding, and analysis format
