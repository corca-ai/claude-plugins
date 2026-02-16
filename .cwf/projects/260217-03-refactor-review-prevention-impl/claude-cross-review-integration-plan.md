# Claude Work Integration Plan (Codex Worktree)

## Scope

- Worktree: `/home/hwidong/codes/claude-plugins-wt-260217-run`
- Branch: `feat/260217-03-review-prevention-impl`
- Reviewed commit range: `439530f..a97beb9` (8 commits)
- Reviewed working-tree artifacts:
  - modified: `.cwf/cwf-state.yaml`, `.cwf/projects/260216-03-hitl-readme-restart/session-state.yaml`
  - untracked: `.cwf/projects/260217-02-refactor-review-prevention-run/*`, `.cwf/projects/260217-03-refactor-review-prevention-impl/*`

## Findings (Severity Order)

1. `Medium` `plugins/cwf/hooks/scripts/check-deletion-safety.sh`
   - Temporary stderr file fallback used predictable `/tmp/...$$.err` path when `mktemp` fails.
   - Risk: symlink/TOCTOU exposure and cross-process collision in worst-case environments.
2. `Medium` `plugins/cwf/hooks/scripts/workflow-gate.sh`
   - Stale-pipeline warning suggested `bash cwf-live-state.sh ...` (relative path).
   - Risk: operator follows warning in a different cwd and cleanup command fails.
3. `Low` `*.provenance.yaml` (7 files)
   - `hook_count` stayed at `16` while current hook inventory is `18`.
   - Impact: deterministic drift gate (`check-growth-drift.sh`) fails despite intended hook changes.
4. `Low` structural debt (deferred)
   - AWK/YAML parser duplication across hook scripts and `cwf-live-state.sh`.
   - Already tracked in next-session artifacts; not blocking this integration wave.

## Integration Decisions

- **Apply now**
  - Harden deletion-safety temp-file handling (fail closed on tmp allocation failure).
  - Fix workflow-gate stale-pipeline cleanup command to use resolved script path.
  - Sync provenance `hook_count` to `18` across all sidecars.
- **Keep as-is**
  - Core hook additions (`check-deletion-safety`, `workflow-gate`) and run/impl/review contract updates from Claude commits.
- **Defer**
  - Parser deduplication/refactor (requires larger design pass and broader regression scope).

## Execution Plan

1. Patch `check-deletion-safety.sh` temp-file handling.
2. Patch `workflow-gate.sh` stale-cleanup guidance.
3. Update `hook_count` in all `.provenance.yaml` files.
4. Validate:
   - `shellcheck -x` on touched shell scripts
   - `bash plugins/cwf/scripts/provenance-check.sh --level warn`
   - `bash plugins/cwf/scripts/check-growth-drift.sh --level warn`

## Merge Notes

- Do not include volatile live-state working changes unless explicitly requested:
  - `.cwf/cwf-state.yaml` (phase/gates runtime state)
  - `.cwf/projects/260216-03-hitl-readme-restart/session-state.yaml`
