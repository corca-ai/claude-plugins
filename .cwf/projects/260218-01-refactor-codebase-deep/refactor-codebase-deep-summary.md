# Refactor Codebase Deep Summary

- Mode: `cwf:refactor --codebase --deep`
- Contract: `.cwf/codebase-contract.json`
- Scan source: `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-scan.json`
- Expert selection source: `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-experts.json`

## Experts Used

Fixed experts (mandatory):
1. Martin Fowler
2. Kent Beck

Context experts (contract-driven selection):
1. David Parnas
2. John Ousterhout

## Scan Baseline

- Findings: 1 error, 65 warnings
- Top classes:
  - `long_line_length`: 26 warnings
  - `large_file_lines`: 15 warnings, 1 error
  - `todo_markers`: 15 warnings
  - `shell_strict_mode`: 9 warnings
- Highest severity target:
  - `plugins/cwf/scripts/cwf-live-state.sh` (1097 lines)

## Convergent Findings (High Agreement)

1. Core control scripts remain monolithic and costly to change.
2. Session/log helper duplication is still a major shotgun-surgery risk.
3. Safer decomposition needs characterization tests and explicit module seams first.

## Productive Tensions (Useful Disagreement)

1. First move priority:
   - Fowler/Beck: immediate tidy-size extraction.
   - Parnas/Ousterhout: stronger module boundary definition first.
2. Primary leverage point:
   - Fowler/Beck: behavior-preserving small refactors in hot scripts.
   - Parnas/Ousterhout: interface/dependency contracts before broad splitting.

## Prioritized Action Plan

P0:
1. Add characterization tests for `plugins/cwf/scripts/cwf-live-state.sh` command behavior.
2. Extract duplicated session/log helper functions into one shared module.

P1:
1. Split `plugins/cwf/scripts/cwf-live-state.sh` by command responsibility with stable CLI.
2. Decompose `plugins/cwf/scripts/check-run-gate-artifacts.sh` into stage-level validators.

P2:
1. Add trend checks for multi-signal hotspots (size + long-line + TODO density).
2. Tighten shell strict-mode rollout using contract-level include/exclude policy.

## Referenced Expert Outputs

- `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-deep-fowler.md`
- `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-deep-beck.md`
- `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-deep-context-1.md`
- `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-deep-context-2.md`

<!-- AGENT_COMPLETE -->
