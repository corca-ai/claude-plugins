# Next Session: S3 — Build `/ship` Skill

## Completed in S2

Convention alignment on main branch:
- Env var migration: `CLAUDE_ATTENTION_*` → `CLAUDE_CORCA_ATTENTION_*` with backward-compat shim
- Description sync: marketplace.json ← plugin.json (attention-hook, smart-read)
- project-context.md: version sync, safe extraction patterns, 2 process heuristics
- Bare code fences: confirmed all already correct (plan miscount — closing fences, not violations)
- attention-hook v2.2.0 deployed, 48/48 tests passed

## Deferred from S1/S2

- prompt-logger stale lock cleanup
- gather-context scripts (g-export.sh, csv-to-toon.sh, slack-to-md.sh) shebang update

## S3 Scope (per master plan)

**Branch**: `marketplace-v3` (first v3 session)
**Task**: Build `/ship` skill — gh CLI workflow automation

### What `/ship` Does

Automate the PR-based release workflow:
1. **Issue creation**: Purpose, success criteria, scope
2. **PR creation**: Linked to issue, with lessons/CDM/review checklist
3. **Auto-merge on approval**: Monitor and merge when approved

### Implementation Details

- **Type**: Repo-level skill (`.claude/skills/ship/SKILL.md`)
- **Why repo-level**: This is project-specific workflow automation, not a general-purpose marketplace plugin
- **Dependencies**: `gh` CLI (GitHub CLI) must be authenticated

### Success Criteria

- Create issue → branch → PR → merge cycle works end-to-end
- `/ship` invocation from Claude Code session triggers the workflow
- Works with `marketplace-v3` branch workflow

## Don't Touch

- Existing plugin code on main (S1/S2 are done)
- Plugin structure migration (S14)
- `cwf` plugin scaffold (S4)

## After Completion

1. Create session dir: `prompt-logs/{YYMMDD}-{NN}-ship-skill/`
2. Write plan.md, lessons.md in that dir
3. **Write next-session.md (S4 핸드오프) in that dir**
4. Run `/retro`
5. Commit and push
6. If master-plan.md architecture decisions changed, edit master-plan.md and record in lessons.md

## Start Command

```text
@prompt-logs/260208-05-refactor-s2/next-session.md 시작합니다
```
