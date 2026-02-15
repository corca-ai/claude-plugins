### Tavily API 문서 탐색

- **Expected**: search_depth는 basic/advanced 두 가지일 것
- **Actual**: fast, ultra-fast 옵션도 추가됨 (2025년 7월). topic(news/finance), time_range, include_domains/exclude_domains, country 등 풍부한 필터링 옵션 존재
- **Takeaway**: Tavily는 단순 검색을 넘어 topic-aware, time-aware, domain-scoped 검색이 가능한 API로 진화함

### Exa API 문서 탐색

- **Expected**: /context 엔드포인트에 더 많은 옵션이 있을 것
- **Actual**: /context는 query와 tokensNum 두 파라미터만 지원. 대신 /search 엔드포인트에 type(neural/fast/auto/deep), category, includeDomains, contents(text/highlights/summary), context 등 풍부한 옵션 존재
- **Takeaway**: Exa의 진짜 파워는 /search + contents 조합에 있음. /context는 간편 래퍼일 뿐

### 스킬 설계 원칙

- **Expected**: 스크립트 파일을 수정하면 될 것
- **Actual**: web-search는 스크립트 없이 SKILL.md + api-reference.md만으로 동작하는 instruction-based 스킬
- **Takeaway**: 개선은 문서(지시사항) 수준에서 이루어져야 함. Claude가 쿼리를 분석하고 적절한 파라미터를 동적으로 선택하도록 지시하는 것이 핵심

When API 공식 문서를 조사할 때 → 엔드포인트별 파라미터 전수 조사 + "우리가 안 쓰는 것" 관점으로 gap analysis 수행

### Instruction-based 스킬에서 "조건부 파라미터" 표현법

- **Expected**: 코드처럼 if/else로 분기를 표현하면 될 것
- **Actual**: SKILL.md의 Execution Flow에서 분석 단계를 명확하게 정의하고, api-reference.md에서 "When to set" 컬럼이 있는 Conditional Parameters 테이블로 표현하는 것이 효과적
- **Takeaway**: 스크립트 없는 스킬에서는 "언제 어떤 파라미터를 추가하라"는 조건부 지시를 명확하게 분리하는 것이 핵심. base payload + conditional 패턴이 깔끔함

### README 양쪽 언어 동기화

- **Expected**: README.md만 수정하면 될 것
- **Actual**: README.ko.md도 항상 동기화해야 함 (CLAUDE.md에 명시됨)
- **Takeaway**: 플랜 단계에서 Files to Modify에 양쪽 README를 모두 포함시킬 것

### 커스텀 스킬 우선 사용 (dogfooding)

- **Expected**: retro에서 Learning Resources 검색 시 빌트인 WebSearch를 사용해도 될 것
- **Actual**: CLAUDE.md에 "커스텀 스킬이 빌트인 도구와 겹치면 커스텀 스킬을 우선하라"고 명시되어 있음. `/web-search`를 사용했어야 함
- **Takeaway**: 검색이 필요할 때 항상 `/web-search` 스킬을 먼저 쓸 것. 특히 해당 스킬을 개선하는 세션에서는 dogfooding이 검증 기회이기도 함
