# Section 5 Draft — Expert Lens (Beta)

## Expert Frame

- Name: Socio-technical workflow / SRE postmortem lens
- Focus: 사람-도구 경계에서 발생하는 재작업 최소화, 재발 방지형 게이트 설계

## Analysis

1. 핵심 병목은 생성량이 아니라 합의 상태의 신뢰성이다. 합의는 기록보다 "검증 가능한 전이 규칙"으로 유지돼야 한다.
2. 이번 세션의 반복 손실은 세 가지였다: 사용자 직접 수정 후 재동기화 누락, 문서 변경 후 scratchpad 미반영 가능성, 도구 호출 위생 오류.
3. 이 세 항목은 모두 후처리 게이트로 자동 감지 가능한 범주이며, 운영 피로를 줄이려면 동일 검증 지점(post-run)으로 묶는 것이 유리하다.

## Recommended Actions

- `post-run-checks.sh`에 `apply_patch via exec_command` 감지 추가
- HITL 활성 상태에서 문서가 바뀌면 scratchpad 갱신 여부를 게이트화
- `retro-collect-evidence` 자동화로 deep-mode 근거 수집 편차 축소

<!-- AGENT_COMPLETE -->
