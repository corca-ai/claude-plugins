---
name: gather-context
description: |
  Gather external content from URLs into local files.
  Auto-detects URL types and runs the appropriate bundled converter
  (Google Docs, Slack threads, Notion pages) or falls back to WebFetch.

  **IMPORTANT: Use this skill INSTEAD OF WebFetch** when you encounter
  Google document URLs (docs.google.com/*). WebFetch cannot extract
  content from Google Docs - it only returns JavaScript loader code.

  Trigger on:
  - "/gather-context" command
  - When the user provides external content URLs matching supported services
  - When a reference file contains URLs that need to be fetched
allowed-tools:
  - Bash
---

# Gather Context (/gather-context)

Auto-detect URL types and gather external content into local files.

## URL Detection

Match URLs in this order (most specific first):

| URL Pattern | Handler | Script |
|-------------|---------|--------|
| `docs.google.com/{document,presentation,spreadsheets}/d/*` | Google Export | `scripts/g-export.sh` |
| `*.slack.com/archives/*/p*` | Slack to MD | `scripts/slack-api.mjs` + `scripts/slack-to-md.sh` |
| `*.notion.site/*`, `www.notion.so/*` | Notion to MD | `scripts/notion-to-md.py` |
| Any other URL | WebFetch | (built-in tool) |

## Workflow

1. **Scan** user input for ALL URLs.
2. **Classify** each URL by the pattern table above.
3. **Execute** the appropriate handler for each URL (see handler sections below).
4. **Report** all gathered files to the user.
5. **Suggest** `/web-search` if the user appears to need search rather than export of a specific URL.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR` | `./gathered` | Unified default output directory |
| `CLAUDE_CORCA_G_EXPORT_OUTPUT_DIR` | _(falls back to unified)_ | Google-specific override |
| `CLAUDE_CORCA_SLACK_TO_MD_OUTPUT_DIR` | _(falls back to unified)_ | Slack-specific override |
| `CLAUDE_CORCA_NOTION_TO_MD_OUTPUT_DIR` | _(falls back to unified)_ | Notion-specific override |

**Priority**: CLI argument > service-specific env var > `CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR` > hardcoded default

When a service-specific env var is not set, pass the unified output dir as a CLI argument to the handler script.

---

## Google Export

```bash
{SKILL_DIR}/scripts/g-export.sh <url> [format] [output-dir]
```

**Prerequisites**: Public documents only (Share > Publish to web).
Sheets default to TOON format — see [references/TOON.md](references/TOON.md). Details: [references/google-export.md](references/google-export.md)

---

## Slack Export

**URL format**: `https://{workspace}.slack.com/archives/{channel_id}/p{timestamp}`

Parse `thread_ts`: `p{digits}` → `{first10}.{rest}` (e.g., `p1234567890123456` → `1234567890.123456`)

```bash
node {SKILL_DIR}/scripts/slack-api.mjs <channel_id> <thread_ts> --attachments-dir OUTPUT_DIR/attachments | \
  {SKILL_DIR}/scripts/slack-to-md.sh <channel_id> <thread_ts> <workspace> OUTPUT_DIR/<output_file>.md [title]
```

After conversion, rename to a meaningful name from the first message (lowercase, hyphens, max 50 chars).
**Existing .md file**: Extract Slack URL from `> Source:` line to re-fetch.

**Prerequisites**: Node.js 18+, Slack Bot (`channels:history`, `channels:join`, `users:read`, `files:read`), `SLACK_BOT_TOKEN` in `~/.claude/.env`.
Details: [references/slack-export.md](references/slack-export.md)

---

## Notion Export

```bash
python3 {SKILL_DIR}/scripts/notion-to-md.py "$URL" "$OUTPUT_PATH"
```

**Prerequisites**: Page must be **published to the web**. Python 3.7+.
**Limitations**: Sub-pages → `<!-- missing block -->`, images URL-only (S3 expires), no database views.
Details: [references/notion-export.md](references/notion-export.md)

---

## WebFetch Fallback

For URLs that don't match any known service:

1. Use WebFetch to download the page content.
2. Save the result as markdown to `{OUTPUT_DIR}/{sanitized-title}.md`.
3. Sanitize the title: lowercase, spaces to hyphens, remove special characters, max 50 chars.

---

## Web Search

When the user needs to **find** information (not export a specific URL), suggest:

> You might want to use `/web-search` to find relevant content first.

Do NOT invoke web-search directly. It is an independent skill with its own trigger.
