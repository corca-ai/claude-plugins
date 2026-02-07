# Retro: Refactor Plugin + Marketplace v2

> Session date: 2026-02-07

## 1. Context Worth Remembering

- corca-plugins 마켓플레이스가 v2.0.0으로 버전업. 플러그인 수명 주기가 성숙 단계에 진입 — 신규 생성보다 통합/승격/폐기가 주요 작업이 됨
- 플러그인 워크플로우가 6단계(Context → Clarify → Plan → Implement → Reflect → Refactor)로 정리됨. README 오버뷰 테이블에 Stage 컬럼 추가
- local skill → marketplace plugin 승격 패턴 확립: `.claude/skills/X/` → `plugins/X/`, `git rm` 로컬, marketplace.json에 추가
- refactor 플러그인이 5가지 모드를 하나의 SKILL.md에서 라우팅하는 첫 번째 "다중 모드" 스킬. 이전 스킬들은 1-2개 모드
- deprecated 플러그인 4개 (suggest-tidyings, deep-clarify, interview, web-search)가 marketplace.json에서 active 플러그인 뒤로 재배치

## 2. Collaboration Preferences

- 유저가 이전 세션에서 상세한 플랜을 설계하고, 구현 세션에서는 "이 플랜 실행해"라는 간결한 지시를 선호. 플랜 → 구현 분리가 잘 작동
- 유저가 `update-all.sh`의 브랜치 동작에 대해 질문 — 인프라 스크립트의 edge case를 능동적으로 확인하는 스타일. 에이전트가 검증 없이 실행하려 했던 것을 유저가 중단
- push 요청 시 "ok"만으로 승인. 간결한 컨펌 스타일

### Suggested CLAUDE.md Updates

- `scripts/update-all.sh`는 main 브랜치 기준으로 동작하므로, feature 브랜치에서는 머지 후 실행해야 한다는 점을 Collaboration Style에 추가 고려

## 3. Waste Reduction

### 불필요한 검증 턴 없음
이 세션은 효율적이었음. 플랜이 상세했기 때문에 의사결정 턴이 거의 없었고, 병렬 에이전트를 활용하여 3개 워크스트림을 동시에 처리.

### 개선 가능 포인트
- **Explore 에이전트 사용**: 15개 소스 파일 읽기에 Explore 에이전트를 사용했는데, 파일 목록이 명확했으므로 직접 Read를 병렬로 호출하는 것이 더 빨랐을 것. Explore는 탐색적 검색에 적합하고, 이미 파일 경로를 아는 경우에는 직접 Read가 효율적
- **README 에이전트 지연**: README.md + README.ko.md 쓰기 에이전트가 약 4분 소요. 두 파일이 독립적이므로 각각 별도 에이전트로 분리하면 병렬 처리 가능했음

## 4. Critical Decision Analysis (CDM)

### CDM 1: 병렬 에이전트 3-way 분할 전략

| Probe | Analysis |
|-------|----------|
| **Cues** | 플랜에 "Agent A/B/C" 3개 워크스트림이 명시되어 있었음. 파일 간 의존성 분석 결과 refactor 콘텐츠, deprecation 업데이트, README가 완전히 독립적 |
| **Goals** | 시간 최소화 vs 에러 방지. 병렬화하면 빠르지만 충돌 위험 |
| **Options** | (1) 순차 실행 (2) 플랜대로 3-way 병렬 (3) 2-way 병렬 (refactor+deprecation vs README) |
| **Basis** | 파일 의존성 그래프에서 교차점이 없음을 확인 후 3-way 채택. 단, refactor 플러그인 scaffold(mkdir)는 에이전트 전에 직접 실행하여 race condition 방지 |
| **Hypothesis** | 순차 실행이었다면 약 3배 느렸을 것. 실제로 deprecation 에이전트는 ~70s, README 에이전트는 ~236s — 순차였으면 총 ~306s vs 병렬 ~236s |

**Key lesson**: 병렬 에이전트 분할 시 "공유 상태(파일/디렉토리)" 유무를 먼저 검증. 공유 상태가 없으면 에이전트 수를 늘리는 것이 항상 유리. 공유 상태가 있으면 선행 작업을 메인 에이전트에서 직접 처리 후 분할.

### CDM 2: quick-scan.sh의 deprecated 스킵 로직 추가

| Probe | Analysis |
|-------|----------|
| **Cues** | 원본 quick-scan.sh는 deprecated 스킵 없이 모든 플러그인을 스캔. refactor가 마켓플레이스에 들어가면 deprecated 4개가 항상 플래그됨 |
| **Goals** | 깨끗한 스캔 결과 (active 플러그인만) vs 원본 스크립트 최소 변경 |
| **Options** | (1) SKILL.md에서 "deprecated 제외" 명시 (2) 스크립트에 deprecated 스킵 추가 (3) 플래그에 deprecated 태그 추가 |
| **Basis** | 스크립트에서 걸러내는 것이 가장 깔끔. plugin.json의 `deprecated` 필드를 python3으로 체크 |
| **Situation Assessment** | 이 결정이 `local` 키워드 버그를 유발. 스킵 로직을 scan_skill() 함수 내부가 아닌 for 루프 스코프에 넣었기 때문 |

**Key lesson**: 기존 함수에 로직을 추가하는 것과 호출부에 추가하는 것 사이에서, bash에서는 scope 규칙(local)을 항상 확인. 새 로직의 위치가 함수 내부인지 외부인지에 따라 변수 선언 방식이 달라짐.

### CDM 3: update-all.sh 실행 여부

| Probe | Analysis |
|-------|----------|
| **Cues** | CLAUDE.md 프로토콜: "커밋 후 `bash scripts/update-all.sh` 실행". 하지만 현재 feat/marketplace-v2 브랜치 |
| **Goals** | 프로토콜 준수 vs 실제 동작 정확성 |
| **Options** | (1) 프로토콜대로 즉시 실행 (2) 스크립트 확인 후 판단 (3) 유저에게 질문 |
| **Basis** | 유저에게 "update-all이 메인 브랜치가 아닐 때도 작동하나요?" 질문 받음. 스크립트를 읽어보니 `marketplace update`가 main 기준으로 pull할 가능성 높음 → 머지 후로 연기 |
| **Experience** | 프로토콜을 맹목적으로 따르면 feature 브랜치에서 잘못된 버전이 설치될 수 있었음. 유저의 질문이 이를 방지 |

**Key lesson**: 프로토콜에 "항상 X 실행"이 있어도, X의 전제 조건(브랜치, 환경)을 확인하는 것이 우선. 특히 배포 관련 스크립트는 현재 브랜치 컨텍스트를 고려해야 함.

## 5. Expert Lens

이 세션은 사전 설계된 플랜의 실행 세션으로, 대부분의 의사결정이 플랜 세션에서 완료됨. 비교적 경량 실행이므로 Expert Lens 분석을 생략.

## 6. Learning Resources

이 세션은 사전 설계된 플랜의 구현에 집중했으며, 새로운 지식 갭이나 호기심 신호가 관찰되지 않음. 학습 자료 추천을 생략.

## 7. Relevant Skills

### update-all.sh 브랜치 안전성
`scripts/update-all.sh`가 현재 브랜치를 확인하지 않는 점이 발견됨. main이 아닌 브랜치에서 실행하면 marketplace가 main 기준으로 업데이트되어 불일치 발생 가능. 스크립트에 브랜치 경고를 추가하는 것이 고려할 만하나, 별도 스킬이 필요한 수준은 아님.

### plugin-deploy 스킬에 deprecation 검증 추가
lessons.md에서 발견된 "deprecated flag 불일치" 문제. plugin-deploy 스킬의 체크리스트에 `marketplace.json`과 `plugin.json` 양쪽의 deprecated 플래그 일치 여부를 검증하는 항목을 추가하면 재발 방지 가능.

그 외 스킬 갭은 식별되지 않음.
