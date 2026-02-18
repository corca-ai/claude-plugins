# Lessons — run-portability-contract-hardening

- Portable-vs-authoring contract split must be plugin-local to avoid host-repo path coupling.
- Running unified gate in hooks for all repos is safe only when `auto` reliably resolves to a host-safe portable profile.
- Fixture regressions must pass markdownlint before reaching deeper policy checks; otherwise intent-specific assertions can produce false negatives.
- Deterministic IDs (claim/test/rule) belong in contracts, not user-facing README or high-level SKILL flow prose.

## Run Gate Violation — 2026-02-18T07:08:17Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Recorded failures:
  - [ship] run-stage-provenance.md must include at least one data row
