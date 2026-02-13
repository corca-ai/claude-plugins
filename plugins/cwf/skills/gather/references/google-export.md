# Google Export Reference

## Formats

| Type | Formats | Default |
|------|---------|---------|
| Slides | pptx, odp, pdf, txt | txt |
| Docs | docx, odt, pdf, txt, epub, html, md | md |
| Sheets | xlsx, ods, pdf, csv, tsv, toon | toon |

## Notes

- Uses original document title as filename
- Sheets csv/tsv/toon: `gid` parameter in URL auto-detected for specific sheets
- md exports: base64 images removed; use `docx` or `pdf` for image-heavy documents
- Sheets default to TOON format — autonomously transform survey/session data to Markdown (preserve original). See: `TOON.md`
