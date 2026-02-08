# S8 Lessons — Migrate clarify → cwf:clarify

## Implementation Learnings

- Simplest migration so far: no scripts to copy, only SKILL.md + 4 reference files
- Reference files use `{SKILL_DIR}/references/` relative paths, so verbatim copy works without modification
- The `cwf:review --mode clarify` integration was already done in S5a/S5b — no additional wiring needed
- Followed same pattern as S7 (gather-context → cwf:gather) for consistency
- Path A web researcher changed from `{gather-context plugin dir}/...` to `{cwf plugin dir}/skills/gather/scripts/search.sh` to use the already-migrated cwf:gather search script
- Added cwf:gather to the Path A availability check (alongside legacy /gather-context) for forward compatibility
- Added cwf:review --mode clarify follow-up note at Phase 5 end for discoverability
