---
name: run
description: "Full CWF pipeline auto-chaining for end-to-end delegation without manual stage sequencing. Orchestrates: gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship. Respects Decision #19: human gates pre-impl, autonomous post-impl. Triggers: \"cwf:run\", \"run workflow\""
---

# Run

Delegate end-to-end workflow orchestration when users do not want to manually sequence each skill.

**Language**: Communicate with the user in their prompt language. Artifacts in English.

## Quick Start

```text
cwf:run <task description>           # Full pipeline from scratch
cwf:run --from impl                  # Resume from impl stage
cwf:run --skip ship                  # Full pipeline, skip ship
cwf:run --skip review-plan,retro     # Skip specific stages
```

Operational note:
- Default `cwf:run` chain is: gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship.
- `refactor` runs before retro/ship to catch cross-skill and docs drift as part of the default delivery quality loop.
- Context-deficit resilience applies: stage orchestration must recover from persisted state/artifacts/handoff files, not prior chat memory.

---

## Phase 1: Initialize

1. Parse task description and flags (`--from`, `--skip`)
1. Bootstrap session directory via `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh --bootstrap <sanitized-title>`
   - This creates the directory, initializes `plan.md`/`lessons.md` if missing, and pre-registers the session in `cwf-state.yaml` `sessions` when state exists.
1. Initialize live state (session-first write path):

   ```bash
   bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . \
     session_id="{next session ID}" \
     dir="{session directory}" \
     branch="{current branch}" \
     worktree_root="{current git worktree root (absolute path)}" \
     worktree_branch="{current branch}" \
     phase="gather" \
     task="{task description}" \
     active_pipeline="cwf:run" \
     user_directive="{original user directive}" \
     pipeline_override_reason="" \
     state_version="1"
   bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh list-set . \
     remaining_gates="review-code,refactor,retro,ship"
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
| 5 | impl | `cwf:impl --skip-clarify` | — | true |
| 6 | review-code | `cwf:review --mode code` | Verdict-based | true |
| 7 | refactor | `cwf:refactor` | — | true |
| 8 | retro | `cwf:retro --from-run` | — | true |
| 9 | ship | `cwf:ship` | User confirms PR | false |

### Stage Execution Loop

For each stage (respecting `--from` and `--skip` flags):

1. Verify worktree consistency (compact/restart safety gate):

   ```bash
   live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve .)
   expected_worktree=$(awk '
     /^live:/ { in_live=1; next }
     in_live && /^[^[:space:]]/ { exit }
     in_live && /^[[:space:]]{2}worktree_root:[[:space:]]*/ {
       sub(/^[[:space:]]{2}worktree_root:[[:space:]]*/, "", $0)
       gsub(/^[\"\047]|[\"\047]$/, "", $0)
       print $0
       exit
     }
   ' "$live_state_file")
   current_worktree=$(git rev-parse --show-toplevel)
   if [[ -n "$expected_worktree" && "$expected_worktree" != "$current_worktree" ]]; then
     echo "WORKTREE_MISMATCH: expected $expected_worktree, got $current_worktree"
     # Halt and ask user before continuing
   fi
   ```

1. Update phase using the live-state helper:

   ```bash
   bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . phase="{current stage name}"
   bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh list-set . \
     remaining_gates="{remaining gate stages in order}"
   ```
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

For non-review auto stages (impl, refactor, retro) — proceed automatically.

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
   - `--from refactor`: code review must have run
   - `--from retro`: refactor must have run (or be explicitly skipped)
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

1. Run session completeness check:

   ```bash
   bash {CWF_PLUGIN_DIR}/scripts/check-session.sh --impl
   ```

   If any FAIL items are reported, fix them before proceeding. This is a forced function — the pipeline is not complete until all checks pass.

1. Update state:
   - Set final phase and clear active pipeline:
     `bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . phase="done" active_pipeline="" user_directive="" pipeline_override_reason=""`
   - Clear pending gates:
     `bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh list-set . remaining_gates=""`
   - Ensure the current session entry in `cwf-state.yaml` stays consistent with final artifacts/summary (registration is initialized during Phase 1 bootstrap)
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
| refactor | completed | docs/skills drift check |
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
1. **State tracking**: Use `cwf-live-state.sh set` and `list-set` at every stage transition so session-local live state stays current while root summary remains synchronized.
1. **Preserve skill autonomy**: Each invoked skill manages its own sub-agents, artifacts, and output. `cwf:run` orchestrates but does not micromanage.
1. **Flags compose**: `--from impl --skip retro` is valid. Apply both filters.
1. **Graceful halt**: When the user chooses "Stop", update state and report what was completed. Do not leave state in an inconsistent phase.
1. **Do not bypass impl branch gate by default**: `cwf:run` must not pass `--skip-branch` to `cwf:impl` unless the user explicitly requests bypass.
1. **Context-deficit resilience**: On resume/restart, reconstruct stage context from `cwf-state.yaml`, session artifacts, and handoff docs before invoking downstream skills.
1. **Worktree consistency gate**: During an active pipeline, if current worktree root diverges from `live.worktree_root`, stop immediately and request explicit user decision before any write/edit/ship action.
1. **Fail-closed run gates**: While `active_pipeline="cwf:run"` and `remaining_gates` includes `review-code`, ship/push/commit intents must be blocked unless `pipeline_override_reason` is explicitly set.

## References

- [agent-patterns.md](../../references/agent-patterns.md) — Shared agent orchestration patterns
- [plan-protocol.md](../../references/plan-protocol.md) — Session artifact location/protocol
