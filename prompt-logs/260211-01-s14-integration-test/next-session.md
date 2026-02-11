# Next Session: Agent-Browser Integration

## Context

- Read: `prompt-logs/260211-01-s14-integration-test/agent-browser-plan.md` (full plan)
- Read: `prompt-logs/260211-01-s14-integration-test/lessons.md` (web research findings)
- Read: `plugins/cwf/references/agent-patterns.md` (current Web Research Protocol, line 159)
- Read: `cwf-state.yaml` (live state)
- Branch: `marketplace-v3`

## Background

S14 integration test revealed WebFetch has 9% success rate on modern sites:
- JS-rendered pages return empty content (deming.org, Amazon, WorldCat)
- 403 Forbidden (ASQ.org)
- Redirect chains (Google Books)

The S33 Web Research Protocol fixed 404s (URL guessing) but cannot fix
WebFetch's inability to render JavaScript. agent-browser (Vercel, headless
Chromium CLI) solves this.

## What Was Already Done in S14

1. agent-browser installed + Chromium downloaded (v0.9.2, `/usr/local/bin/agent-browser`)
2. deming.org 렌더링 검증 완료 — WebFetch 빈 페이지 → agent-browser 전체 콘텐츠 성공
3. agent-patterns.md Web Research Protocol 2-tier 업데이트 완료
4. cwf-state.yaml tools에 `agent_browser: available` 등록
5. Plan written at `prompt-logs/260211-01-s14-integration-test/agent-browser-plan.md`
6. Lessons documented at `prompt-logs/260211-01-s14-integration-test/lessons.md`
7. compact-context.sh: 2 bugs fixed (decisions field leak + quote stripping)
8. docs/v3-migration-decisions.md written
6. Integration test completed (all CDM items verified, cross-refs clean)

## Remaining Steps (from agent-browser-plan.md)

### Step 1: Chromium Install (if not done)

```bash
agent-browser install  # Download Chromium
agent-browser open https://deming.org && agent-browser snapshot -c && agent-browser close
```

### Step 2: cwf:setup tool detection

Edit `plugins/cwf/skills/setup/SKILL.md`: add agent-browser to tool
detection alongside codex/gemini.

Edit `cwf-state.yaml` tools section:
```yaml
tools:
  agent_browser: available  # or unavailable
```

### Step 3: Update Web Research Protocol

Edit `plugins/cwf/references/agent-patterns.md` line 159+.
Replace current protocol with two-tier fetch strategy:

1. **WebFetch first** (fast, lightweight)
2. **If empty/minimal content (<50 chars)** → retry with agent-browser:
   ```bash
   agent-browser open <url>
   agent-browser snapshot -c
   agent-browser close
   ```
3. Keep existing rules: discover-first, skip 404 domains, budget turns

### Step 4: Verify sub-agent prompts

Check these skills have Bash in allowed-tools for their research sub-agents:
- clarify/SKILL.md (Web Researcher, Phase 2 Sub-agent B)
- plan/SKILL.md (Prior Art Researcher, Phase 2.2 Sub-agent A)
- retro/SKILL.md (Expert sub-agents, Batch 2)
- review/SKILL.md (Expert α/β)

Each sub-agent prompt should reference agent-patterns.md Web Research Protocol.

### Step 5: Regression test

Re-run S33 Deming scenario. Target: >50% URL success rate (was 9%).

## Success Criteria (BDD)

```gherkin
Given agent-browser is installed
When a sub-agent fetches deming.org (JS-rendered)
Then readable text content is returned

Given agent-browser is NOT installed
When a sub-agent does web research
Then it falls back to WebFetch (no regression)

Given empty WebFetch response
When agent-browser is available
Then sub-agent retries with agent-browser before skipping
```

## Don't Touch

- WebFetch tool behavior
- Existing protocol rules that work (discover-first, skip domains, budget turns)
- S14 session artifacts (already complete)

## After Completion

1. Write plan.md, lessons.md, retro.md in session dir
2. Update cwf-state.yaml: add session entry
3. Commit agent-browser integration changes
4. Consider: merge to main if user's other pre-merge work is complete

## Start Command

```text
@prompt-logs/260211-01-s14-integration-test/next-session.md 시작합니다
```
