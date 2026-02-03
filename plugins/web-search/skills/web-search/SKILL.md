---
name: web-search
description: |
  Web search, code search, and URL content extraction skill.
  Calls Tavily and Exa APIs directly via curl.
  Triggers: "/web-search", or when user requests web search.
allowed-tools:
  - Bash
---

# Web Search (/web-search)

Call Tavily/Exa REST APIs via wrapper scripts for web search, code search, and URL content extraction.

**Language**: Adapt all outputs to match the user's prompt language.

## Commands

```
/web-search                         → Usage guide
/web-search help                    → Usage guide
/web-search <query>                 → General web search (Tavily)
/web-search --news <query>          → News search (Tavily, topic: news)
/web-search --deep <query>          → Advanced depth search (Tavily)
/web-search code <query>            → Code/technical search (Exa)
/web-search extract <url> [query]   → Extract URL content, optionally reranked by query (Tavily)
```

**Modifiers** (`--news`, `--deep`) can appear anywhere before the query. They are optional — query intelligence auto-detects topic and depth when possible.

## Execution Flow

1. Parse args → subcommand (search | code | extract), query/url, modifiers (--news, --deep)
2. No args or "help" → print usage and stop
3. **Query intelligence** (search subcommand only — analyze before calling script):
   a. Detect modifier flags:
      `--news` → `--topic news`
      `--deep` → `--deep`
   b. Detect temporal intent in query → `--time-range`:
      "today", "latest today" → `day`
      "this week", "latest", "recent" → `week`
      "this month" → `month`
      "this year", "2025", "2026" → `year`
   c. Detect topic from query (if not set by flag):
      news keywords (breaking, headline, announced, report) → `--topic news`
      finance keywords (stock, price, market, earnings, revenue) → `--topic finance`
   d. If no signals detected → no extra flags
4. **Call the appropriate script**:

### search (default)

```bash
{SKILL_DIR}/scripts/search.sh [--topic news|finance] [--time-range day|week|month|year] [--deep] "<query>"
```

### code

Assess query complexity → set tokensNum:
- Simple lookup (e.g., "golang sort slice") → 3000
- Standard query (e.g., "React useEffect cleanup") → 5000
- Complex/architectural → 10000
- Deep research → 15000

```bash
{SKILL_DIR}/scripts/code-search.sh [--tokens NUM] "<query>"
```

### extract

```bash
{SKILL_DIR}/scripts/extract.sh "<url>" [--query "<relevance_query>"]
```

## Usage Message (no args or "help")

```
Web Search Skill

Usage:
  /web-search <query>                General web search (Tavily)
  /web-search --news <query>         News search (Tavily, topic: news)
  /web-search --deep <query>         Advanced depth search (Tavily)
  /web-search code <query>           Code/technical search (Exa)
  /web-search extract <url> [query]  Extract URL content, optionally reranked by query (Tavily)

Query intelligence (auto-detected):
  Temporal keywords (latest, today, 2025...) → time_range filter
  News/finance topics → topic filter

Environment variables:
  TAVILY_API_KEY    Required for search and extract
  EXA_API_KEY       Required for code search
```

## Data Privacy

Queries are sent to external search services. Do not include confidential code or sensitive information in search queries.
