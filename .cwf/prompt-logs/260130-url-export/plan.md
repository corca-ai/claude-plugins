# Plan: url-export unified skill

## Background

Unify three individual export skills (g-export, slack-to-md, notion-to-md) under a single interface. Spec document: `url-export.md`

## Approach

SKILL.md-only architecture — no scripts, agent-level URL detection and delegation to existing skills.

### Files to Create

- `plugins/url-export/.claude-plugin/plugin.json`
- `plugins/url-export/skills/url-export/SKILL.md`

### Files to Modify

- `.claude-plugin/marketplace.json` — add url-export entry
- `README.md` — add to overview table + new section
- `AI_NATIVE_PRODUCT_TEAM.md` — add link in research tools section

## Success Criteria

```gherkin
Given url-export skill is installed
When user provides a Google Docs URL
Then agent delegates to g-export skill

Given url-export skill is installed
When user provides a Slack message URL
Then agent delegates to slack-to-md skill

Given url-export skill is installed
When user provides a Notion URL
Then agent delegates to notion-to-md skill

Given url-export skill is installed but the target skill is not installed
When user provides a supported service URL
Then agent shows installation instructions

Given url-export skill is installed
When user provides an unknown URL
Then agent falls back to WebFetch and saves as markdown
```

## Deferred Actions

- (none)
