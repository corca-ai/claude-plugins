---
name: plan
description: "Agent-assisted plan drafting to define a reviewable execution contract before coding. Reuses gather/clarify evidence first, fills unresolved gaps with targeted research, applies BDD success criteria and cwf:review integration, then persists plan+lessons as runtime-independent files for plan→impl→review continuity. Triggers: \"cwf:plan\", \"plan this task\""
---

# Plan

Create a reviewable execution contract (scope, files, success criteria) before code changes begin.

## Quick Start

```text
cwf:plan <task description>
```

## Design Intent (Post-v3 Architecture)

CWF v3 moved planning from runtime-specific plan-mode hooks to a runtime-independent skill (`cwf:plan`) with file-based contracts.

1. **Better planning input quality before drafting**
   - `gather` + `clarify` collect evidence and decision points before planning starts.
   - Planning conversations can reveal constraints/preferences that must be recorded in `lessons.md` immediately, not after implementation.
2. **Context continuity without user-managed reset choreography**
   - Some runtimes expose context-reset workflows after planning discussions.
   - CWF keeps continuity by default through `plan.md`, `lessons.md`, and optional `cwf:handoff --phase`, instead of shifting context-management burden to the user.
3. **Stable cross-runtime contract for long autonomous work**
   - `plan.md` (WHAT) + `phase-handoff.md` (HOW, optional) + `lessons.md` (learned constraints) define a persistent contract for impl/review stages.
   - This keeps execution safe and reliable across auto-compact and runtime boundaries (Claude/Codex).

---

## Phase 0: Update Live State

Use the live-state helper (session-first write target):

```bash
bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . \
  phase="plan" \
  task="{task summary}"
```

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

## Phase 2: Evidence Baseline & Gap-Fill Research

### 2.0 Resolve session directory

Resolve the effective live-state file, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
```

### 2.1 Build baseline from existing artifacts

Use persisted artifacts as the default planning evidence before launching any new research.

1. Resolve the effective live-state file and read `live.clarify_result_file` when set.
2. Read gather/clarify artifacts already available for this session, prioritizing:
   - clarify summary file (`live.clarify_result_file`)
   - `{session_dir}/clarify-codebase-research.md`
   - `{session_dir}/clarify-web-research.md`
   - `{session_dir}/clarify-expert-alpha.md`
   - `{session_dir}/clarify-expert-beta.md`
   - relevant gathered markdown outputs (and matching `.meta.yaml`) from the current session directory
3. Build an **Evidence Gap List**:
   - which decision points are already answerable from existing evidence
   - which decision points still need additional investigation

If no reusable artifacts are available, treat all unresolved decision points as gap candidates and continue to Phase 2.2.

### 2.2 Context recovery check (gap-fill outputs)

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these gap-fill output files:

| Agent | Output file |
|-------|-------------|
| Prior Art Researcher | `{session_dir}/plan-prior-art-research.md` |
| Codebase Analyst | `{session_dir}/plan-codebase-analysis.md` |

Decision:

- If Evidence Gap List is empty: skip to Phase 3 (no extra research needed).
- If Evidence Gap List is non-empty and both files are valid: reuse them and skip to Phase 3.
- Otherwise continue to Phase 2.3.

### 2.3 Adaptive gap triage

Assess each unresolved gap to decide which extra research lane is needed:

| Gap type | Agent decision |
|----------|----------------|
| Gap is mainly repository-specific (existing architecture, constraints, local patterns) | Launch Codebase Analyst only |
| Gap is mainly external best practice / prior art | Launch Prior Art Researcher only |
| Gap spans both repository constraints and external practice | Launch both agents in parallel |
| Gap is already answerable from baseline after re-check | No launch for that gap |

When uncertain, prefer launching both agents.

### 2.4 Launch targeted sub-agents

Launch sub-agents **simultaneously** using the Task tool — only for lanes selected in Phase 2.3 and only when their result files are missing or invalid.
- Shared output persistence contract: [agent-patterns.md § Sub-agent Output Persistence Contract](../../references/agent-patterns.md#sub-agent-output-persistence-contract).

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

    Baseline evidence summary from gather/clarify:
    {summary from Phase 2.1}

    Unresolved evidence gaps to investigate:
    {gap list for prior-art lane from Phase 2.3}

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

    Baseline evidence summary from gather/clarify:
    {summary from Phase 2.1}

    Unresolved evidence gaps to investigate:
    {gap list for codebase lane from Phase 2.3}

    ## Output Persistence
    Write your complete findings to: {session_dir}/plan-codebase-analysis.md
    At the very end of the file, append this sentinel marker on its own line:
    <!-- AGENT_COMPLETE -->
```

Wait for all launched sub-agents to complete. Re-validate each launched file using the context recovery protocol.

### 2.5 Read output files

After sub-agents complete, read the result files from the session directory (not in-memory return values):

- `{session_dir}/plan-prior-art-research.md` — Prior art research findings
- `{session_dir}/plan-codebase-analysis.md` — Codebase analysis findings

Use these file contents as additional input for Phase 3 synthesis.

### 2.6 Persistence Gate (Critical when gap-fill research runs)

Apply the stage-tier policy from the context recovery protocol when Phase 2.4 launched any gap-fill sub-agent:

1. `plan-prior-art-research.md` and `plan-codebase-analysis.md` are critical.
2. If either file is still invalid after one bounded retry, **hard fail** the
   stage with explicit file-level error and stop plan drafting.
3. Record gate path in output (`PERSISTENCE_GATE=HARD_FAIL` or equivalent).

If no gap-fill sub-agent was launched, record `PERSISTENCE_GATE=SKIP_NO_GAP` and proceed.

## Phase 3: Plan Drafting

Synthesize baseline evidence (from gather/clarify artifacts) and any additional gap-fill research into a structured plan. Read `{SKILL_DIR}/../../references/plan-protocol.md` for protocol rules on location, sections, and format.

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

### Plan Structure Contract

Use [`plan-protocol.md`](../../references/plan-protocol.md) as the single source of truth for:

- Required plan/lesson sections
- Success criteria baseline structure
- Artifact location and creation timing
- `lessons.md` format and language policy

Keep only these skill-specific additions in the generated plan:

1. Add a required `## Commit Strategy` section:
   - **Per step** (default for modular changes)
   - **Per change pattern** (for cross-cutting changes)
   - **Custom** (explicit commit boundaries + rationale)
1. Keep Success Criteria in the two-layer format:
   - **Behavioral (BDD)** scenarios
   - **Qualitative** non-functional criteria
1. Expand `## Decision Log` to include evidence/source and resolution metadata:

   | # | Decision Point | Evidence / Source (artifact or URL + confidence) | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
   |---|----------------|---------------------------------------------------|-------------------------|------------|--------|-------------|-------------------|
   | 1 | ... | ... | ... | ... | open/resolved | ... | ... |

   - `Status=open`: leave `Resolution`, `Resolved By`, and `Resolved At` as `TBD`.
   - `Status=resolved`: cite concrete evidence (e.g., `plan-codebase-analysis.md`, `plan-prior-art-research.md`, URL).

### Research Integration

- Start from gather/clarify evidence as the primary baseline for plan rationale
- Incorporate gap-fill findings only for unresolved decisions
- Note where codebase patterns inform implementation steps
- Flag conflicts between best practices and existing code as decision points

## Phase 4: Write Artifacts

Determine the session directory following plan-protocol.md location rules:

1. If the user provided an output path, use it.
2. Otherwise run `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh --bootstrap <title>` and use its output path.
   - `--bootstrap` creates the resolved directory, initializes missing `plan.md`/`lessons.md`, and pre-registers the session in `cwf-state.yaml` `sessions` when state exists.

Write two files:

### plan.md

Write the complete plan from Phase 3, following `plan-protocol.md` and the skill-specific additions above (`Commit Strategy`, expanded `Decision Log`).

### lessons.md

Initialize `lessons.md` using the shared format in `plan-protocol.md` (user language). If no learnings exist yet, create the file with a header and a short placeholder note.

Before finishing this skill, append plan-stage learnings captured during user ping-pong (for example: clarified constraints, corrected assumptions, revealed preferences). Do not defer these to implementation.

## Phase 5: Review Offer

After writing plan artifacts, suggest review:

```text
Plan drafted at .cwf/projects/{dir}/plan.md.

For a multi-perspective review before implementation, run:
  cwf:review --mode plan
```

---

## Rules

1. **Evidence-first before drafting**: Use gather/clarify artifacts as baseline first; run additional research only for unresolved evidence gaps
2. **Two-layer criteria**: Success criteria must include both BDD and qualitative layers
3. **Cite evidence**: Reference specific files, URLs, or sources for plan decisions
4. **Follow protocol**: Adhere to plan-protocol.md for format and location
5. **Don't over-plan**: Keep steps actionable and concrete, avoid excessive detail
6. **Preserve task intent**: Refine the approach, don't redirect the goal
7. **Cross-cutting → shared reference first**: When identical logic applies to 3+ targets, create a shared reference file as Step 0. "동일 적용" is a plan smell — replace with an explicit shared file path
8. **Commit Strategy is required**: Every plan must include a Commit Strategy section. Default is one commit per Step.
9. **Preparatory refactoring check**: When a target file is 300+ lines with 3+ planned changes, add Step 0 to extract separable blocks first
10. **Conditional critical persistence hard-fail**: When gap-fill research is launched, if `plan-prior-art-research.md` or `plan-codebase-analysis.md` remains invalid after bounded retry, stop with explicit error instead of drafting from partial data
11. **Language override is mandatory**: `plan.md` is in English; `lessons.md` is in the user's language
12. **Plan-stage learnings must be logged immediately**: Record conversation-time learnings in `lessons.md` during planning, not only after implementation

## References

- [plan-protocol.md](../../references/plan-protocol.md) — Plan & Lessons Protocol
