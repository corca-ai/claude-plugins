# Lessons — S14 Integration Test

### compact-context.sh decisions field leak

- **Expected**: `decisions:` list items in cwf-state.yaml parsed separately
  from `key_files`
- **Actual**: YAML parser had no handler for `decisions:` field, so
  `current_list` remained `key_files` and decision items leaked into
  key_files output
- **Takeaway**: When adding new list fields to cwf-state.yaml, the
  compact-context.sh YAML parser must be updated in parallel. The parser
  is hand-rolled (no yq dependency) so new fields require explicit handlers.

### compact-context.sh quote stripping inconsistency

- **Expected**: All scalar YAML fields strip surrounding quotes consistently
- **Actual**: `session_id` and `task` used `\"?([^\"]*)\"?` pattern but
  `dir`, `branch`, `phase` used `(.+)` — retaining literal quotes. This
  caused plan.md path lookup to fail silently during impl-phase enrichment.
- **Takeaway**: When a hand-rolled parser handles the same data type
  differently across fields, the inconsistency will eventually cause a bug.
  Apply the same extraction pattern to all fields of the same type.

### Static verification as integration test substitute

- **Expected**: Full E2E test by running cwf:run on a real task
- **Actual**: Running cwf:run recursively within a session is impractical
  (context explosion). Static verification of SKILL.md logic by dedicated
  Explore agents was effective — all 5 CDM items, 7 run logic checks,
  6 fail-fast checks, and 28 cross-references verified with specific
  line numbers.
- **Takeaway**: For skill-based systems, static verification of the
  specification (SKILL.md) is a viable integration test strategy. The
  specification IS the implementation for LLM-driven skills.

### Web Research Protocol fixed 404s but exposed WebFetch tool limits

- **Expected**: Web Research Protocol (S33) + sub-agent prompt improvement
  would raise web research success rate substantially
- **Actual**: Replayed S33 Deming expert scenario. 404 count dropped
  from many (S33) to **0** — protocol worked. But overall success rate
  was 9% (1/11 URLs). Failure breakdown: JS-rendered pages returning
  empty content (5), 403 Forbidden (2), redirect chains (3). Only
  Britannica returned usable content.
- **Root cause**: WebFetch is an HTTP GET + HTML-to-markdown tool. It
  cannot execute JavaScript. Modern sites (deming.org, Amazon, WorldCat,
  Google Books) render content client-side → WebFetch gets empty shells.
- **Takeaway**: The 404 problem and the JS rendering problem are distinct.
  Protocol fixed the former. The latter requires a real browser engine.
  agent-browser (headless Chromium CLI) is the right tool — it renders JS,
  handles redirects, and returns accessibility tree or text content.

### Agent team vs sub-agent for web research: wrong framing

- **Expected**: Switching from sub-agents to agent teams (which have skill
  access including cwf:gather) would improve web research quality
- **Actual**: Investigation showed the capability gap (sub-agents lack
  skills) is real but irrelevant to the failure mode. Both sub-agents and
  agent team members use the same WebFetch tool — both hit the same JS
  rendering wall. cwf:gather adds URL routing intelligence but uses
  WebFetch underneath.
- **Takeaway**: Match the solution to the actual failure mode. The answer
  to "WebFetch can't render JS" is a better fetch tool, not a different
  agent architecture. Diagnose before prescribing.
