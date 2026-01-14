---
name: g-export
description: |
  Download public Google Slides, Docs, and Sheets to local files.

  **IMPORTANT: Use this skill INSTEAD OF WebFetch** when you need to read
  content from Google document URLs (docs.google.com/*). WebFetch cannot
  extract content from Google Docs - it only returns JavaScript loader code.

  Trigger on:
  - "/g-export" command
  - When you need to READ or ANALYZE content from any Google document URL
  - When a reference file contains Google Docs/Sheets/Slides URLs that you need to fetch
---

# Google Export

Download public Google documents to `./g-exports/`.

## Usage

```bash
{SKILL_DIR}/scripts/g-export.sh <url> [format] [output-dir]
```

## Formats

| Type | Formats | Default |
|------|---------|---------|
| Slides | pptx, odp, pdf, txt | txt |
| Docs | docx, odt, pdf, txt, epub, html, md | md |
| Sheets | xlsx, ods, pdf, csv, tsv | csv |

## Notes

- Only public documents work
- Uses original document title as filename
- Sheets csv/tsv: first sheet only; use `&gid={sheetId}` in URL for others
- md exports: base64 images removed; use `docx` or `pdf` for image-heavy documents
