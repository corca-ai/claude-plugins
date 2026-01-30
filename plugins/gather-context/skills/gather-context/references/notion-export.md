# Notion Export Reference

## Supported URL Formats

- `https://workspace.notion.site/Title-{32hex}`
- `https://www.notion.so/Title-{32hex}`
- `https://www.notion.so/{32hex}`
- 32-character hex string (bare page ID)

## Prerequisites

- Page must be **published to the web** (Share > Publish in Notion)
- Python 3.7+

## Known Limitations

- Sub-pages: `<!-- missing block -->`. Images: URL-only (S3 expires). Database views: not supported.
- Relies on undocumented Notion v3 API (`POST /api/v3/loadPageChunk`, cursor-based, 3 retries with backoff)
