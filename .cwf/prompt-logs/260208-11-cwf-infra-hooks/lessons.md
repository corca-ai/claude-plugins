# S6a Lessons

## Migration Pattern

- CWF stubs keep: shebang, set -euo pipefail, comment, HOOK_GROUP, gate source
- Source logic starts after the source's shebang/pipefail/comment block
- Don't duplicate `set -euo pipefail` (already in stub header)
- For log-turn: `$1` arg (HOOK_TYPE) must come after gate source but before `cat` (stdin consumption)
- Gate exit happens at source time — if disabled, script exits before any stdin read

## Verification Strategy

- Byte-level diff of migrated logic vs source ensures no accidental modifications
- Gate tests require creating/removing `~/.claude/cwf-hooks-enabled.sh` — clean up after
- Smoke tests: pipe minimal JSON via stdin, check exit code
- hooks.json is read-only verification — no changes needed since S4 scaffolded it correctly

## hooks.json Confirmation

- check-markdown: PostToolUse, matcher `Write|Edit`, sync — matches markdown-guard
- smart-read: PreToolUse, matcher `Read`, sync — matches smart-read plugin
- log-turn: Stop (async) + SessionEnd with `session_end` arg (async) — matches prompt-logger
