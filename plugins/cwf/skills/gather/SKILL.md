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

Prerequisites and format caveats live in [references/google-export.md](references/google-export.md). TOON behavior for Sheets is defined in [references/TOON.md](references/TOON.md).

### Slack Export

**URL format**: `https://{workspace}.slack.com/archives/{channel_id}/p{timestamp}`

Parse `thread_ts`: `p{digits}` → `{first10}.{rest}` (e.g., `p1234567890123456` → `1234567890.123456`)

```bash
node {SKILL_DIR}/scripts/slack-api.mjs <channel_id> <thread_ts> --attachments-dir OUTPUT_DIR/attachments | \
  {SKILL_DIR}/scripts/slack-to-md.sh <channel_id> <thread_ts> <workspace> OUTPUT_DIR/<output_file>.md [title]
```

After conversion, rename to a meaningful name from the first message (lowercase, hyphens, max 50 chars). **Existing .md file**: Extract Slack URL from `> Source:` line to re-fetch.

Prerequisites, token setup, and error recovery are defined in [references/slack-export.md](references/slack-export.md).

### Notion Export

```bash
python3 {SKILL_DIR}/scripts/notion-to-md.py "$URL" "$OUTPUT_PATH"
```

Publication requirements and known limitations are defined in [references/notion-export.md](references/notion-export.md).

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

For URLs that don't match any known service, run this deterministic routine:

1. **Resolve paths**:
   - `slug`: sanitized title/url token (lowercase, spaces to hyphens, remove special characters, max 50 chars)
   - `output_md`: `{OUTPUT_DIR}/{slug}.md`
   - `output_meta`: `{OUTPUT_DIR}/{slug}.meta.yaml`

2. **Mandatory URL safety precheck (before any fetch/extract)**:
   - Parse URL and derive: `scheme`, `host`, `resolved_ips` (A/AAAA when available).
   - Evaluate block rules in this fixed order and store the first match as `blocked_reason_code`:
     1. `non_http_scheme` — scheme is not `http` or `https`
     2. `localhost_target` — host is `localhost` or ends with `.localhost`
     3. `loopback_target` — host/IP in `127.0.0.0/8` or `::1/128`
     4. `link_local_target` — host/IP in `169.254.0.0/16` or `fe80::/10`
     5. `private_ipv4_target` — host/IP in RFC1918 ranges (`10/8`, `172.16/12`, `192.168/16`)
     6. `private_ipv6_target` — host/IP in `fc00::/7`
   - Default behavior for blocked URLs: do not run extraction.
   - Required interactive override path:
     1. `Override once for this URL and continue` (explicit user confirmation required)
     2. `Skip this URL` (default)
   - If override is not explicitly confirmed, stop processing this URL and write failed metadata.

3. **Try Tavily extract first**:
   ```bash
   {SKILL_DIR}/scripts/extract.sh "<url>" > "{output_md}.tmp"
   ```
   - Success contract: exit code `0` and temp file has non-whitespace content.
   - On success: move temp file to `{output_md}` and set metadata `method: tavily-extract`.
   - If `TAVILY_API_KEY` is missing or extraction fails, continue to Step 4.

4. **WebFetch fallback (single fixed procedure)**:
   - Run one Task call with this exact prompt contract:
     ```text
     Fetch this URL with WebFetch: <url>
     Return markdown only (preserve headings, lists, and links).
     If content cannot be retrieved, return exactly: WEBFETCH_EMPTY
     ```
   - If the result is not `WEBFETCH_EMPTY`, save it to `{output_md}` and set metadata `method: webfetch-fallback`.

5. **Empty-output handling**:
   - Treat as failure when `{output_md}` is missing, whitespace-only, or the fallback response equals `WEBFETCH_EMPTY`.
   - On failure, do not keep partial markdown output.

6. **Metadata capture (always required)**:
   - Write `{output_meta}` with at least:
     - `source_url`
     - `retrieved_at_utc` (ISO 8601 UTC)
     - `handler: generic`
     - `safety_precheck`:
       - `status` (`passed`, `blocked`, or `overridden`)
       - `blocked_reason_code` (empty when passed)
       - `host`
       - `resolved_ips`
     - `method` (`tavily-extract`, `webfetch-fallback`, or `none`)
     - `status` (`success` or `failed`)
     - `output_file` (empty when failed)
     - `failure_reason` (when failed)
   - For safety-blocked URLs without explicit override, set:
     - `status: failed`
     - `method: none`
     - `output_file: ""`
     - `failure_reason: url_safety_blocked`

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

### Task Output Contract

Input mapping:
- `query_raw`: original `--local` argument
- `query_slug`: sanitized query token (lowercase, spaces to hyphens, remove special characters, max 50 chars)
- `output_md`: `{OUTPUT_DIR}/local-{query_slug}.md`
- `output_meta`: `{OUTPUT_DIR}/local-{query_slug}.meta.yaml`

Task prompt contract:

```text
Explore this codebase for: <query_raw>.
Use Glob, Grep, and Read to find relevant code, patterns, and architecture.
Return a structured markdown summary with:
## Overview
## Key Files
## Code Patterns
## Notable Details
Include file paths and line references where possible.
Write your complete output to: <output_md>
The file MUST exist when you finish and must end with: <!-- AGENT_COMPLETE -->
```

Execution and failure handling:
1. Run Task once using the prompt contract above.
2. Validate output contract (`output_md` exists, has non-whitespace content, and ends with `<!-- AGENT_COMPLETE -->`).
3. If invalid or Task fails, retry once with the same input and explicit correction.
4. If retry still fails, stop local gather for this query and report failure clearly.

Provenance metadata guidance:
- Always write `output_meta` with: `mode: local`, `query_raw`, `query_slug`, `subagent_type`, `attempts`, `status`, `output_md` (if any), `generated_at_utc`.
- When failed, include `failure_reason` and preserve diagnostics from the last Task run.

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
