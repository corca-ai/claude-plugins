# Next Session: S4 — Scaffold `plugins/cwf/`

## Completed in S3

Built `/ship` skill as repo-level skill (`.claude/skills/ship/`):

- `SKILL.md`: 4 subcommands (`issue`, `pr`, `merge`, `status`) — 258 lines
- `references/issue-template.md`: issue body with session context variables
- `references/pr-template.md`: PR body with lessons, CDM, review checklist
- `marketplace-v3` branch created from main
- gh CLI integration verified

## Deferred from S1/S2

- prompt-logger stale lock cleanup
- gather-context scripts (g-export.sh, csv-to-toon.sh, slack-to-md.sh) shebang update

## S4 Scope (per master plan)

**Branch**: `marketplace-v3` (feature branch: `feat/cwf-scaffold`)
**Task**: Scaffold `plugins/cwf/` — plugin.json, hooks.json, `cwf-hook-gate.sh`, `cwf-state.yaml`

### What to Build

1. **`plugins/cwf/.claude-plugin/plugin.json`** — single plugin metadata
2. **`plugins/cwf/hooks/hooks.json`** — unified hook definitions (empty matchers, wiring only)
3. **`plugins/cwf/hooks/scripts/cwf-hook-gate.sh`** — shared gate script that sources `cwf-hooks-enabled.sh` and exits if a hook is disabled
4. **`cwf-state.yaml`** — initial persistent workflow state file (location TBD: project root or `~/.claude/`)
5. **`plugins/cwf/references/agent-patterns.md`** — shared agent team patterns reference

### Key Decisions to Confirm

- `cwf-state.yaml` location: project root vs `~/.claude/`
- Hook definitions: stub all 7 hook groups or start with a subset?
- Whether to include a minimal `README.md` in `plugins/cwf/`

### Success Criteria

- Plugin loads in clean session: `claude --plugin-dir ./plugins/cwf --dangerously-skip-permissions`
- `cwf-hook-gate.sh` correctly gates on enabled/disabled hooks
- `cwf-state.yaml` schema is valid and readable by skills

### Don't Touch

- Existing plugins on main (S1/S2 work is done)
- `/ship` skill (S3 — just completed)
- Individual skill migrations (S5+)

### Dependencies

- Requires: S3 completed (branch exists, `/ship` available)
- Blocks: S5a (cwf:review needs plugin structure)

### After Completion

1. Use `/ship issue` to create S4 issue
2. Use `/ship pr` to create PR
3. Write `prompt-logs/{YYMMDD}-{NN}-cwf-scaffold/plan.md`, `lessons.md`, `next-session.md`
4. Run `/retro`
5. Commit and push

### Start Command

```text
@prompt-logs/260208-06-ship-skill/next-session.md 시작합니다
```
