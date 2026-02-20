# Lessons — scenario-dashboard-html

## Dashboard parsing strategy

- **Expected**: One source file would contain all scenario verdicts.
- **Actual**: Results are distributed across `master-scenarios.md`, per-scenario docs, and artifact links.
- **Takeaway**: Use master table as index, then hydrate details from scenario markdown.

When generating unified visualization from CWF project artifacts -> parse iteration master tables first, then join per-scenario markdown sections.

## Browser smoke for static HTML

- **Expected**: CLI-level generation checks would be enough.
- **Actual**: Interactive behavior needed runtime verification (filters/search/detail panel).
- **Takeaway**: Keep one screenshot + explicit interaction checks with `agent-browser`.

When shipping a static interactive report -> include browser-level smoke evidence, not only generator stdout.

## cwf:review non-interactive constraint

- **Expected**: `cwf:review --mode code` would return in non-interactive `claude --print`.
- **Actual**: both direct and provider-forced runs timed out (`exit=124`) with empty output.
- **Takeaway**: record review invocation evidence as runtime limitation and avoid silently claiming review completion.

When `cwf:review` is requested in non-interactive environment -> run explicit timed attempts, preserve logs/exit codes, and report limitation transparently.
