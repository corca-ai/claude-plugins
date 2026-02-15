# Next Session — S22 Follow-up

## Recommended focus
1. Add deterministic checks to prevent env-loading regression (e.g., grep-based check for direct `source ~/.claude/.env` in runtime scripts outside shared loader).
2. Run a real `/review` dry-run to validate provider-routing instructions in practice (auto + explicit provider overrides).

## Open risk
- `/review` skill remains instruction-driven (not executable code). Consistency still depends on agent compliance; an executable wrapper would further reduce drift.
