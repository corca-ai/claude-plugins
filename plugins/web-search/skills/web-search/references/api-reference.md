# API Reference

Reference for the web-search skill. Execution is handled by wrapper scripts (`search.sh`, `code-search.sh`, `extract.sh`); this document covers what SKILL.md needs for intent analysis and parameter decisions.

## Environment Variables

| Variable | Required for | Get key at |
|----------|-------------|------------|
| `TAVILY_API_KEY` | `/web-search`, `/web-search extract` | https://app.tavily.com/home |
| `EXA_API_KEY` | `/web-search code` | https://dashboard.exa.ai/api-keys |

Only check the key required for the invoked subcommand. Do not require both keys at once.

## Tavily Search Parameters

### Conditional Parameters

| Parameter | Values | When to set |
|-----------|--------|-------------|
| `topic` | `"general"` (default), `"news"`, `"finance"` | Set based on query analysis or `--news` flag. Omit for general queries. |
| `time_range` | `"day"`, `"week"`, `"month"`, `"year"` | Set when temporal intent detected (e.g., "latest", "today", "this week", "2025", "2026"). Omit for evergreen queries. |
| `search_depth` | `"basic"` (default), `"advanced"` | Override to `"advanced"` when `--deep` flag is used or query is complex/research-oriented. |
| `include_raw_content` | `"markdown"` | Include when `search_depth` is `"advanced"`. Provides full page content for deeper analysis. |

Only add conditional parameters when they apply. Default behavior (no extra params) must remain unchanged for simple queries.

## Tavily Extract Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `query` | string | Optional. Reranks extracted chunks by relevance to this query. Only add when the user provides a query after the URL. |

## Exa Code Context — Token Allocation

`tokensNum`: Max response tokens (range: 1000-50000). Set dynamically based on query complexity:

| Query type | tokensNum | Example |
|-----------|-----------|---------|
| Simple lookup | 3000 | "golang sort slice" |
| Standard query | 5000 | "React useEffect cleanup" |
| Complex/architectural | 10000 | "React server components vs client components patterns" |
| Deep research | 15000 | "microservices event sourcing CQRS implementation patterns" |

Choose the tier that best matches the query. When unsure, default to 5000.

## Error Handling

Handled by scripts. Common HTTP status codes for reference:

| HTTP Code | Meaning |
|-----------|---------|
| 200 | Success |
| 401 | Invalid API key |
| 429 | Rate limit exceeded |
| Other | Request failed |
