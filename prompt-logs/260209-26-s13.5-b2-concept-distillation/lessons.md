# Lessons — S13.5-B2 Concept Distillation + README v3

### 분석 산출물의 위치 판단 — "reference vs session artifact" 구분 기준

- **Expected**: Jackson 프레임워크 적용 결과이므로 `references/essence-of-software/` 옆에 두는 것이 자연스러울 것
- **Actual**: 3단계 위치 착오 발생. 처음 `docs/` (T2: consumer count 기준 → project-level) → 유저 피드백으로 `references/` (외부 프레임워크 적용물) → 최종적으로 `prompt-logs/` (세션 산출물)
- **근본 원인**: "누가 이 문서를 참조하는가"만 보고, "이 문서가 언제 쓰이는가"를 놓침. Consumer count는 위치의 한 축이지만, lifecycle이 더 중요한 축. 분석 결과는 README라는 최종 deliverable에 흡수되면 역할이 끝남 — 영구 레퍼런스가 아니라 중간 산출물
- **Takeaway**: 문서 위치 결정 시 2축 판단: (1) consumer count (누가 읽는가), (2) lifecycle (언제까지 유효한가). Lifecycle이 세션 범위면 prompt-logs/, 프로젝트 범위면 docs/ 또는 references/

When 문서 위치 결정 → consumer count + lifecycle 2축 판단. 세션 산출물(분석 결과, 중간 문서)은 prompt-logs/에 남기고 cwf-state.yaml session history로 추적. 영구 참조만 docs/ 또는 references/

### Jackson의 "Skill Conventions"는 concept가 아니다

- **Expected**: Phase-handoff에서 식별한 6개 generic concept 후보 중 Skill Conventions도 generic concept일 것
- **Actual**: Skill Conventions는 Jackson의 specificity principle이 실현된 구조적 균일성(structural uniformity)이지, 자체 operational principle을 가진 behavioral concept이 아님. OP를 쓰려고 하면 "when a skill follows the template, users find it familiar"가 되는데, 이건 Jackson의 Familiarity 원칙 자체이지 독립 concept이 아님
- **Takeaway**: Concept 후보를 검증할 때 OP를 써볼 것. OP가 기존 원칙(Familiarity, Specificity 등)을 반복하면 그것은 concept가 아니라 원칙의 적용임

### "Agent Patterns" → "Agent Orchestration"으로 리네이밍

- **Expected**: Phase-handoff의 "Agent Patterns" 명칭을 그대로 사용
- **Actual**: "Patterns"는 구현 전략(Single, Adaptive, Agent team, 4 parallel)을 열거하는 분류 체계이고, concept의 purpose("parallelize work without sacrificing quality")를 반영하지 못함. "Orchestration"이 purpose를 더 직접적으로 표현
- **Takeaway**: Concept 이름은 구현 분류가 아니라 purpose를 반영해야 함. Jackson의 "purpose distinct from specification" 원칙이 이름에도 적용됨

### Session Lifecycle — infrastructure vs concept의 경계

- **Expected**: cwf-state.yaml 중심의 세션 관리가 7번째 generic concept이 될 수 있을 것
- **Actual**: 현재 cwf-state.yaml는 shared data store로만 기능함. Skills가 읽고 쓰지만, "세션 상태가 변하면 X가 자동으로 발생한다"는 고유한 behavior가 없음. check-session.sh가 artifact 검증을 하지만 이는 외부 스크립트이지 concept의 action이 아님
- **Takeaway**: Data store ≠ concept. Concept은 purpose + behavior(OP)가 있어야 함. CWF가 자동 stage transition이나 artifact enforcement를 내장하면 그때 concept으로 승격 가능

### README 구조: "왜 → 무엇 → 어떻게" 순서의 효과

- **Expected**: 기존 README처럼 Installation을 먼저 두고 plugin 설명을 나열하면 충분할 것
- **Actual**: Concept distillation을 먼저 수행하고 그 결과를 README의 "Why CWF?"와 "Core Concepts" 섹션으로 변환하니, 9개 skill의 개별 설명이 반복적이지 않고 각각이 어떤 concept 조합인지로 차별화됨. 336줄 → 273줄로 19% 감소하면서도 정보 밀도는 증가
- **Takeaway**: README 재작성 시 concept analysis를 먼저 수행하면, 개별 feature 나열이 아닌 concept composition으로 설명할 수 있어 중복 감소 + 이해도 향상

### Concept distillation → refactor 스킬 통합 설계 방향 (미구현)

- **Observation**: Concept distillation이 refactor의 분석 품질을 높일 수 있는 3가지 통합 지점 식별
- **Integration Point 1 — Deep Review에 concept integrity 기준 추가**: 스킬이 주장하는 generic concept 조합이 실제 구현(phase 구조, sub-agent 패턴)과 일치하는지 검증. 예: Expert Advisor를 쓴다고 했으면 contrasting framework 강제 로직이 있는가?
- **Integration Point 2 — Holistic에 synchronization analysis 차원 추가**: 같은 generic concept를 동기화하는 스킬들이 일관된 방식으로 구현하는가? Under-synchronization(빠뜨린 concept) / over-synchronization(불필요한 복잡도) 감지
- **Integration Point 3 — criteria 문서에 concept map 내장**: holistic-criteria.md 또는 review-criteria.md에 synchronization map(9×6 테이블)을 reference로 포함. Provenance가 자연스럽게 작동 — concept map의 provenance가 스킬 추가/변경 시 staleness 감지
- **설계 결정 필요**: concept-distillation.md를 references/로 승격할지, criteria 문서에 요약본을 내장할지
- **Status**: 별도 세션에서 설계 + 구현 필요. 소스 문서: `prompt-logs/260209-26-s13.5-b2-concept-distillation/concept-distillation.md`

### 유저 피드백에 대한 과도한 동의 — 독립적 판단 부족

- **Expected**: 유저가 distillation 문서 위치를 `references/`로 제안했을 때, lifecycle 관점에서 반론을 제시해야 했음
- **Actual**: 유저 제안에 바로 동의하고 위치를 변경함. 결과적으로 유저 스스로 `prompt-logs/`가 맞다고 재수정
- **근본 원인**: CLAUDE.md의 "In design discussions, provide honest counterarguments and trade-off analysis. Do not just agree" 규칙이 있음에도, 유저의 판단에 즉시 순응하는 패턴. 특히 문서 위치처럼 "정답이 하나가 아닌" 설계 결정에서 반론 없이 동의하는 것은 유저에게 도움이 안 됨
- **Takeaway**: 유저 제안이 합리적으로 보여도, 1) 현재 판단의 근거를 먼저 설명하고, 2) 유저 제안의 장점을 인정하되, 3) trade-off를 명시한 후 유저가 결정하게 할 것. "동의 후 수정"보다 "반론 후 합의"가 품질이 높음
