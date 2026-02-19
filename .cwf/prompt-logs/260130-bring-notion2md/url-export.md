# url-export: Unified URL Export Skill

## Overview

A single skill that detects the type of external URL provided by the user and delegates to the appropriate converter. This eliminates the need for users to remember which skill to invoke for which URL type.

## Motivation

The corca-plugins marketplace currently has three separate export skills:
- **g-export**: Google Docs/Slides/Sheets → local files
- **slack-to-md**: Slack threads → markdown
- **notion-to-md**: Notion pages → markdown

Each has its own trigger command and URL detection pattern. Users must know which skill handles which URL. A unified skill would:
1. **Reduce cognitive load**: one command for all external content
2. **Simplify discovery**: the agent auto-detects URL type and delegates
3. **Provide consistent output handling** across all converters
4. **Enable extensibility**: new services can be added to the detection table

## Proposed Interface

### Command

```
/url-export <url> [options]
```

### Options

- `--format <fmt>`: Override output format (only applies to g-export)
- `--output <path>`: Override output file path
- `--output-dir <dir>`: Override output directory

### Auto-detection

When a user provides any URL in conversation (not just via the `/url-export` command), the agent should recognize whether it matches a supported service and offer to export it.

## URL Detection Rules

| URL Pattern | Converter | Output Format |
|-------------|-----------|---------------|
| `docs.google.com/{presentation\|document\|spreadsheets}/d/*` | g-export | varies (txt/md/toon) |
| `*.slack.com/archives/*/p*` | slack-to-md | markdown |
| `*.notion.site/*`, `www.notion.so/*` | notion-to-md | markdown |
| Any other URL | WebFetch fallback | markdown summary |

Detection order: most specific patterns first, generic WebFetch fallback last.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CORCA_URL_EXPORT_OUTPUT_DIR` | `./exports` | Unified default output directory |
| `CLAUDE_CORCA_G_EXPORT_OUTPUT_DIR` | (falls back to URL_EXPORT_OUTPUT_DIR) | Google-specific override |
| `CLAUDE_CORCA_SLACK_TO_MD_OUTPUT_DIR` | (falls back to URL_EXPORT_OUTPUT_DIR) | Slack-specific override |
| `CLAUDE_CORCA_NOTION_TO_MD_OUTPUT_DIR` | (falls back to URL_EXPORT_OUTPUT_DIR) | Notion-specific override |

**Priority chain**: CLI argument > service-specific env var > unified env var > hardcoded default

## Architecture

### Recommended: SKILL.md-only Orchestration

The unified skill contains ONLY a SKILL.md with no scripts. It provides the agent with URL detection rules and instructs the agent to:

1. Detect URL type from the pattern table
2. Invoke the installed individual skill (e.g., "use g-export skill to download this URL")
3. If the specific skill is not installed, inform the user
4. For unknown URLs, fall back to WebFetch

```
plugins/url-export/
├── .claude-plugin/plugin.json
└── skills/url-export/
    └── SKILL.md              # Detection rules + delegation instructions only
```

**Why this approach**:
- Zero code duplication — each converter lives in its own plugin
- Works with plugin isolation — the agent invokes skills by name, not by file path
- Easy to extend — add a new URL pattern row and point to the new skill
- Individual skills remain independently usable via their own commands
- Minimal maintenance burden

### Alternatives Considered

**Option A: Dispatcher Script** — A bash/python script that parses URLs and calls the appropriate converter script. Problem: plugin isolation means one plugin cannot reference scripts in sibling plugins because each is installed to a separate version-specific cache directory.

**Option B: Bundled Plugin** — Copy all three converters' scripts into a single plugin. Problem: code duplication; updates to individual skills must be manually synced.

## Extensibility

To add support for a new service (e.g., Confluence, GitHub Issues, Figma):

1. Create a new export plugin following the unified pattern (`CLAUDE_CORCA_<SERVICE>_OUTPUT_DIR`, Configuration section in SKILL.md, priority chain)
2. Add URL pattern and converter entry to the url-export SKILL.md detection table
3. Document the new service in README.md

## Open Questions

1. **Replacement or addition?** — Should url-export replace the individual skills or coexist alongside them?
   - *Recommendation*: Addition. Individual skills remain for users who prefer explicit invocation or only need one service.

2. **WebFetch fallback behavior** — How should the generic fallback work?
   - *Recommendation*: Use WebFetch to download the page, convert to markdown, and save to the output directory. This gives a "good enough" result for any public URL.

3. **Plugin dependencies** — Can a plugin declare that it requires other plugins?
   - The current marketplace schema does not support plugin dependencies. The SKILL.md should instruct the agent to check if required skills are installed and guide the user to install them if missing.

## Implementation Sequence

1. Ensure all three export skills follow the unified pattern (env vars, priority chain, SKILL.md structure) — **already done**
2. Create `plugins/url-export/` with SKILL.md-only dispatcher
3. Add to marketplace.json
4. Document in README.md
5. Test with all URL types (Google, Slack, Notion, generic)
