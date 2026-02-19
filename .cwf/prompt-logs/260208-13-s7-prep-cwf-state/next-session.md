# S7 Handoff: gather-context → cwf:gather Migration

## Previous Session (S7-prep)

Populated `cwf-state.yaml` as machine-readable SSOT for CWF v3 project state. Updated master-plan.md handoff template and CLAUDE.md to enforce its maintenance.

## What S7 Should Do

### Goal
Migrate the `gather-context` plugin's core functionality into `plugins/cwf/` as the `cwf:gather` skill.

### Context
- `gather-context` is currently the most complex plugin (hybrid: hooks + skills)
- It handles URL auto-detect, web search (Tavily/Exa), and local codebase exploration
- The PreToolUse hook blocks WebSearch and redirects to `/gather-context --search`
- Migration should preserve all functionality while consolidating into CWF

### Key Files to Read First
- `cwf-state.yaml` — current project state (12 sessions completed, `build` stage)
- `plugins/gather-context/` — source plugin to migrate
- `plugins/cwf/` — target CWF plugin structure
- `prompt-logs/260208-12-s6b-cwf-migration/lessons.md` — migration patterns from S6b

### Risks
- gather-context has the most complex hook (PreToolUse WebSearch redirect)
- Multiple external API integrations (Tavily, Exa, Slack, Notion, GitHub)
- High usage frequency — any regression will be immediately noticeable

### Branch
Continue on `marketplace-v3` branch.

## Start Command

```text
@prompt-logs/260208-13-s7-prep-cwf-state/next-session.md 시작합니다
```
