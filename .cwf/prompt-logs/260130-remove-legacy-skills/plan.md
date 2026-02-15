# Plan: Remove Legacy Individual Skills

## Context

`gather-context` (v1.0.0) bundles all converter scripts from `g-export`, `slack-to-md`, and `notion-to-md`. The three individual skills are now redundant — same scripts exist in two places, creating maintenance burden. User base is small, so breaking change impact is minimal.

## Success Criteria

```gherkin
Given the marketplace is updated
When a user runs `claude plugin marketplace update corca-plugins`
Then g-export, slack-to-md, notion-to-md are no longer listed as available plugins

Given a user visits the README
When they look for g-export, slack-to-md, or notion-to-md
Then they find a "삭제된 스킬" section at the bottom explaining migration to gather-context

Given gather-context is installed
When a user provides a Google/Slack/Notion URL
Then the functionality works identically (scripts are bundled)
```

## Changes

### 1. Delete plugin directories

- `plugins/g-export/` (entire directory)
- `plugins/slack-to-md/` (entire directory)
- `plugins/notion-to-md/` (entire directory)

### 2. `.claude-plugin/marketplace.json`

Remove three entries from `plugins` array:
- `slack-to-md` (lines 19-23)
- `g-export` (lines 37-41)
- `notion-to-md` (lines 49-53)

### 3. `README.md`

- Remove 3 rows from overview table (lines 38-40: g-export, slack-to-md, notion-to-md)
- Remove g-export section (lines 105-142)
- Remove notion-to-md section (lines 143-179)
- Remove slack-to-md section (lines 180-214)
- Update gather-context "참고" section (line 309): remove note about individual skills being available
- Add "삭제된 스킬" section before "라이선스" explaining:
  - These skills were removed in v1.8.0
  - Functionality is now in gather-context
  - Migration: `claude plugin install gather-context@corca-plugins`

### 4. `CHANGELOG.md`

Add `[1.8.0]` entry:
- Removed: `g-export`, `slack-to-md`, `notion-to-md` — replaced by `gather-context`

### 5. `docs/project-context.md`

Line 8: Remove g-export, slack-to-md, notion-to-md from the skills list.

### 6. `docs/adding-plugin.md`

Line 32: Replace `slack-to-md` example with `gather-context`.

## Verification

1. `ls plugins/` — confirm g-export, slack-to-md, notion-to-md are gone
2. Validate marketplace.json is valid JSON: `python3 -m json.tool .claude-plugin/marketplace.json`
3. Check no broken internal links remain: grep for `g-export`, `slack-to-md`, `notion-to-md` across docs and README (prompt-logs/ excluded)

## Deferred Actions

_(none)_
