# Lessons: plugin-deploy Skill Implementation

### 기존 플러그인 패턴 분석

- **Expected**: 플러그인마다 구조가 다를 것
- **Actual**: 모든 플러그인이 일관된 패턴 사용 (plugin.json 필드, 디렉토리 구조, env 로딩)
- **Takeaway**: `check-consistency.sh`에서 이 일관된 패턴을 기준으로 검증하면 됨

### Open Questions 해결

- **Expected**: 유저에게 물어봐야 할 수 있음
- **Actual**: 플랜 문서에 이미 leaning toward 방향이 명시되어 있음 (commit = prepare only, version = always ask)
- **Takeaway**: 플랜에 방향성이 적혀 있으면 그대로 따르고, 구현 중 발견된 문제만 질문

When 플랜에 "leaning toward" 방향이 있으면 → 그대로 결정하고 진행

### 로컬 스킬 vs 마켓플레이스 플러그인

- **Expected**: 원래 계획대로 marketplace plugin으로 구현
- **Actual**: 유저가 "이 레포에만 특화된 스킬이니 로컬 스킬이어야 한다"고 피드백
- **Takeaway**: 범용성이 없는 자동화 도구는 `.claude/skills/`에 로컬로 두는 게 맞음. marketplace plugin은 어떤 프로젝트에서든 쓸 수 있는 것만.

When 특정 레포에만 의미 있는 스킬 → `.claude/skills/`에 로컬 배치, marketplace 불필요

### 토큰 효율 치트시트

- **Expected**: CLAUDE.md에 4개 문서 읽으라는 지시가 필요
- **Actual**: 유저가 "매번 같은 문서 4개 읽는 게 토큰 낭비"라고 지적
- **Takeaway**: 핵심 패턴을 한 파일로 압축한 치트시트를 만들고, CLAUDE.md는 치트시트를 우선 참조하도록 변경

When 반복적으로 읽는 참조 문서가 여러 개 → 치트시트로 통합하여 토큰 절약

### bash 조건부 확장 JSON 버그

- **Expected**: `${var:+"\"$var\""}${var:-null}` 패턴으로 JSON optional string 처리
- **Actual**: 변수가 non-empty일 때 둘 다 확장되어 `"value"value` 출력
- **Takeaway**: bash에서 JSON optional을 출력하려면 helper 함수 (`json_str()`) 사용

When bash에서 optional JSON 필드 출력 → `json_str()` 헬퍼 함수로 분기
