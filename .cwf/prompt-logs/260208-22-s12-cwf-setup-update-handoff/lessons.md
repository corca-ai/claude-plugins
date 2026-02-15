### Dogfooding 규칙 위치 결정

- **Expected**: handoff 문서에 세션별로 "cwf:gather 써라, cwf:clarify 써라" 지시
- **Actual**: CLAUDE.md에 영속적 규칙으로 넣기로 결정. 스킬 목록 하드코딩 없이 "CWF 스킬이 있으면 수동으로 하지 말고 스킬을 써라"
- **Takeaway**: 매 세션 반복되는 지시는 handoff가 아닌 CLAUDE.md에. 중복 제거 원칙 — marketplace.json이나 skills/ 디렉토리에서 발견 가능한 정보를 별도로 유지하지 않음

When 모든 세션에 적용되는 규칙 → CLAUDE.md에 넣고, handoff에서는 반복하지 않음

### 스킬 목록 하드코딩 vs 동적 발견

- **Expected**: CLAUDE.md에 `Available skills: cwf:gather, cwf:clarify, ...` 명시
- **Actual**: 스킬 변경 시 두 곳을 수정해야 하는 중복 문제 지적 → skills/ 디렉토리나 트리거 목록으로 발견하도록 변경
- **Takeaway**: SSOT 위반을 만들지 않기. 열거 가능한 정보는 열거하지 말고 발견 메커니즘을 안내

### Clear context and go 시 lessons 유실 위험

- **Expected**: plan-and-lessons 프로토콜이 "lessons.md는 plan.md와 동시에 생성" 명시 → 안전
- **Actual**: ExitPlanMode에서 lessons.md 존재를 검증하는 훅이 없음. 에이전트가 plan 작성에 집중하면 pre-plan 대화 learnings이 기록 안 될 수 있음
- **Takeaway**: "프로토콜에 적혀 있다"는 행동 규칙이고, 검증이 없으면 누락됨. eval > state > doc 위계 적용 — ExitPlanMode PreToolUse 훅으로 lessons.md 존재/비어있지 않음 검증 필요

When plan 승인 전 clear context 위험 → ExitPlanMode 훅에서 lessons.md 검증 (후속 작업)

### refactor --docs 개밥먹기 첫 사례

- **Expected**: S12 계획 수립 후 바로 구현 착수
- **Actual**: project-context.md 압축 필요성을 논의 중 refactor --docs를 먼저 실행하기로 결정 — CWF 스킬의 첫 실제 사용
- **Takeaway**: 개밥먹기를 계획에 포함하면 자연스럽게 도구 품질 피드백이 나옴. "나중에 테스트"보다 "지금 사용"이 효과적

### project-context.md Plugins 섹션 중복

- **Expected**: project-context.md가 아키텍처 패턴과 규약 중심
- **Actual**: 개별 플러그인 상세 설명(67-80행)이 README와 거의 동일 — 인라인 오버로드
- **Takeaway**: project-context.md는 "왜 이렇게 설계했는가"(패턴, 규약, 결정 근거)를 담고, "무엇이 있는가"(기능 목록)는 README에 위임

### impl 완료 후 retro 자동 제안 부재

- **Expected**: check-session.sh --impl PASS 후 retro 실행이 자연스럽게 이어짐
- **Actual**: 에이전트가 impl 완료 = 세션 완료로 인식, retro 실행 않음. 유저가 "retro 했나요?"로 직접 확인
- **Takeaway**: "impl 끝 → retro → 세션 끝"이 올바른 워크플로우. check-session.sh가 이 경계를 흐리게 만듦. CLAUDE.md에 명시하거나 자동 체이닝 필요

When impl 완료 후 → retro 실행 여부 확인 (현재는 수동, S13에서 자동화 검토)

### 린터 빡빡함 우려

- **Expected**: markdownlint + shellcheck 훅이 코드 품질을 자동 보장
- **Actual**: 유저가 "불필요하게 빡빡하지 않은가" 우려 제기. 실사용 데이터 없이 빡빡함을 판단할 수 없음
- **Takeaway**: 도구 강도 조정은 실사용 피드백 기반으로. cwf:setup hook toggle이 첫 번째 방어선, 린터 설정 자체 조정은 두 번째

When 린터 빡빡함 우려 → 구체적 사례 수집 후 조정 (S13에서 검토)

### 기존 파일에 Write 사용 금지

- **Expected**: retro 업데이트 시 기존 내용 보존하며 추가
- **Actual**: Write 도구로 retro.md 전체를 덮어써서 pre-work retro 내용 소실. 유저가 발견하여 복원
- **Takeaway**: 기존 파일에 내용 추가 시 반드시 Edit 사용. Write는 전체 파일을 교체하므로 기존 내용이 사라짐. CLAUDE.md "Never delete user-created files" 규칙의 연장선

When 기존 파일에 내용 추가 → Edit 사용 (Write는 새 파일 생성 시에만)

## Deferred Actions

- [ ] ExitPlanMode PreToolUse 훅: lessons.md 존재 + 비어있지 않음 검증 (cwf 훅 또는 plan-and-lessons 훅)
- [ ] impl → retro 자동 체이닝: CLAUDE.md 규칙 명시 또는 cwf:impl Phase 4에 retro 제안 추가
- [ ] 린터 빡빡함 검토: S13에서 lint_markdown/lint_shell 실사용 데이터 수집 후 강도 조정
