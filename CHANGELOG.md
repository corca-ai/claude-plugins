# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-09

### Added
- Plugin structure with `.claude-plugin/plugin.json` manifest
- Skills: `clarify`, `slack-to-md`
- Hooks: `attention.sh` for Slack/Discord notifications on idle
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
