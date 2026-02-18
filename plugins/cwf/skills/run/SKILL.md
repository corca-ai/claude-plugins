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
cwf:run --ambiguity-mode strict      # Override T3 handling policy for this run
```

Operational note:
- Default `cwf:run` chain is: gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship.
- `refactor` runs before retro/ship to catch cross-skill and docs drift as part of the default delivery quality loop.
- Context-deficit resilience applies: stage orchestration must recover from persisted state/artifacts/handoff files, not prior chat memory.

---

## Phase 1: Initialize

1. Parse task description and flags (`--from`, `--skip`, `--ambiguity-mode`)
1. Resolve ambiguity mode (`--ambiguity-mode` or config default):

   ```bash
   source {CWF_PLUGIN_DIR}/hooks/scripts/env-loader.sh
   cwf_env_load_vars CWF_RUN_AMBIGUITY_MODE

   # precedence: CLI flag > config/env > built-in default
   resolved_mode="{--ambiguity-mode flag value if provided}"
   if [[ -z "$resolved_mode" ]]; then
     resolved_mode="${CWF_RUN_AMBIGUITY_MODE:-defer-blocking}"
   fi

   case "$resolved_mode" in
     strict|defer-blocking|defer-reversible|explore-worktrees) ;;
     *)
       echo "Invalid ambiguity mode: $resolved_mode (fallback: defer-blocking)"
       resolved_mode="defer-blocking"
       ;;
   esac
   ```
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
     ambiguity_mode="{resolved_mode}" \
     blocking_decisions_pending="false" \
     ambiguity_decisions_file="{session directory}/run-ambiguity-decisions.md" \
     stage_provenance_file="{session directory}/run-stage-provenance.md" \
     pipeline_override_reason="" \
     state_version="1"
   planned_closing_gates="{comma-separated subset of review-code,refactor,retro,ship after applying --from/--skip filters}"
   bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh list-set . \
     remaining_gates="$planned_closing_gates"
   ```

1. Initialize ambiguity ledger file (all modes):

   ```bash
   cat > "{session directory}/run-ambiguity-decisions.md" <<'EOF'
   # Run Ambiguity Decisions
   mode: {resolved_mode}
   open_blocking_count: 0
   open_non_blocking_count: 0
   updated_at: {ISO-8601 UTC}

   | Decision ID | Stage | Question | Chosen Option | Blocking | Reversible | Follow-up |
   |---|---|---|---|---|---|---|
   EOF
   ```

1. Initialize stage provenance log file:

   ```bash
   stage_provenance_file="{session directory}/run-stage-provenance.md"
   if [[ ! -f "$stage_provenance_file" ]]; then
     cat > "$stage_provenance_file" <<'EOF'
   # Run Stage Provenance
   | Stage | Skill | Args | Started At (UTC) | Finished At (UTC) | Duration (s) | Artifacts | Gate Outcome |
   |---|---|---|---|---|---|---|---|
   EOF
   elif ! grep -Fqx '| Stage | Skill | Args | Started At (UTC) | Finished At (UTC) | Duration (s) | Artifacts | Gate Outcome |' "$stage_provenance_file"; then
     printf '\n| Stage | Skill | Args | Started At (UTC) | Finished At (UTC) | Duration (s) | Artifacts | Gate Outcome |\n|---|---|---|---|---|---|---|---|\n' >> "$stage_provenance_file"
   fi
   ```

1. Report initialization:

```text
Pipeline initialized: {session_dir}
Ambiguity mode: {resolved_mode}
Stages: {list of stages to execute, with skipped ones marked}
```

---

## Phase 2: Pipeline Execution

Execute stages in order. Each stage invokes the corresponding CWF skill via the Skill tool.

### Stage Definition

| # | Stage | Skill Invocation | Gate | Auto |
|---|-------|-----------------|------|------|
| 1 | gather | `cwf:gather` | — | false |
| 2 | clarify | `cwf:clarify` | T3 policy depends on ambiguity mode | false |
| 3 | plan | `cwf:plan` | User approves plan | false |
| 4 | review-plan | `cwf:review --mode plan` | Verdict-based | true |
| 5 | impl | `cwf:impl --skip-clarify` | — | true |
| 6 | review-code | `cwf:review --mode code` | Verdict-based | true |
| 7 | refactor | `cwf:refactor` | — | true |
| 8 | retro | `cwf:retro --from-run` | — | true |
| 9 | ship | `cwf:ship` | User confirms PR | false |

### Ambiguity Modes (Clarify T3 Policy)

Use `live.ambiguity_mode` (resolved in Phase 1).

| Mode | Clarify T3 handling | Merge policy |
|---|---|---|
| `strict` | Stop and ask user for every T3 decision | no extra blocking by mode |
| `defer-blocking` | Decide autonomously, but persist unresolved decision debt | unresolved decision debt is merge-blocking at ship |
| `defer-reversible` | Decide autonomously with reversible structure (flags/adapters/switch points) | track debt, non-blocking by default |
| `explore-worktrees` | Implement alternatives in separate worktrees, then pick baseline | blocking depends on final unresolved debt |

When mode is not `strict`, create/update `{session_dir}/run-ambiguity-decisions.md` whenever T3 debt exists using this minimum file contract:

```markdown
# Run Ambiguity Decisions
mode: {mode}
open_blocking_count: {integer}
open_non_blocking_count: {integer}
updated_at: {ISO-8601 UTC}

| Decision ID | Stage | Question | Chosen Option | Blocking | Reversible | Follow-up |
|---|---|---|---|---|---|---|
| ... | clarify | ... | ... | yes/no | yes/no | issue/pr ref or TODO |
```

#### `explore-worktrees` operational flow

When `mode=explore-worktrees` and unresolved T3 alternatives exist, use this concrete workflow:

1. Create a deterministic worktree workspace under the session directory:

   ```bash
   session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
   wt_root="$session_dir/worktrees"
   mkdir -p "$wt_root"
   ```

1. For each alternative `{option_slug}`, create a dedicated branch + worktree:

   ```bash
   branch_name="run/t3-{decision_id}-{option_slug}"
   worktree_path="$wt_root/{decision_id}-{option_slug}"
   git worktree add -b "$branch_name" "$worktree_path" HEAD
   ```

1. Execute the minimal downstream validation path in each worktree (usually `plan` + `review-plan`, or targeted `impl` delta) and capture artifacts per option.
1. Select a baseline option and record the choice in `run-ambiguity-decisions.md` (decision ID, selected branch/worktree, rationale, follow-up).
1. Reconcile and clean up:
   - Keep baseline changes on the main pipeline branch via merge/cherry-pick.
   - Remove non-baseline worktrees and branches after confirming no needed uncommitted work remains:

     ```bash
     dirty_status=$(git -C "{worktree_path}" status --porcelain)
     if [[ -n "$dirty_status" ]]; then
       echo "WORKTREE_DIRTY: {worktree_path}"
       echo "$dirty_status"
       # Ask user whether to keep, commit/stash, or explicitly allow discard before cleanup.
     else
       git worktree remove "{worktree_path}"
       if ! git branch -d "run/t3-{decision_id}-{option_slug}"; then
         echo "BRANCH_NOT_MERGED: run/t3-{decision_id}-{option_slug}"
         # Ask user whether to keep branch for follow-up or explicitly allow force-delete.
       fi
     fi
     ```

   - Keep a non-baseline branch only if explicitly recorded as deferred follow-up.

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
1. For stages that consume session logs (`review-code`, `retro`, `ship`), run a best-effort Codex sync immediately before invocation:

   ```bash
   if [[ "{current stage name}" == "review-code" || "{current stage name}" == "retro" || "{current stage name}" == "ship" ]]; then
     bash {CWF_PLUGIN_DIR}/scripts/codex/sync-session-logs.sh --cwd "$PWD" --quiet || true
   fi
   ```
1. Invoke the skill using the Skill tool:

   ```bash
   stage_started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   stage_started_epoch=$(date -u +%s)
   # invoke stage skill
   Skill(skill="{skill-name}", args="{args if any}")
   stage_finished_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   stage_finished_epoch=$(date -u +%s)
   stage_duration_s=$((stage_finished_epoch - stage_started_epoch))
   ```

1. If current stage is `clarify`, apply ambiguity-mode handling:

   1. Resolve session dir and ambiguity file path:

      ```bash
      session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
      mode=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . ambiguity_mode)
      ambiguity_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . ambiguity_decisions_file)
      ```

   1. Determine whether clarify left unresolved T3 debt (use clarify summary/artifacts and explicit T3 table).
   1. Apply mode behavior:
      - `strict`: halt and ask user for each unresolved T3 item before proceeding.
      - `defer-blocking`: record autonomous decision + follow-up in `run-ambiguity-decisions.md`; set `blocking_decisions_pending="true"` if any blocking items remain open.
      - `defer-reversible`: record autonomous decision + reversible structure note; keep `blocking_decisions_pending="false"` unless user explicitly marks an item as blocking.
      - `explore-worktrees`: evaluate alternatives in separate worktrees; record comparison + final choice; set blocking flag based on remaining open debt.
   1. Synchronize live state:

      ```bash
      bash {CWF_PLUGIN_DIR}/scripts/sync-ambiguity-debt.sh \
        --base-dir . \
        --session-dir "$session_dir"
      ```

1. Enforce deterministic stage-artifact gate for run-closing stages (`review-code`, `refactor`, `retro`, `ship`):

   ```bash
   session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
   bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
     --session-dir "$session_dir" \
     --stage "{current stage name}" \
     --strict \
     --record-lessons
   ```

   - If this gate fails, stop immediately.
   - Report the failure to the user with file-level details.
   - Ask the user whether to revise and re-run the stage.

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

Clarify-stage exception:
- If stage is `clarify` and `ambiguity_mode` is `strict`, unresolved T3 items must be resolved with the user before `Proceed`.
- If stage is `clarify` and mode is not `strict`, T3 debt may continue only after `run-ambiguity-decisions.md` is updated and `blocking_decisions_pending` is synchronized.

#### Auto Gates (auto: true)

For review stages, check the verdict:
- **Pass** or **Conditional Pass** — proceed automatically
- **Revise** — attempt auto-fix (see Review Failure Handling)
- **Fail** — hard-stop the pipeline; summarize blocking findings and ask the user how to proceed

For non-review auto stages (impl, refactor, retro) — proceed automatically.

#### Stage Provenance Checklist (Required)

Append exactly one row to `{session_dir}/run-stage-provenance.md` for every stage outcome (`Proceed`, `Revise`, `Fail`, `Skipped`, `User Stop`), including early-stop paths before halting.

- `Stage`: current stage name
- `Skill` and `Args`: invoked skill + resolved args
- `Started At (UTC)` / `Finished At (UTC)` / `Duration (s)`
- `Artifacts`: key output paths produced by this stage (or `—`)
- `Gate Outcome`: `Proceed`, `Revise`, `Fail`, `Skipped`, or `User Stop`

Append format:

```bash
printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
  "{stage}" "{skill}" "{args}" \
  "$stage_started_at" "$stage_finished_at" "$stage_duration_s" \
  "{artifact_paths_or_dash}" "{gate_outcome}" \
  >> "{session_dir}/run-stage-provenance.md"
```

For skip or pre-invocation stop paths (for example `WORKTREE_MISMATCH`, review hard-stop, or user-selected `Stop`), set unavailable timing/skill fields to `—` and still append before exit.

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

When a review returns **Fail**:

1. Do not auto-fix or auto-retry.
1. Halt pipeline progression immediately.
1. Report fail reasons with file-level references and the stage name.
1. Ask user for an explicit decision: `Revise plan/code`, `Skip downstream stages`, or `Stop`.
1. Keep `remaining_gates` unchanged until the user explicitly resolves the fail path.

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
   session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
   stage_provenance_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . stage_provenance_file)
   gate_args=()
   for closing_stage in review-code refactor retro ship; do
     if awk -F'|' -v stage="$closing_stage" '
       BEGIN { found=0 }
       /^\|/ {
         s=$2; outcome=$9
         gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
         gsub(/^[[:space:]]+|[[:space:]]+$/, "", outcome)
         if (s == stage && outcome != "Skipped") {
           found=1
         }
       }
       END { exit(found ? 0 : 1) }
     ' "$stage_provenance_file"; then
       gate_args+=(--stage "$closing_stage")
     fi
   done

   if [[ "${#gate_args[@]}" -gt 0 ]]; then
     bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
       --session-dir "$session_dir" \
       "${gate_args[@]}" \
       --strict \
       --record-lessons
   else
     echo "No run-closing stages were executed; skip final run-closing artifact gate."
   fi
   ```

   If any FAIL items are reported, fix them before proceeding. This is a forced function — the pipeline is not complete until all checks pass.

1. Update state:
   - Clear pending gates first:
     `bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh list-set . remaining_gates=""`
   - Set final phase and clear active pipeline:
     `bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . phase="done" active_pipeline="" user_directive="" pipeline_override_reason="" blocking_decisions_pending="false"`
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
- Stage provenance: {session_dir}/run-stage-provenance.md
- Session dir: {session_dir}
```

---

## Rules

1. **Decision #19 baseline**: Pre-impl stages require human gates and post-impl stages chain automatically. Ambiguity defer modes are explicit, scoped overrides for clarify-stage T3 debt only.
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
1. **Artifact gate is mandatory for stage closure**: `review-code`, `refactor`, `retro`, and `ship` are not complete unless `check-run-gate-artifacts.sh --strict` passes for that stage.
1. **Ambiguity mode precedence**: `--ambiguity-mode` flag overrides config. Config (`CWF_RUN_AMBIGUITY_MODE`) overrides built-in default (`defer-blocking`).
1. **Defer modes require persistence**: Any non-`strict` T3 carry-over must be recorded in `{session_dir}/run-ambiguity-decisions.md` and synchronized to `live.blocking_decisions_pending` via `sync-ambiguity-debt.sh`.
1. **defer-blocking merge discipline**: If unresolved blocking debt exists, ship must treat it as merge-blocking until linked issue/PR follow-up is recorded and blocking count reaches zero.
1. **Per-stage provenance is mandatory**: Every stage outcome (`Proceed`/`Revise`/`Fail`/`Skipped`/`User Stop`) must append a provenance row, including early-stop paths before halt/return.
1. **Review `Fail` is not `Revise`**: `Fail` halts automation immediately and requires explicit user direction before any downstream stage.

## References

- [agent-patterns.md](../../references/agent-patterns.md) — Shared agent orchestration patterns
- [plan-protocol.md](../../references/plan-protocol.md) — Session artifact location/protocol
