# Lessons — S15 Agent-Browser Integration

### Inline protocol duplication vs shared reference

- **Expected**: Sub-agent prompts would already reference agent-patterns.md
  Web Research Protocol
- **Actual**: clarify and plan had inline web research rules duplicating
  (and outdating) the protocol. retro and review had no protocol reference
  at all for their web-searching sub-agents.
- **Takeaway**: When a shared protocol exists, sub-agent prompts should
  reference it by path rather than inlining rules. Inline rules drift out
  of sync when the protocol is updated (as happened with the S14 two-tier
  update — agent-patterns.md was updated but sub-agent prompts still had
  WebFetch-only rules).

### WebFetch vs agent-browser on JS-rendered sites

- **Expected**: WebFetch might return partial content from deming.org
- **Actual**: WebFetch returns only minified JS/CSS bundles — zero readable
  content. agent-browser returns full page with navigation, headings, and
  body text via accessibility tree snapshot.
- **Takeaway**: The two-tier strategy (WebFetch first → agent-browser
  fallback) is correct. WebFetch is not "partial" on JS sites — it is
  completely empty. The <50 chars threshold in the protocol is appropriate.
