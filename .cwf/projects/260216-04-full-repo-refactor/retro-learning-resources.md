# 세션 260216-04 학습 리소스

> 세션에서 다룬 핵심 주제(SSOT 다국어 문서 관리, 멀티 에이전트 오케스트레이션, 선언적 설정의 국제화)에 맞춰 선별한 외부 리소스 3건.

---

## 1. Localization as Code: A Composable Approach to Localization

**URL**: https://phrase.com/blog/posts/localization-as-code-composable-workflow/

**핵심 내용**: 로컬라이제이션을 소프트웨어 딜리버리 라이프사이클의 일급 시민(first-class citizen)으로 격상시키는 "as code" 패러다임을 체계적으로 설명한다. `.phrase.yml` 같은 선언적 설정 파일로 소스 언어, 대상 로케일, 파일 구조를 정의하고, CI/CD 파이프라인에서 번역 커버리지가 임계치 이하일 때 빌드를 실패시키는 게이팅(gating) 전략을 제시한다. 핵심 통찰은 번역을 "마지막 단계"가 아니라 피처 브랜치와 병렬로 진행하는 워크플로로 전환하여 drift를 구조적으로 방지하는 것이다.

**CWF 작업과의 연관성**: 이번 세션에서 한국어 README를 SSOT로 두고 영어 README를 파생 문서로 관리하면서 발견한 구조적 불일치(Design Intent 서브섹션 누락 등)는 정확히 이 글이 해결하려는 "out-of-band release" 문제에 해당한다. CWF의 13개 스킬 문서에 대해 `.phrase.yml`과 유사한 선언적 스킴을 도입하면 — 예를 들어 SSOT 언어의 섹션 구조를 스키마로 정의하고, 파생 언어 문서가 해당 스키마와 일치하는지 CI에서 자동 검증하는 방식 — `cwf:refactor --docs`가 수동으로 찾아낸 drift를 자동화된 게이트로 전환할 수 있다. CORCA003 lint 규칙이 문서보다 권위적이라는 세션 결정("AUTO_EXISTING 원칙")과도 일맥상통한다: 결정적 도구(deterministic tool) > 산문 문서(prose documentation).

---

## 2. Towards a Science of Scaling Agent Systems (arXiv 2512.08296)

**URL**: https://arxiv.org/html/2512.08296v1

**핵심 내용**: 180개 실험을 통해 멀티 에이전트 시스템의 스케일링 법칙을 정량적으로 도출한 연구다. 세 가지 핵심 발견: (1) **도구-조정 트레이드오프** — 도구가 16개인 환경에서 단일 에이전트 효율 0.466 대비 멀티 에이전트는 0.074~0.234로 급락한다. (2) **역량 천장** — 단일 에이전트 기준선이 약 45%를 넘으면 에이전트를 추가해도 조정 오버헤드만 증가한다. (3) **아키텍처별 에러 증폭** — 독립 에이전트는 17.2배, 중앙 집중형은 4.4배, 분산형은 7.8배로 에러가 증폭된다. 실용적 의사결정 규칙: 기준선 성공률 40% 미만의 어려운 태스크에만 멀티 에이전트를 투입하고, 도구 8개 이하의 구조화된 도메인에서는 중앙 집중형, 병렬 탐색에서는 분산형을 선택한다.

**CWF 작업과의 연관성**: 이번 세션에서 30개 이상의 병렬 서브 에이전트를 실행하며 토큰 한도에 여러 번 도달한 경험이 이 논문의 "도구-조정 트레이드오프"와 직접 매핑된다. CWF의 `cwf:refactor`가 holistic/deep/code/docs 4개 모드를 병렬로 돌리는 구조는 "자연스럽게 분해 가능한(naturally decomposable) 태스크"에 해당하여 멀티 에이전트가 유효하지만, 각 서브 에이전트가 사용하는 도구 수를 5개 이하로 제한하는 것이 효율적이다. 또한 논문의 메시지 포화 효과(c* ≈ 0.39 messages/turn)는 서브 에이전트 간 불필요한 통신을 줄이는 설계 지침으로 활용할 수 있다. "Hybrid 아키텍처가 Centralized 대비 230% 추가 비용으로 2%만 개선"이라는 수치는 CWF 오케스트레이터의 비용 최적화 전략에 직접 적용 가능하다.

---

## 3. Designing Cooperative Agent Architectures in 2025

**URL**: https://samiranama.com/posts/Designing-Cooperative-Agent-Architectures-in-2025/

**핵심 내용**: 프로덕션 멀티 에이전트 시스템의 4대 설계 축을 정리한다: (1) **다층 메모리** — 빠른 벡터 캐시 + 지식 그래프(출처 추적, SHA-256 해시) + 잠재 압축(160k+ 토큰 보존). (2) **조정 토폴로지** — manager-worker(태스크 분해가 명확한 경우), blackboard/shared KG(복잡한 오케스트레이션), peer debate(품질 검증). (3) **프로토콜 기반 협력** — MCP(Model Context Protocol)를 통한 표준화된 도구 인터페이스와 OAuth식 최소 권한 스코핑. (4) **거버넌스 프레임워크** — JSON 스키마 출력 검증, 지속적 평가, 명시적 컴퓨트 예산. 핵심 권고는 "manager-worker로 시작하고 베이스라인이 안정된 후에 복잡한 토폴로지로 진화하라"는 것이다.

**CWF 작업과의 연관성**: CWF는 이미 13개 스킬과 7개 훅 그룹을 가진 사실상의 manager-worker 아키텍처이며, 이 글의 권고와 정확히 일치하는 진화 경로 위에 있다. 특히 MCP 프로토콜 기반의 도구 인터페이스 표준화는 CWF의 `hooks.json` + `${CLAUDE_PLUGIN_ROOT}` 패턴과 구조적으로 유사하다 — 향후 CWF 훅을 MCP 서버로 래핑하면 벤더 독립성을 확보할 수 있다. 또한 "Agent-SafetyBench 보안 실패의 80%가 최소 권한 도구 적용으로 사라진다"는 수치는 `~/.claude/cwf-hooks-enabled.sh`에서 훅을 선택적으로 토글하는 현재 거버넌스 패턴의 가치를 정량적으로 뒷받침한다. 다층 메모리 아키텍처(벡터 캐시 + 지식 그래프)는 CWF 세션 아티팩트 시스템(`auto-register sessions`)의 자연스러운 확장 방향이다.

---

*검색 일자: 2026-02-16 | 검색 엔진: Tavily (search.sh, --deep)*
<!-- AGENT_COMPLETE -->
