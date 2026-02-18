# Lessons — pre-release-refactor-audit

### 범위 해석 (skill 전체 deep)

- **Expected**: 사용자 요청의 "--skill 전체"는 CWF 플러그인 스킬 전부를 의미한다.
- **Actual**: `plugins/cwf/skills/*`를 기본 범위로 확정했다.
- **Takeaway**: CWF 릴리즈 점검에서는 외부 글로벌 스킬까지 확장하지 않고, 플러그인 소유 범위를 기본 스코프로 잡는다.

When 사용자 요청이 "전체"처럼 광범위 표현일 때 → 먼저 플러그인 소유 경계를 기준으로 범위를 고정하고 진행한다.

### 의사결정 개입 조건

- **Expected**: 블로킹 트레이드오프가 나타나면 사용자와 선택지 비교 후 결정한다.
- **Actual**: 시작 시점에는 블로킹 의사결정이 없어서 즉시 실행 단계로 진입했다.
- **Takeaway**: 초기 clarify에서 비차단 가정은 바로 확정하고, 구현 중 구조적 충돌이 생길 때만 멈춰서 의사결정을 요청한다.

## Run Gate Violation — 2026-02-18T12:56:42Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [review-code] artifact missing or empty: review-security-code.md
  - [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-security-code.md
  - [review-code] artifact missing or empty: review-ux-dx-code.md
  - [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-ux-dx-code.md
  - [review-code] artifact missing or empty: review-correctness-code.md
  - [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-correctness-code.md
  - [review-code] artifact missing or empty: review-architecture-code.md
  - [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-architecture-code.md
  - [review-code] artifact missing or empty: review-expert-alpha-code.md
  - [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-expert-alpha-code.md
  - [review-code] artifact missing or empty: review-expert-beta-code.md
  - [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-expert-beta-code.md
  - [review-code] artifact missing or empty: review-synthesis-code.md
  - [refactor] refactor-summary.md missing heading: ## Refactor Summary
  - [retro] retro.md missing '- Mode:' declaration

### 게이트 산출물 계약 우선 확인

- **Expected**: `cwf:review` 결과 요약 문서만 있으면 run gate를 통과할 수 있다.
- **Actual**: gate는 슬롯별 `review-*-code.md` + sentinel + `review-synthesis-code.md` 패턴을 엄격히 요구했다.
- **Takeaway**: 수동 리뷰를 수행할 때도 `check-run-gate-artifacts.sh`의 파일 계약을 먼저 확인하고 산출물 이름/형식을 맞춰야 한다.

When run-gate를 수동으로 맞출 때 → stage별 required artifact/pattern을 먼저 추출하고 문서를 생성한다.

### SoT 검증 시 비정상 경로 먼저 점검

- **Expected**: 정상 경로 동작이 맞으면 SoT와 구현 정합성이 대체로 맞다.
- **Actual**: 실제 불일치는 `jq` 미설치, repo 외부 실행, skip stage 같은 비정상/경계 경로에서 주로 드러났다.
- **Takeaway**: SoT 감사는 “happy path”보다 의존성 결손·재시작·스킵 경로를 우선 점검해야 효과적이다.

When README SoT 감사를 수행할 때 → dependency-degraded path와 skip/resume path를 기본 체크리스트로 둔다.
