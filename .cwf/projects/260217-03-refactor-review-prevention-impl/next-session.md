# Next Session — Post Prevention Proposals

## Carry-Forward Items

### Code Review Concern: AWK Parser Duplication (P1)
- 4/6 reviewers flagged ~90 lines of AWK list/scalar extraction logic duplicated across `workflow-gate.sh`, `check-deletion-safety.sh`, and `cwf-live-state.sh`
- Recommendation: Source shared functions from `cwf-live-state.sh` instead of inlining
- Reference: `review-synthesis-code.md` Concern #2
- Expert Beta (Perrow): "common-mode failure waiting to happen"

### Deferred Prevention Proposals (P2)
From `.cwf/projects/260217-01-refactor-review/review-and-prevention.md`:
- **D**: Script dependency graph automation
- **F**: Session log → review pipeline
- **H**: README structure sync hook
- **I**: Shared reference extraction for cross-cutting patterns

### Retro Persist Proposals
- `project-context.md`: Add hook exit code rule documentation
- `decision_journal` schema: Consider auto-recording user decision points for compaction immunity
- Hook matcher: Investigate path-based filtering to avoid /tmp file false triggers

## Context for Next Agent
- Branch: `feat/260217-03-review-prevention-impl` (8 commits, not yet merged to marketplace-v3)
- Ship was deferred — PR creation pending
- Worktree: `/home/hwidong/codes/claude-plugins-wt-260217-run`
- Code review verdict: Conditional Pass (4/5 concerns addressed in post-review commits)
