# Plan: L1-L3 Implementation — impl Git Awareness + Sub-agent File Persistence

## Context

Session S32 (docs overhaul) revealed three lessons:

- **L1**: cwf:impl has zero git awareness — no branch creation, no per-work-item
  commits. A 93-file implementation produced a monolithic uncommitted diff.
- **L2**: cwf:clarify sub-agent completion is not enforced. Context compaction
  loses in-memory wait state, so research results arrive after impl finishes.
- **L3**: Post-hoc commit organization works but wastes knowledge that existed
  at work-item boundaries during execution.

Prior art research found: Aider commits per LLM response with Conventional
Commits; GitHub Copilot auto-creates branches from issues; Temporal uses
event-sourced state for durable execution; GitHub Actions uses `needs` +
`if: always()` for phase gates with override.

## Goal

1. Add git workflow integration to cwf:impl (branch gate, commit gate)
2. Add file-based sub-agent result persistence to **all 5 skills** that use
   sub-agents with in-memory results: clarify, plan, review, retro, refactor
3. Add clarify completion gate to cwf:impl

The clarify→plan→review→impl→ship pipeline becomes resilient to context loss
and produces atomic, reviewable commits.

## Scope

- **Included**: impl/SKILL.md, clarify/SKILL.md, plan/SKILL.md,
  review/SKILL.md, retro/SKILL.md, refactor/SKILL.md, cwf-state.yaml schema
- **Included (hooks)**: log-turn.sh (Turn 1 repetition bug fix)
- **Excluded**: ship/SKILL.md, gather/SKILL.md (already persists to file),
  impl/SKILL.md Phase 3b (agents write files directly — inherently persistent),
  new skill creation, references/ files, agent-prompts.md

## Steps

### Step 1: Add Phase 0.5 (Branch Gate) to impl/SKILL.md

Insert a new "Phase 0.5: Branch Gate" section between Phase 0 and Phase 1.

Content:

1. Run `git branch --show-current` to detect current branch
2. Run `git rev-parse --verify main 2>/dev/null` and
   `git rev-parse --verify master 2>/dev/null` to detect base branch name
3. **If on base branch** (main/master or the branch listed in cwf-state.yaml
   as the repo's primary branch):
   - Derive a branch name from the plan title:
     `feat/{sanitized-plan-title}` (lowercase, spaces→hyphens, max 50 chars)
   - Run `git checkout -b {branch-name}`
   - Report: "Created feature branch: {branch-name}"
4. **If already on a feature branch**: Report "On feature branch: {name}" and
   proceed
5. **NEVER proceed on a base branch** — this is a hard gate, not a warning.
   The only escape is `cwf:impl --skip-branch` which skips this phase entirely.

Include exact bash commands in the SKILL.md instructions. Use prohibition
language: "NEVER proceed with implementation on a base branch."

### Step 2: Add Phase 1 Clarify Pre-condition to impl/SKILL.md

Add a "1.0 Clarify Completion Check" sub-section before "1.1 Plan Discovery".

Content:

1. Read `cwf-state.yaml` → check `live.clarify_completed_at` field
2. **If field exists and is non-empty**: Clarify completed → proceed to 1.1
3. **If field is missing or empty**:
   - Display message: "Clarify phase has not completed. Run cwf:clarify first,
     or use `cwf:impl --skip-clarify` to bypass."
   - **Hard-block**: Stop execution. Do not proceed to plan discovery.
4. `--skip-clarify` flag bypasses this check entirely with a logged warning:
   "Skipping clarify pre-condition check (--skip-clarify)."

### Step 3: Add Phase 3 Commit Gate to impl/SKILL.md

Add commit instructions at two points:

**3A. After Phase 3a completion** (direct execution path):

After step 5 ("If phase-handoff.md was loaded...") and before step 6
("After completion, proceed to Phase 4"), insert:

1. Run `git add` on all files modified during this work item (specific files,
   not `git add -A`)
2. Construct commit message:
   - Type: infer from domain (feat/fix/docs/refactor/chore)
   - Scope: derive from the plan step's primary target (e.g., `impl`, `clarify`)
   - Description: summarize the work item's deliverable
   - Body: list the step descriptions that were executed
   - Trailer: `Co-Authored-By: Claude <agent>` (from git log convention)
3. Run `git commit` with the constructed message using HEREDOC format
4. Report the commit hash and summary

**3B. After each 3b batch completion** (agent team path):

After "3b.3 Sequential Batches" step 4, insert a "3b.3.5 Batch Commit" section:

1. **File-to-work-item mapping**: Each agent's prompt MUST include the list of
   files it is expected to modify. The orchestrator maintains a map:
   `{work_item_id → [file_paths]}` derived from Phase 2 decomposition.
   After batch completion, use this map to attribute files to work items.
   If an agent modifies unexpected files (not in its assigned list), include
   them in that work item's commit with a note in the commit body.
2. After each batch completes (before launching next batch), stage and commit
   per work item using the file map from step 1
3. Same commit message construction as 3A
4. If a batch contains multiple work items, create one commit per work item
   (not one per batch) — stage only the files mapped to each work item
5. Between commits, verify `git status --porcelain` shows clean state before
   proceeding to next batch

**Lesson-driven commits**: If during implementation a lesson is discovered:

1. Record it in lessons.md immediately
2. If the lesson leads to a code change, make that change
3. Commit the lesson-driven change separately with type `fix` or `refactor`
   and body referencing the lesson: "Driven by lesson: {lesson title}"

### Step 4: Add file-based result persistence to clarify/SKILL.md

Modify Phase 2, Phase 2.5, and Phase 3.5 to persist sub-agent results to files.

**Common pattern** (applies to all sub-agent persistence steps 4–9):

```text
Sub-agent launch:
1. Include output file path in agent prompt: "Write your complete findings
   to: {session_dir}/{skill}-{agent-name}.md. The file MUST exist when
   you finish." — agent self-persists, not orchestrator-persists.
2. Set max_turns: research agents ≤20, expert/advisor agents ≤12
3. Session dir = cwf-state.yaml → live.dir value

Research agent prompt strategy (root-cause fix for 404/429):
Note: Sub-agents bypass session hooks (hooks are session-level snapshots).
Sub-agents CAN use WebSearch directly — the redirect-websearch.sh hook
does not apply to them. Sub-agents CANNOT use cwf:gather (session-level
skill, inaccessible to sub-agents). Therefore the research strategy
relies on WebSearch + WebFetch directly, not gather-script.
1. "Use WebSearch to discover valid URLs first. NEVER construct URLs from
   memory or training data — they may be outdated or nonexistent."
2. "Find 3–5 authoritative sources. Stop when sufficient evidence is
   collected — do NOT exhaustively search."
3. "If a WebFetch returns 404 or 429, skip that domain entirely. Move to
   the next source."
4. "Prefer official documentation over blog posts."

Context recovery (before launching):
1. Check if result files already exist in session dir (from interrupted run)
2. If file exists → validate before reuse:
   a. File size > 0 bytes (not empty)
   b. File contains a sentinel marker at the end: `<!-- AGENT_COMPLETE -->`
      (each agent prompt includes: "End your output file with the exact line
      `<!-- AGENT_COMPLETE -->` as the last line.")
   c. If file exists but fails validation → treat as incomplete, re-launch
      that sub-agent (the new run overwrites the partial file)
3. If file exists AND valid → read it instead of re-launching that sub-agent
4. Only launch sub-agents for missing or invalid results
```

**Phase 2 file names**:

- Sub-agent A → `{session_dir}/clarify-codebase-research.md`
- Sub-agent B → `{session_dir}/clarify-web-research.md`

**Phase 2.5 file names**:

- Expert α → `{session_dir}/clarify-expert-alpha.md`
- Expert β → `{session_dir}/clarify-expert-beta.md`

**Phase 3.5 file names** (if T3 items exist):

- Advisor α → `{session_dir}/clarify-advisor-alpha.md`
- Advisor β → `{session_dir}/clarify-advisor-beta.md`

### Step 5: Add completion tracking to clarify/SKILL.md

Modify Phase 5 (Output) to write completion state.

After writing the clarification summary file, add:

1. Edit `cwf-state.yaml` → set `live.clarify_completed_at` to current
   ISO 8601 timestamp
2. Edit `cwf-state.yaml` → set `live.clarify_result_file` to the path of the
   saved clarification summary file

This state is what impl Phase 1.0 checks as a pre-condition.

### Step 6: Add file-based result persistence to plan/SKILL.md

Modify Phase 2 (Parallel Research) to persist sub-agent results to files.

**Phase 2 file names**:

- Sub-agent A (Prior Art) → `{session_dir}/plan-prior-art-research.md`
- Sub-agent B (Codebase) → `{session_dir}/plan-codebase-analysis.md`

Apply the same context recovery pattern from Step 4: check for existing files
before launching, skip agents whose results already exist.

### Step 7: Add file-based result persistence + error observability to review/SKILL.md

Modify Phase 2 (Launch All Reviewers) to persist each reviewer's verdict.

**Phase 2 file names** (6 reviewers):

- Slot 1 (Security) → `{session_dir}/review-security.md`
- Slot 2 (UX/DX) → `{session_dir}/review-ux-dx.md`
- Slot 3 (Correctness) → `{session_dir}/review-correctness.md`
- Slot 4 (Architecture) → `{session_dir}/review-architecture.md`
- Slot 5 (Expert α) → `{session_dir}/review-expert-alpha.md`
- Slot 6 (Expert β) → `{session_dir}/review-expert-beta.md`

Apply the same context recovery pattern.

**L9 fix — External CLI error observability** (Phase 3.2):

When an external CLI (Codex/Gemini) fails (exit code ≠ 0):

1. Read the stderr log file (`{tmp_dir}/{tool}-stderr.log`)
2. Extract the first actionable error message:
   - For JSON stderr: parse `.error.message` or `.error.details`
   - For plain text: find the last line containing "Error" or "error"
   - Fallback: first 3 non-empty lines of stderr
3. Include the extracted error in the Confidence Note of the Review Synthesis:
   "Slot N ({tool}) FAILED → fallback. Cause: {extracted_error}"
4. This replaces the current exit-code-only classification

### Step 8: Add file-based result persistence to retro/SKILL.md

Modify deep mode batches to persist sub-agent results.

**Batch 1 file names**:

- Agent A (CDM) → `{session_dir}/retro-cdm-analysis.md`
- Agent B (Learning Resources) → `{session_dir}/retro-learning-resources.md`

**Batch 2 file names**:

- Agent C (Expert α) → `{session_dir}/retro-expert-alpha.md`
- Agent D (Expert β) → `{session_dir}/retro-expert-beta.md`

Apply the same context recovery pattern. Light mode has no sub-agents — no
changes needed for light mode.

### Step 9: Add file-based result persistence to refactor/SKILL.md

Modify all three sub-agent modes to persist results.

**Deep Review mode (`--skill`) Phase 4 file names**:

- Agent A (Structural) → `{session_dir}/refactor-deep-structural.md`
- Agent B (Quality+Concept) → `{session_dir}/refactor-deep-quality.md`

**Holistic mode (`--skill --holistic`) Phase 3 file names**:

- Agent A (Convention) → `{session_dir}/refactor-holistic-convention.md`
- Agent B (Concept) → `{session_dir}/refactor-holistic-concept.md`
- Agent C (Workflow) → `{session_dir}/refactor-holistic-workflow.md`

**Code Tidying mode (`--code`) Phase 2**: Multiple agents (one per commit).
File per agent: `{session_dir}/refactor-tidy-commit-{N}.md`

Apply the same context recovery pattern for all modes.

### Step 10: Fix log-turn.sh Turn 1 repetition bug

**Bug**: Session log repeats Turn 1 content on every hook invocation instead
of incrementally appending new turns.

**Root cause**: When the first invocation encounters meta/snapshot entries that
get filtered out, `TURN_NUM_FILE` is never written. Subsequent invocations
still read `TURN_START=1`, causing Turn 1 to be re-logged every time.

**Fix locations** in `plugins/cwf/hooks/scripts/log-turn.sh`:

1. After the "no turns to log" early exit (around the turn filtering logic):
   write `TURN_NUM_FILE` even when no turns are logged, so the next
   invocation starts from the correct turn number
2. Fix the rewind case turn numbering formula to not produce duplicate turn
   numbers when transcript is truncated
3. Ensure `LAST_OFFSET` is always updated after processing, even when zero
   turns are extracted

### Step 11: Update cwf-state.yaml schema documentation

Add inline YAML comments to cwf-state.yaml documenting the new fields in the
`live` section:

```yaml
live:
  session_id: "..."
  dir: "..."
  branch: "..."
  phase: "..."
  task: "..."
  key_files: [...]
  decisions: [...]
  # Added by cwf:clarify Phase 5 — read by cwf:impl Phase 1.0
  clarify_completed_at: ""    # ISO 8601 timestamp, empty = not completed
  clarify_result_file: ""     # Path to clarify summary file
```

No breaking changes — new fields are optional and default to empty.

## Success Criteria

### Behavioral (BDD)

```gherkin
Feature: impl Branch Gate (Phase 0.5)

  Scenario: On base branch, auto-create feature branch
    Given cwf:impl is invoked on the "main" branch
    When Phase 0.5 Branch Gate executes
    Then a new branch "feat/{plan-title}" is created
    And implementation proceeds on the new branch

  Scenario: On feature branch, proceed normally
    Given cwf:impl is invoked on branch "feat/l1-l3-impl"
    When Phase 0.5 Branch Gate executes
    Then no branch is created
    And a message "On feature branch: feat/l1-l3-impl" is shown

  Scenario: Skip branch gate with flag
    Given cwf:impl --skip-branch is invoked on "main"
    When Phase 0.5 is evaluated
    Then Phase 0.5 is skipped entirely
    And a warning "Skipping branch gate" is logged

Feature: impl Clarify Pre-condition (Phase 1.0)

  Scenario: Clarify completed, proceed
    Given cwf-state.yaml has live.clarify_completed_at = "2026-02-10T12:00:00Z"
    When cwf:impl Phase 1.0 reads state
    Then implementation proceeds to Phase 1.1

  Scenario: Clarify not completed, hard-block
    Given cwf-state.yaml has no clarify_completed_at field
    When cwf:impl Phase 1.0 reads state
    Then an error message is shown referencing cwf:clarify
    And implementation does NOT proceed

  Scenario: Skip clarify check with flag
    Given cwf:impl --skip-clarify is invoked
    When Phase 1.0 is evaluated
    Then the clarify check is bypassed with a logged warning

Feature: impl Commit Gate (Phase 3)

  Scenario: Direct execution commits after completion
    Given Phase 3a direct execution completes modifying files A, B
    When the Commit Gate executes
    Then files A, B are staged (not git add -A)
    And a Conventional Commit is created with relevant type and scope
    And the commit message body lists the executed step descriptions

  Scenario: Agent team commits per work item per batch
    Given Phase 3b batch 1 completes with work items W1 (files A, B) and W2 (files C)
    And the orchestrator has a file-to-work-item map from Phase 2 decomposition
    When the Batch Commit (3b.3.5) executes
    Then two commits are created: one for W1 (A, B) and one for W2 (C)
    And git status is clean before batch 2 launches

  Scenario: Lesson-driven change creates separate commit
    Given a lesson is discovered during implementation
    When the lesson leads to a code change
    Then the lesson is recorded in lessons.md
    And the code change is committed separately referencing the lesson

Feature: Sub-agent File Persistence (all skills)

  Scenario: clarify sub-agent results saved to files
    Given cwf:clarify Phase 2 sub-agents complete
    When results are collected
    Then clarify-codebase-research.md exists in the session directory
    And clarify-web-research.md exists in the session directory

  Scenario: clarify expert results saved to files
    Given cwf:clarify Phase 2.5 experts complete
    When results are collected
    Then clarify-expert-alpha.md exists in the session directory
    And clarify-expert-beta.md exists in the session directory

  Scenario: plan research results saved to files
    Given cwf:plan Phase 2 sub-agents complete
    When results are collected
    Then plan-prior-art-research.md exists in the session directory
    And plan-codebase-analysis.md exists in the session directory

  Scenario: review verdicts saved to files
    Given cwf:review Phase 2 reviewers complete
    When results are collected
    Then 6 review-{slot}.md files exist in the session directory

  Scenario: retro deep mode results saved to files
    Given cwf:retro deep mode Batch 1 and 2 complete
    When results are collected
    Then retro-cdm-analysis.md, retro-learning-resources.md exist
    And retro-expert-alpha.md, retro-expert-beta.md exist

  Scenario: refactor sub-agent results saved to files
    Given cwf:refactor --skill deep review Phase 4 completes
    When results are collected
    Then refactor-deep-structural.md and refactor-deep-quality.md exist

  Scenario: Context recovery skips existing valid results (any skill)
    Given a sub-agent result file already exists in session dir
    And the file is non-empty and ends with "<!-- AGENT_COMPLETE -->"
    When the skill's sub-agent phase starts (after context compaction)
    Then the corresponding sub-agent is NOT re-launched
    And the existing file is read instead

  Scenario: Context recovery re-launches for invalid results
    Given a sub-agent result file exists but is empty or lacks sentinel
    When the skill's sub-agent phase starts
    Then the corresponding sub-agent IS re-launched
    And the partial file is overwritten

  Scenario: Agent self-persists results (not orchestrator)
    Given a sub-agent is launched with output path in prompt
    When the sub-agent completes
    Then the output file exists at the specified path
    And the orchestrator reads the file (not the in-memory return value)

  Scenario: Research agent uses WebSearch before WebFetch
    Given a research sub-agent prompt includes the strategy rules
    When the agent needs external documentation
    Then it uses WebSearch to discover valid URLs first
    And does NOT construct URLs from memory

Feature: review External CLI Error Observability (L9)

  Scenario: External CLI failure includes error cause in Confidence Note
    Given Gemini CLI fails with exit code 1
    And stderr.log contains "MODEL_CAPACITY_EXHAUSTED" error
    When Phase 3.2 error handling executes
    Then the Confidence Note includes "Cause: MODEL_CAPACITY_EXHAUSTED"
    And the fallback agent is launched as before

  Scenario: External CLI failure with unparseable stderr
    Given Codex CLI fails with exit code 1
    And stderr.log contains unstructured text
    When Phase 3.2 error handling executes
    Then the Confidence Note includes the first 3 non-empty stderr lines
    And the fallback agent is launched as before

Feature: log-turn.sh Turn Logging

  Scenario: Multiple turns logged incrementally
    Given a session with 5 user/assistant turns
    When log-turn.sh runs after each turn
    Then the session log contains Turn 1 through Turn 5
    And no turn is duplicated

  Scenario: First invocation with only meta entries
    Given the transcript contains only system/snapshot entries
    When log-turn.sh runs
    Then TURN_NUM_FILE is still written
    And the next invocation starts from the correct turn number

Feature: clarify Completion Tracking (Phase 5)

  Scenario: Completion state written after output
    Given cwf:clarify Phase 5 writes the summary file
    When state tracking executes
    Then cwf-state.yaml live.clarify_completed_at has an ISO 8601 timestamp
    And cwf-state.yaml live.clarify_result_file has the summary file path
```

### Qualitative

- SKILL.md instructions use exact bash commands (not prose descriptions)
- Hard gates use prohibition language ("NEVER", "Do NOT proceed")
- Override flags are documented with their bypass behavior
- New cwf-state.yaml fields are backward-compatible (empty = not set)
- Commit messages follow the Conventional Commits format visible in git log
- File persistence paths are deterministic (no random names)
- File persistence pattern is consistent across all 5 skills (same naming
  convention: `{skill}-{agent-name}.md`, same recovery logic)
- Context recovery check-then-skip logic is identical in all skills
- Sub-agent prompts use "WebSearch first" strategy, not URL guessing
- max_turns is set on all sub-agent Task calls
- Agent self-persistence: agent writes its own output file, orchestrator reads
- External CLI failures expose error cause in Confidence Note (not just exit code)
- Context recovery validates file completeness (sentinel marker), not just existence

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| plugins/cwf/skills/impl/SKILL.md | Edit | Add Phase 0.5 Branch Gate, Phase 1.0 Clarify Pre-condition, Phase 3 Commit Gate |
| plugins/cwf/skills/clarify/SKILL.md | Edit | Add Phase 2/2.5/3.5 file persistence, Phase 5 completion tracking |
| plugins/cwf/skills/plan/SKILL.md | Edit | Add Phase 2 file persistence + context recovery |
| plugins/cwf/skills/review/SKILL.md | Edit | Add Phase 2 file persistence + context recovery |
| plugins/cwf/skills/retro/SKILL.md | Edit | Add Batch 1/2 file persistence + context recovery |
| plugins/cwf/skills/refactor/SKILL.md | Edit | Add all mode file persistence + context recovery |
| cwf-state.yaml | Edit | Add clarify_completed_at, clarify_result_file fields with documentation comments |
| plugins/cwf/hooks/scripts/log-turn.sh | Edit | Fix Turn 1 repetition bug (offset + turn numbering) |

## Don't Touch

- plugins/cwf/skills/ship/SKILL.md
- plugins/cwf/skills/gather/SKILL.md (already persists to file)
- plugins/cwf/skills/impl/references/agent-prompts.md
- plugins/cwf/references/ (all shared reference files)

## Deferred Actions

- [ ] Update agent-prompts.md Implementation Agent Prompt Template to include
  commit instructions (depends on validating the commit gate pattern first)
- [ ] Add git status verification to Phase 4 (verify clean working tree after
  all commits)
- [ ] Consider adding `live.impl_branch` field to cwf-state.yaml for ship
  integration
