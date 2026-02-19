# Retro: url-export 통합 스킬 생성

> Session date: 2026-01-30

## 1. Context Worth Remembering

- 이 레포는 코르카의 Claude Code 플러그인 마켓플레이스로, 스킬(g-export, slack-to-md, notion-to-md 등)과 훅(attention-hook)을 배포한다.
- 사용자는 스펙 문서를 `prompt-logs/{YYMMDD}-{title}/` 디렉토리에 미리 작성해두고, 그것을 기반으로 구현을 지시하는 워크플로우를 사용한다.
- SKILL.md-only 아키텍처라는 패턴이 있다 — 스크립트 없이 에이전트 지시만으로 기존 스킬들을 오케스트레이션하는 메타 스킬. url-export가 이 패턴의 첫 사례다.

## 2. Collaboration Preferences

- 사용자는 CLAUDE.md에 적힌 프로토콜을 **명시적으로 상기시키지 않아도** 에이전트가 스스로 따르길 기대한다. 이번 세션에서 plan mode 프로토콜을 따르지 않은 것에 대해 바로 피드백을 줬다.
- 사용자는 간결한 피드백 루프를 선호한다 — "plan-and-lesson을 따를 거라고 생각했는데 안 했네요"라는 한 문장으로 문제를 정확히 짚었다.
- 구현 결과물 자체에 대한 수정 요청 없이 **프로세스 준수 여부**에 대한 피드백을 우선시했다. 프로세스를 중요하게 여기는 사용자다.

### Suggested CLAUDE.md Updates

- `## Plan Mode` 섹션에 다음 내용을 추가할 것을 제안:
  - `For non-trivial implementation tasks, proactively use EnterPlanMode even when the user does not explicitly request it. The protocol applies whenever the task matches the criteria for planning (new plugin, multi-file changes, architectural decisions).`
- **적용 완료**: CLAUDE.md에 반영됨.

### Post-Retro Findings

- retro의 Persist Findings(Step 5) 과정에서 plan.md 작성 언어 관련 추가 학습이 발생했다: plan.md는 에이전트가 주 독자이므로 영어, lessons.md/retro.md는 사용자가 주 독자이므로 사용자 언어(한국어)로 작성해야 한다.
- 이 규칙은 세션 단위 lessons.md에만 있었으나, 사용자 피드백으로 `docs/plan-and-lessons.md`에 persistent하게 반영했다.
- 이처럼 retro 작성 후 사용자와의 핑퐁에서 새로운 학습이 발생하는 패턴이 반복된다. retro 스킬의 워크플로우에 post-retro 반영 단계가 필요하다. → retro SKILL.md에 Step 6 "Post-Retro Discussion" 추가 완료.
- prompt-logs 디렉토리 혼동: 스펙 문서가 `bring-notion2md/`에 있었다는 이유로 세션 아티팩트도 같은 디렉토리에 넣었으나, 현재 세션의 주제("url-export")로 새 디렉토리를 만들어야 했다. → `docs/plan-and-lessons.md`의 Location 섹션에 규칙 추가 완료.

## 3. Prompting Habits

- 이번 세션에서 사용자의 프롬프트는 효과적이었다: `prompt-logs/260130-bring-notion2md/url-export.md 에 따라 새 스킬을 만들어주세요` — 스펙 문서 경로를 명시하고 의도를 간결하게 전달했다.
- 개선 가능한 점: 스펙 문서에 plan mode 진입 여부를 명시하거나, CLAUDE.md 프로토콜 강화로 에이전트가 자동으로 따르게 만드는 것이 더 효과적이다. 사용자가 매번 "plan mode로 들어가세요"라고 말할 필요가 없도록.

## 4. Learning Resources

- [Using CLAUDE.MD files: Customizing Claude Code for your codebase](https://claude.com/blog/using-claude-md-files) — CLAUDE.md 작성 모범 사례. 프로토콜 강제 규칙을 더 정교하게 작성하는 데 참고.
- [Claude Code Best Practices: The Plan Mode](https://cuong.io/blog/2025/07/15-claude-code-best-practices-plan-mode) — Plan mode 활용 패턴 정리. 에이전트가 자발적으로 plan mode를 사용하는 워크플로우 설계에 참고.
- [Extend Claude with skills](https://code.claude.com/docs/en/skills) — 공식 스킬 가이드. SKILL.md-only 오케스트레이션 같은 고급 패턴 확인.
- [Claude Code Swarm Orchestration Skill](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea) — 멀티 에이전트 오케스트레이션 패턴. url-export처럼 메타 스킬을 설계할 때 참고할 수 있는 구조.

## 5. Relevant Skills

이번 세션에서 드러난 스킬 갭은 없다. url-export 자체가 기존 스킬들의 갭(통합 인터페이스 부재)을 해결하는 스킬이었다.

향후 고려할 점: 스펙 문서 → 구현 워크플로우가 반복된다면, "스펙 문서를 읽고 자동으로 plan mode 진입 + plan.md 생성 + 구현"까지 하는 스킬을 `skill-creator`로 만들 수 있을 것이다.
