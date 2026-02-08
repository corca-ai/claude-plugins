# Retro: SW Factory 분석 + CWF v3 설계 논의

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- 사용자는 외부 분석 문서(SW Factory)를 읽고 자신의 프로젝트에 적용할 개념을 추출하는 "설계 논의" 세션 패턴을 사용한다. 구현 없이 설계만 하는 세션을 명시적으로 구분함.
- SW Factory의 핵심 개념(시나리오 테스팅, 홀드아웃, 만족도 스펙트럼, Shift Work)이 CWF v3 마스터 플랜에 5개의 새로운 아키텍처 결정(#16–#20)으로 반영됨.
- 사용자는 "요약"보다 "포인터"를 선호한다 — Pyramid Summaries를 Progressive Disclosure Index로 재프레이밍. 정보 손실 없는 구조화가 압축보다 우선.
- 사용자는 수치적 점수보다 서사적 판정을 신뢰한다 — "지능적 에이전트를 믿을 수 있지 않을까" 발언. 이는 CWF 전체 설계 철학에 영향.
- BDD-style success criteria와 시나리오 테스팅의 연결은 사용자가 발견한 통찰 — plan → review 파이프라인의 자연스러운 계약(contract).

## 2. Collaboration Preferences

- **논의 세션의 리듬**: 에이전트가 먼저 분석과 제안을 구조화하여 제시 → 사용자가 짧게 승인/수정/추가 → 에이전트가 반영. 이 패턴이 이 세션에서 잘 작동함.
- **사용자의 리프레이밍 능력**: "요약 → 인덱스", "BDD + 시나리오 연결" 등 에이전트의 제안을 더 정확한 프레임으로 재구성하는 패턴. 에이전트는 초기 제안을 "초안"으로 취급하고 사용자의 리프레이밍을 적극 수용해야 함.
- **"both!" 응답**: 사용자는 선택지가 제시되면 병렬 실행을 선호. "A할까요 B할까요"보다 "A와 B를 병렬로 합니다"가 맞는 접근.

### Suggested CLAUDE.md Updates

- 현재 CLAUDE.md에 "In design discussions, provide honest counterarguments and trade-off analysis. Do not just agree."가 있는데, 이 세션에서 잘 지켜짐 (홀드아웃 필요성에 대한 반론, 수치 점수의 함정 분석). 추가 변경 불필요.

## 3. Waste Reduction

이 세션은 설계 논의 세션으로, 전반적으로 낭비가 적었다.

**유일한 비효율**: SW Factory 분석 문서가 `origin/main`에만 있고 현재 `marketplace-v3` 브랜치에 없어서, `git show origin/main:...`로 읽어야 했음. 1턴의 추가 탐색이 필요했다.

- **근본 원인 (5 Whys)**: `references/` 디렉토리가 main 브랜치에만 커밋되고 marketplace-v3에 머지되지 않았음 → marketplace-v3 브랜치가 main과 주기적으로 동기화되지 않음 → v3 작업이 장기 브랜치이므로 의도적으로 분리된 상태 → **구조적 제약** (장기 브랜치 전략의 부산물)
- **심각도**: 낮음. `git show`로 해결 가능. 별도 조치 불필요.
- **분류**: 구조적 제약 (일회성, 조치 불필요)

## 4. Critical Decision Analysis (CDM)

### CDM 1: 수치적 만족도 점수를 거부하고 서사적 판정을 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | SW Factory 분석에서 "satisfaction spectrum" 개념을 읽은 후, 이를 `cwf:review`에 적용하는 방안을 논의. 에이전트가 "8/10, 77%" 같은 수치적 집계를 예시로 제안. |
| **Goals** | 리뷰 결과의 실용성 (인간이 읽고 판단할 수 있는가) vs 정량적 추적 가능성 (자동화된 pass/fail 결정) |
| **Options** | (A) 수치적 점수 + 집계 → 자동 threshold 판정. (B) 구조화된 서사 (Pass/Conditional/Revise) → 맥락 보존. (C) 혼합 — 수치 + 서사 |
| **Basis** | 사용자: "수치적인 것의 단점이 더 많은 것 같기도 합니다. 문장으로 적고, 지능적 에이전트를 믿을 수 있지 않을까." 수치 점수의 false precision 위험과 기계적 threshold("77%니까 통과")의 함정. |
| **Knowledge** | StrongDM 자체도 boolean → probability 전환을 했으나, 최종 판정은 여전히 시나리오 궤적의 질적 평가에 의존. 숫자는 도구이지 판정 자체가 아님. |
| **Hypothesis** | 수치를 도입했다면: 리뷰어마다 다른 기준으로 점수를 매기는 문제, 집계 방법(평균? 최소?)에 대한 추가 설계 부담, "점수가 낮지만 실제로는 문제없는" 오탐(false negative) 발생. |
| **Experience** | ML 분야에서 단일 metric(accuracy, F1 등)이 모델 품질을 오도하는 사례 다수. 코드 리뷰에서도 SonarQube 등의 수치가 실제 코드 품질과 상관관계가 약한 경우 많음. |

**Key lesson**: 에이전트의 판단이 충분히 지능적인 맥락에서, 수치 점수는 정보를 추가하는 것이 아니라 맥락을 제거한다. 서사적 판정 + 질적 등급(Pass/Conditional/Revise)이 인간과 에이전트 모두에게 더 유용하다.

### CDM 2: Pyramid Summaries를 Progressive Disclosure Index로 리프레이밍

| Probe | Analysis |
|-------|----------|
| **Cues** | 에이전트가 "코드베이스 상위 수준 요약을 cwf-state.yaml에 캐싱"을 제안. 사용자가 "'요약'이라기보다 '언제 뭘 읽을까'의 링크 index.md를 생성하는 느낌이 어떤가요? progressive disclosure?"로 재프레이밍. |
| **Goals** | 에이전트의 컨텍스트 효율성 vs 유지보수 부담 vs 정보 손실 방지 |
| **Options** | (A) 요약 캐싱 — 파일 내용을 요약하여 저장. (B) Progressive disclosure index — "when to read what" 포인터만 저장. (C) 둘 다 — 요약 + 포인터 |
| **Basis** | 요약은 정보를 압축/손실시키고, 원본이 바뀌면 stale해짐. 포인터는 정보 손실이 없고, 구조가 바뀌지 않는 한 유효. 유지보수 부담이 근본적으로 다름. |
| **Analogues** | 웹의 사이트맵, 도서관의 색인 카드 — 내용을 요약하는 것이 아니라 "어디에 무엇이 있는가"를 알려줌. 검색 엔진의 인덱싱도 같은 패턴. |
| **Aiding** | 에이전트의 초기 제안이 "요약" 프레임에 갇혀 있었음. SW Factory의 Pyramid Summaries라는 이름 자체가 "summaries"를 내포하여 그 방향으로 유도. 사용자의 재프레이밍이 이 프레임에서 벗어남. |

**Key lesson**: 외부 개념을 차용할 때, 원래 이름에 함축된 프레임에 갇히지 말 것. StrongDM의 "Pyramid Summaries"를 우리 맥락에서는 "Progressive Disclosure Index"로 변환한 것이 더 정확한 설계.

### CDM 3: BDD-style success criteria와 시나리오 테스팅의 연결

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자: "시나리오 테스트를 만드는 건 plan 단계의 success criteria를 bdd 스타일로 작성하는 것과 연결될 여지가 있어 보이는데" |
| **Goals** | SW Factory의 시나리오 개념을 CWF 워크플로우에 자연스럽게 통합 vs 별도의 시나리오 관리 시스템 구축 |
| **Options** | (A) 별도 시나리오 파일 시스템 (StrongDM 방식). (B) Plan의 success criteria를 시나리오로 활용 (워크플로우 내재화). (C) 두 계층 — plan criteria(공개) + holdout(비공개) |
| **Basis** | Plan에 이미 success criteria가 있으므로, 이를 시나리오 형식(BDD)으로 작성하면 추가 시스템 없이 자연스러운 계약이 됨. behavioral + qualitative 이중 카테고리로 모든 유형의 기준을 포괄. |
| **Knowledge** | BDD의 Given/When/Then은 기계적 검증에 적합하지만, 모든 품질 기준이 이 형식에 맞지는 않음 (예: "코드가 사용자 친화적이어야 한다"). 이중 카테고리가 이 한계를 해결. |
| **Hypothesis** | (A)를 선택했다면: 별도 시나리오 파일 관리 부담, plan과의 중복, 워크플로우에 추가 단계 필요. (B)만 선택했다면: holdout 없이 reward hacking 방지 불가. (C)가 두 문제를 모두 해결. |

**Key lesson**: 새로운 개념을 도입할 때, 기존 워크플로우의 산출물을 재활용할 수 있는지 먼저 탐색하라. 별도 시스템보다 기존 흐름에 녹아드는 설계가 채택률과 유지보수성 모두 높다.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

이 세션은 5개의 아키텍처 결정을 포함하는 설계 논의로, deep 분석이 유의미할 수 있음.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| **retro** (v2.0.2) | 현재 사용 중. |
| **clarify** (v2.0.1) | 사용하지 않음. 이 세션은 요구사항 정의가 아니라 설계 논의였으므로 적절. |
| **gather-context** (v2.0.2) | SW Factory 분석 문서를 `git show`로 직접 읽음. `origin/main`의 파일이라 gather-context의 로컬 탐색으로는 처리 어려웠을 것. 적절한 판단. |
| **refactor** (v1.1.2) | 사용하지 않음. 코드 변경 없는 논의 세션이므로 적절. |
| **ship** (local) | 검증 대상으로 파일을 읽음. 런타임 테스트는 다음 구현 세션에서. |

### Skill Gaps

이 세션에서 별도의 스킬 갭은 식별되지 않음. 설계 논의는 에이전트-사용자 대화로 충분히 진행됨.

향후 고려: `cwf:review` 구현 후, 설계 논의의 결과물(master-plan 변경)을 자동 리뷰하는 데 사용할 수 있을 것.
