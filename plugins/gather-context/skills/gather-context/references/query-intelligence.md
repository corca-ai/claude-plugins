# Query Intelligence

Logic for routing and enriching search queries before calling scripts. Applied to `--search` mode only.

## Routing Decision Tree

```text
Is query prefixed with "code" or --search code?
  YES → code-search.sh (Exa)
  NO  → Does query match code context keywords?
          YES → code-search.sh (Exa)
          NO  → search.sh (Tavily)
```

### Code Context Keywords

Auto-route to `code-search.sh` when query contains programming-specific terms:
- Language names: python, javascript, typescript, golang, rust, java, etc.
- Framework/library names: React, Vue, Django, FastAPI, Express, etc.
- Programming concepts: "how to implement", "code example", "library for", "API for"
- Technical patterns: "design pattern", "architecture", "algorithm"

When ambiguous, default to Tavily (general search).

## Temporal Intent Detection

Analyze the query for temporal keywords and set `--time-range` flag on `search.sh`:

| Keywords in query | `--time-range` value |
|-------------------|---------------------|
| "today", "latest today" | `day` |
| "this week", "latest", "recent" | `week` |
| "this month" | `month` |
| "this year", "2025", "2026" | `year` |

If no temporal keywords → omit `--time-range`.

## Topic Detection

Detect topic from query content (if not set by `--news` or `--deep` flag):

| Keywords | Topic flag |
|----------|-----------|
| breaking, headline, announced, report, news | `--topic news` |
| stock, price, market, earnings, revenue, IPO, trading | `--topic finance` |

If no topic keywords → omit `--topic` (defaults to general).

## Code Search Token Allocation

For `code-search.sh`, assess query complexity and set `--tokens`:

| Query type | tokensNum | Example |
|-----------|-----------|---------|
| Simple lookup | 3000 | "golang sort slice" |
| Standard query | 5000 | "React useEffect cleanup" |
| Complex/architectural | 10000 | "React server components vs client components patterns" |
| Deep research | 15000 | "microservices event sourcing CQRS implementation patterns" |

Default to 5000 when unsure.

## Modifier Flags

| User flag | Script flag | Effect |
|-----------|------------|--------|
| `--news` | `--topic news` | Sets Tavily topic to news |
| `--deep` | `--deep` | Sets Tavily search_depth to advanced, includes raw_content |

Modifiers can appear anywhere before the query.
