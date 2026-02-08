# S8 Lessons — Migrate clarify → cwf:clarify

## Implementation Learnings

- Simplest migration so far: no scripts to copy, only SKILL.md + 4 reference files
- Reference files use `{SKILL_DIR}/references/` relative paths, so verbatim copy works without modification
- The `cwf:review --mode clarify` integration was already done in S5a/S5b — no additional wiring needed
- Followed same pattern as S7 (gather-context → cwf:gather) for consistency
- Path A web researcher changed from `{gather-context plugin dir}/...` to `{cwf plugin dir}/skills/gather/scripts/search.sh` to use the already-migrated cwf:gather search script
- Added cwf:gather to the Path A availability check (alongside legacy /gather-context) for forward compatibility
- Added cwf:review --mode clarify follow-up note at Phase 5 end for discoverability
- **누락**: next-session.md(S9 핸드오프) 생성을 빠뜨림 — plan.md의 step 8만 따라가고, 원본 핸드오프(S7→S8)의 "After Completion" 체크리스트를 재확인하지 않음. CLAUDE.md의 "do not wait for explicit reminders" 원칙 위반. 교훈: 플랜 작성 시 원본 핸드오프의 완료 조건을 플랜에 포함시키거나, 구현 후 원본 핸드오프를 다시 읽어야 함.
