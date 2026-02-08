# Handoff: Next Session (S7-prep — cwf-state.yaml + Handoff Template)

## Project Status

All sessions from the CWF v3 master plan (`prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`):

| Session | Status | Summary |
|---------|--------|---------|
| S0 | done | Clarify + master plan |
| S1 | done | Refactor: critical fixes + set -euo pipefail + shebang |
| S2 | done | Refactor: bare code fences + env var migration + description sync |
| S3 | done | Build `/ship` skill |
| S4 | done | Scaffold `plugins/cwf/`, plugin.json, hooks.json, cwf-hook-gate.sh |
| S4.5 | done | Improve `/ship` skill — Korean templates, autonomous merge |
| S4.6 | done | SW Factory analysis — scenario-driven verification, narrative verdicts |
| S5a | done | `cwf:review` — internal reviewers (security + ux via Task) |
| S5b | done | `cwf:review` — external CLI integration (codex + gemini) + fallback |
| S6a | done | Migrate simple infra hooks (read, log, lint-markdown) into cwf |
| S6b | done | Migrate attention-hook + enter-plan-mode + check-shell into cwf |
| S7 | **not started** | Migrate gather-context → `cwf:gather` with adaptive team |
| S8 | not started | Migrate clarify → `cwf:clarify` + review integration |
| S9 | not started | Migrate plan-and-lessons hook + new plan skill |
| S10 | not started | Build `cwf:impl` |
| S11a | not started | Migrate retro with parallel sub-agent enhancement |
| S11b | not started | Migrate refactor with parallel sub-agent enhancement |
| S12 | not started | Build `cwf:setup` + `cwf:update` + `cwf:handoff` |
| S13 | not started | Holistic refactor review on entire cwf plugin |
| S14 | not started | Integration test, deprecate old plugins, merge to main |

Current branch: `marketplace-v3` (S6b merged)

## Context

- Read: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` (architecture decisions, roadmap)
- Read: `prompt-logs/260208-12-s6b-cwf-migration/lessons.md` (handoff gap finding)
- Problem discovered: session completion status was only tracked in markdown roadmap, which agents couldn't reliably parse. S5a/S5b were done but roadmap wasn't updated, causing the S6b agent to misjudge project state.

## Task

Implement `cwf-state.yaml` as machine-readable single source of truth for project state, and update the handoff workflow to reference it.

## Scope

1. **Create `cwf-state.yaml`** in project root (or `~/.claude/` — decide based on master-plan Decision #12)
   - Populate with current session history (all S0–S6b as completed)
   - Include `workflow.current_stage`, `sessions[]`, `tools`, `hooks` sections per master-plan spec
   - Schema should match the example in master-plan.md § "Persistent Workflow State"

2. **Update master-plan.md handoff template** (§ "Handoff Template")
   - Add step: "Update cwf-state.yaml session entry" to the "After Completion" checklist
   - Add `cwf-state.yaml` to the Context section

3. **Update CLAUDE.md** (if needed)
   - Add reminder to update `cwf-state.yaml` after session completion
   - Reference it as SSOT for project state

4. **Update next-session.md template convention**
   - Include Project Status section sourced from `cwf-state.yaml`

## Don't Touch

- `plugins/cwf/` skill/hook implementations (S7+ work)
- Existing hook scripts

## Success Criteria

```gherkin
Given cwf-state.yaml exists with session history
When a new session agent reads the file
Then it can programmatically determine which sessions are done/pending

Given the handoff template includes cwf-state.yaml update step
When a session completes and follows the template
Then cwf-state.yaml is always kept in sync with actual progress
```

## Dependencies

- Requires: S6b completed (done)
- Blocks: Nothing directly — this is a process improvement that benefits all future sessions

## After Completion

1. Create next session dir: `prompt-logs/{YYMMDD}-{NN}-{title}/`
2. Write plan.md, lessons.md in that dir
3. Write next-session.md (S7 handoff) in that dir
4. Mark this session as done in master-plan.md roadmap AND cwf-state.yaml
5. If architecture decisions changed, edit master-plan.md and record in lessons.md

## Start Command

```text
@prompt-logs/260208-12-s6b-cwf-migration/next-session.md 시작합니다
```
