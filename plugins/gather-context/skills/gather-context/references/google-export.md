# Google Export Reference

## Formats

| Type | Formats | Default |
|------|---------|---------|
| Slides | pptx, odp, pdf, txt | txt |
| Docs | docx, odt, pdf, txt, epub, html, md | md |
| Sheets | xlsx, ods, pdf, csv, tsv, toon | toon |

## Script Usage

```bash
{SKILL_DIR}/scripts/g-export.sh <url> [format] [output-dir]
```

## Notes

- Uses original document title as filename
- Sheets csv/tsv/toon: exports first sheet by default; gid parameter in URL (e.g., `?gid=123`) is auto-detected for specific sheets
- md exports: base64 images removed; use `docx` or `pdf` for image-heavy documents
- Only public documents work (Share > Publish to web)

## TOON Format

Default format for Sheets. After reading the output, autonomously decide to transform survey/session data to Markdown for better readability (preserve the original file).

See: [TOON.md](TOON.md)
