# Agent-Browser Integration into CWF Sub-Agent Prompts

## Context

S14 integration test revealed WebFetch has 9% success rate on modern JS-rendered
sites. agent-browser (Vercel, headless Chromium CLI v0.9.2) was installed and
the Web Research Protocol in agent-patterns.md was updated to a two-tier fetch
strategy (WebFetch first, agent-browser fallback). This session completes the
remaining integration work.

## Goal

Ensure all CWF sub-agents that do web research can use agent-browser as a
fallback when WebFetch returns empty content from JS-rendered sites.

## Scope

- Add agent-browser to cwf:setup tool detection (SKILL.md Phase 2.1)
- Update sub-agent prompts in clarify, plan, retro, review to reference
  the Web Research Protocol (instead of inline WebFetch-only rules)
- Regression test with deming.org (JS-rendered site)

## Commit Strategy

Single commit — all changes are part of one coherent integration.

## Steps

### Step 1: Add agent-browser to cwf:setup tool detection

Edit `plugins/cwf/skills/setup/SKILL.md`:
- Phase 2.1: add `command -v agent-browser` check
- Phase 2.2: add `agent_browser` to yaml example
- Phase 2.3: add `agent_browser` to report table

### Step 2: Update sub-agent prompts

Replace inline WebFetch-only rules with reference to Web Research Protocol
in agent-patterns.md. Affected sub-agents:

| Skill | Sub-agent | Change |
|-------|-----------|--------|
| clarify | Web Researcher (B) | Replace inline rules → protocol reference |
| plan | Prior Art Researcher (A) | Replace inline rules → protocol reference |
| retro | Learning Resources (B) | Add protocol reference |
| retro | Expert α/β (Batch 2) | Add protocol reference |
| review | Expert α/β | Add protocol reference |

### Step 3: Regression test

Verify agent-browser renders deming.org where WebFetch returns empty page.

## Success Criteria

### Behavioral (BDD)

```gherkin
Given agent-browser is installed
When a sub-agent fetches deming.org (JS-rendered site)
Then readable text content is returned (not empty shell)

Given agent-browser is NOT installed
When a sub-agent does web research
Then it falls back to WebFetch with existing protocol (no regression)

Given empty WebFetch response
When agent-browser is available
Then sub-agent retries with agent-browser before skipping the URL
```

### Qualitative

- No breaking changes to existing sub-agent behavior
- Sub-agent prompts reference shared protocol instead of duplicating rules
- cwf:setup correctly detects agent-browser

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| plugins/cwf/skills/setup/SKILL.md | Edit | Add agent-browser detection |
| plugins/cwf/skills/clarify/SKILL.md | Edit | Web Researcher protocol ref |
| plugins/cwf/skills/plan/SKILL.md | Edit | Prior Art Researcher protocol ref |
| plugins/cwf/skills/retro/SKILL.md | Edit | Learning Resources + Expert protocol ref |
| plugins/cwf/skills/review/SKILL.md | Edit | Expert α/β protocol ref |

## Don't Touch

- plugins/cwf/references/agent-patterns.md (already updated in S14)
- cwf-state.yaml tools section (already has agent_browser: available from S14)
- WebFetch tool behavior
