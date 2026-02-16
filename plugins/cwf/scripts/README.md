# Operational Script Map

This file maps scripts under [plugins/cwf/scripts](.).

- [check-session.sh](check-session.sh): Validates session artifacts and semantic closure checks.
- [next-prompt-dir.sh](next-prompt-dir.sh): Computes next session directory name.
- [cwf-artifact-paths.sh](cwf-artifact-paths.sh): Resolves artifact/state/projects paths with project-config precedence (.cwf/config.local.yaml → .cwf/config.yaml → env).
- [codex/codex-with-log.sh](codex/codex-with-log.sh): Wrapper entrypoint that runs Codex and syncs logs.
- [codex/install-wrapper.sh](codex/install-wrapper.sh): Installs, checks, or disables the Codex wrapper.
- [codex/sync-skills.sh](codex/sync-skills.sh): Symlinks CWF skills/references into Codex user scope.
- [codex/verify-skill-links.sh](codex/verify-skill-links.sh): Verifies linked skill references resolve correctly.
- [codex/sync-session-logs.sh](codex/sync-session-logs.sh): Exports session logs into repository project artifacts.
- [codex/redact-session-logs.sh](codex/redact-session-logs.sh): Batch-redacts existing markdown session logs.
- [codex/redact-jsonl.sh](codex/redact-jsonl.sh): Redacts JSONL logs.
- [codex/redact-sensitive.pl](codex/redact-sensitive.pl): Core sensitive-token redaction engine.
