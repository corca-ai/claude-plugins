# Section 5 Draft — Expert Lens (Alpha)

## Expert Frame

- Name: Daniel Jackson-oriented concept modeling lens
- Focus: 개념 경계(what/why/how 분리), 상태 전이 명시성, 재사용 가능한 계약 단위

## Analysis

1. 이번 세션의 강점은 SoT를 기준점으로 고정해 개념 경계를 복원한 점이다.
2. 약점은 규약의 실행 가능성이다. 문장 규칙이 많아도 상태 전이/게이트가 비결정적이면 재현률이 떨어진다.
3. `context-deficit resilience`는 단일 섹션 조언이 아니라 공용 계약이어야 한다. 공용 참조에서 정의하고 개별 스킬은 참조/적용만 담당해야 drift를 줄일 수 있다.

## Recommended Actions

- `skill-conventions`에 전역 컨텍스트 결손 복원 계약을 단일 문구로 추가
- `context-recovery-protocol`에 "대화 메모리 비의존" 규칙을 명시
- `hitl` 상태에 `intent_resync_required`와 확인 타임스탬프를 추가해 다음 청크 전이 조건을 결정적으로 강제

<!-- AGENT_COMPLETE -->
