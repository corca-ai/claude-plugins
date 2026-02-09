## Architecture Review

### Concerns (blocking)
- **[C1]** The `provenance-check.sh` script uses `grep` and `sed` to parse `.provenance.yaml` files. While this avoids a new dependency like `yq`, the parsing logic is brittle and assumes a very simple `key: value` format without quotes, comments, or other YAML features. This creates a maintainability risk: if the provenance file format ever needs to evolve (e.g., for values containing special characters), the script will fail silently or in unexpected ways.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** The commit bundles two distinct features: the provenance system and the propagation of unresolved items in the `handoff` skill. Both contribute to the goal of preventing context loss, but they are architecturally separate. In the future, separating mechanically unrelated changes into distinct commits would improve clarity and make the repository history easier to trace.

### Behavioral Criteria Assessment
- [x] **All 6 provenance sidecar files exist and report FRESH with exit code 0** — The commit introduces 6 `.provenance.yaml` files with counts (`skill_count: 9`, `hook_count: 13`) that match the expected system state at the time of the commit, ensuring `provenance-check.sh` passes.
- [x] **Artificially stale provenance (skill_count: 5) reports STALE with correct delta message** — The logic in `provenance-check.sh` correctly calculates the delta between recorded and current counts and formats a "reasons" string (e.g., `skills: 5 → 9 (+4)`), which is then included in the "STALE" output.
- [x] **Refactor holistic mode checks provenance before loading criteria, warns user if different** — The `refactor` skill (`SKILL.md`) is explicitly updated with a "1b. Provenance Check" phase that requires comparing counts and using `AskUserQuestion` to warn the user if a discrepancy is found.
- [x] **skill-conventions.md has formal Provenance Rule (not "Future Consideration")** — The section "Future Consideration: Self-Healing Criteria" has been promoted to a formal specification under "Provenance Rule: Self-Healing Criteria", defining the pattern for the project.

### Provenance
source: REAL_EXECUTION
tool: gemini
reviewer: Architecture
duration_ms: —
command: —
