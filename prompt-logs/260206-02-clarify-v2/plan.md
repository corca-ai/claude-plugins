# Clarify v2 — Unified Requirement Clarification

> Merges clarify (v1) + deep-clarify + interview into a single plugin.

## Steps

- [x] Create prompt-logs session dir + plan.md + lessons.md
- [x] Write aggregation-guide.md (port from deep-clarify)
- [x] Write advisory-guide.md (port from deep-clarify)
- [x] Write research-guide.md (merge deep-clarify's two guides)
- [x] Write questioning-guide.md (new: from interview + clarify v1)
- [x] Write SKILL.md v2 (main skill file)
- [x] Update plugin.json (version 2.0.0)
- [x] Update marketplace.json (deprecate deep-clarify + interview)
- [x] Update README.md + README.ko.md

## Key Decisions

- Default mode: Research-first → Tier classification → Persistent questioning
- --light mode: Direct Q&A (old clarify behavior)
- gather-context integration: Defensive (check availability)
- Sub-agent count: Max 4 (2 researchers + 2 advisors)
