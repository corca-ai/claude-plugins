# Run Stage Operations Details

Detailed operational reference for `cwf:run` Phase 2 execution:
- `explore-worktrees` ambiguity mode flow
- per-stage execution loop and gate handling
- review failure recovery paths
- `--from` / `--skip` stage controls

`SKILL.md` keeps the orchestration contract and invariants. Use this file for deterministic execution details.

## Contents

- [`explore-worktrees` operational flow](#explore-worktrees-operational-flow)
- [Stage Execution Loop](#stage-execution-loop)
- [Review Failure Handling](#review-failure-handling)
- [`--from` Flag](#--from-flag)
- [`--skip` Flag](#--skip-flag)

## `explore-worktrees` operational flow

When `mode=explore-worktrees` and unresolved T3 alternatives exist:

- Create a deterministic worktree workspace under session directory:

```bash
session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
wt_root="$session_dir/worktrees"
mkdir -p "$wt_root"
```

- For each alternative `{option_slug}`, create dedicated branch + worktree:

```bash
branch_name="run/t3-{decision_id}-{option_slug}"
worktree_path="$wt_root/{decision_id}-{option_slug}"
git worktree add -b "$branch_name" "$worktree_path" HEAD
```

- Run minimal downstream validation in each worktree and capture artifacts per option.
- Select baseline option and record in `run-ambiguity-decisions.md`.
- Reconcile and clean up:
  - keep baseline changes on pipeline branch
  - remove non-baseline worktrees/branches after cleanliness checks

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

## Stage Execution Loop

For each stage (respecting `--from` and `--skip`):

- Verify worktree consistency gate:

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

- Update live state (`phase`, `remaining_gates`).
- For `review-code|retro|ship`, run best-effort session-log sync:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-session-logs.sh --cwd "$PWD" --quiet || true
```

- Invoke stage skill and capture timing:

```bash
stage_started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
stage_started_epoch=$(date -u +%s)
Skill(skill="{skill-name}", args="{args if any}")
stage_finished_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
stage_finished_epoch=$(date -u +%s)
stage_duration_s=$((stage_finished_epoch - stage_started_epoch))
```

- Clarify-stage ambiguity handling:
  - resolve `session_dir`, `ambiguity_mode`, `ambiguity_file`
  - apply mode behavior (`strict`, `defer-blocking`, `defer-reversible`, `explore-worktrees`)
  - synchronize state:

```bash
bash {CWF_PLUGIN_DIR}/scripts/sync-ambiguity-debt.sh \
  --base-dir . \
  --session-dir "$session_dir"
```

- Enforce deterministic stage-artifact gate for run-closing stages:

```bash
session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "$session_dir" \
  --stage "{current stage name}" \
  --strict \
  --record-lessons
```

- Apply stage gate:
  - user gates (`auto: false`): AskUserQuestion with `Proceed|Revise|Skip next|Stop`
  - auto gates (`auto: true`):
    - review stages: `Pass/Conditional Pass -> proceed`, `Revise -> one auto-fix`, `Fail -> hard-stop`
    - non-review auto stages: proceed

- Append exactly one row to `{session_dir}/run-stage-provenance.md` for every outcome (`Proceed|Revise|Fail|Skipped|User Stop`), including early-stop paths.

Append format:

```bash
printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
  "{stage}" "{skill}" "{args}" \
  "$stage_started_at" "$stage_finished_at" "$stage_duration_s" \
  "{artifact_paths_or_dash}" "{gate_outcome}" \
  >> "{session_dir}/run-stage-provenance.md"
```

## Review Failure Handling

When review verdict is **Revise**:

- Extract concerns.
- If `review-plan` failed:
  - re-run `cwf:plan` with concerns
  - re-run `cwf:review --mode plan`
  - if still Revise: halt and ask user
- If `review-code` failed:
  - create fix plan from concerns
  - re-run `cwf:impl` with fix plan
  - re-run `cwf:review --mode code`
  - if still Revise: halt and ask user

Maximum 1 auto-fix attempt per review stage.

When review verdict is **Fail**:

- no auto-fix / no auto-retry
- halt pipeline immediately
- report fail reasons with file-level references
- ask user decision (`Revise plan/code`, `Skip downstream stages`, `Stop`)
- keep `remaining_gates` unchanged until explicit user resolution

## `--from` Flag

When `--from <stage>` is provided:

- Skip all stages before `<stage>`.
- Run deterministic precheck:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-from-prereqs.sh --from "<stage>" --base-dir .
```

- Use checker output as authority for prerequisite pass/fail.
- On checker failure, print missing checks verbatim and ask whether to proceed anyway.
- If user overrides, set `pipeline_override_reason` before continuing.

## `--skip` Flag

When `--skip <stage1>,<stage2>` is provided:

- Mark listed stages as skipped.
- Skip them at execution time.
- Report each skip:

```text
Skipping {stage} (--skip flag).
```
