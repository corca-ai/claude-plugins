# Next Session Handoff — Full Skill Portability Refactor

## 1. Context Files to Read

1. `AGENTS.md` — repository-wide operating invariants and documentation map.
2. `docs/plugin-dev-cheatsheet.md` — plugin lifecycle and validation workflow.
3. `.cwf/cwf-state.yaml` — current tracked session state and artifact history.
4. `.cwf/projects/260217-10-refactor-portability-default/plan.md` — approved scope and deferred action.
5. `.cwf/projects/260217-10-refactor-portability-default/review-synthesis-impl.md` — resolved impl review findings and residual risk.
6. `plugins/cwf/skills/refactor/SKILL.md` and `plugins/cwf/skills/refactor/references/docs-review-flow.md` — updated portability-default contract behavior.

## 2. Task Scope

Execute the deferred second phase: apply portability-default refactor to all remaining CWF skills, using the updated `refactor` capability as the auditing baseline.

Target outcomes:
- Per-skill portability findings and remediations are captured as artifacts.
- Repository-coupled assumptions are moved to contract/context-detection patterns where appropriate.
- Deterministic gates remain green after each meaningful batch of fixes.

## 3. Don't Touch

- Do not modify unrelated non-CWF plugins unless a deterministic gate proves a hard dependency.
- Do not weaken deterministic gates to force green outcomes.
- Do not use destructive git operations (`reset --hard`, blanket checkout) on a dirty tree.

## 4. Lessons from Prior Sessions

- Portability should be baseline behavior, not optional mode-specific guidance.
- Contract fields must have executable semantics in procedures (not documentation-only fields).
- For plugin docs under `plugins/cwf`, path-format lint rules can conflict; resolve both `CORCA001` and `CORCA004` constraints together.
- Plugin lifecycle validation (`check-consistency` + Codex sync + final gates) prevents stale skill-link states.

## Unresolved Items from S260217-10

### From Deferred Actions

- [ ] Apply the updated portability-default `refactor` workflow across all CWF skills after re-entry/reload validation.

### From Lessons

- [ ] Add an executable end-to-end check for docs-contract parsing/runtime behavior under `cwf:refactor --docs`.

## 5. Success Criteria

```gherkin
Given all CWF skills are in scope for refactor review
When portability-default criteria are applied skill-by-skill
Then each skill has either a portability pass result or a concrete remediation commit with file evidence.
```

```gherkin
Given repository-specific behavior is needed in any skill
When the behavior is evaluated for portability risk
Then it is guarded by contract/context detection rather than unconditional host-repo assumptions.
```

```gherkin
Given implementation and review changes are complete
When deterministic gates and plugin lifecycle checks are re-run
Then markdown/link/graph/provenance and plugin consistency checks all pass.
```

## 6. Dependencies

- `npx` / `markdownlint-cli2`
- `lychee` (required by `plugins/cwf/skills/refactor/scripts/check-links.sh`)
- `node` for `doc-graph.mjs`
- `bash` scripts under `plugins/cwf/scripts/` and `.claude/skills/plugin-deploy/scripts/`

## 7. Dogfooding

- Discover available skills directly from `plugins/cwf/skills/*/SKILL.md` and declared triggers.
- Use `cwf:run` orchestration where it improves continuity, but keep stage artifacts explicit for auditability.
- Reuse `refactor` references/scripts instead of re-describing checks in prose.

## 8. Execution Contract (Mention-Only Safe)

1. Mention-only execution:
- If the user references this handoff file (with or without "start"), treat it as execution authorization for this handoff scope.
2. Branch gate before implementation edits:
- Before edits, check current branch.
- If on a base branch (`main`, `master`, or detected primary), create/switch to a feature branch before proceeding.
3. Commit gate during execution:
- Commit by meaningful unit (per skill batch or remediation cluster), not one final monolithic commit.
- After the first completed unit, run `git status --short`, confirm next boundary, and commit before continuing.
4. Selective staging:
- Stage only intended files for the active unit; never broad-stage unrelated worktree changes.

## 9. Start Command

Run `cwf:run` for the deferred portability-wide refactor session, anchored to this handoff and the updated `refactor` contract behavior.
