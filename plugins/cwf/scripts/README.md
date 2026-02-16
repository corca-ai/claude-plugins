# Operational Script Map

This file maps scripts under [plugins/cwf/scripts](.).

- [check-session.sh](check-session.sh): Validates session artifacts and semantic closure checks.
- [check-growth-drift.sh](check-growth-drift.sh): Reports cross-surface drift across skills/docs/scripts/state/provenance.
- [next-prompt-dir.sh](next-prompt-dir.sh): Computes next session directory name, with optional `--bootstrap` to initialize artifacts and register `cwf-state.yaml` session metadata.
- [cwf-artifact-paths.sh](cwf-artifact-paths.sh): Resolves artifact/state/projects paths with project-config precedence (.cwf/config.local.yaml → .cwf/config.yaml → env).
- [cwf-live-state.sh](cwf-live-state.sh): Resolves/syncs hybrid live-state files and updates top-level live scalars with session-first writes plus root-summary sync (`resolve`, `sync`, `set key=value`).
- [retro-collect-evidence.sh](retro-collect-evidence.sh): Collects retro evidence snapshot (token-limit signals, HITL decisions/events, warning lines, changed-files context).
- [provenance-check.sh](provenance-check.sh): Verifies provenance sidecar freshness against current CWF skill/hook counts.
- [codex/codex-with-log.sh](codex/codex-with-log.sh): Wrapper entrypoint that runs Codex and syncs logs.
- [codex/post-run-checks.sh](codex/post-run-checks.sh): Post-run quality checks (changed files only) for markdown/shell/link/live-state gates plus tool-hygiene and HITL scratchpad sync guards.
- [codex/install-wrapper.sh](codex/install-wrapper.sh): Installs, checks, or disables the Codex wrapper.
- [codex/sync-skills.sh](codex/sync-skills.sh): Symlinks CWF skills/references into Codex user scope.
- [codex/verify-skill-links.sh](codex/verify-skill-links.sh): Verifies linked skill references resolve correctly.
- [codex/sync-session-logs.sh](codex/sync-session-logs.sh): Exports session logs into repository project artifacts.
- [codex/redact-session-logs.sh](codex/redact-session-logs.sh): Batch-redacts existing markdown session logs.
- [codex/redact-jsonl.sh](codex/redact-jsonl.sh): Redacts JSONL logs.
- [codex/redact-sensitive.pl](codex/redact-sensitive.pl): Core sensitive-token redaction engine.
