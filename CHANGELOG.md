# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-02-07

### Added

- Hooks: `markdown-guard` (1.0.0) — PostToolUse hook that validates markdown files after Write/Edit, reports lint violations for Claude to self-correct
- Config: `.markdownlint-cli2.jsonc` — proper ignore config for markdownlint-cli2 (`.markdownlintignore` was never supported by cli2)

### Changed

- Skills: `retro` (2.0.0→2.0.1) — added Rule 10: always include language specifiers on code fences in markdown output
- Skills: `refactor` (1.1.0→1.1.1) — added bare code fence check to docs-criteria
- Config: `.markdownlint.json` — disabled MD036 (emphasis as heading) for external reference files
- Docs: fixed 8 MD040 violations (bare code fences) across README, docs, references, and protocol files
- Docs: fixed MD022 violations (blanks around headings) via auto-fix in CHANGELOG, review-criteria, testing guide
- Skills (local): `plugin-deploy` — added markdown quality reminder to checklist

## [1.9.2] - 2026-02-03

### Changed

- Skills: `retro` (1.3.3→1.3.4) — added explicit "Persistence check" checklist to post-retro phase (CLAUDE.md / skills·protocol / project-context.md)

## [1.9.1] - 2026-02-03

### Changed

- Skills: `retro` (1.3.2→1.3.3) — replaced find-skills/skill-creator references with generic guidance
- Docs: sub-agent review follow-up — fixed 404 link in claude-marketplace.md, CLAUDE.md link text mismatch, CHANGELOG plan-and-lessons entry error, marketplace.json meta version; slimmed adding-plugin.md; added env loading rationale to cheatsheet; linked project-context.md from CLAUDE.md; added process heuristics to project-context.md; cleaned skills-guide.md; shortened README install blocks (9×10 lines → 9×1 line)

## [1.9.0] - 2026-02-03

### Added

- Hooks: `smart-read` (1.0.0) — PreToolUse hook that enforces intelligent file reading based on file size (warn >500 lines, deny >2000 lines)
- Skills (local): `plugin-deploy` — local skill to automate post-modification plugin lifecycle
- Docs: `docs/plugin-dev-cheatsheet.md` — quick reference to reduce repeated doc reads
- Scripts: `scripts/update-all.sh` — bulk marketplace + plugin update script

### Changed

- Skills: `web-search` (2.0.0→2.0.1) — refactored to script delegation pattern (SKILL.md → wrapper scripts for API execution); added PreToolUse hook to redirect built-in WebSearch to `/web-search`; slimmed api-reference.md (381→56 lines, removed dead curl/jq patterns)
- Skills: `gather-context` (1.1.1) — applied 3-tier env loading to slack-api.mjs; loosely coupled with WebSearch (hook handles redirect)
- Skills: `retro` (1.3.2) — minor refinements
- Hooks: `plan-and-lessons` (1.1.0→1.2.0) — protocol timing: lessons.md created alongside plan.md; added Prior Art Search section to protocol
- Docs: comprehensive doc audit — slimmed claude-marketplace.md (510→43 lines), api-reference.md (381→56 lines); updated project-context.md, cheatsheet, CHANGELOG

## [1.8.0] - 2026-01-30

### Changed

- Skills: `retro` (1.3.0) — Section 2 right-placement check: suggest updating referenced documents instead of CLAUDE.md when the learning belongs there; Section 6 post-retro release procedure reminder
- Hooks: `plan-and-lessons` (1.1.0) — Protocol Timing section: lessons.md must be created at the same time as plan.md

### Removed

- Skills: `g-export`, `slack-to-md`, `notion-to-md` — functionality is now bundled in `gather-context`. Install `gather-context` instead.

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
