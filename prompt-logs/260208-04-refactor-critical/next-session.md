# Next Session: S2

## Completed in S1

All critical/important refactor issues fixed:
- Unsafe `eval "$(grep ...)"` → safe parameter expansion (4 scripts + 1 doc)
- JSON escaping → `jq -Rs .` (2 scripts)
- Stale lock cleanup (1 script)
- Shebang + strict mode convention (14 scripts total)
- Version bumps: gather-context 2.0.2, attention-hook 2.1.1, prompt-logger 1.3.1, smart-read 1.0.1, plan-and-lessons 1.3.1, refactor 1.1.2

## S2 Scope (per master plan)

S2: `/refactor --docs` validation — add docs consistency checking to the refactor skill.

## Pre-flight

- Run `bash scripts/update-all.sh` after S1 commit+push (updates marketplace + installed plugins)
- Verify all 6 plugins install cleanly
