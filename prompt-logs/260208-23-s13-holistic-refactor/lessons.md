# Lessons — S13 Holistic Refactor

### 참조 경로 깊이 실수 패턴

- **Expected**: `skills/{name}/SKILL.md`에서 `../../references/`로 2단계 올라가면 `plugins/cwf/references/`에 도달
- **Actual**: 4개 스킬이 `../references/` (1단계) 또는 `../../../references/` (3단계)를 사용. 세션마다 다른 작성자가 만들면서 경로 깊이가 불일관
- **Takeaway**: 공유 참조 파일 경로는 한 곳에서 검증 가능한 패턴이 필요. 스킬 작성 시 기존 스킬(setup, handoff)의 참조 링크를 복사하는 것이 안전

When 새 스킬에서 shared references 링크 → setup이나 handoff의 References 섹션을 참고

### Rules 섹션 누락 탐지

- **Expected**: 모든 스킬이 동일한 구조(frontmatter → Quick Start → Phases → Rules → References)
- **Actual**: gather만 Rules 섹션이 없었음. S7에서 마이그레이션할 때 원본(gather-context)에 Rules가 없었기 때문
- **Takeaway**: 마이그레이션 시 구조적 체크리스트가 필요. frontmatter 형식, Language 선언, Rules 섹션, References 섹션이 필수

### 언어 선언 표준화

- **Expected**: 모든 스킬이 동일한 Language 선언 패턴 사용
- **Actual**: 5가지 이상 다른 표현 사용. retro만 파일 하단에 별도 섹션으로 배치
- **Takeaway**: `**Language**: Write {artifact} in English. Communicate with the user in their prompt language.` 패턴으로 통일. retro는 사용자 언어 예외 유지

### 린터 빡빡함 — 실사용 데이터 부재

- **Expected**: S12에서 우려된 린터 빡빡함에 대해 구체적 사례 수집 후 조정
- **Actual**: markdownlint .markdownlint.json 설정이 이미 주요 마찰 규칙(MD013, MD031-34 등)을 비활성화. 28개 파일 0 errors. shellcheck은 기본 규칙 전체 적용이나 구체적 false positive 사례 없음
- **Takeaway**: 현재 설정이 합리적. cwf:setup 토글이 첫 번째 방어선. 추가 조정은 구체적 마찰 사례 수집 후에만

### 반복 패턴 추출 — skill-conventions.md

- **Expected**: 9개 스킬이 동일 구조(frontmatter → Language → Phases → Rules → References)를 따름
- **Actual**: 구조가 암묵적으로 반복되고 있었으나, 이를 명시화한 공유 레퍼런스가 없었음. 새 스킬 작성 시 기존 스킬을 무작위로 참고하면서 불일관성 발생
- **Takeaway**: 3개 이상 스킬이 동일 패턴을 반복하면 `references/`에 추출. holistic-criteria.md에 패턴 추출 분석(1c)을 추가하여 자동 탐지하도록 개선

When 반복 패턴 3+ 스킬 → shared reference 추출 제안 (holistic criteria 1c)

### Holistic 분석에서 인라인 vs 서브에이전트

- **Expected**: cwf:refactor --holistic 스킬 지시대로 3개 병렬 서브에이전트 실행
- **Actual**: 이미 모든 파일을 읽은 상태에서 서브에이전트를 실행하면 컨텍스트 손실. 인라인 분석이 더 효율적
- **Takeaway**: 서브에이전트 패턴은 데이터 수집과 분석이 분리될 때 유용. 이미 데이터가 컨텍스트에 있으면 인라인이 나음
