# Retro: S13.5 Docs Review Session (Light)

## 1. Context Worth Remembering

- User의 문서 철학이 이번 세션에서 명확하게 결정됨: 4개 원칙 (P1-P4)
- dogfood.sh 패턴: 소스→캐시 동기화로 로컬 개발 워크플로우 확립
- refactor --docs는 기계적 정합성에 강하고, 수동 분석은 구조 최적화에 강함. 상호보완적.
- CWF v0.7.0: 11개 스킬 (ship, review 통합), 7개 훅 그룹

## 2. Collaboration Preferences

- User는 외부 아티클 기반 원칙 수립 → 구체적 실행 계획 도출 패턴을 선호
- "솔직한 의견"을 자주 요청. 반대 의견이나 tension을 숨기지 말 것
- "대강" 통합 후 plan으로 남기는 패턴: 완벽보다 진행을 우선시

## 3. Waste Reduction

- refactor --docs를 먼저 돌렸으면 README.ko.md 불일치를 놓치지 않았을 것.
  교훈: 스킬이 있으면 먼저 스킬을 돌리고, 그 결과 위에 수동 분석을 얹어야 함.
- 캐시 구조를 처음에 제대로 파악하지 않아 dogfood.sh 첫 실행에서 Python syntax error 발생.
  교훈: 인라인 Python에 bash 변수 interpolation은 위험. heredoc (<<PYEOF) 패턴 사용.

## 4. Critical Decisions

### CDM 1: "dogfood.sh vs PLUGIN_ROOT 제거 vs symlink"

- 상황: CWF 소스 수정 → 캐시 반영 경로가 끊김
- 선택지: (A) PLUGIN_ROOT 의존 제거 + 로컬 symlink, (B) 캐시 자동 동기화 스크립트, (C) 수동 복사
- 결정: (B) dogfood.sh — 플러그인 구조를 유지하면서 즉시 반영
- 근거: (A)는 8개 SKILL.md + 15개 symlink 변경 필요. (B)는 1개 스크립트로 해결.
  PLUGIN_ROOT 구조는 marketplace 배포 시 필요하므로 제거보다 유지가 나음.
- 결과: 즉시 작동. 다음 세션부터 `bash scripts/dogfood.sh` 한 줄로 소스→캐시 반영.

### CDM 2: "4개 원칙 도출 과정"

- 상황: docs 전면 재점검 → 유저가 점진적으로 원칙을 제안
- 전개: (1) refactor --docs 결과 분석 → (2) "스킬이 하는 걸 왜 문서에?" → P1 도출 → (3) "CWF는 범용이어야" → P2 도출 → (4) "플러그인 안에서는 강결합" → P3 → (5) "what/why만, how는 스크립트화" → P4
- 패턴: 구체적 문제 (docs 중복) → 추상적 원칙 → 다시 구체적 계획. 이 bottom-up 패턴이 이 유저와의 작업에서 반복됨.

## 7. Persist Candidates

### → docs/documentation-guide.md

P1-P4 원칙. 단, plan.md에 이미 상세히 기술되어 있으므로 다음 세션에서 docs 재작성 시 자연스럽게 반영될 것. 지금 별도로 persist할 필요는 낮음.

### → docs/plugin-dev-cheatsheet.md

dogfood.sh 사용법. 다음 세션 W10에서 cheatsheet에 추가될 것.

### → CLAUDE.md

현재 세션에서 이미 5줄 트리밍 완료. 추가 persist는 다음 세션 W1에서.
