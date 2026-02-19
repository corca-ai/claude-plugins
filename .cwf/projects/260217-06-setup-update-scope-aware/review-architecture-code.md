## Architecture Review (Code)

### Findings
- Scope detection is centralized in `detect-plugin-scope.sh`, reducing duplicated logic.
- Setup/update policy is now aligned with script surface (`--scope`, `--project-root`).
- Reconciliation behavior is documented at update-contract level to handle cache-version drift.

<!-- AGENT_COMPLETE -->
