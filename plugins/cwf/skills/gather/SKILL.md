---
name: gather
description: "Unified information acquisition that stabilizes context before reasoning: URL auto-detect (Google/Slack/Notion/GitHub/web), web search (Tavily/Exa), and local codebase exploration. Triggers: \"cwf:gather\", \"gather <url>\", \"web search\", \"code search\""
---

# Gather Context (cwf:gather)

Convert scattered sources into local, reusable artifacts so later phases reason over stable context instead of transient links.

**Language**: Write gathered artifacts in English. Communicate with the user in their prompt language.

## Quick Reference

```text
cwf:gather <url>                  URL auto-detect → download to OUTPUT_DIR
cwf:gather <url1> <url2> ...      Multiple URLs
cwf:gather --search <query>       Web search (Tavily)
cwf:gather --search --news <q>    News search (Tavily)
cwf:gather --search --deep <q>    Advanced depth search (Tavily)
cwf:gather --search code <query>  Code/technical search (Exa)
cwf:gather --local <query>        Local codebase exploration
cwf:gather                        Usage guide
cwf:gather help                   Usage guide
```

Why this exists:
- Normalize heterogeneous sources into local markdown artifacts that downstream skills can cite and diff reliably.
- Enforce source-access constraints explicitly (for example, Google Docs/Notion exports require public or published sharing).

## Workflow

1. **Parse** args → mode (URL | `--search` | `--local` | help)
2. **No args or "help"** → print [usage message](#usage-message) and stop
3. **Execute** the appropriate handler (see sections below)
4. **Save** results to `OUTPUT_DIR` (URL and `--local` modes)
5. **Suggest** follow-up: after URL gathering, suggest `--search` for supplementary research if helpful

---

## URL Auto-Detect

Scan input for all URLs. Classify each by pattern table (most specific first):

| URL Pattern | Handler | Script / Tool |
|-------------|---------|---------------|
| `docs.google.com/{document,presentation,spreadsheets}/d/*` | Google Export | [scripts/g-export.sh](scripts/g-export.sh) |
| `*.slack.com/archives/*/p*` | Slack to MD | [scripts/slack-api.mjs](scripts/slack-api.mjs) + [scripts/slack-to-md.sh](scripts/slack-to-md.sh) |
| `*.notion.site/*`, `www.notion.so/*` | Notion to MD | [scripts/notion-to-md.py](scripts/notion-to-md.py) |
| `github.com/*` | GitHub | `gh` CLI |
| Any other URL | Generic | [scripts/extract.sh](scripts/extract.sh) → WebFetch fallback |

### Google Export

```bash
{SKILL_DIR}/scripts/g-export.sh <url> [format] [output-dir]
```

**Prerequisites**: Public documents only (Share > Publish to web). Sheets default to TOON format — see [references/TOON.md](references/TOON.md). Details: [references/google-export.md](references/google-export.md)

### Slack Export

**URL format**: `https://{workspace}.slack.com/archives/{channel_id}/p{timestamp}`

Parse `thread_ts`: `p{digits}` → `{first10}.{rest}` (e.g., `p1234567890123456` → `1234567890.123456`)

```bash
node {SKILL_DIR}/scripts/slack-api.mjs <channel_id> <thread_ts> --attachments-dir OUTPUT_DIR/attachments | \
  {SKILL_DIR}/scripts/slack-to-md.sh <channel_id> <thread_ts> <workspace> OUTPUT_DIR/<output_file>.md [title]
```

After conversion, rename to a meaningful name from the first message (lowercase, hyphens, max 50 chars). **Existing .md file**: Extract Slack URL from `> Source:` line to re-fetch.

**Prerequisites**: Node.js 18+, Slack Bot (`channels:history`, `channels:join`, `users:read`, `files:read`), `SLACK_BOT_TOKEN` in shell profile (`~/.zshrc`/`~/.bashrc`). Details: [references/slack-export.md](references/slack-export.md)

### Notion Export

```bash
python3 {SKILL_DIR}/scripts/notion-to-md.py "$URL" "$OUTPUT_PATH"
```

**Prerequisites**: Page must be **published to the web**. Python 3.7+. **Limitations**: Sub-pages → `<!-- missing block -->`, images URL-only (S3 expires), no database views. Details: [references/notion-export.md](references/notion-export.md)

### GitHub

For `github.com` URLs, use the `gh` CLI to extract content as markdown.

**Prerequisite check**: Verify `command -v gh` first. If `gh` is not available, fall through to Generic handler.

When `gh` is missing for a GitHub URL, do not silently downgrade only. Ask the user:
1. `Install gh now (recommended)` — run `bash {SKILL_DIR}/../setup/scripts/install-tooling-deps.sh --install gh`, then retry GitHub handler once.
2. `Continue with Generic handler` — proceed with reduced metadata extraction.
3. `Skip this URL` — do not process this GitHub URL in this run.

| URL type | Command |
|----------|---------|
| PR (path pattern: /pull/N) | `gh pr view <url> --json title,body,state,author,comments --template '...'` |
| Issue (path pattern: /issues/N) | `gh issue view <url> --json title,body,state,author,comments --template '...'` |
| Repository (owner/repo) | `gh repo view <url> --json name,description,readme` |
| Other GitHub URL | Fall through to Generic handler |

Save output to `{OUTPUT_DIR}/{type}-{owner}-{repo}-{number}.md`.

**Template for PR/Issue** (pass to `--template`):
```text
# {{.title}}
State: {{.state}} | Author: {{.author.login}}

{{.body}}

{{range .comments}}---
**{{.author.login}}** ({{.createdAt}}):
{{.body}}
{{end}}
```

### Generic URL

For URLs that don't match any known service:

1. **Try `extract.sh`** (Tavily extract) if `TAVILY_API_KEY` is likely set:
   ```bash
   {SKILL_DIR}/scripts/extract.sh "<url>"
   ```
   If extraction succeeds, save to `{OUTPUT_DIR}/{sanitized-title}.md`.

2. **Fallback to WebFetch** if no `TAVILY_API_KEY` or extraction fails:
   - Use WebFetch tool to download the page content.
   - Save the result as markdown to `{OUTPUT_DIR}/{sanitized-title}.md`.

Sanitize title: lowercase, spaces to hyphens, remove special characters, max 50 chars.

---

## --search Mode

Web and code search via external APIs.

**Read [references/query-intelligence.md](references/query-intelligence.md)** before executing search — it contains the routing logic and parameter tables.

### Subcommands

| Command | Backend | Script |
|---------|---------|--------|
| `--search <query>` | Tavily | [scripts/search.sh](scripts/search.sh) |
| `--search --news <query>` | Tavily (topic: news) | `scripts/search.sh --topic news` |
| `--search --deep <query>` | Tavily (advanced) | `scripts/search.sh --deep` |
| `--search code <query>` | Exa | [scripts/code-search.sh](scripts/code-search.sh) |

### Execution

1. Read [query-intelligence.md](references/query-intelligence.md) for routing and parameter decisions
2. Route: `code` prefix or auto-detected code context → `code-search.sh`; otherwise → `search.sh`
3. Apply query intelligence (temporal, topic, token allocation) per reference
4. Call script via Bash:
   ```bash
   {SKILL_DIR}/scripts/search.sh [--topic news|finance] [--time-range day|week|month|year] [--deep] "<query>"
   {SKILL_DIR}/scripts/code-search.sh [--tokens NUM] "<query>"
   ```
5. Display results to user (scripts output formatted markdown)

**Graceful degradation**: If API key is missing, scripts print setup instructions to stderr. Do not stop at an error message only. Ask whether to configure now:
- `Configure now (recommended)` — run `cwf:setup --env` (and `cwf:setup --tools` if runtime dependencies are also missing), then retry the same search once.
- `Skip search for now` — continue without search results.
- `Show setup commands only` — print exact export/setup commands.
See [references/search-api-reference.md](references/search-api-reference.md).

### Data Privacy

Queries are sent to external search services. Do not include confidential code or sensitive information in search queries.

---

## --local Mode

Explore the local codebase for a topic and save structured results.

### Execution

1. Launch a sub-agent:
   ```text
   Task(subagent_type="general-purpose", prompt="Explore this codebase for: <query>. Use Glob, Grep, and Read to find relevant code, patterns, and architecture. Return a structured markdown summary with: ## Overview, ## Key Files, ## Code Patterns, ## Notable Details. Be thorough but concise.")
   ```
2. Save sub-agent output to `{OUTPUT_DIR}/local-{sanitized-query}.md`
3. Report file location to user

Sanitize query for filename: lowercase, spaces to hyphens, remove special characters, max 50 chars.

---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CWF_GATHER_OUTPUT_DIR` | .cwf/projects | Unified default output directory |
| `CWF_GATHER_GOOGLE_OUTPUT_DIR` | _(falls back to unified)_ | Google-specific override |
| `CWF_GATHER_NOTION_OUTPUT_DIR` | _(falls back to unified)_ | Notion-specific override |
| `TAVILY_API_KEY` | — | Required for `--search` and generic URL extract |
| `EXA_API_KEY` | — | Required for `--search code` |

**Output dir priority**: CLI argument > service-specific env var > `CWF_GATHER_OUTPUT_DIR` > hardcoded default (.cwf/projects)

When a service-specific env var is not set, pass the unified output dir as a CLI argument to the handler script.

---

## Supplementary Research

After gathering URL content, if best practices, reference documentation, or supplementary context would help the user, use the search scripts directly via Bash (not the WebSearch tool):

```bash
{SKILL_DIR}/scripts/search.sh "<query>"
```

Examples:
- Gathered a Google Doc describing a migration plan → search for best practices
- Gathered a Slack thread about an unfamiliar library → search for official docs
- Gathered a Notion page with a technical spec → search for implementation examples

---

## Usage Message

Print when no args or "help":

```text
Gather Context — Unified Information Acquisition

Usage:
  cwf:gather <url>                  Gather content from URL (auto-detect service)
  cwf:gather --search <query>       Web search (Tavily)
  cwf:gather --search --news <q>    News search
  cwf:gather --search --deep <q>    Deep search
  cwf:gather --search code <query>  Code/technical search (Exa)
  cwf:gather --local <query>        Explore local codebase

Supported URL services:
  Google Docs/Slides/Sheets, Slack threads, Notion pages, GitHub PRs/issues, generic web

Environment variables:
  TAVILY_API_KEY    Web search and URL extraction (https://app.tavily.com)
  EXA_API_KEY       Code search (https://dashboard.exa.ai)
```

---

## Rules

1. **URL auto-detect priority**: Match most specific pattern first (Google > Slack > Notion > GitHub > Generic)
2. **Graceful degradation**: Missing API keys print setup instructions, don't crash
3. **Output dir hierarchy**: CLI argument > service-specific env var > unified env var > .cwf/projects
4. **Data privacy**: Do not include confidential code or sensitive information in search queries
5. **Sub-agent for --local**: Always use Task tool, never inline exploration
6. **All code fences must have language specifier**: Never use bare fences
7. **Missing dependency interaction**: For missing required tools/keys, ask to install/configure now; do not only report unavailability.

## References

- [references/google-export.md](references/google-export.md) — Google Docs/Slides/Sheets export details
- [references/slack-export.md](references/slack-export.md) — Slack thread export details
- [references/notion-export.md](references/notion-export.md) — Notion page export details
- [references/TOON.md](references/TOON.md) — TOON format for spreadsheets
- [references/search-api-reference.md](references/search-api-reference.md) — Tavily/Exa API parameters
- [references/query-intelligence.md](references/query-intelligence.md) — Search routing and query enrichment
