# Kent Beck Deep Refactor Review

Assigned identity confirmed: Kent Beck (`.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-experts.json`, `selected`).

Framework lens: small safe refactorings, Tidy First sequencing, and behavior preservation (Kent Beck, *Tidy First?*; *Test-Driven Development: By Example*).

## Top 3 concerns (blocking risks)
1. `plugins/cwf/scripts/cwf-live-state.sh` is at error-level size (1095 lines). It combines parsing, persistence, gate transition checks, and command dispatch in one place, so a small change has a wide regression radius.
2. Critical run-path scripts are oversized and tightly coupled: `plugins/cwf/scripts/check-run-gate-artifacts.sh` (766 lines), `plugins/cwf/scripts/codex/sync-session-logs.sh` (781 lines), and `plugins/cwf/hooks/scripts/log-turn.sh` (751 lines). These files sit on workflow correctness paths, so failures propagate across stages.
3. Dense long-line hotspots reduce safe micro-refactoring in guard logic, especially `plugins/cwf/hooks/scripts/redirect-websearch.sh` (line 14, 283 chars), `plugins/cwf/scripts/check-growth-drift.sh` (line 163, 297 chars), and `plugins/cwf/hooks/scripts/workflow-gate.sh` (line 15, 191 chars).

## Top 3 suggestions (high leverage)
1. Do a Tidy First split of `plugins/cwf/scripts/cwf-live-state.sh`: extract pure helper functions (trim/path/yaml scalar-list transforms) into a sourced library while keeping CLI behavior unchanged.
2. Break `plugins/cwf/scripts/check-run-gate-artifacts.sh` into stage modules (`review-code`, `refactor`, `retro`, `ship`) and keep the main script focused on argument parsing, policy mode handling, and summary output.
3. Refactor long-line hotspots first by extracting named variables/functions at `plugins/cwf/hooks/scripts/redirect-websearch.sh:14`, `plugins/cwf/scripts/check-growth-drift.sh:163`, and `plugins/cwf/hooks/scripts/workflow-gate.sh:15`; keep each conditional step independently readable.

## Prioritized first action
Create the first seam in `plugins/cwf/scripts/cwf-live-state.sh` by extracting only read-only flows (`resolve`, `get`, `list-get`) into a sourced module, then run existing run-gate checks before any write-path split.
<!-- AGENT_COMPLETE -->
