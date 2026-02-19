# Next Session — Execute Minimal Smoke Tests

## Context Files to Read

1. `AGENTS.md` — cross-runtime invariants and navigation map
2. `.cwf/cwf-state.yaml` — live workflow state and session history (SSOT)
3. `.cwf/projects/260219-03-minimal-smoke-plan/plan.md` — smoke test plan with case definitions, tier classification, and execution steps
4. `.cwf/projects/260219-03-minimal-smoke-plan/lessons.md` — timeout patterns and tier classification learnings
5. `.cwf/projects/260219-01-pre-release-audit-pass2/retro.md` — parent session retro with waste analysis and expert lens
6. `scripts/noninteractive-skill-smoke.sh` — smoke test harness
7. `scripts/tests/noninteractive-skill-smoke-fixtures.sh` — test fixtures for the harness

## Task Scope

Execute the minimal smoke test plan created in session S260219-03:

1. **Create `minimal-smoke-cases.txt`** in the repo-smoke sandbox with 6 cases (3 Tier 1 core + 3 Tier 2 extended) in `id|prompt` format.
2. **Run the smoke harness** with `--timeout 45 --max-failures 0 --max-timeouts 3` against the case file.
3. **Evaluate results**: Tier 1 must all PASS; Tier 2 may TIMEOUT.
4. **Fix and re-run** if any Tier 1 case fails — investigate logs, fix the skill, re-run.
5. **Persist results** in `iter2/artifacts/skill-smoke-minimal/`.

The case set is defined in the plan's "Minimal Smoke Case Set" section.

## Don't Touch

- `plugins/cwf/skills/*/SKILL.md` — skill definitions are not in scope for modification unless a smoke failure reveals a loading bug
- `scripts/noninteractive-skill-smoke.sh` — the harness itself should not be modified; only the case file and sandbox are in scope
- `.cwf/cwf-state.yaml` session entries for sessions other than the current one
- Parent session artifacts in `.cwf/projects/260219-01-pre-release-audit-pass2/` (read-only reference)

## Lessons from Prior Sessions

- **Timeout pattern** (S260219-03): Sub-agent-spawning skills (plan, review, impl) inherently exceed 60s. Smoke tests should validate "skill loads and runs without crash," not full workflow completion.
- **Tier classification** (S260219-03): 2-tier system (core must-pass + extended informational) improves signal-to-noise. Separate `max-failures` and `max-timeouts` to distinguish core failures from extended timeouts.
- **Orchestration slot limits** (S260219-01 retro): Parallel sub-agent spawns can exceed runtime thread cap. Not directly relevant to smoke execution, but relevant if debugging timeout causes.

## Unresolved Items from S260219-03

### From Deferred Actions

- [ ] If Tier 2 cases consistently pass, promote them to Tier 1 in a future iteration
- [ ] [carry-forward] Consider adding `--parallel` support to the smoke harness for faster execution

## Success Criteria

```gherkin
Given minimal-smoke-cases.txt exists with 6 cases (3 core, 3 extended)
When noninteractive-skill-smoke.sh runs with --timeout 45 --max-failures 0 --max-timeouts 3
Then the gate exits 0 (PASS)

Given the 3 Tier 1 cases (gather, ship-help, retro-light)
When each completes within the 45s timeout
Then each reports result=PASS reason=OK in summary.tsv

Given the 3 Tier 2 cases (setup-env, clarify-light, refactor-quick)
When any times out
Then the overall gate still passes (timeout count <= 3)
```

## Dependencies

- `noninteractive-skill-smoke.sh` must support `--cases-file` flag (verify before execution)
- The `iter2/sandbox/repo-smoke` directory must exist and be a valid git repo (already confirmed in S260219-03)
- CWF plugin must be accessible at `plugins/cwf` from the repo root

## Dogfooding

Discover available CWF skills via `plugins/cwf/skills/` directory listing and the trigger list in `plugins/cwf/settings.json`. Use `cwf:gather` for any file reading, `cwf:retro --light` at session end.

## Execution Contract (Mention-Only Safe)

1. **Mention-only execution**: If the user input only mentions `next-session.md` (with or without "start"), treat it as "execute this handoff" — not a request to summarize the file.
2. **Branch gate before implementation edits**: Before creating/modifying the case file, detect current branch. If on a base branch (`main`, `master`, or repo primary branch), create/switch to a feature branch and continue execution.
3. **Commit gate during execution**: Commit in meaningful units:
   - Commit 1: case file creation (`minimal-smoke-cases.txt`)
   - Commit 2: smoke results and any skill fixes (if needed)
   - After the first commit, run `git status --short`, decide next commit boundary, and commit before continuing.
4. **Selective staging**: Stage only intended files for the current unit. Do not use broad staging (`git add -A` or `git add .`).

## Start Command

Read `plan.md` from session S260219-03, create `minimal-smoke-cases.txt` per Step 1, then execute the smoke harness per Step 2. Evaluate results per Step 3 and persist artifacts.
