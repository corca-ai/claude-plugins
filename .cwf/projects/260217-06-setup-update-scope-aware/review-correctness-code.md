## Correctness Review (Code)

### Findings
- `sync-skills.sh` resolves destination by scope and validates scope enum.
- `install-wrapper.sh` resolves scope paths deterministically and reports active state by scope.
- `detect-plugin-scope.sh` returns deterministic active scope with documented precedence.
- Modified markdown files pass markdownlint and link/doc-graph checks.

<!-- AGENT_COMPLETE -->
