---
name: plan
description: "Agent-assisted plan drafting to define a reviewable execution contract before coding. Includes parallel research, BDD success criteria, and cwf:review integration. Complements the plan-protocol hook (passive injection) with active, structured plan creation. Triggers: \"cwf:plan\", \"plan this task\""
---

# Plan

Create a reviewable execution contract (scope, files, success criteria) before code changes begin.

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

### 2.0 Resolve session directory

Read `cwf-state.yaml` → `live.dir` to get the current session directory path.

```yaml
session_dir: "{live.dir value from cwf-state.yaml}"
```

### 2.1 Context recovery check

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

| Agent | Output file |
|-------|-------------|
| Prior Art Researcher | `{session_dir}/plan-prior-art-research.md` |
| Codebase Analyst | `{session_dir}/plan-codebase-analysis.md` |

Skip to Phase 3 if both files are valid. These two files are **critical outputs** for plan synthesis.

### 2.2 Launch sub-agents

Launch sub-agents **simultaneously** using the Task tool — only for agents whose result files are missing or invalid.

#### Sub-agent A: Prior Art Researcher

```yaml
Task tool:
  subagent_type: general-purpose
  max_turns: 20
  prompt: |
    Research best practices, frameworks, and prior art relevant to this task.

    ## Web Research Protocol
    Read the "Web Research Protocol" section of
    {CWF_PLUGIN_DIR}/references/agent-patterns.md and follow it exactly.
    Key points: discover URLs via WebSearch first (never guess URLs),
    use WebFetch then fall back to agent-browser for JS-rendered pages,
    skip failed domains, budget turns for writing output.
    You have Bash access for agent-browser CLI commands.

    Find:
    - Established methodologies or patterns for this type of work
    - Common pitfalls and how others avoided them
    - Relevant tools, libraries, or approaches
    Cite real sources with URLs. Report findings — do not make decisions.

    Task:
    {task description from Phase 1}

    Key decisions:
    {decisions from Phase 1}

    ## Output Persistence
    Write your complete findings to: {session_dir}/plan-prior-art-research.md
    At the very end of the file, append this sentinel marker on its own line:
    <!-- AGENT_COMPLETE -->
```

#### Sub-agent B: Codebase Analyst

```yaml
Task tool:
  subagent_type: Explore
  max_turns: 20
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

    ## Output Persistence
    Write your complete findings to: {session_dir}/plan-codebase-analysis.md
    At the very end of the file, append this sentinel marker on its own line:
    <!-- AGENT_COMPLETE -->
```

Wait for all launched sub-agents to complete. Re-validate each launched file using the context recovery protocol.

### 2.3 Read output files

After sub-agents complete, read the result files from the session directory (not in-memory return values):

- `{session_dir}/plan-prior-art-research.md` — Prior art research findings
- `{session_dir}/plan-codebase-analysis.md` — Codebase analysis findings

Use these file contents as input for Phase 3 synthesis.

### 2.4 Persistence Gate (Critical)

Apply the stage-tier policy from the context recovery protocol:

1. `plan-prior-art-research.md` and `plan-codebase-analysis.md` are critical.
2. If either file is still invalid after one bounded retry, **hard fail** the
   stage with explicit file-level error and stop plan drafting.
3. Record gate path in output (`PERSISTENCE_GATE=HARD_FAIL` or equivalent).

## Phase 3: Plan Drafting

Synthesize research from both sub-agents into a structured plan. Read `{SKILL_DIR}/../../references/plan-protocol.md` for protocol rules on location, sections, and format.

### Cross-Cutting Pattern Gate

Before finalizing Steps, scan for cross-cutting patterns:

1. Identify steps that apply **identical logic to 3+ targets** (files, skills, modules)
2. If found: add a **Step 0** that creates a shared reference file for the common pattern. Subsequent steps reference the shared file — never duplicate the pattern inline.
3. If not found: proceed normally

**Prohibited instructions** in step descriptions:
- "동일 적용" / "apply the same pattern" / "same as Step N"
- Any instruction that delegates architecture to parallel implementors

Each step must either reference a shared file or contain self-contained instructions. Parallel agents cannot see each other's work, so sharing must be decided at plan level.

### Preparatory Refactoring Check

Before finalizing Steps, assess whether preparatory refactoring is needed:

1. For each target file in "Files to Create/Modify", check its line count
2. If a file is **300+ lines** AND **3+ changes are planned** for it:
   - Add a **Step 0** that extracts separable blocks to reference files
   - This reduces edit surface for subsequent steps and improves commit independence
3. If no files meet the threshold: proceed normally

### Required Plan Sections

````markdown
# {Plan Title}

## Context
{Why this plan exists, background information}

## Goal
{Precise description of the desired outcome}

## Scope
{What is included and excluded}

## Commit Strategy
{How changes should be committed — one of:}
- **Per step**: Each step gets its own commit (default for modular changes)
- **Per change pattern**: Group commits by concept when cross-cutting
- **Custom**: Explicit commit boundaries with rationale

If not specified, default to **one commit per Step**.

## Steps
1. {Step with clear deliverable}
2. {Step with clear deliverable}
...

## Success Criteria

Two-layer format:

### Behavioral (BDD)

```gherkin
Given [context] When [action] Then [expected outcome]
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

1. If the user provided an output path, use it.
2. Otherwise run `{SKILL_DIR}/../../scripts/next-prompt-dir.sh <title>` and use its output path.
3. Create the resolved directory path.

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
Plan drafted at .cwf/projects/{dir}/plan.md.

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
7. **Cross-cutting → shared reference first**: When identical logic applies to 3+ targets, create a shared reference file as Step 0. "동일 적용" is a plan smell — replace with an explicit shared file path
8. **Commit Strategy is required**: Every plan must include a Commit Strategy section. Default is one commit per Step.
9. **Preparatory refactoring check**: When a target file is 300+ lines with 3+ planned changes, add Step 0 to extract separable blocks first
10. **Critical persistence outputs hard-fail**: If `plan-prior-art-research.md` or `plan-codebase-analysis.md` remains invalid after bounded retry, stop with explicit error instead of drafting from partial data

## References

- [plan-protocol.md](../../references/plan-protocol.md) — Plan & Lessons Protocol
