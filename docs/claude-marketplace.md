# Marketplace Reference

For full marketplace documentation (creating, hosting, distributing, troubleshooting), see the [official Claude Code docs](https://code.claude.com/docs/en/plugin-marketplaces).

## This Project's marketplace.json

Location: `.claude-plugin/marketplace.json`

### Plugin Entry Format

```json
{
  "name": "{name}",
  "source": "./plugins/{name}",
  "description": "A {skill|hook} that ...",
  "keywords": ["keyword1", "keyword2"]
}
```

### Key Rules

- `name`: kebab-case, matches the plugin directory name
- `source`: relative path to the plugin directory (always `./plugins/{name}`)
- `description`: should match `plugin.json` description
- `keywords`: for discovery and categorization

### Plugin Caching

Plugins are copied to a cache location on install. Files outside the plugin directory (e.g., `../shared-utils`) won't be available. Use `${CLAUDE_PLUGIN_ROOT}` in hooks and MCP configs to reference files within the installed plugin.

### User Commands

```bash
# Add marketplace
/plugin marketplace add corca-ai/claude-plugins

# Update marketplace catalog
/plugin marketplace update

# Install/update a plugin
/plugin install {name}@corca-plugins
/plugin update {name}@corca-plugins
```
