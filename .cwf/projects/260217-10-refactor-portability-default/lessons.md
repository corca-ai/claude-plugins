# Lessons — refactor-portability-default

- Initialized by `next-prompt-dir --bootstrap`
- Treat portability as a default review axis in `refactor` criteria and flow docs; avoid adding optional flags for baseline quality concerns.
- When adding repository-local contracts, ensure procedure docs and script outputs are symmetric (same statuses/fields such as `fallback`, warning metadata, and skipped-check semantics).
- For plugin docs under `plugins/cwf`, resolve markdown lint custom-rule interactions early (`CORCA001` inline path literals vs `CORCA004` plugin-root link boundary) to avoid two-step rework.
- Keep plugin lifecycle checks in-loop for skill/script changes: run plugin consistency check, codex skill sync, and final deterministic gates before closure.
- Portability follow-up across non-refactor skills should prioritize context detection and graceful fallback over repository-name/path assumptions (base branch, AGENTS-managed index target, cache roots).
- Docs-contract behavior should be protected by an executable runtime check script, not manual one-off verification.
- Execution-contract commit gate may conflict with plugin-deploy rule (`never auto-commit`); treat commit boundaries as explicit user decision points.
