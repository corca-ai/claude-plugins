## Correctness Review

### Concerns (blocking)
No blocking concerns identified.

### Suggestions (non-blocking)
No suggestions.

### Behavioral Criteria Assessment
- [x] `check-session --live` passes — `plugins/cwf/scripts/check-session.sh:21-167` now sources the plugin-local resolvers and, when invoked with `--live`, iterates the `live` block, rejecting the command if any of `session_id`, `dir`, `phase`, or `task` is empty before returning success, which keeps the live-state gate intact.
- [x] Session log file generated under `.cwf/sessions/` (legacy alias preserved) — `plugins/cwf/scripts/codex/sync-session-logs.sh:33-48` feeds `resolve_cwf_session_logs_dir("$PWD")`, and `plugins/cwf/scripts/cwf-artifact-paths.sh:121-149` prefers `$artifact_root/sessions` while falling back to the legacy `$projects/sessions` when the modern folder is absent, so logs continue to land under `.cwf/sessions` with the alias preserved.
- [x] Session baseline artifacts are complete — `plugins/cwf/scripts/check-session.sh:385-600` resolves the applicable artifact list (explicit session entry or `session_defaults`), then checks that every artifact file exists and is non-empty, failing the command when any required baseline artifact is missing.

### Provenance
source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness
duration_ms: —
command: —

<!-- AGENT_COMPLETE -->
