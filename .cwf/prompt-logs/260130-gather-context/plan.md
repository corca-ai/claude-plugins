# Plan: Migrate url-export to gather-context

## Goal

Replace `url-export` (a router that delegates to separately installed skills) with `gather-context` (a self-contained plugin that bundles all converter scripts).

## Decision: Option B — Internalize scripts, keep web-search independent

- Bundle scripts from g-export, slack-to-md, notion-to-md directly into gather-context
- Keep web-search as a separate skill (different trigger, different purpose)
- Keep g-export, slack-to-md, notion-to-md as standalone skills (independent value)
- Remove url-export from marketplace entirely

## Success Criteria

```gherkin
Given a user installs only gather-context
When they provide a Google Docs / Slack / Notion URL
Then the bundled script runs without needing separate skill installations

Given url-export was previously in the marketplace
When a user updates the marketplace
Then url-export is no longer listed and gather-context is available
```

## Implementation

1. Create `plugins/gather-context/` with plugin.json, SKILL.md (<500 lines), references/, and copied scripts
2. Update marketplace.json (remove url-export, add gather-context, bump to 1.7.0)
3. Update CHANGELOG.md with [1.7.0] section
4. Delete `plugins/url-export/`
5. Update README.md, AI_NATIVE_PRODUCT_TEAM.md, docs/project-context.md

## Deferred Actions

- [ ] Hook observability improvement (discussed during plan mode — separate task)
