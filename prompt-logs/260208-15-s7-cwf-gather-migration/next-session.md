# Handoff: Next Session (S8 — Migrate clarify → cwf:clarify)

## Project Status

SSOT: `cwf-state.yaml`

| Session | Status | Summary |
|---------|--------|---------|
| S0–S6b | done | Clarify, refactor, scaffold, review, hooks migration |
| S7 | done | Migrate gather-context → `cwf:gather` (8 scripts, 6 refs, WebSearch redirect hook activated) |
| S8 | **not started** | Migrate clarify → `cwf:clarify` + `cwf:review --mode clarify` integration |
| S9–S14 | not started | Remaining build/harden/launch sessions |

Current branch: `marketplace-v3`

## Context

- Read: `cwf-state.yaml` (project state SSOT)
- Read: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` (architecture, agent team strategy)
- Read: `prompt-logs/260208-15-s7-cwf-gather-migration/lessons.md` (S7 migration learnings)

## Task

Migrate the `clarify` plugin into CWF as `cwf:clarify`. Integrate with existing `cwf:review --mode clarify`.

## Scope

1. **Copy skill files** from `plugins/clarify/skills/clarify/` into `plugins/cwf/skills/clarify/`
   - SKILL.md (adapt frontmatter `name: clarify` → produces `cwf:clarify` trigger, update all `/clarify` → `cwf:clarify`)
   - `references/` (4 files: advisory-guide.md, aggregation-guide.md, questioning-guide.md, research-guide.md — verbatim copy)

2. **Review integration** — master plan says `cwf:clarify` output feeds into `cwf:review --mode clarify`
   - Check if `cwf:review` SKILL.md already supports `--mode clarify` (built in S5a/S5b)
   - If so, update `cwf:clarify` SKILL.md to reference `cwf:review --mode clarify` as a follow-up step
   - If not, add the mode to `cwf:review`

3. **Version bump** — `plugin.json` 0.3.0 → 0.4.0

4. **Documentation updates**
   - CLAUDE.md: check for `/clarify` references → update to `cwf:clarify`
   - `plugins/cwf/references/plan-protocol.md`: check for `/clarify` references
   - Any other docs referencing `/clarify`

5. **Agent team strategy** — master plan specifies "4 sub-agents: 2 research + 2 advisory"
   - Evaluate: does current clarify SKILL.md already use sub-agents?
   - If not, this may be a future enhancement (deferred to avoid scope creep)
   - Decision: migrate first (copy + adapt), enhance agent strategy later if needed

## Don't Touch

- `plugins/clarify/` source — keep intact until S14 deprecation
- Agent team enhancements beyond what current clarify already does
- `marketplace.json` updates (S14)

## Lessons from S7

- `cp *` fails on `__pycache__` directories — use explicit file list or ignore exit code
- After copy, explicitly verify `chmod +x` on all scripts (clarify has no scripts, but check anyway)
- Stub → real transition pattern is clean — CWF's gate mechanism works well
- `update-all.sh` is skipped on feature branches (only needed on main after merge)

## Success Criteria

```gherkin
Given the CWF plugin is loaded
When the user invokes cwf:clarify
Then the clarify skill executes with the same behavior as /clarify

Given cwf:clarify produces clarification output
When the user wants review
Then cwf:review --mode clarify can process the output
```

## After Completion

1. Create session dir: `prompt-logs/{YYMMDD}-{NN}-s8-cwf-clarify/`
2. Write plan.md, lessons.md, next-session.md (S9 handoff)
3. Run `/retro`
4. Update `cwf-state.yaml` with S8 entry
5. Commit and push

## Start Command

```text
@prompt-logs/260208-15-s7-cwf-gather-migration/next-session.md 시작합니다
```
