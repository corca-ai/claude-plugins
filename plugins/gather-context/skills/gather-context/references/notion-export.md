# Notion Export Reference

## Supported URL Formats

- `https://workspace.notion.site/Title-{32hex}`
- `https://www.notion.so/Title-{32hex}`
- `https://www.notion.so/{32hex}`
- 32-character hex string (bare page ID)

## Script Usage

```bash
python3 {SKILL_DIR}/scripts/notion-to-md.py "$URL" "$OUTPUT_PATH"
```

## Prerequisites

- Page must be **published to the web** (Share > Publish in Notion)
- Python 3.7+

## Known Limitations

- Sub-pages: rendered as `<!-- missing block -->`
- Images: URL references only (Notion S3 URLs expire)
- Database views (`collection_view`): not supported
- Relies on undocumented Notion v3 API

## Supported Block Types

| Block Type | Markdown Output |
|-----------|----------------|
| `page` | `# Title` (root) / `**Title**` (sub-page) |
| `header` | `# Title` |
| `sub_header` | `## Title` |
| `sub_sub_header` | `### Title` |
| `text` | Plain text |
| `bulleted_list` | `- Item` (nested with 2-space indent) |
| `numbered_list` | `1. Item` (nested with 2-space indent) |
| `quote` | `> Text` (children also prefixed with `>`) |
| `divider` | `---` |
| `code` | Fenced block with language tag (plain text, no inline formatting) |
| `to_do` | `- [x]` / `- [ ]` |
| `toggle` | `**Title**` (children rendered below) |
| `callout` | `> {icon} Text` |
| `image` | `![caption](url)` (http/https only) |
| `bookmark` | `[title](url)` (http/https only) |
| `table` | GFM pipe table (`\|` escaped, newlines → `<br>`) |
| `column_list`/`column` | Layout only — children rendered directly |

Unsupported types emit `<!-- unsupported: {type} -->`.

## Rich Text Formatting

| Format | Markdown | Notes |
|--------|----------|-------|
| Bold | `**text**` | |
| Italic | `*text*` | |
| Bold+Italic | `***text***` | |
| Code | `` `text` `` | Wins over other formatting |
| Strikethrough | `~~text~~` | |
| Link | `[text](url)` | http/https only |
| Highlight | (ignored) | |
| Underline | (ignored) | |

## API Details

- Endpoint: `POST https://www.notion.so/api/v3/loadPageChunk`
- Pagination: cursor-based, max 50 chunks x 100 blocks
- Retry: 3 attempts with exponential backoff (2^n seconds) on 429/5xx
- Timeout: 30 seconds per request
