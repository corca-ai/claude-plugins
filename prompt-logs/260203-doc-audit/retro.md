# Retro: 문서 감사 및 개선

> Session date: 2026-02-03

## 1. Context Worth Remembering

- 이번 감사로 문서 총량이 ~850줄 감소 (claude-marketplace.md 510→43, api-reference.md 381→56, checklist.md 중복 제거)
- Progressive disclosure 계층이 확립됨: CLAUDE.md(포인터, ~50줄) → cheatsheet(~150줄) → deep docs(modifying-plugin, adding-plugin, skills-guide, marketplace-ref)
- project-context.md가 이번에 Architecture Patterns, Plugins 섹션이 추가되어 프로젝트의 "살아있는 지식"으로서 역할이 강화됨

## 2. Collaboration Preferences

- 유저의 프롬프트가 매우 효과적이었음 — 감사 기준을 명시적으로 나열 ("빠진 내용 / 방대 / 과도한 구체성 / 중복 / progressive disclosure")하여 별도 질문 없이 즉시 작업 가능
- "plan-and-lesson 프로토콜 이용해서 개선 계획 작성 후 진행, retro, commit, push"라는 한 줄로 전체 워크플로우를 지정 — CLAUDE.md에 이미 이 패턴이 반영되어 있음
- 문서 전용 작업에서도 EnterPlanMode를 사용하는 것이 유효했음 — 변경 범위가 6개 파일 10개 항목이라 계획 없이는 누락 위험이 있었을 것

CLAUDE.md 변경 제안 없음 — 현재 CLAUDE.md가 이 세션의 워크플로우와 잘 정렬되어 있음.

## 3. Prompting Habits

이 세션에서 프롬프팅 관련 문제는 발생하지 않음. 유저의 프롬프트 패턴이 인상적인 점:

- **체크리스트형 기준 제시**: "빠진 내용은 없는지 / 지나치게 방대하거나 / 너무 지능을 믿지 않고 구체적이거나 / 지나치게 중복이 있거나 / progressive disclosure 원칙을 지키지 않았거나" — 이 패턴은 향후에도 감사 작업에 효과적
- **의도 확인 요청** ("의도를 이해하셨나요?"): 대규모 작업 전 인식 정렬을 위한 좋은 습관

## 4. Learning Resources

- [Diátaxis Documentation Framework](https://docs.divio.com/documentation-system/) — 문서를 Tutorials, How-to, Reference, Explanation 4가지로 분류하는 프레임워크. 이번 감사에서 적용한 "독자별 적정 수준" 원칙과 직접 연결됨
- [6 Things Developer Tools Must Have in 2026 (Evil Martians)](https://evilmartians.com/chronicles/six-things-developer-tools-must-have-to-earn-trust-and-adoption) — 개발자 도구의 discoverability와 progressive disclosure를 다룸. CLI 플러그인 생태계 설계에 참고 가치 있음
- [SwiftUI API Design: Progressive Disclosure (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10059/) — API/인터페이스 설계에서 progressive disclosure를 적용하는 사례. SKILL.md 설계 철학("적절한 자유도 설정")과 맥이 같음

### Post-Retro Findings

1. **Prior Art 검색을 plan 단계 기본 동작으로**: 유저가 "모든 plan은 설계 아닌가?"라고 지적. How to Measure Anything 인용 — "It's been done before—don't reinvent the wheel." 검색 비용 대비 잠재 가치가 비대칭적으로 높음. → protocol.md에 "Prior Art Search" 섹션 추가, plan-and-lessons v1.2.0
2. **버전 누락 발견**: web-search api-reference.md를 381→56줄로 대폭 수정했지만 plugin.json 버전을 안 올림. 플러그인 내부 파일은 어떤 것이든 바뀌면 patch 이상 bump 필요. → web-search v2.0.1

## 5. Relevant Skills

이 세션에서 명확한 스킬 갭은 없음. "문서 감사"는 빈도가 낮은 작업이라 전용 스킬보다는 필요 시 ad-hoc으로 진행하는 것이 적절. 다만, 이번 감사에서 발견한 체크리스트(단일 출처 원칙, 독자별 수준, 죽은 문서 감지)는 lessons.md에 기록되어 향후 감사 시 참조 가능.
