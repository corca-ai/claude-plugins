# Plan — S21 Env Loader + External Reviewer Routing

## Objective
Reduce Claude-specific env coupling by introducing a shared profile-first loader with legacy compatibility, and make `/review` external slots provider-flexible across Codex/Gemini/Claude fallback.

## Scope
1. Add shared shell env loader and migrate scripts to use it.
2. Align docs to profile-first policy with `~/.claude/.env` as legacy fallback.
3. Update `/review` skill spec to support slot-level provider routing (`auto|codex|gemini|claude`).
4. Validate script syntax and loader behavior with smoke tests.

## Success Criteria
- [x] Hook/gather shell scripts no longer duplicate env-loading logic.
- [x] Loader precedence is `process env -> shell profiles -> ~/.claude/.env`.
- [x] Backward compatibility with `~/.claude/.env` is preserved.
- [x] `/review` spec documents provider-flexible external routing for both slots.
- [x] `bash -n` and `node --check` pass for changed runtime scripts.
