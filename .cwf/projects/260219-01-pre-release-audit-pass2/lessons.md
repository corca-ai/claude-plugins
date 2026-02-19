# Lessons — pre-release-audit-pass2

### v3 우선 정책 확정

- **Expected**: 기존 하위호환을 가능한 한 유지하면서 점진 개선
- **Actual**: 사용자 의도가 명확히 v3 완성도 우선(미배포 v3 기준 하위호환 불필요)
- **Takeaway**: pre-release major 전환에서는 기술부채를 남기는 호환 레이어보다 명확한 계약/동작을 우선한다

When pre-1.0 대격변 구간이라면 -> compatibility shim 추가보다 제거/단순화를 기본값으로 둔다.

### 의사결정 게이트 방식

- **Expected**: 대부분 자율 처리
- **Actual**: 아키텍처/정책 트레이드오프가 있으면 사용자와 합의 후 진행이 필요
- **Takeaway**: 자동 수정과 사용자 의사결정 경계를 계획 단계에서 명시해야 재작업이 줄어든다

When 선택지 간 장단점이 명확히 갈리는 구조적 변경이면 -> 즉시 옵션/트레이드오프를 제시하고 중단한다.

### 서브에이전트 활용 기준

- **Expected**: 일부 탐색만 병렬화
- **Actual**: 사용자가 토큰 비용보다 검토 품질을 우선하므로 병렬 분석 최대화가 요구됨
- **Takeaway**: 분석 단계(코드/클레임/외부 prior-art)를 분리해 병렬 수집 후 합성하는 방식이 적합하다

When 점검 범위가 코드+문서+운영계약까지 걸치면 -> 탐색 서브에이전트를 도메인별로 분리해 동시에 실행한다.

## Run Gate Violation — 2026-02-18T22:43:23Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [refactor] refactor-summary.md missing heading: ## Refactor Summary

## Run Gate Violation — 2026-02-18T23:51:22Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [retro] retro.md missing '- Mode:' declaration

## Iteration 2 Lesson — Smoke False PASS Hardening (2026-02-19)

- **Expected**: `WAIT_INPUT` 패턴만 보강하면 non-interactive false PASS가 충분히 줄어든다.
- **Actual**: 질문형 문구가 스킬/상황마다 다양하고, 빈 출력(`exit 0`) 케이스도 존재해 추가 누락이 발생했다.
- **Takeaway**: smoke 분류는 `WAIT_INPUT` + `NO_OUTPUT`를 fail-closed 기본값으로 두고, 신규 문구는 픽스처부터 추가해야 한다.

When non-interactive smoke reports unexpected PASS with incomplete behavior -> first add fixture and classifier rule, then rerun gate before concluding.
