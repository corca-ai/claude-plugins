# Plan: Add web-search plugin

## Summary

Add the `web-search` skill from `/Users/ted/codes/works/.claude/skills/web-search/` as a plugin in the corca-plugins marketplace. Copy skill files as-is, create plugin metadata, and update all documentation.

## Success Criteria

```gherkin
Given the web-search skill exists at /Users/ted/codes/works/.claude/skills/web-search/
When I add it as a plugin following the existing plugin structure
Then the following files are created:
  - plugins/web-search/.claude-plugin/plugin.json
  - plugins/web-search/skills/web-search/SKILL.md (copied from source)
  - plugins/web-search/skills/web-search/references/api-reference.md (copied from source)

Given the plugin files are in place
When I update the marketplace metadata
Then marketplace.json contains the web-search entry and version is bumped to 1.6.0

Given the plugin is registered
When I update documentation
Then README.md has an overview table row and a skill documentation section (Korean)
And AI_NATIVE_PRODUCT_TEAM.md mentions web-search in the research tools context
And CHANGELOG.md has a 1.6.0 entry
```

## Steps

1. Create plugin directory structure: `plugins/web-search/{.claude-plugin,skills/web-search/references}`
2. Copy SKILL.md and references/api-reference.md from source (no modification)
3. Create plugin.json with standard metadata (name, description, version 1.0.0, author Corca)
4. Update marketplace.json: add web-search entry after url-export, bump version 1.5.0 → 1.6.0
5. Update README.md: add overview table row + full skill documentation section in Korean
6. Update AI_NATIVE_PRODUCT_TEAM.md: add web-search link in research tools context (line 36)
7. Update CHANGELOG.md: add 1.6.0 entry

## Design Decisions

- **Env vars stay as-is**: `TAVILY_API_KEY` / `EXA_API_KEY` are standard third-party API key names, not plugin-specific settings. No rename to `CLAUDE_CORCA_*` convention needed (same rationale as `SLACK_BOT_TOKEN` in slack-to-md).
- **Version bump**: 1.5.0 → 1.6.0 (minor, backward-compatible addition).

## Deferred Actions

- (none)
