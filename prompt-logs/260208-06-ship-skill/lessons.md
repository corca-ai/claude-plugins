# S3 Lessons: /ship Skill

### Scope 결정 — core + status

- **Expected**: full (issue→pr→merge 원스텝) 서브커맨드가 필요할 것
- **Actual**: 유저 판단 — core만 있으면 에이전트가 알아서 조합 가능, `full`은 불필요
- **Takeaway**: 에이전트가 사용하는 스킬은 조합 가능한 primitive 단위로 제공하면 충분

When 에이전트용 스킬 설계 시 → 단계별 primitive를 제공하고 orchestration은 에이전트에게 위임

### 템플릿 파일의 nested code fence 문제

- **Expected**: PR template에서 ```` ```markdown ```` 안에 ```` ```text ```` 블록 사용 가능
- **Actual**: markdownlint가 nested fence를 올바르게 처리하지 못함 — 외부 fence가 내부 ` ``` `에서 닫힘
- **Takeaway**: 템플릿 파일은 code fence로 감싸지 말고 HTML comment로 구간 표시 (`<!-- BEGIN TEMPLATE -->`)

When 에이전트가 읽어서 치환하는 템플릿 → 코드 펜스 대신 comment 기반 구분자 사용

### Instruction-only skill은 빠르게 완성됨

- **Expected**: 스크립트 기반 skill과 비슷한 노력
- **Actual**: SKILL.md + references 2개로 끝 — 테스트도 gh CLI 호출만 확인하면 됨
- **Takeaway**: 에이전트 판단에 자유도를 줄 수 있는 워크플로우는 instruction-only가 적합

When 워크플로우가 명확하지만 세부 판단이 필요 → instruction-only skill 선호
