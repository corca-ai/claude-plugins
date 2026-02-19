# Iteration 2 추천안 (메인 머지 전/후 기준)

## 목적

Iteration 1에서 확인된 blocker/timeout을 바탕으로, 배포 리스크를 가장 빠르게 줄이는 실행 순서를 제안한다.

## 추천 순서

1. 설치 경로 복구 확인 (최우선)
   - 이유: 신규 유저 온보딩의 첫 단계가 실패하면 이후 setup/skill 검증이 무의미해진다.
   - 실행:
     - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`
     - 머지 후 `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main`

2. 스킬 체인의 non-interactive 경계 명시
   - 이유: 현재 timeout의 다수가 "사용자 선택 대기"로 관측되며, 이 상태는 CI/자동화에서 무한 대기 리스크를 만든다.
   - 실행:
     - `scripts/noninteractive-skill-smoke.sh` summary의 `reason` 컬럼(`WAIT_INPUT|TIMEOUT|ERROR|OK`) 기준으로 스킬별 정책 문서화
     - interactive-only 스킬은 fail-fast 메시지로 종료하도록 우선 보완
   - 업데이트(2026-02-19):
     - `cwf:run` 질문형 종료가 `PASS/OK`로 집계되는 false positive를 수정해 `FAIL/WAIT_INPUT`으로 분류되도록 반영 완료

3. cwf:run/cwf:retro provenance 강제 기록 강화
   - 이유: timeout이 발생해도 어디서 멈췄는지 기록이 있어야 다음 수정이 반복 가능하다.
   - 실행:
     - stage 진입/탈출 시점의 최소 provenance 기록을 timeout 이전에 flush
     - Iteration 2에서 `I1-R60` 대응 재시도

4. hook 회귀 검증 최소세트 유지
   - 이유: hook은 현재 안정적이지만, 스킬 수정 시 간접 회귀가 발생할 수 있다.
   - 실행:
     - `bash scripts/hook-core-smoke.sh`를 pre-merge 기본 게이트로 유지

## 권장 판정 기준

- 머지 전 필수
  - premerge gate PASS
  - hook-core-smoke PASS
- 머지 직후 필수
  - predeploy gate PASS (public marketplace에서 `cwf` 확인)
- Iteration 2 완료 조건(1차)
  - smoke 14 케이스 기준 `WAIT_INPUT + TIMEOUT` 합계가 Iteration 1 대비 감소

## 현재 상태 메모 (2026-02-19)

- premerge gate: PASS
- predeploy gate: FAIL (`corca-ai/claude-plugins@main` marketplace `cwf` 누락)
- `cwf:run` 단건 smoke: `FAIL/WAIT_INPUT` (false PASS 제거 확인)
- `cwf:retro --light` 단건 smoke: `TIMEOUT` (잔여 개선 대상)
