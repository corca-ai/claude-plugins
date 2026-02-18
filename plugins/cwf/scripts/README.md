# Operational Script Map

This file maps scripts under [plugins/cwf/scripts](.).

- [check-session.sh](check-session.sh): Validates session artifacts and semantic closure checks.
- [check-growth-drift.sh](check-growth-drift.sh): Reports cross-surface drift across skills/docs/scripts/state/provenance, with optional strict hook regression execution via `--strict-hooks`.
- [test-hook-exit-codes.sh](test-hook-exit-codes.sh): Deterministic hook allow/block regression suite (`--suite`, `--strict`) with hooks-manifest driven target discovery.
- [check-script-deps.sh](check-script-deps.sh): Validates runtime script dependency edges from hooks manifest and script references.
- [check-readme-structure.sh](check-readme-structure.sh): Verifies heading-level structure parity between the root English and Korean README documents.
- [check-review-routing.sh](check-review-routing.sh): Validates review routing cutoff contract (`prompt_lines > 1200`) and deterministic fallback expectations.
- [check-shared-reference-conformance.sh](check-shared-reference-conformance.sh): Verifies shared output-persistence reference adoption across composing skills and duplication threshold.
- [check-run-gate-artifacts.sh](check-run-gate-artifacts.sh): Validates stage artifacts for `cwf:run` gate closure (`review-code`, `refactor`, `retro`, `ship`) with contract-driven stage/policy modes (session/project/explicit contract priority), and can append gate failures to `lessons.md`.
- [next-prompt-dir.sh](next-prompt-dir.sh): Computes next session directory name, with optional `--bootstrap` to initialize artifacts and register `cwf-state.yaml` session metadata.
- [cwf-artifact-paths.sh](cwf-artifact-paths.sh): Resolves artifact/state/projects paths with project-config precedence (.cwf-config.local.yaml → .cwf-config.yaml → env).
- [cwf-live-state.sh](cwf-live-state.sh): Resolves/syncs hybrid live-state files, reads live scalars/lists (`get`, `list-get`), updates top-level live fields (`set`, `list-set`, `list-remove`), and appends replay-safe decision entries (`journal-append`).
- [cwf-live-state-core.sh](cwf-live-state-core.sh): Core parsing/upsert helpers shared by `cwf-live-state` entrypoints.
- [cwf-live-state-journal.sh](cwf-live-state-journal.sh): Decision-journal and list-mutation helpers for `cwf-live-state`.
- [cwf-live-state-mutate.sh](cwf-live-state-mutate.sh): Sync/set/list-set mutation handlers for `cwf-live-state`.
- [detect-plugin-scope.sh](detect-plugin-scope.sh): Detects active Claude plugin scope (`user`/`project`/`local`) for a cwd with deterministic precedence.
- [retro-collect-evidence.sh](retro-collect-evidence.sh): Collects retro evidence snapshot (token-limit signals, HITL decisions/events, warning lines, changed-files context).
- [provenance-check.sh](provenance-check.sh): Verifies provenance sidecar freshness against current CWF skill/hook counts.
- [codex/codex-with-log.sh](codex/codex-with-log.sh): Wrapper entrypoint that runs Codex and syncs logs.
- [codex/post-run-checks.sh](codex/post-run-checks.sh): Post-run quality checks (changed files only) for markdown/shell/link/live-state gates plus tool-hygiene and HITL scratchpad sync guards.
- [codex/install-wrapper.sh](codex/install-wrapper.sh): Installs, checks, or disables a Codex wrapper for `user`/`project`/`local` scopes.
- [codex/sync-skills.sh](codex/sync-skills.sh): Symlinks CWF skills/references into Codex scope-specific destinations.
- [codex/verify-skill-links.sh](codex/verify-skill-links.sh): Verifies linked skill references resolve correctly.
- [codex/sync-session-logs.sh](codex/sync-session-logs.sh): Exports session logs into repository project artifacts.
- [codex/redact-session-logs.sh](codex/redact-session-logs.sh): Batch-redacts existing markdown session logs.
- [codex/redact-jsonl.sh](codex/redact-jsonl.sh): Redacts JSONL logs.
- [codex/redact-sensitive.pl](codex/redact-sensitive.pl): Core sensitive-token redaction engine.
