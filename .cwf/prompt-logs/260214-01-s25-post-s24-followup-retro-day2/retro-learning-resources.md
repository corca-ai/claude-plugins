# Retro Learning Resources

## 1) Diátaxis: A systematic framework for technical documentation authoring
- URL: https://diataxis.fr/
- 핵심 요약: Diátaxis는 문서를 `Tutorial`, `How-to`, `Reference`, `Explanation` 네 가지 목적 기반 타입으로 분리해, 중복과 혼선을 줄이는 구조를 제시합니다. 특히 "한 문서, 한 목적" 원칙을 강제해 AGENTS/가이드 문서가 점점 비대해지는 문제를 예방하는 데 효과적입니다. 결과적으로 문서 품질 개선을 사람의 기억에 의존하지 않고 정보 구조 자체로 유도합니다.
- 이 레포에 바로 유용한 이유: 이번 세션에서 합의한 "less-is-more"와 "자동화 가능한 규칙은 prose가 아니라 gate로" 원칙을 문서 IA 수준에서 고정할 수 있습니다. 예를 들어 AGENTS.md는 운영 불변식(Explanation/Reference) 중심으로 유지하고, 실행 절차는 How-to 문서로 분리하는 리팩터링 기준으로 바로 쓸 수 있습니다.

## 2) pre-commit (Official Documentation)
- URL: https://pre-commit.com/
- 핵심 요약: pre-commit은 Git hook 실행을 언어/런타임 독립적으로 표준화하고, hook 버전 고정(rev pinning)으로 팀 전체의 검사 결과를 결정적으로 맞춰줍니다. `pre-commit`, `pre-push` 등 stage별 실행 정책을 선언적으로 관리해 "로컬 통과 = CI 통과"에 가까운 흐름을 만들 수 있습니다. 또한 신규 기여자도 한 번의 설치로 동일한 품질 게이트를 즉시 적용할 수 있습니다.
- 이 레포에 바로 유용한 이유: 현재 논의된 markdown/link/session 게이트를 hook 계층으로 분리 운영할 때, 수동 스크립트 호출 대신 단일 manifest 기반으로 유지보수 복잡도를 낮출 수 있습니다. `cwf:setup`에서 필수 선택을 받은 뒤 pre-commit 설치까지 연결하면 온보딩 편차를 줄이고 재현성을 높일 수 있습니다.

## 3) Anthropic Engineering — Building effective agents
- URL: https://www.anthropic.com/engineering/building-effective-agents
- 핵심 요약: 이 글은 에이전트 시스템을 설계할 때 가장 단순한 패턴에서 시작해 필요할 때만 복잡도를 올리라는 실전 원칙을 제시합니다. 또한 prompt chaining, routing, parallelization 같은 워크플로 패턴과 각 단계 사이의 명시적 검증(check) 지점을 강조해, 실패를 조기에 차단하는 구조를 설명합니다. 도구 인터페이스를 명확히 정의하고 관측 가능성을 확보하는 것이 운영 신뢰성의 핵심이라는 점도 구체적으로 다룹니다.
- 이 레포에 바로 유용한 이유: `cwf:setup` 단일 진입 설계와 훅 게이트 계층화를 진행할 때, "복잡도 점진 증가"와 "단계별 평가 게이트" 원칙을 바로 적용할 수 있습니다. 즉, 초기에는 최소 필수 질문+필수 게이트만 두고, 실제 실패 패턴 데이터가 쌓일 때 고급 훅/검증을 추가하는 운영 전략으로 연결됩니다.

<!-- AGENT_COMPLETE -->
