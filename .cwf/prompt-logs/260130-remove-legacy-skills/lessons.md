### "독립적 가치"의 유효기간

- **Expected**: gather-context 작업 시 "개별 스킬은 독립적 가치가 있으니 유지"라고 결정
- **Actual**: 실제로는 동일 스크립트가 두 곳에 존재하는 유지보수 부담만 남았고, 사용자도 적어서 유지할 이유가 없었음
- **Takeaway**: 통합 스킬을 만들 때 "기존 것도 유지"는 보수적 판단이지만, 사용자 규모가 작다면 과감하게 한 번에 정리하는 게 나음

When 통합 스킬이 기존 스킬을 완전히 대체 + 사용자 적음 → 기존 스킬을 바로 삭제하고 마이그레이션 안내만 남기기

### lessons.md는 plan.md와 동시에 생성해야 한다

- **Expected**: 쉬운 태스크라 구현 중 예상 밖의 일이 생기면 그때 lessons를 쓰면 됨
- **Actual**: lesson은 구현 중이 아니라 플랜 모드 진입 전 대화에서 이미 발생했음 (이전 세션의 "유지" 결정이 뒤집히는 순간). 하지만 lessons.md 자체를 생성하지 않아서 기록 타이밍을 놓침
- **Takeaway**: lessons.md는 plan.md와 동시에 생성하고, 대화에서 배움이 나오는 순간 바로 기록. 태스크 난이도와 무관하게 프로토콜은 동일하게 적용

When plan.md 생성 시 → lessons.md도 함께 생성 (빈 파일이라도). 배움이 나오면 즉시 기록

### Retro 배움의 올바른 정착 위치

- **Expected**: retro에서 발견한 배움을 CLAUDE.md에 추가하면 compound됨
- **Actual**: CLAUDE.md에 쌓이면 accumulate일 뿐. CLAUDE.md가 참조하는 문서(protocol.md 등)에 내용이 속한다면, 그 문서를 보강하는 게 progressive disclosure 원칙에 부합
- **Takeaway**: retro에서 CLAUDE.md 변경을 제안하기 전에, 해당 배움이 CLAUDE.md가 참조하는 하위 문서에 속하는지 먼저 확인. 속한다면 하위 문서를 수정

When retro에서 CLAUDE.md 변경 제안 시 → 배움이 참조 문서에 속하면 참조 문서를 수정, CLAUDE.md는 포인터로만 유지

### Post-retro에서 플러그인 코드 변경 시 배포 절차 누락

- **Expected**: retro SKILL.md, protocol.md 수정 후 당연히 plugin.json 버전도 올릴 것
- **Actual**: post-retro의 맥락이 "대화와 기록"이라서, 코드 변경에 수반되는 배포 절차(plugin.json, CHANGELOG)를 잊음
- **Takeaway**: post-retro에서도 플러그인 코드를 변경했다면 일반적인 배포 절차를 동일하게 적용해야 함. retro SKILL.md Section 6에 해당 안내 추가 완료

When post-retro에서 플러그인 코드 변경 시 → plugin.json 버전 + CHANGELOG 업데이트

### 규칙을 추가한 변경 자체에도 규칙 적용

- **Expected**: "post-retro에서 plugin.json을 올리라"는 규칙을 SKILL.md에 추가했으니 당연히 해당 SKILL.md 변경에도 plugin.json을 올릴 것
- **Actual**: 규칙 추가와 규칙 적용을 별개로 인식. retro plugin.json이 1.2.0인 채로 CHANGELOG에 1.2.0으로 기록
- **Takeaway**: 새 규칙을 추가하는 변경 자체가 그 규칙의 첫 번째 적용 대상. 메타 규칙: "규칙을 만들었으면 지금 이 변경에도 적용되는지 확인"

When 새 규칙을 코드에 추가할 때 → 그 변경 자체가 규칙의 첫 번째 적용 대상인지 확인
