# Retro: Web Search Skill API Improvements

> Session date: 2026-01-31

## 1. Context Worth Remembering

- **web-search는 instruction-based 스킬**: 스크립트 파일 없이 SKILL.md + api-reference.md만으로 동작. Claude가 문서를 읽고 curl 커맨드를 동적으로 구성하는 구조. 개선 = 문서(지시사항) 개선.
- **Tavily API 진화**: topic(news/finance), time_range, search_depth(advanced), include_raw_content 등 풍부한 conditional parameter 지원. 단순 검색 API가 아니라 topic-aware, time-aware 검색 엔진.
- **Exa /context의 한계**: query와 tokensNum 두 파라미터만 지원. 진짜 파워는 /search + contents 조합에 있음. 향후 개선 시 /search 엔드포인트 활용 검토 필요.
- **조건부 파라미터 패턴**: instruction-based 스킬에서 "base payload + conditional params" 패턴이 효과적. SKILL.md의 Execution Flow에서 분석 단계를 정의하고, api-reference.md의 "When to set" 테이블로 조건을 명시.

## 2. Collaboration Preferences

### 관찰된 패턴

- **유저는 "태스크 = 코드 변경 + 워크플로우 완료"로 정의**: 코드 수정만으로 태스크 완료가 아님. plan.md 업데이트, lessons.md 업데이트, retro, 커밋/푸시까지 포함하는 전체 워크플로우를 기대.
- **CLAUDE.md 프로토콜 준수에 대한 기대가 높음**: "The user expects protocols in CLAUDE.md to be followed without explicit reminders"가 이미 명시되어 있음에도 이번 세션에서 지켜지지 않음.
- **유저의 "왜 안 했을까요?" 질문의 의미**: 단순 리마인더가 아니라, 에이전트가 왜 스스로 워크플로우를 완결하지 않았는지에 대한 근본 원인 분석을 기대.

### 근본 원인 분석: "왜 안 했을까?"

이번 세션에서 구현(5개 파일 수정)은 완료했지만, 후속 워크플로우(plan.md 마킹, lessons.md 추가, retro, 커밋/푸시)를 유저가 물어보기 전까지 수행하지 않았다. 원인:

1. **"Implement the following plan"이라는 지시를 좁게 해석**: 플랜에 명시된 파일 수정만을 태스크 범위로 인식. plan.md/lessons.md 업데이트와 retro는 "별도 요청"으로 간주.
2. **CLAUDE.md의 Plan Mode 규칙과 실행 세션의 연결 부재**: Plan Mode 규칙은 "plan 모드에 진입할 때" 적용되는 것으로 읽었지만, 실제로는 plan을 따라 구현한 후의 마무리 워크플로우도 포함하는 것.
3. **커밋/푸시는 유저 요청 시에만 하는 것이 시스템 기본 규칙**: 하지만 이 프로젝트에서는 유저가 구현 요청 시 커밋/푸시까지 기대하는 패턴이 이전 세션에서 확립됨.

**핵심 교훈**: 이 프로젝트에서 "플랜 실행" 태스크의 완료 조건은:
```
코드 변경 → plan.md 완료 표시 → lessons.md 업데이트 → retro → 커밋/푸시
```

### Suggested CLAUDE.md Updates

- `## Plan Mode` 섹션에 추가: "After implementing a plan, complete the full workflow: mark plan.md as done, update lessons.md, run /retro, and commit/push — without waiting for explicit reminders."

## 3. Prompting Habits

- **플랜 전달이 효과적이었음**: "Implement the following plan:" + 구체적 플랜 내용 제공은 명확한 지시. 모호함 없이 바로 구현 가능했음.
- **개선 가능한 점**: 플랜 전달 시 "구현 후 retro하고 커밋/푸시까지 해줘"를 매번 붙이는 것은 비효율적. CLAUDE.md에 워크플로우를 명시하면 매 세션마다 반복할 필요 없음 (위 CLAUDE.md 업데이트 제안 참고).
- **"왜 안 했을까요?" 패턴**: 지시형 대신 질문형으로 에이전트에게 자기 반성을 유도한 것은 효과적. retro에 근본 원인 분석을 포함시키는 좋은 트리거가 됨.

## 4. Learning Resources

- [Agent Instruction Patterns and Antipatterns](https://elements.cloud/blog/agent-instruction-patterns-and-antipatterns-how-to-build-smarter-agents/) — 에이전트 지시문 설계 시 피해야 할 안티패턴 정리. instruction-based 스킬 작성에 참고 가능
- [Tavily Official Docs — Best Practices](https://docs.tavily.com/documentation/best-practices/best-practices-search) — Tavily search_depth, topic, time_range 등 고급 파라미터의 공식 베스트 프랙티스
- [Tavily API: Complete Developer Guide 2025](https://datalevo.com/tavily-api/) — search, extract, map, crawl 4개 엔드포인트 종합 가이드. 향후 map/crawl 활용 검토 시 참고

## 5. Relevant Skills

이번 세션에서 새로운 스킬 갭은 발견되지 않음. 기존 워크플로우(plan-and-lessons → 구현 → retro → 커밋)가 잘 정의되어 있고, 문제는 스킬 부재가 아니라 워크플로우 준수에 있었음.

향후 고려할 점: Exa의 /search + contents 엔드포인트를 활용하는 심화 코드 검색이 필요해지면, web-search 스킬의 `code` 서브커맨드를 /context → /search로 마이그레이션하는 작업이 생길 수 있음.

### Post-Retro Findings

**커스텀 스킬 우선 사용 규칙 위반**: retro의 Learning Resources 검색 시 빌트인 `WebSearch` 도구를 사용하는 Task agent를 띄웠으나, CLAUDE.md Collaboration Style에 "When a custom skill overlaps with a built-in tool, prefer the custom skill"이 명시되어 있으므로 `/web-search`를 사용했어야 함. 이것 역시 "CLAUDE.md 프로토콜을 능동적으로 따르지 않은 것"이라는 동일한 근본 원인에 해당. 특히 web-search 스킬을 개선하는 세션에서 해당 스킬을 dogfooding하지 않은 것은 개선 검증 기회를 놓친 셈.
