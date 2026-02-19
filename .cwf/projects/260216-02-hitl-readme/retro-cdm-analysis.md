# Section 4 Draft — Critical Decision Analysis (CDM)

## CDM-1: README.ko SoT 고정과 동기화 순서 분리

- Signal: 한/영 문서와 스킬 문서를 동시에 수정할 때 합의 충돌이 반복되었다.
- Decision: `README.ko.md`를 먼저 안정화하고 외부 반영은 후속 동기화로 분리했다.
- Alternatives:
  - A) 한/영 동시 수정
  - B) 스킬 문서 우선 수정
- Why chosen: 기준 문서가 하나여야 HITL 합의 재현률을 높일 수 있다.
- Outcome: 합의 추적은 쉬워졌지만, 후속 동기화 누락 위험이 남았다.
- Guardrail: SoT 변경 직후 동기화 대상 파일을 scratchpad/plan에 명시하고 체크리스트로 검증.

## CDM-2: HITL 개선을 플래그 추가 대신 상태 전이 강화로 해결

- Signal: 사용자 불만의 핵심은 모드 다양성 부족이 아니라 합의-적용 불일치였다.
- Decision: 새 모드 플래그를 만들지 않고 `intent_resync_required` 상태 전이와 scratchpad 동기화 규약을 강화했다.
- Alternatives:
  - A) `--guided` 신규 플래그
  - B) 별도 완전자율 모드 분리
- Why chosen: 모드 분기는 학습 비용만 높이고 실제 실패 원인(상태 불일치)을 해결하지 못한다.
- Outcome: 단일 흐름 유지와 계약 강화가 동시에 가능해졌다.
- Guardrail: 다음 청크 제시 전 `intent_resync_required=false`를 결정적 게이트로 검사.

## CDM-3: Wrapper 옵션 2 유지 + post-run deterministic gate 확장

- Signal: `apply_patch via exec_command` 같은 도구 위생 문제가 프롬프트 규약만으로 재발했다.
- Decision: Codex wrapper post-run checks에 anti-pattern 탐지와 HITL 동기화 게이트를 추가한다.
- Alternatives:
  - A) 문서 규약만 유지
  - B) pre-run 차단만 추가
- Why chosen: 사용 흐름을 막지 않으면서도 재발 징후를 실행 직후 감지할 수 있다.
- Outcome: 경고 모드 기본(`warn`) + 엄격 모드(`strict`)로 운영 부담을 조절할 수 있다.
- Guardrail: changed-files 기반 검사로 비용을 제한하고 오탐 패턴은 명시적으로 조정.

<!-- AGENT_COMPLETE -->
