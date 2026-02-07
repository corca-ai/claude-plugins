# Plugin Deploy Checklist

Detailed reference for edge cases. SKILL.md handles the main flow; consult this for specifics.

For version bump rules, marketplace.json format, and deploy workflow, see [plugin-dev-cheatsheet.md](../../../../docs/plugin-dev-cheatsheet.md).

## New Plugin Checklist

- [ ] `plugins/{name}/` directory with correct structure
- [ ] `.claude-plugin/plugin.json` with name, description, version, author, repository
- [ ] SKILL.md (skill) or hooks.json (hook) or both (hybrid)
- [ ] marketplace.json entry added
- [ ] README.md: add to overview table + detail section under Skills or Hooks
- [ ] README.ko.md: same structure, Korean translation
- [ ] AI_NATIVE_PRODUCT_TEAM.md: add link if plugin fits an existing category

## Modified Plugin Checklist

- [ ] Version bumped in plugin.json
- [ ] marketplace.json description synced
- [ ] README.md and README.ko.md descriptions still accurate
- [ ] No breaking changes without major version bump

## README Format Reference

### Overview table row

```markdown
| [{name}](#{name}) | {Skill|Hook|Skill + Hook} | {Short description} |
```

### Detail section

```markdown
### [{name}](plugins/{name}/skills/{name}/SKILL.md)

**Install**:
\```bash
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git
claude plugin install {name}@corca-plugins
\```

**Update**:
\```bash
claude plugin marketplace update corca-plugins
claude plugin update {name}@corca-plugins
\```

{Description paragraph}

**Usage**: ...
**Key features**: ...
```

## Deprecation Checklist

When a plugin is deprecated:

- [ ] Set `"deprecated": true` in `plugin.json`
- [ ] Remove entry from `marketplace.json`
- [ ] Clear local plugin cache: `claude plugin uninstall {name}@corca-plugins`
- [ ] Update README.md / README.ko.md — remove from overview table and detail section
- [ ] Commit with message: `chore: deprecate {name} plugin`

## Markdown Quality

- When adding code blocks to README or other markdown files, always include a language specifier on code fences (`bash`, `json`, `text`, `yaml`, etc.). Never use bare `` ``` ``.

## Edge Cases

- **Plugin with scripts but no SKILL.md/hooks.json**: invalid — needs entry point
- **Plugin renamed**: treat as new plugin + deprecate old
- **marketplace.json has no version field for plugin**: OK, version lives in plugin.json
- **README section order**: Skills come before Hooks, within each group maintain existing order
