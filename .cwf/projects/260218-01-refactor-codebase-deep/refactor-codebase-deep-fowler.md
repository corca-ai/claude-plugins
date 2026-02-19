# Martin Fowler Deep Refactor Review

Identity confirmation: assigned expert is **Martin Fowler** (`.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-experts.json`, `fixed[0]` and `selected[0]`).

## Top 3 concerns (blocking risks)

1. **`plugins/cwf/scripts/cwf-live-state.sh` is a God Script (1095 lines, scan error).**
   It mixes parsing, validation, state migration, gate transition checks, and CLI dispatch in one place. This is classic *Long Method/Large Class* pressure that creates **Divergent Change** risk: any new live-state rule likely touches the same file.

2. **Behavior duplication across logging/sync paths creates Shotgun Surgery risk.**
   `plugins/cwf/hooks/scripts/log-turn.sh` and `plugins/cwf/scripts/codex/sync-session-logs.sh` both implement overlapping live-session resolution/linking/time helpers (`extract_live_dir_value`, `resolve_live_session_dir`, `link_log_into_live_session`, `utc_to_epoch`, `utc_to_local`). Fixes will fragment unless extracted.

3. **Refactor gate reliability is reduced by monolithic checks plus truncated scan evidence.**
   `plugins/cwf/scripts/check-run-gate-artifacts.sh` is itself large (766 lines), while `plugins/cwf/skills/refactor/scripts/codebase-quick-scan.sh` intentionally truncates findings (`top_findings_limit: 30`) and the current scan reports `omitted_findings.warnings: 35` in `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-scan.json`.
   That means governance runs with incomplete detail when prioritization is most needed.

## Top 3 suggestions (high leverage)

1. **Extract duplicated session/live-state utilities into one shared shell library first.**
   Target shared code now duplicated in `plugins/cwf/hooks/scripts/log-turn.sh` and `plugins/cwf/scripts/codex/sync-session-logs.sh`; keep wrappers thin and behavior-compatible.

2. **Split `plugins/cwf/scripts/cwf-live-state.sh` by command seam, not by technical layer.**
   Carve into command-focused modules (`resolve/get/list-get`, `set/list-set/list-remove`, `journal-append`) behind a stable CLI adapter. This applies Fowler’s incremental refactoring style without big-bang rewrite.

3. **Make deep-review scans lossless (or fail fast when lossy).**
   In `plugins/cwf/skills/refactor/scripts/codebase-quick-scan.sh`, either raise/deactivate `top_findings_limit` for deep mode or fail when `omitted_findings.warnings > 0` so reviewers never reason from partial inventories.

## Prioritized first action

**First action:** extract and reuse the duplicated live-session helper functions between
`plugins/cwf/hooks/scripts/log-turn.sh` and `plugins/cwf/scripts/codex/sync-session-logs.sh`.

Why first: it is the safest high-impact move (small surface, immediate reduction of duplication/Shotgun Surgery), and it creates a clean foundation for the larger split of `plugins/cwf/scripts/cwf-live-state.sh`.

<!-- AGENT_COMPLETE -->
