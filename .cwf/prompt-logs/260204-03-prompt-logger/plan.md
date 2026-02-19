# Plan: prompt-logger Plugin

Hook-only plugin that auto-logs every conversation turn to markdown files for retrospective analysis.

## Architecture

- **Hooks**: `Stop` (async) + `SessionEnd` (async) → same script `log-turn.sh`
- **Processing**: Incremental via line-count offset tracking in `/tmp/` state files
- **Output**: One markdown file per session, append-mode
- **No model involvement**: Pure bash + jq

## Steps

- [x] Step 0: Create prompt-logs artifacts
- [x] Step 1: hooks.json (Stop + SessionEnd)
- [x] Step 2: log-turn.sh (main script)
- [x] Step 3: jq parsing (turn grouping, tool summaries, image handling)
- [x] Step 4: Output format (markdown with truncation)
- [x] Step 5: Configuration (env vars)
- [x] Step 6: plugin.json, marketplace.json, READMEs, test, deploy
