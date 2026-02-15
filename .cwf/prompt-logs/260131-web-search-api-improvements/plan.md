# Plan: Web Search Skill API Improvements

## Context

The web-search skill currently uses minimal parameters for both Tavily and Exa APIs. Official docs reveal many unused features that can significantly improve search quality without adding user-facing complexity.

**Design constraint**: This is an instruction-based skill (no scripts). All changes are to SKILL.md and api-reference.md — Claude reads these docs and dynamically constructs curl commands.

## Success Criteria

```gherkin
Given a query like "latest React 19 features"
When the user runs /web-search latest React 19 features
Then Tavily is called with time_range parameter for recency

Given a query like "Tesla stock price today"
When the user runs /web-search Tesla stock price today
Then Tavily is called with topic: "finance"

Given a news query
When the user runs /web-search --news Ukraine conflict
Then Tavily is called with topic: "news"

Given a code search
When the user runs /web-search code React useOptimistic hook
Then Exa /context is called with tokensNum dynamically set based on query complexity

Given a URL extraction with a question
When the user runs /web-search extract https://example.com "what is their pricing?"
Then Tavily extract is called with query parameter for relevance reranking
```

## Changes

### 1. SKILL.md — Add Query Intelligence + Optional Modifiers ✅

**Add to Commands section**: Optional modifiers for explicit control
```
/web-search --news <query>       → News search (Tavily topic: news)
/web-search --deep <query>       → Advanced search depth (Tavily search_depth: advanced)
/web-search extract <url> [query] → Extract with relevance reranking
```

**Add to Execution Flow**: Query analysis step (between steps 1-2)
- Detect temporal intent → set `time_range` (keywords: latest, recent, today, this week, 2025, 2026)
- Detect topic → set `topic` (news keywords → "news", finance keywords → "finance")
- Detect modifier flags (--news, --deep) → override defaults
- For extract: check for optional query after URL → set `query` parameter

### 2. api-reference.md — Expand API Parameters ✅

**Tavily Search**: Add conditional parameters
- `topic`: "general" (default) | "news" | "finance" — based on query analysis
- `time_range`: "day" | "week" | "month" | "year" — based on temporal intent
- `search_depth`: "basic" (default) | "advanced" (when --deep flag or complex query)
- `include_raw_content`: "markdown" — when search_depth is "advanced"

**Tavily Extract**: Add query parameter
- `query`: optional string — reranks extracted chunks by relevance

**Exa Code Context**: Dynamic token allocation
- `tokensNum`: "dynamic" instead of hardcoded 5000

### 3. Version Bump ✅

**plugin.json**: 1.0.0 → 1.1.0

### 4. README.md + README.ko.md Update ✅

Update web-search section with new modifiers (both languages).

## Files Modified

1. `plugins/web-search/skills/web-search/SKILL.md` ✅
2. `plugins/web-search/skills/web-search/references/api-reference.md` ✅
3. `plugins/web-search/.claude-plugin/plugin.json` ✅
4. `README.md` ✅
5. `README.ko.md` ✅

## Verification

1. `/web-search latest Claude Code features` → verify time_range is set
2. `/web-search --news AI regulation` → verify topic: "news"
3. `/web-search code React server components` → verify tokensNum is dynamic
4. `/web-search extract https://docs.tavily.com "pricing"` → verify query param sent
5. `/web-search normal query` → verify defaults unchanged (no regression)

## Deferred Actions

- [ ] None
