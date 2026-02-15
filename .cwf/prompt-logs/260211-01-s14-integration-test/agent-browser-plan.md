# Agent-Browser Integration Plan

## Context

Web research sub-agents have a 9% success rate due to WebFetch limitations:
JS-rendered pages (45%), 403 errors (18%), redirect chains (27%). The Web
Research Protocol (S33) eliminated 404s from URL guessing but cannot fix
tool-level limitations. agent-browser (headless Chromium CLI by Vercel)
renders JS and handles redirects natively.

## Goal

Integrate agent-browser as the primary web content fetcher, with WebFetch
as lightweight fallback. Update the Web Research Protocol so all sub-agents
doing web research use agent-browser when available.

## Scope

- Install agent-browser + Chromium
- Update Web Research Protocol in agent-patterns.md
- Update cwf:setup to detect agent-browser availability
- Update sub-agent prompts in skills that do web research
- Test with the S33 Deming scenario as regression test

## Commit Strategy

Per step — each step is independently useful.

## Steps

### Step 1: Install agent-browser

```bash
npm install -g agent-browser
agent-browser install  # Download Chromium
```

Verify: `agent-browser open https://deming.org && agent-browser snapshot -c`

### Step 2: Add agent-browser to cwf:setup tool detection

Edit `plugins/cwf/skills/setup/SKILL.md` and `cwf-state.yaml` tools section:

```yaml
tools:
  codex: available
  gemini: available
  agent_browser: available  # NEW
```

Detection: `command -v agent-browser && echo AGENT_BROWSER_FOUND`

### Step 3: Update Web Research Protocol in agent-patterns.md

Replace the current "Web Research Protocol" section with a two-tier
fetch strategy:

```markdown
## Web Research Protocol

### Tier 1: Discover URLs
Use WebSearch to find valid URLs. NEVER construct URLs from memory.

### Tier 2: Fetch Content
Two-tier fetch strategy based on tool availability:

**If agent-browser is available** (check: `command -v agent-browser`):
1. `agent-browser open <url>` — navigate to page
2. `agent-browser snapshot -c` — get compact accessibility tree (best for
   structured content extraction)
3. `agent-browser close` — clean up session
- Handles: JS rendering, redirects, SPAs
- Use for: documentation sites, knowledge bases, any URL where WebFetch
  returned empty/partial content

**Fallback to WebFetch** (always available):
- Use for: static HTML pages, APIs returning JSON/text, raw markdown
- Use when: agent-browser is not installed or page is known to be static
- WebFetch is faster and lighter — prefer it for simple pages

### Fetch Decision Heuristic
1. First attempt: WebFetch (fast, low overhead)
2. If WebFetch returns empty/minimal content (<50 chars of body text):
   try agent-browser if available
3. If both fail: skip this URL and move to next source

### Common Rules (unchanged)
- Skip failed domains (404, 429, 403) entirely
- Stop at 3-5 sources
- Budget turns: reserve 2-3 turns for writing output
```

### Step 4: Update sub-agent prompt templates

Skills that spawn web research sub-agents need the updated protocol.
Each already references agent-patterns.md "Web Research Protocol" —
verify these references are in place:

| Skill | Sub-agent | Reference check |
|-------|-----------|-----------------|
| clarify | Web Researcher (Phase 2 Sub-agent B) | SKILL.md line ~118 |
| plan | Prior Art Researcher (Phase 2.2 Sub-agent A) | SKILL.md line ~88 |
| retro | Expert sub-agents (Batch 2) | SKILL.md |
| review | Expert α/β sub-agents | SKILL.md |

For each, ensure the sub-agent prompt includes:
1. The Bash tool in allowed tools (needed for `agent-browser` CLI)
2. An instruction to check `agent-browser` availability before using it
3. Reference to Web Research Protocol in agent-patterns.md

### Step 5: Regression test with S33 Deming scenario

Re-run the exact scenario that failed:
- Expert sub-agent verifying Deming identity
- Target URLs: deming.org, Amazon, WorldCat, Google Books, ASQ.org
- Success criteria: >50% URL success rate (up from 9%)

## Success Criteria

### Behavioral (BDD)

```gherkin
Given agent-browser is installed
When a sub-agent fetches deming.org (JS-rendered site)
Then readable text content is returned (not empty shell)

Given agent-browser is NOT installed
When a sub-agent does web research
Then it falls back to WebFetch with existing protocol (no regression)

Given the Web Research Protocol in agent-patterns.md
When a sub-agent encounters empty WebFetch response
Then it retries with agent-browser before skipping the URL
```

### Qualitative

- The two-tier fetch strategy is simple enough for sub-agents to follow
  without complex decision trees
- No breaking changes to existing sub-agent behavior when agent-browser
  is not installed
- cwf:setup correctly detects and records agent-browser availability

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| plugins/cwf/references/agent-patterns.md | Edit | Update Web Research Protocol |
| plugins/cwf/skills/setup/SKILL.md | Edit | Add agent-browser detection |
| cwf-state.yaml | Edit | Add agent_browser to tools |
| plugins/cwf/skills/clarify/SKILL.md | Verify | Sub-agent prompt includes Bash |
| plugins/cwf/skills/plan/SKILL.md | Verify | Sub-agent prompt includes Bash |
| plugins/cwf/skills/retro/SKILL.md | Verify | Sub-agent prompt reference |
| plugins/cwf/skills/review/SKILL.md | Verify | Expert sub-agent prompt reference |

## Don't Touch

- WebFetch tool behavior (platform-level, not ours to modify)
- Existing Web Research Protocol rules that work (discover-first, skip
  domains, budget turns)
- agent-browser source code

## Deferred Actions

- [ ] Explore agent-browser `--session` for persistent browser contexts
      across multiple fetches (could reduce overhead)
- [ ] Consider adding agent-browser to cwf:gather URL routing (currently
      gather uses WebFetch directly)
- [ ] Measure token cost difference: agent-browser snapshot vs WebFetch
      markdown output
