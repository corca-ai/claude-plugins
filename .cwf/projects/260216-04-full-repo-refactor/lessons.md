# Lessons — full-repo-refactor

### CORCA003 lint rule overrides convention docs

- **Expected**: `skill-conventions.md`의 multi-line `|` frontmatter 형식이 정답
- **Actual**: CORCA003 lint rule이 single-line 형식을 강제하고, 13개 SKILL.md 전부에서 에러 발생
- **Takeaway**: 린트 규칙이 실제 소스 오브 트루스. 컨벤션 문서가 린트와 불일치하면 문서를 수정해야 함 (AUTO_EXISTING 원칙)

### Expert Roster Update는 공유 가이드에 추출해야 함

- **Expected**: 각 스킬에서 roster update 로직을 인라인으로 관리
- **Actual**: clarify, review, retro 3곳에 동일한 로직이 복제됨
- **Takeaway**: 3+ 스킬에서 동일 패턴이 반복되면 shared reference로 추출. expert-advisor-guide.md의 Roster Maintenance 섹션으로 통합 완료

### ship 스킬의 하드코딩된 한국어와 브랜치명

- **Expected**: ship이 다국어/범용 브랜치 지원
- **Actual**: Language 선언이 한국어로 고정, base branch가 marketplace-v3로 고정, PR 템플릿 변수에 한국어 리터럴 포함
- **Takeaway**: 스킬의 Language 선언은 "user's language" 패턴을 따라야 하고, 기본값은 범용이어야 함

### README SSOT 구조 정렬은 설계 의도 섹션이 핵심

- **Expected**: README.md와 README.ko.md가 구조적으로 동일
- **Actual**: 한국어 README에만 "설계 의도" + "무엇을 하는가" 서브섹션 존재
- **Takeaway**: SSOT 선언(README.ko.md)의 구조를 영문에도 미러링. Design Intent 섹션은 각 스킬이 왜 존재하는지 이해하는 데 필수

### Phase 2 subsection 번호 재정렬 필요

- **Expected**: 새 서브섹션 삽입 시 자동 정렬
- **Actual**: plan SKILL.md에 2.2 Adaptive Sizing Gate 삽입 후 2.3이 두 개 존재
- **Takeaway**: 번호 기반 서브섹션에 삽입 시 반드시 후속 번호 업데이트 확인
