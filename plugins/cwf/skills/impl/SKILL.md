---
name: impl
description: |
  Implementation orchestration from a plan. Decomposes plan steps into
  parallelizable work items, spawns domain-appropriate agents, and verifies
  completion against BDD success criteria.
  Triggers: "cwf:impl", "implement this plan"
allowed-tools:
  - Task
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Impl

Orchestrate autonomous implementation from a structured plan.

**Language**: Write all implementation artifacts in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:impl                    # Auto-detect most recent plan.md
cwf:impl <path/to/plan.md>  # Explicit plan path
cwf:impl --skip-branch      # Skip Phase 0.5 branch gate (stay on current branch)
cwf:impl --skip-clarify     # Skip Phase 1.0 clarify pre-condition check
```

---

## Phase 0: Update Live State

Edit `cwf-state.yaml` `live` section: set `phase: impl`, `task` to the plan's goal summary, and `key_files` to the plan's key files list.

## Phase 0.5: Branch Gate

Ensure implementation runs on a feature branch, never on a base branch.

> **NEVER proceed with implementation on a base branch.** This is a hard gate, not a warning.

If `--skip-branch` flag is provided, skip this phase entirely and log:

```text
Skipping branch gate (--skip-branch).
```

Otherwise, execute these steps:

### 0.5.1 Detect Current Branch

```bash
git branch --show-current
```

### 0.5.2 Detect Base Branch Name

```bash
git rev-parse --verify main 2>/dev/null && echo "main" || true
git rev-parse --verify master 2>/dev/null && echo "master" || true
```

Also check `cwf-state.yaml` for a custom primary branch name (e.g., if the repo uses a non-standard base branch listed under `live.branch` when `live.phase` is not `impl`).

### 0.5.3 Gate Decision

**If on a base branch** (main, master, or the repo's primary branch):

1. Derive a branch name from the plan title:
   - Format: `feat/{sanitized-plan-title}`
   - Sanitize: lowercase, spaces to hyphens, strip non-alphanumeric (except hyphens), max 50 chars
2. Create the feature branch:

   ```bash
   git checkout -b feat/{sanitized-plan-title}
   ```

3. Report:

   ```text
   Created feature branch: feat/{sanitized-plan-title}
   ```

**If already on a feature branch** (not main/master/primary):

Report and proceed:

```text
On feature branch: {branch-name}
```

**NEVER proceed on a base branch** — the only escape is `cwf:impl --skip-branch` which skips this phase entirely. Do NOT proceed with implementation on a base branch under any circumstances.

---

## Phase 1: Load Plan

Find and parse the plan that drives implementation.

### 1.0 Clarify Completion Check

Verify that `cwf:clarify` has completed before proceeding with implementation.

If `--skip-clarify` flag is provided, skip this check entirely and log:

```text
Skipping clarify pre-condition check (--skip-clarify).
```

Otherwise, execute these steps:

1. Read `cwf-state.yaml` and check the `live.clarify_completed_at` field
2. **If field exists and is non-empty**: Clarify completed — proceed to 1.1

   ```text
   Clarify completed at {clarify_completed_at}. Proceeding to plan discovery.
   ```

3. **If field is missing or empty**: Hard-block. Display this message and stop:

   ```text
   Clarify phase has not completed. Run cwf:clarify first,
   or use `cwf:impl --skip-clarify` to bypass.
   ```

   Do NOT proceed to plan discovery. This is a hard gate — implementation cannot begin without a completed clarify phase unless explicitly bypassed.

### 1.1 Plan Discovery

If an explicit path was provided, use it. Otherwise:

1. Scan `prompt-logs/*/plan.md` using Glob
2. Sort by directory name (most recent date-sequence first)
3. Select the most recent `plan.md`

If no plan is found, report to the user and stop:

```text
No plan.md found in prompt-logs/. Run cwf:plan first.
```

### 1.1b Phase Handoff Discovery

Check for a `phase-handoff.md` in the same directory as the discovered `plan.md`:

1. Derive the directory from the plan path: `dirname {plan.md path}`
2. Check if `phase-handoff.md` exists in that directory
3. If found, read and parse all sections:
   - **Context Files to Read**: Additional files the agent must read before implementation
   - **Design Decision Summary**: Key choices with rationale — treat as binding context
   - **Protocols to Follow**: Behavioral rules — treat as binding constraints alongside plan.md
   - **Do NOT**: Prohibitions — append to plan's "Don't Touch" list as behavioral constraints
   - **Implementation Hints**: Practical guidance — use during Phase 3 execution
   - **Success Criteria**: Additional BDD criteria — merge with plan's criteria for Phase 4 verification
4. If phase-handoff.md specifies "Context Files to Read", read each listed file before proceeding

If `phase-handoff.md` is not found, proceed normally with plan.md only. Phase handoff is optional.

### 1.2 Section Extraction

Read the plan and extract these sections (all optional except Steps):

| Section | Key Content |
|---------|-------------|
| **Context** | Background, rationale |
| **Goal** | Desired outcome |
| **Steps** | Ordered implementation steps (REQUIRED) |
| **Files to Create/Modify** | File paths with actions |
| **Success Criteria — Behavioral (BDD)** | Given/When/Then scenarios |
| **Success Criteria — Qualitative** | Non-functional quality attributes |
| **Don't Touch** | Files explicitly out of scope |
| **Deferred Actions** | Items not for this session |

If the Steps section is missing or empty, report to the user and stop.

### 1.3 User Confirmation

Present a summary and confirm before proceeding:

```markdown
## Plan Loaded

**Source**: {path to plan.md}
**Goal**: {goal from plan}
**Steps**: {count} steps
**Files**: {count} files to create/modify
**BDD Criteria**: {count} scenarios
**Don't Touch**: {list or "none specified"}
**Phase Handoff**: {path to phase-handoff.md, or "not found (proceeding with plan only)"}
**Phase Protocols**: {count} protocols to follow
**Phase Do NOT**: {count} prohibitions

Proceed with implementation?
```

Use `AskUserQuestion` with options: "Proceed", "Review plan first", "Cancel".

---

## Phase 2: Analyze & Decompose

Break the plan into parallelizable work items and size the agent team.

### 2.1 Domain Detection

Read `{SKILL_DIR}/references/agent-prompts.md` Section "Domain Signal Table".

For each step, identify the primary domain by matching:
- File patterns mentioned in the step
- File patterns from the "Files to Create/Modify" table
- Keywords and descriptions in the step text

### 2.2 Dependency Analysis

Read `{SKILL_DIR}/references/agent-prompts.md` Section "Dependency Detection Heuristics".

Analyze step-to-step dependencies:
- **File overlap**: Steps touching the same file must be sequential
- **Output references**: Step N uses output from Step M → sequential
- **Ordering keywords**: "after", "then", "once X is done" → sequential
- **Independent**: No shared files, no output dependencies → parallel-safe

### 2.3 Work Item Grouping

Group steps into work items:

1. Place sequential-dependent steps in the same work item (preserve order)
2. Group steps with the same domain into one work item when possible
3. Keep parallel-safe items in separate work items
4. Each work item gets: assigned steps, file list, relevant BDD criteria

### 2.4 Adaptive Team Sizing

Read `{SKILL_DIR}/../../references/agent-patterns.md` for general agent principles.

| Work Items | Agents | Strategy |
|------------|--------|----------|
| 1 (≤3 files) | 0 | Direct execution — Phase 3a |
| 2-3 | 2 | Group related items per agent |
| 4-6 | 3 | Balance parallelism vs coordination |
| 7+ | 4 (hard cap) | Beyond 4, overhead exceeds gains |

### 2.5 Present Decomposition

Show the decomposition before executing:

```markdown
## Decomposition

### Work Items

| # | Steps | Domain | Files | Parallel |
|---|-------|--------|-------|----------|
| 1 | 1, 2 | {domain} | {file list} | yes |
| 2 | 3 | {domain} | {file list} | yes |
| 3 | 4, 5 | {domain} | {file list} | after #1 |

### Execution Strategy
- **Mode**: {Direct (3a) | Agent Team (3b)}
- **Agents**: {count}
- **Batches**: {count} (sequential batches of parallel items)

### Don't Touch (enforced)
- {files from plan's Don't Touch section}
```

If Agent Team mode: use `AskUserQuestion` with "Execute", "Adjust grouping", "Cancel". If Direct mode: proceed without confirmation.

---

## Phase 3a: Direct Execution

For simple plans (1 work item, ≤3 files).

1. Execute each step in the work item sequentially
2. Use Write, Edit, Bash, and other allowed tools directly
3. Follow the plan's step descriptions precisely
4. Respect the "Don't Touch" list — never modify those files
5. If phase-handoff.md was loaded, apply its Implementation Hints during execution and respect its "Do NOT" constraints
6. **Commit Gate**: Stage and commit the completed work before proceeding:

   a. Stage only the files modified during this work item (specific files, not `git add -A`):

      ```bash
      git add path/to/file1 path/to/file2
      ```

   b. Construct a Conventional Commit message:
      - **Type**: Infer from domain — `feat` (new feature), `fix` (bug fix), `docs` (documentation), `refactor` (restructuring), `chore` (maintenance)
      - **Scope**: Derive from the plan step's primary target (e.g., `impl`, `clarify`, `review`)
      - **Description**: Summarize the work item's deliverable (imperative mood, max 72 chars)
      - **Body**: List the step descriptions that were executed
      - **Trailer**: `Co-Authored-By: Claude <agent>` (follow the git log convention of the repo)

   c. Commit using HEREDOC format:

      ```bash
      git commit -m "$(cat <<'EOF'
      type(scope): description of deliverable

      Steps executed:
      - Step N: description
      - Step M: description

      Co-Authored-By: Claude <agent>
      EOF
      )"
      ```

   d. Report the commit:

      ```text
      Committed: {short-hash} type(scope): description
      ```

7. After commit, proceed to Phase 4

---

## Phase 3b: Agent Team Execution

For complex plans requiring parallel work.

### 3b.1 Prompt Construction

For each work item, build an agent prompt using the template from `{SKILL_DIR}/references/agent-prompts.md` Section "Implementation Agent Prompt Template". The prompt includes:

- The specific steps assigned to this agent
- The file list (create/modify) for these steps
- Relevant BDD criteria that this agent's work should satisfy
- The Don't Touch list (full list — every agent must respect it)
- Context from the plan (Goal, relevant Context sections)
- Phase handoff protocols, hints, and "Do NOT" constraints (if phase-handoff.md was loaded)

### 3b.2 Parallel Launch

Launch agents for parallel-safe work items in a **single message** with multiple Task tool calls:

```yaml
# All parallel items in one message
Task tool (item 1):
  subagent_type: general-purpose
  mode: bypassPermissions
  prompt: |
    {constructed prompt from 3b.1}

Task tool (item 2):
  subagent_type: general-purpose
  mode: bypassPermissions
  prompt: |
    {constructed prompt from 3b.1}
```

### 3b.3 Sequential Batches

If some work items depend on others:

1. Launch all parallel-safe items in batch 1
2. Wait for batch 1 to complete
3. Launch dependent items in batch 2 (include batch 1 results as context)
4. Repeat until all batches complete

Between batches, briefly verify that prior batch outputs exist and are valid before launching the next batch.

### 3b.3.5 Batch Commit

After each batch completes (before launching the next batch), stage and commit per work item.

**1. File-to-work-item mapping**: The orchestrator maintains a map derived from Phase 2 decomposition:

```text
{work_item_id → [file_paths]}
```

Each agent's prompt (from 3b.1) MUST include the list of files it is expected to modify. After batch completion, use this map to attribute files to work items. If an agent modifies unexpected files (not in its assigned list), include them in that work item's commit with a note in the commit body:

```text
Unexpected files modified: path/to/unexpected-file
```

**2. Per-work-item commits**: If a batch contains multiple work items, create one commit per work item (not one per batch). Stage only the files mapped to each work item:

```bash
# Work item W1
git add path/to/file-a path/to/file-b
git commit -m "$(cat <<'EOF'
type(scope): W1 deliverable summary

Steps executed:
- Step N: description
- Step M: description

Co-Authored-By: Claude <agent>
EOF
)"

# Work item W2
git add path/to/file-c
git commit -m "$(cat <<'EOF'
type(scope): W2 deliverable summary

Steps executed:
- Step P: description

Co-Authored-By: Claude <agent>
EOF
)"
```

**3. Commit message construction**: Same rules as Phase 3a step 6 — Conventional Commit with type, scope, description, body listing executed steps, and Co-Authored-By trailer.

**4. Clean state verification**: Between commits (and before launching the next batch), verify the working tree is clean:

```bash
git status --porcelain
```

If the output is non-empty, investigate and resolve before proceeding. Do NOT launch the next batch with uncommitted changes.

**5. Report**: After all commits in the batch, report:

```text
Batch {N} committed:
- {short-hash} type(scope): W1 summary
- {short-hash} type(scope): W2 summary
```

### 3b.3.6 Lesson-Driven Commits

If during implementation a lesson is discovered (any insight about codebase behavior, tool limitations, or pattern violations):

1. Record it in `lessons.md` immediately
2. If the lesson leads to a code change, make that change
3. Commit the lesson-driven change **separately** from the work item commit:

   ```bash
   git add lessons.md path/to/changed-file
   git commit -m "$(cat <<'EOF'
   fix(scope): brief description of lesson-driven fix

   Driven by lesson: {lesson title}

   The lesson revealed that {brief explanation}, requiring this change.

   Co-Authored-By: Claude <agent>
   EOF
   )"
   ```

   Use type `fix` or `refactor` depending on whether it corrects a bug or restructures code. The commit body MUST reference the lesson with the prefix "Driven by lesson:".

### 3b.4 Result Collection

For each completed agent:

1. Record which steps were completed
2. Note any files created or modified
3. Capture any issues or deviations reported by the agent
4. If an agent reports failure, record the failure and continue with other agents

---

## Phase 4: Verify & Suggest Review

Check implementation against the plan's success criteria.

### 4.1 BDD Criteria Checklist

For each BDD scenario from the plan (and from `phase-handoff.md` Success Criteria, if present):

1. Determine which work item(s) should have addressed it
2. Check if the relevant files were created/modified
3. Mark each criterion:
   - **Covered**: Implementation addresses this scenario
   - **Uncovered**: No implementation found for this scenario
   - **Partial**: Some aspects addressed, others missing

### 4.2 Qualitative Assessment

For each qualitative criterion, briefly note how the implementation addresses it (or flag if it doesn't).

### 4.3 Completion Summary

Present the verification results:

````markdown
## Implementation Complete

### BDD Criteria Coverage

| # | Scenario | Status | Notes |
|---|----------|--------|-------|
| 1 | {Given/When/Then summary} | Covered | {brief note} |
| 2 | {Given/When/Then summary} | Uncovered | {what's missing} |

### Qualitative Assessment

| Criterion | Assessment |
|-----------|------------|
| {criterion} | {how it's addressed} |

### Files Modified

| File | Action | Agent |
|------|--------|-------|
| {path} | Created | {agent # or "direct"} |

### Issues

- {any deviations, failures, or concerns}
````

### 4.4 Uncovered Criteria

If any BDD criteria are uncovered:

1. List them explicitly
2. Ask the user whether to:
   - Attempt to address them now (additional implementation pass)
   - Defer them (add to Deferred Actions)
   - Ignore them (they may be covered by later stages)

### 4.5 Suggest Review

After presenting the summary:

```text
Implementation complete. To review the code quality and verify against
the plan's success criteria, run:
  cwf:review --mode code
```

---

## Rules

1. **Plan is the contract**: Implement what the plan says. Do not add features, refactor unrelated code, or reinterpret the goal
2. **Don't Touch means don't touch**: Never modify files in the Don't Touch list, even for "improvements"
3. **Parallel when safe, sequential when needed**: Only parallelize items with no file overlap or output dependencies
4. **No idle agents**: Size the team to the work. One agent with real work beats three agents where two wait
5. **Fail forward**: If one agent fails, collect its error and continue with others. Report all failures in Phase 4
6. **Verify against criteria**: Every BDD scenario must be checked, not assumed
7. **Preserve existing patterns**: Follow codebase conventions visible in existing files. Do not introduce new patterns without plan justification
8. **Markdown discipline**: All code fences must have a language specifier
9. **Phase handoff protocols are binding**: When `phase-handoff.md` is present, its "Protocols to Follow" and "Do NOT" sections carry the same weight as plan constraints. They are not suggestions.
10. **Phase handoff is optional**: Impl works with `plan.md` alone. Phase handoff enriches but is never required.
11. **Never implement on a base branch**: Phase 0.5 is a hard gate. The only bypass is `--skip-branch`.
12. **Commit per work item, not per batch**: Each work item gets its own commit with Conventional Commit format. Never create monolithic commits spanning multiple work items.
13. **Stage specific files, never `git add -A`**: Only stage files known to belong to the current work item. Prevent accidental inclusion of unrelated changes.
14. **Lesson-driven changes get separate commits**: If a lesson triggers a code change, commit it independently with a "Driven by lesson:" reference in the body.

## References

- [references/agent-prompts.md](references/agent-prompts.md) — Agent prompt template, domain signals, dependency heuristics
- [agent-patterns.md](../../references/agent-patterns.md) — Shared agent orchestration patterns
