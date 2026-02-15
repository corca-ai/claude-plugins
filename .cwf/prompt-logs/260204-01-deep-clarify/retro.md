# Retro: deep-clarify 설계

> Session date: 2025-02-04

## 1. Context Worth Remembering

- 사용자는 LLM 프롬프팅의 미세한 차이가 출력 품질에 미치는 영향을 실무적으로 잘 이해하고 있음 (예시 앵커링 문제, 실존 전문가 이름의 효과 등)
- 스킬 설계에서 "모델의 창의성을 제약하지 않는 것"을 높이 가치 있게 봄 — 규칙을 최소화하고 원칙으로 유도하는 방향을 선호
- 서브에이전트 아키텍처에 대한 관심이 높음 — 단순히 병렬화가 아니라 "건설적 차이(constructive difference)"를 통한 품질 향상에 주목
- 기존 사용자에게 영향을 주지 않는 변경 전략을 선호 (v2 업데이트보다 별도 플러그인 분리)

## 2. Collaboration Preferences

- **토론 기반 설계**: 사용자는 "솔직한 의견"을 반복적으로 요청했고, 에이전트가 동의뿐 아니라 반론도 제시하길 기대함. 이 세션은 코드 작성 없이 순수하게 설계 토론만으로 진행되었으며, 사용자가 이를 의도적으로 선택함
- **점진적 아이디어 발전**: 사용자는 한 번에 완성된 요구사항을 주지 않고, 대화를 통해 아이디어를 점진적으로 발전시킴. 초기 "clarify 개선" → 3-tier 모델 → 서브에이전트 → 전문가 페르소나 → advisory 에이전트로 진화
- **세션 구분 의식**: 구현을 다음 세션으로 미루고, 이번 세션의 산출물(plan, lessons, retro)을 먼저 정리하는 것을 중시함

### Suggested CLAUDE.md Updates

- Collaboration Style에 추가: "설계 토론 세션에서는 에이전트의 솔직한 반론과 트레이드오프 분석을 기대함. 동의만 하지 말 것."

## 3. Prompting Habits

이 세션에서는 사용자의 프롬프팅이 효과적이었음. 특히:

- **"솔직한 의견이 듣고 싶습니다"** — 에이전트가 비판적 사고를 하도록 명시적으로 유도. 이것이 없었으면 에이전트가 모든 아이디어에 동의했을 가능성이 있음
- **"모두 제 생각에 불과하니 건설적으로 토론해봅시다"** — 위계 없는 토론 환경을 조성. 에이전트가 반론을 편하게 제시할 수 있게 함
- **세션 종료 타이밍 결정**: "이번 세션만으로 충분히 좋은 논의를 많이 한 것 같습니다"처럼 토론의 종료 시점을 명확히 선언한 것이 효과적. 에이전트가 불필요하게 구현으로 돌진하는 것을 방지

개선 가능한 점:
- v1 이름 논의에서 "이 스킬만의 별도 이름" 의 "이 스킬"이 v1인지 v2인지 모호했음. 결과적으로 AskUserQuestion 한 라운드가 추가됨. "v2에 새 이름을 주고 싶습니다"처럼 주어를 명시하면 더 빨랐을 것

## 4. Learning Resources

- [SocraSynth: Multi-LLM Agent Collaborative Intelligence](http://infolab.stanford.edu/~echang/SocraSynth.html) — Stanford에서 연구한 멀티-LLM 토론 프레임워크. deep-clarify의 advisory 에이전트 패턴과 직접적으로 관련됨. 토론 시 "contentious vs conciliatory" 톤 조절로 할루시네이션을 줄이는 방법론
- [Expert Persona Prompting (Emergent Mind 리뷰)](https://www.emergentmind.com/topics/expert-persona-prompting) — 전문가 페르소나 프롬프팅의 성능 이점, 견고성, 충실도에 대한 연구 종합. "모델과 태스크에 따라 효과가 비균일"하다는 발견이 중요 — deep-clarify의 grounding 제약조건의 근거
- [Multi-Agent Debate Strategies (Emergent Mind)](https://www.emergentmind.com/topics/multi-agent-debate-mad-strategies) — MAD(Multi-Agent Debate) 전략의 종합 리뷰. 특히 "divergent thinking → robust correctness" 패턴이 deep-clarify의 Advisor α/β 구조와 부합
- [Levels of Autonomy for AI Agents (Knight First Amendment Institute)](https://knightcolumbia.org/content/levels-of-autonomy-for-ai-agents-1) — AI 에이전트 자율성의 L1-L5 단계 정의. deep-clarify의 "자율 조사 → 선택적 질문" 패턴이 L3에 해당한다는 분석의 근거

## 5. Relevant Skills

- **deep-clarify 자체가 이 세션에서 식별된 스킬 갭**: 기존 clarify의 "모든 걸 물어보는" 방식의 한계를 느끼고 설계됨. 다음 세션에서 구현 예정
- 추가 갭 없음. suggest-tidyings에서 서브에이전트 fan-out 패턴이 이미 설계되어 있어 구현 참고 가능
