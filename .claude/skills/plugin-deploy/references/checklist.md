# Plugin Deploy Checklist

Detailed reference for edge cases. SKILL.md handles the main flow; consult this for specifics.

## New Plugin Checklist

- [ ] `plugins/{name}/` directory with correct structure
- [ ] `.claude-plugin/plugin.json` with name, description, version, author, repository
- [ ] SKILL.md (skill) or hooks.json (hook) or both (hybrid)
- [ ] marketplace.json entry: name, source (`./plugins/{name}`), description, keywords
- [ ] README.md: add to overview table + detail section under Skills or Hooks
- [ ] README.ko.md: same structure, Korean translation
- [ ] AI_NATIVE_PRODUCT_TEAM.md: add link if plugin fits an existing category

## Modified Plugin Checklist

- [ ] Version bumped in plugin.json
- [ ] marketplace.json version/description synced (if version is tracked there)
- [ ] README.md and README.ko.md descriptions still accurate
- [ ] No breaking changes without major version bump

## Version Bump Rules

| Change type | Bump | Examples |
|------------|------|---------|
| Bug fix, typo, minor tweak | patch | Fix script error, update wording |
| New feature, new flag, new capability | minor | Add --deep flag, new subcommand |
| Breaking change, renamed skill, changed API | major | Rename /search → /web-search |

## README Format Reference

### Overview table row

```markdown
| [{name}](#{name}) | {Skill\|Hook\|Skill + Hook} | {Short description} |
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

## marketplace.json Entry Format

```json
{
  "name": "{name}",
  "source": "./plugins/{name}",
  "description": "A {skill|hook} that ...",
  "keywords": ["keyword1", "keyword2"]
}
```

## Edge Cases

- **Plugin with scripts but no SKILL.md/hooks.json**: invalid — needs entry point
- **Plugin renamed**: treat as new plugin + deprecate old
- **marketplace.json has no version field for plugin**: some entries omit version — that's OK, version lives in plugin.json
- **README section order**: Skills come before Hooks, within each group maintain existing order
