## Refactor Summary

### Scope
- Introduced concept-governance package and deterministic concept gate.
- Migrated core contract runtime defaults to YAML artifacts.
- Migrated refactor codebase-contract workflow from JSON default to YAML default.
- Added commit-boundary governance rule to concept/contract governance docs.

### Structural Outcomes
- New concept registry (`plugins/cwf/concepts/registry.yaml`) and checker execution path (`plugins/cwf/scripts/check-concepts.sh`).
- YAML contract set added under `plugins/cwf/contracts/*.yaml`.
- Refactor scripts now default to `.cwf/codebase-contract.yaml`.

### Validation Snapshot
- `check-concepts.sh --strict`: pass
- `check-portability-contract.sh --contract auto --context manual`: pass
- `check-change-impact.sh --working`: pass
- `check-claim-test-mapping.sh`: pass
- `check-codebase-contract-runtime.sh`: pass
- `scripts/check-schemas.sh --json`: pass

### Notes
- Legacy JSON contract files are not used by default runtime path after this refactor stage.

