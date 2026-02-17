# Retro

- Mode: light
- Session: 260217-06-setup-update-scope-aware
- Scope: setup/update scope-aware contract + codex integration scripts/docs

## 1. Context Worth Remembering

- Claude plugin scope와 Codex integration scope는 분리된 개념이며, setup/update에서 둘 다 명시적으로 다뤄야 혼선을 줄일 수 있다.
- `project/local` 컨텍스트에서 user-global(`~/.agents`, `~/.local/bin`) 변경은 반드시 명시적 확인이 필요하다.
- 버전 캐시 경로가 바뀌는 업데이트 이후에는 Codex 링크/래퍼 재조정(reconcile)이 운영 안정성에 중요하다.

## 2. Collaboration Preferences

- 사용자는 구조 설명보다 실제 동작 계약(what/why)과 즉시 구현을 선호한다.
- 구현 후 `review → refactor → retro`를 연속 실행해 상태를 닫는 흐름을 기대한다.

## 3. Waste Reduction

- 초기 문서 변경 시 setup/update/script 간 계약 불일치가 발생할 수 있으므로, 변경 직후 deterministic gates를 바로 실행하는 것이 재작업을 줄였다.
- markdownlint의 custom rule(CORCA001)로 인한 재수정이 있었으므로, path-like inline code 사용을 초기에 피하는 것이 효율적이다.

## 4. Critical Decision Analysis (CDM)

- Decision: Codex 기본 타깃을 활성 플러그인 스코프로 둘지 여부.
- Why: 사용자 기대(로컬 설치면 로컬 경로 사용)와 side-effect 최소화 요구를 동시에 만족해야 했다.
- Result: 기본은 active scope(`local > project > user`)로 하고, non-user에서 user-global 변경은 명시적 opt-in으로 확정.

## 7. Relevant Tools

- Used: `detect-plugin-scope.sh`, `sync-skills.sh`, `install-wrapper.sh`, markdownlint, check-links, doc-graph, check-run-gate-artifacts.
- Gap: refactor stage contract policy(`refactor_expected_skills`)가 quick-scan-only 세션에도 warning을 남긴다. 정책 의도 재검토 또는 quick-scan 전용 예외 기준이 있으면 운영 노이즈를 줄일 수 있다.
