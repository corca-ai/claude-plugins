# S2: Refactor Convention Alignment — Lessons

## Implementation Learnings

- **Plan에서 bare fence 카운트가 closing fence를 포함하고 있었음**: 플랜 단계에서 `grep -c '^```$'`로 카운트한 93개 fence가 실제로는 모두 closing fence였다. opening fence에는 이미 language specifier가 있었음. 검증 방법: `npx markdownlint-cli2` (MD040 rule)로 확인해야 정확함. 단순 grep은 opening/closing을 구분하지 못한다.
- **8개 서브에이전트 병렬 실행 효과적**: bare fence 수정(6개), env var 마이그레이션(1개), description sync(1개)를 동시에 실행. 실제 수정이 필요한 작업(env var, description)이 빠르게 완료됨.
- **Env var 마이그레이션 shim 패턴**: `${NEW:-${OLD:-default}}` 네스트 패턴으로 backward-compat 보장. 이 패턴은 plugin-dev-cheatsheet.md의 환경변수 컨벤션과 일치.
