# Lessons — S9 cwf:plan

### cwf:plan은 cwf:clarify보다 간결해야 함

- **Expected**: cwf:clarify의 5-phase 패턴을 그대로 따라갈 것으로 예상
- **Actual**: plan skill은 advisory/persistent-questioning이 불필요 — 연구 결과를 종합하는 것이 핵심
- **Takeaway**: 스킬 패턴을 복사할 때 해당 스킬의 핵심 가치에 맞게 단순화할 것

When 기존 스킬을 참고할 때 → 구조만 참고하고, phase는 목적에 맞게 조정

### 마크다운 템플릿에서 코드 펜스 중첩 시 4-backtick 사용

- **Expected**: ` ```markdown ` 안에 ` ```gherkin `을 넣어도 lint 통과
- **Actual**: 내부 코드 펜스의 닫는 ` ``` `가 외부 펜스를 먼저 종료시킴 (MD040 에러)
- **Takeaway**: 코드 펜스 안에 코드 펜스를 포함할 때는 외부를 4-backtick(` ```` `)으로 감쌀 것

When SKILL.md에 마크다운 템플릿을 작성할 때 → 내부에 코드 펜스가 있으면 외부는 4-backtick 사용
