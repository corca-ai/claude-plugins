# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-01-30

### Added
- Skills: `gather-context` - Unified context gathering skill that auto-detects URLs (Google Docs, Slack, Notion) and bundles all converter scripts. No separate skill installation needed.

### Removed
- Skills: `url-export` - Replaced by `gather-context`. Users should install `gather-context` instead.

## [1.6.0] - 2026-01-30

### Added
- Skills: `web-search` - Web search, code search, and URL content extraction via Tavily and Exa REST APIs

## [1.4.0] - 2026-01-30

### Added
- Skills: `notion-to-md` - Converts public Notion pages to local Markdown files via Notion's v3 API (Python 3.7+ stdlib only)
- Docs: `docs/skills-guide.md` - Reference document for skill structure, env var naming conventions, and design principles
- Requirements: `requirements/url-export.md` - Plan document for unified URL export skill (`url-export`)

### Changed
- Skills: `g-export` - Added `CLAUDE_CORCA_G_EXPORT_OUTPUT_DIR` env var for configurable output directory
- Skills: `slack-to-md` - Added `CLAUDE_CORCA_SLACK_TO_MD_OUTPUT_DIR` env var for configurable output directory
- Skills: Unified SKILL.md structure across all three export skills (g-export, slack-to-md, notion-to-md) with consistent Configuration section, env var table, and priority chain

## [1.1.0] - 2025-01-10

### Added
- Skills: `suggest-tidyings` - Analyzes recent commits to find safe refactoring opportunities based on Kent Beck's "Tidy First?" philosophy
  - Parallel sub-agent analysis for multiple commits
  - 8 tidying techniques (Guard Clauses, Dead Code Removal, etc.)
  - Safety validation against HEAD changes

## [1.0.0] - 2025-01-09

### Added
- Plugin structure with `.claude-plugin/plugin.json` manifest
- Skills: `clarify`, `slack-to-md`
- Hooks: `attention.sh` for Slack notifications on idle
- `hooks/hooks.json` for plugin-based hook configuration
- MIT License

### Changed
- Moved skills from `.claude/skills/` to `skills/` (plugin convention)
- Moved hook scripts to `hooks/scripts/`
- Updated installation to support `--plugin-dir` flag

### Migration from previous versions
If you were using the standalone `.claude/skills/` structure:
1. Update your skill paths from `.claude/skills/` to `skills/`
2. Use `claude --plugin-dir /path/to/this-repo` instead of manual copying
