## Architecture Review
### Concerns (blocking)
- **[C1]** Markdown hook silently bails when `markdownlint-cli2` is missing, so doc quality enforcement disappears on hosts lacking that binary (the hook simply exits 0 at `plugins/cwf/hooks/scripts/check-markdown.sh:150-205`).
  Severity: moderate
- **[C2]** `sync-skills.sh` now only links from the current plugin root (`plugins/cwf/scripts/codex/sync-skills.sh:17-189`) and no longer knows about `CODEX_HOME_LEGACY`/`LEGACY_SKILLS_DIR` or `--cleanup-legacy` (see the systemic audit notes in `refactor-summary.md:40-44`). Upgrading pre-v3 installs leaves the old `~/.codex/skills/*` entries untouched, so Codex may keep loading stale copies or fail in the presence of the legacy layout; there is no migration path or user warning, which undermines the repo-agnostic portability promise.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** Make `check-markdown` report missing tooling (log a warning, add a state flag, or exit non-zero) and include `markdownlint-cli2` installation in the setup-contract/runtime report so the docs gate cannot be silently skipped when the binary is absent (`repo-agnostic-audit.md:17-29` already flagged this fail-open behavior).
- **[S2]** Preserve a legacy-skill cleanup step (reintroduce an opt-in `--cleanup-legacy`/`LEGACY_SKILLS_DIR` pass or at least warn/move the old entries before linking new ones) so upgrades remove the stale `~/.codex/skills` artifacts instead of letting Codex keep resolving them.

### Behavioral Criteria Assessment
- [ ] All actionable codebase/deep/docs findings fixed or explicitly deferred with rationale (`repo-agnostic-audit.md:17-29` still calls out the markdown-hook dependency gap with no fix recorded in this diff).
- [x] Every skill deep review finding resolved or explicitly deferred with evidence (`refactor-summary.md:5-52` lists skill fixes and a single deferred compiled artifact).
- [x] Docs deterministic checks pass for modified scope (`refactor-summary.md:31-38` shows `markdownlint`, link check, and `doc-graph` all passed).
- [x] README/README.ko SoT and portability claims map to concrete behavior without repo-specific hard dependency (`sot-conformance-audit.md:1-40` verifies each claim against enforcing skills/hooks).
- [x] Review/retro artifacts exist and run-gates passable (the session directory now contains `review-correctness-code.md`, `review-security-code.md`, `review-ux-dx-code.md`, and `retro.md`, and `refactor-summary.md:59-67` lists the validation commands that passed).

### Provenance
source: FALLBACK
tool: claude-task-fallback
reviewer: Architecture
duration_ms: —
command: —
<!-- AGENT_COMPLETE -->
