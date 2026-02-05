# Cross-Plugin Analysis

> Date: 2025-02-05
> Plugins analyzed: 7 skills, 5 hooks (4 hook-only + 1 hybrid), 2 local skills

## Plugin Map

| Plugin | Type | Words | Key Capabilities |
|--------|------|-------|-----------------|
| clarify | skill | 541 | Iterative Q&A requirement refinement |
| deep-clarify | skill | 987 | Research-first requirement clarification (codebase + web) |
| interview | skill | 556 | Long-form conversational requirements discovery |
| gather-context | hybrid | 596 | URL → local file (Google/Slack/Notion/WebFetch) |
| web-search | hybrid | 426 | Tavily/Exa web & code search, URL extraction |
| retro | skill | 970 | Session retrospective (7-section analysis) |
| suggest-tidyings | skill | 221 | Safe code cleanup suggestions from commits |
| plan-and-lessons | hook | — | EnterPlanMode → prompt-logs directory setup |
| smart-read | hook | — | Read hook → context injection |
| prompt-logger | hook | — | Stop/SessionEnd → turn logging |
| attention-hook | hook | — | User input tracking, idle notifications, timers |
| plugin-deploy | local | ~350 | Post-modification plugin lifecycle automation |
| refactor-skill | local | ~400 | Skill review (single, scan, holistic) |

## 1. Pattern Propagation

### a. Language Adaptation

**Source**: deep-clarify, web-search, retro, plugin-deploy — all specify language matching.

**Missing in**:
- **clarify**: No language rule. Directly converses with users via AskUserQuestion. High impact.
- **suggest-tidyings**: No language rule. Produces user-facing analysis report.
- **gather-context**: No language rule. Lower impact (mostly script output) but "Supplementary Research" section is user-facing.

**Fix**: Add `**Language**: Match the user's language.` after title in each SKILL.md.

### b. Sub-agent Maturity

**Source**: deep-clarify — most mature pattern:
- Reference guides in `references/` that sub-agents read
- Parallel execution with role separation
- Structured output format from guides

**Partially adopted by**: retro (expert-lens-guide.md), suggest-tidyings (tidying-guide.md)

**Gap**: suggest-tidyings' sub-agent prompt is more ad-hoc than deep-clarify's pattern. The tidying-guide.md reference exists but the prompt structure could follow deep-clarify's template more closely.

### c. Usage Message / No-args Help

**Source**: web-search, plugin-deploy — explicit usage message when invoked with no args or "help".

**Missing in**: clarify, gather-context, suggest-tidyings, interview.

**Fix**: Each skill with subcommands or required args should define a usage block.

## 2. Boundary Issues

### a. Requirements Trio: clarify vs deep-clarify vs interview

**Conflict**: All three trigger on requirement clarification intents. A user saying "이 기능 요구사항 정리해줘" could match any of them.

| | clarify | deep-clarify | interview |
|---|---------|-------------|-----------|
| Style | Q&A, every ambiguity asked | Research first, only Tier 3 asked | Conversational, open-ended |
| Speed | Fast (direct questions) | Slow (parallel sub-agents) | Slow (multi-turn dialogue) |
| Best for | Specific vague feature | Requirement needing codebase/web context | Greenfield discovery |
| Output | Before/After comparison | Decision table with evidence | Scratchpad + Synthesis |

**Resolution**: Group in README as "pick one based on preference." User primarily uses deep-clarify. Consider absorbing interview's strengths (scratchpad, why-dig methodology) into deep-clarify.

### b. web-search extract vs gather-context WebFetch fallback

**Conflict**: Both extract URL content to markdown.
- `web-search extract <url>` → Tavily API (paid, reranking)
- `gather-context <url>` → pattern-match specific services, fallback to WebFetch

**Resolution (decided)**: Absorb web-search into gather-context. gather-context becomes the unified information acquisition layer. Major version bump. See "Decided Actions" below.

## 3. Missing Connections

### a. interview → deep-clarify handoff

**Flow**: interview produces SYNTHESIS.md → user manually invokes deep-clarify on remaining ambiguities.

**Gap**: No suggestion to continue with deep-clarify after interview.

**Fix**: Add to interview's "Closing" section: if ambiguities remain, suggest `/deep-clarify`. Gate on deep-clarify being installed.

### b. deep-clarify sub-agents ↔ web-search compatibility

**Flow**: deep-clarify's Sub-agent B does web research. web-search hook blocks WebSearch tool and redirects to `/web-search`.

**Gap**: Sub-agent may fail if hook blocks its WebSearch calls. Even if it works, misses Tavily/Exa quality.

**Fix (decided)**: After web-search is absorbed into gather-context, deep-clarify will use gather-context for research. Defensive fallback to self-contained research when gather-context is not installed.

### c. retro → installed skills awareness

**Flow**: retro Section 7 identifies skill gaps and suggests find-skills / skill-creator.

**Gap**: Doesn't check already-installed skills. User may have a skill that would have helped but wasn't used.

**Fix (decided)**: Before external search, scan installed skills (Glob `~/.claude/plugins/*/skills/*/SKILL.md`). Suggest both "could have used this session" and "try this going forward."

### d. prompt-logger → retro session matching

**Flow**: retro Step 5 guesses which session log matches by date.

**Gap**: Heuristic matching, no session ID linkage.

**Assessment**: Current approach is pragmatic. Adding session ID would couple two independent plugins. Not worth the coupling cost. Keep as-is.

## Decided Actions

From discussion with user (this session):

| Priority | Action | Effort | Affected |
|----------|--------|--------|----------|
| 1 | gather-context absorbs web-search: URL patterns (+ GitHub via gh), `--research`, `--codebase`, `--code` subcommands. Major version bump. | large | gather-context, web-search (deprecated) |
| 2 | deep-clarify uses gather-context for research + absorbs interview strengths (scratchpad, why-dig) | medium | deep-clarify |
| 3 | retro Section 3: replace "misunderstanding" lens with "waste reduction" (fewer tokens/turns for same+ quality) | small | retro |
| 4 | retro Section 7: scan installed skills, suggest usage (not just installation) | small | retro |
| 5 | Language adaptation: add to clarify, suggest-tidyings, gather-context | small | 3 plugins |
| 6 | Usage messages: add no-args help to clarify, gather-context, suggest-tidyings | small | 3 plugins |
| 7 | README: group clarify/deep-clarify/interview as "pick one" | small | README |

## Notes

- Interview was not created by the user — changes to clarify and interview are deferred
- web-search hook (WebSearch → redirect) moves to gather-context after absorption
- All cross-plugin connections must be defensive (gate on plugin existence)
- gather-context subcommand design: `--research` replaces `/web-search`, `--codebase` for code exploration, `--code` for Exa code search. URLs auto-detected by pattern (Google/Slack/Notion/GitHub/generic)
- find-skills is kept for marketplace discovery; installed skills scan is a new preceding step in retro
