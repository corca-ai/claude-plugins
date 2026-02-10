---
name: run
description: |
  Full CWF pipeline auto-chaining. Orchestrates the complete workflow:
  gather → clarify → plan → review(plan) → impl → review(code) → retro → ship.
  Respects Decision #19: human gates pre-impl, autonomous post-impl.
  Triggers: "cwf:run", "run workflow"
allowed-tools:
  - Skill
  - Task
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Run

Full CWF pipeline orchestration with configurable user gates.

**Language**: Communicate with the user in their prompt language. Artifacts in English.

## Quick Start

```text
cwf:run <task description>           # Full pipeline from scratch
cwf:run --from impl                  # Resume from impl stage
cwf:run --skip ship                  # Full pipeline, skip ship
cwf:run --skip review-plan,retro     # Skip specific stages
```

---

## Phase 1: Initialize

1. Parse task description and flags (`--from`, `--skip`)
1. Create session directory via `scripts/next-prompt-dir.sh <sanitized-title>`
1. Update `cwf-state.yaml` `live` section:

```yaml
live:
  session_id: "{next session ID}"
  dir: "{session directory}"
  branch: "{current branch}"
  phase: "gather"
  task: "{task description}"
```

1. Report initialization:

```text
Pipeline initialized: {session_dir}
Stages: {list of stages to execute, with skipped ones marked}
```

---

## Phase 2: Pipeline Execution

Execute stages in order. Each stage invokes the corresponding CWF skill via the Skill tool.

### Stage Definition

| # | Stage | Skill Invocation | Gate | Auto |
|---|-------|-----------------|------|------|
| 1 | gather | `cwf:gather` | — | false |
| 2 | clarify | `cwf:clarify` | User confirms requirements | false |
| 3 | plan | `cwf:plan` | User approves plan | false |
| 4 | review-plan | `cwf:review --mode plan` | Verdict-based | true |
| 5 | impl | `cwf:impl --skip-clarify --skip-branch` | — | true |
| 6 | review-code | `cwf:review --mode code` | Verdict-based | true |
| 7 | retro | `cwf:retro` | — | true |
| 8 | ship | `cwf:ship` | User confirms PR | false |

### Stage Execution Loop

For each stage (respecting `--from` and `--skip` flags):

1. Update `cwf-state.yaml` `live.phase` to the current stage name
1. Invoke the skill using the Skill tool:

   ```text
   Skill(skill="{skill-name}", args="{args if any}")
   ```

1. After skill completes, apply the gate:

#### User Gates (auto: false)

Ask the user with `AskUserQuestion`:

```text
{stage} complete. How to proceed?
```

Options:
- **Proceed** — continue to next stage
- **Revise** — re-run the current stage (with user's feedback as additional context)
- **Skip next** — skip the next stage and continue
- **Stop** — halt the pipeline

#### Auto Gates (auto: true)

For review stages, check the verdict:
- **Pass** or **Conditional Pass** — proceed automatically
- **Revise** — attempt auto-fix (see Review Failure Handling)

For non-review auto stages (impl, retro) — proceed automatically.

### Review Failure Handling

When a review returns **Revise**:

1. Extract the concerns from the review output
1. If the failed review was `review-plan`:
   - Re-invoke `cwf:plan` with concerns as additional context
   - Re-invoke `cwf:review --mode plan`
   - If still Revise: halt and ask user
1. If the failed review was `review-code`:
   - Create a fix plan from the concerns
   - Re-invoke `cwf:impl` with the fix plan
   - Re-invoke `cwf:review --mode code`
   - If still Revise: halt and ask user

Maximum 1 auto-fix attempt per review stage. After that, escalate to user.

### --from Flag

When `--from <stage>` is provided:

1. Skip all stages before `<stage>`
1. Verify prerequisites exist:
   - `--from impl`: plan.md must exist
   - `--from review-code`: implementation must be committed
   - `--from retro`: review must have run
1. If prerequisites are missing, report and ask user whether to proceed anyway

### --skip Flag

When `--skip <stage1>,<stage2>` is provided:

1. Mark listed stages as skipped in the pipeline
1. During execution, skip them and proceed to the next stage
1. Report each skip:

```text
Skipping {stage} (--skip flag).
```

---

## Phase 3: Completion

After all stages complete (or the pipeline is halted):

1. Update `cwf-state.yaml`:
   - Set `live.phase` to `"done"`
   - Append session entry to `sessions` list
1. Report pipeline summary:

```markdown
## Pipeline Complete

### Stages Executed
| Stage | Status | Notes |
|-------|--------|-------|
| gather | completed | — |
| clarify | completed | — |
| plan | completed | — |
| review-plan | Pass | — |
| impl | completed | 3 commits |
| review-code | Conditional Pass | 1 concern addressed |
| retro | completed | — |
| ship | skipped | --skip flag |

### Artifacts
- Plan: {path to plan.md}
- Lessons: {path to lessons.md}
- Retro: {path to retro.md}
- Session dir: {session_dir}
```

---

## Rules

1. **Decision #19**: Pre-impl stages require human gates. Post-impl stages chain automatically. This is the core design principle.
1. **One auto-fix attempt**: Never loop more than once on a review failure. Escalate to user after 1 retry.
1. **Skill invocation only**: Use the Skill tool to invoke CWF skills. Do not inline skill logic.
1. **State tracking**: Update `cwf-state.yaml` `live.phase` at every stage transition. This enables compact recovery to know where the pipeline was interrupted.
1. **Preserve skill autonomy**: Each invoked skill manages its own sub-agents, artifacts, and output. `cwf:run` orchestrates but does not micromanage.
1. **Flags compose**: `--from impl --skip retro` is valid. Apply both filters.
1. **Graceful halt**: When the user chooses "Stop", update state and report what was completed. Do not leave state in an inconsistent phase.
