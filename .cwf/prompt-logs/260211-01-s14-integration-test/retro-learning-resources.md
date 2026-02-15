# S14 Retro: Learning Resources

S14 세션의 핵심 주제들에 맞춰 선별한 학습 자료 3건입니다. 사용자의 현재 수준(AI-native 워크플로우 프레임워크를 직접 설계/구현하는 시니어 개발자)에 맞게 기초 튜토리얼이 아닌, 아키텍처 관점의 심화 자료를 선정했습니다.

---

## 1. Spec-Driven Development: Unpacking one of 2025's New Engineering Practices (ThoughtWorks)

**URL**: https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices

**핵심 내용**:
- Spec-driven development(SDD)는 "잘 작성된 소프트웨어 요구사항 명세를 프롬프트로 사용하여 AI 코딩 에이전트가 실행 가능한 코드를 생성하는 개발 패러다임"으로 정의됩니다. 명세의 품질 요소(Given/When/Then 시나리오, 도메인 지향 언어, 자연어+구조화 포맷의 조합)와 함께, 명세가 일회성 중간산물이 아닌 "source of truth"가 될 수 있는지에 대한 업계 논쟁을 다룹니다.
- Waterfall과의 결정적 차이점은 human-in-the-loop 리뷰를 통한 짧은 피드백 루프이며, "spec drift와 hallucination은 본질적으로 피하기 어렵기 때문에 결정론적 CI/CD가 여전히 필수"라는 현실적 조언을 담고 있습니다.

**S14 세션과의 연관성**:
S14에서 발견한 "LLM 기반 skill 시스템에서는 SKILL.md 명세 자체가 곧 구현"이라는 통찰과 직접적으로 맞닿습니다. CWF의 정적 검증 접근법(SKILL.md 스펙을 병렬 Explore 에이전트로 검증)은 SDD의 핵심 원리를 이미 실천하고 있는 것이며, 이 글은 그 실천을 더 넓은 업계 맥락에서 위치시켜 줍니다. 특히 "spec drift" 문제에 대한 경고는 CWF의 스킬 명세가 늘어날수록 주의해야 할 지점입니다.

---

## 2. Playwright MCP: A Modern Guide to Test Automation (Testomat.io)

**URL**: https://testomat.io/blog/playwright-mcp-modern-test-automation-from-zero-to-hero/

**핵심 내용**:
- Playwright MCP(Model Context Protocol)는 LLM이 스크린샷 대신 **접근성 트리(accessibility tree) 스냅샷**을 통해 웹 페이지와 상호작용하는 패러다임입니다. 시각적 픽셀 데이터가 아닌 의미론적(semantic) 페이지 구조를 전달하므로, 모델이 요소의 목적과 관계를 이해할 수 있습니다.
- Element ref(요소 참조)를 통해 CSS 셀렉터나 시각적 좌표에 의존하지 않는 안정적인 요소 타겟팅이 가능하며, UI가 변경되어도 자동화가 깨지지 않는 강건성을 확보합니다. 스냅샷 기반 접근은 대역폭과 처리 비용도 스크린샷 대비 훨씬 낮습니다.

**S14 세션과의 연관성**:
S14에서 WebFetch의 한계(JS 렌더링 사이트 성공률 9%)를 진단하고 agent-browser(headless Chromium CLI)를 해결책으로 설계했습니다. Playwright MCP의 접근성 트리 스냅샷 방식은 agent-browser 구현의 핵심 참고 아키텍처입니다. 특히 "스크린샷 vs 접근성 트리"라는 트레이드오프는 CWF의 웹 수집 도구 설계에서 반복적으로 마주칠 의사결정 지점이며, 이 자료가 각 접근법의 장단점을 명확히 정리해 줍니다.

---

## 3. Claiming Architecture: ADRs at Change-Time (Entrofi)

**URL**: https://www.entrofi.net/claiming-architectural-reality-part-1-adrs-at-change-time/

**핵심 내용**:
- 아키텍처 결정 기록(ADR)이 작성 후 방치되는 일반적인 문제를 해결하기 위해, **pre-commit hook에 ADR 인식을 통합**하는 방법을 제안합니다. 코드를 커밋하는 바로 그 순간에 관련 아키텍처 결정을 떠올리게 함으로써, ADR을 회고적 문서가 아닌 개발 플로우의 능동적 참여자로 전환합니다.
- 핵심 통찰은 "아키텍처 추론을 개발 흐름 안에서 가시화"하는 것이며, 이를 통해 과거 결정과 현재 구현 사이의 단절을 방지합니다.

**S14 세션과의 연관성**:
S14에서 24개 세션에 걸친 20개 아키텍처 결정을 v3-migration-decisions.md로 종합하는 작업을 수행했습니다. 이 자료는 그런 결정 기록이 "만들고 끝"이 아니라 지속적으로 코드 변경과 연동되어야 한다는 다음 단계를 제시합니다. CWF의 hook 시스템(pre-commit, post-session)에 아키텍처 결정 참조를 통합하면, v3-migration-decisions.md 같은 문서가 자연스럽게 살아있는 문서로 유지될 수 있습니다. 이는 AI 보조 반복 개발에서의 지식 관리라는 S14의 핵심 주제와 직접 연결됩니다.

---

## 보충: 함께 참고할 만한 자료

| 자료 | URL | 한줄 요약 |
|------|-----|-----------|
| JetBrains: Spec-Driven Approach for Coding with AI | https://blog.jetbrains.com/junie/2025/10/how-to-use-a-spec-driven-approach-for-coding-with-ai/ | Requirements.md -> Plan.md -> Tasks.md 3단계 워크플로우의 실전 가이드 |
| Dennis Adolfi: AI-Generated ADRs | https://adolfi.dev/blog/ai-generated-adr/ | Claude Code로 코드베이스 분석 -> ADR 자동 생성하는 실전 사례 |
| Zyte: Best Headless Browsers for Web Scraping (2026) | https://www.zyte.com/learn/best-headless-browsers-for-web-scraping/ | Playwright vs Puppeteer vs Selenium vs 관리형 브라우저 비교 분석 |

---

*Generated: 2026-02-11 | Session: S14 Retro*
*Search protocol: Tavily search -> WebFetch verification -> content synthesis*

<!-- AGENT_COMPLETE -->
