# S2: Refactor Convention Alignment — Plan

## Tasks

- [x] 1a. Update `.markdownlint-cli2.jsonc` — add `references/anthropic-skills-guide/` to ignores
- [x] 1b. ~~Fix bare code fences across 22 files~~ — all files already had specifiers; "93 fences" were closing fences (correct as-is)
- [x] 2. Env var migration: `CLAUDE_ATTENTION_*` → `CLAUDE_CORCA_ATTENTION_*` with backward-compat shim
- [x] 3. Description sync: marketplace.json ← plugin.json for attention-hook, smart-read
- [x] 4. project-context.md version sync and S1 convention reference
- [x] 5. README review — no content issues (fence fixes were unnecessary)
- [x] 6. Run markdownlint validation — 0 errors across 37 files
- [x] 7. `/plugin-deploy` for attention-hook — 0 gaps, 48/48 tests passed
- [x] 8. Commit, push, `bash scripts/update-all.sh` — 9/9 plugins updated
