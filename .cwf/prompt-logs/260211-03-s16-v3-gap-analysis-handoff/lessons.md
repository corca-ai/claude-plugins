# Lessons: S16 — Handoff Design for Exhaustive V3 Analysis

### Scope anchor must be explicit

- **Observation**: "v3 sessions" can mean either `cwf-state.yaml` sessions only or
  all records after the v3 kickoff commit.
- **Decision**: Anchor analysis scope to `42d2cd9..HEAD` for record collection,
  then map to v3 milestones.
- **Takeaway**: Use git-range anchors to avoid semantic drift in session scope.

### `session.md` is convenience, not completeness

- **Observation**: Many directories include `session.md`, but not all relevant
  records depend on it.
- **Decision**: Treat `session.md` as optional pointer. Primary corpus comes
  from git-range file listing and `prompt-logs/sessions*.md`.
- **Takeaway**: Coverage should be source-driven, not link-driven.

### Omission resistance requires preserving uncertainty

- **Observation**: Some deferred or discussed items may be unresolved or
  superseded without explicit closure.
- **Decision**: Keep an explicit `Unknown` state instead of forcing binary
  resolved/unresolved classification.
- **Takeaway**: "Unknown" is a valid result and a key anti-omission mechanism.
