# Retro: plugin-deploy 스킬 구현

> Session date: 2026-02-03

## 1. Context Worth Remembering

- **로컬 스킬 vs 마켓플레이스 플러그인 구분 기준**: 범용성이 핵심. 어떤 프로젝트에서든 쓸 수 있으면 marketplace plugin (`plugins/`), 이 레포에서만 의미 있으면 local skill (`.claude/skills/`). plugin-deploy는 후자.
- **토큰 효율에 민감**: 유저는 에이전트의 반복적 문서 읽기 패턴을 관찰하고 개선을 요구함. 이 세션에서 치트시트(`docs/plugin-dev-cheatsheet.md`)를 만들어 해결.
- **Script delegation pattern**: 이 레포의 실행형 스킬(web-search, gather-context)은 SKILL.md가 의도 분석, 스크립트가 결정적 실행을 담당하는 패턴을 따름. plugin-deploy도 이 패턴 적용 (check-consistency.sh).

## 2. Collaboration Preferences

- **중간 피드백의 가치**: 유저가 구현 도중 interrupt하여 "이건 로컬 스킬이어야 한다"는 아키텍처 피드백을 줌. 이로 인해 marketplace 관련 작업 4개(plugin.json, marketplace.json, README×2, AI_NATIVE)가 불필요해져 작업량이 크게 줄었음.
- **"off-topic"이라도 중요한 피드백**: 토큰 낭비 지적은 off-topic으로 시작했지만, 치트시트라는 실질적 개선으로 이어짐. 유저는 세션의 맥락에서 벗어나더라도 개선 아이디어를 자유롭게 제시하는 스타일.
- **솔직한 의견 요구**: "I want to hear your frank opinion" — 에이전트가 동의만 하는 게 아니라 기술적 판단을 내리길 기대함. 이미 CLAUDE.md에 "professional objectivity" 관련 시스템 프롬프트가 있지만, 유저 수준에서도 이를 명시적으로 요구.

### Suggested CLAUDE.md Updates

- Collaboration Style에 추가: "When creating new skills or automation tools, first evaluate whether it should be a marketplace plugin (general-purpose, usable in any project) or a local skill (`.claude/skills/`, repo-specific). Prefer local skill unless the tool has clear cross-project utility."

## 3. Prompting Habits

- **효과적이었던 패턴**: "plan.md를 plan-and-lesson 프로토콜에 따라 구현해주세요. 구현 후 가능한 부분은 최대한 로컬 테스트, retro, commit, push." — 플랜 파일 포인터 + 기대하는 워크플로우를 한 문장에 담아 명확.
- **개선할 수 있는 패턴**: "세션에서 나갔다 오겠습니다" — 좋은 의도지만, 만약 에이전트가 결정이 필요한 open question(이 세션에서는 skill name, commit strategy 등)을 만나면 블로킹됨. 대안: open question에 대한 default 방향도 함께 제시하면 에이전트가 자율적으로 진행 가능. (이 세션에서는 플랜에 leaning toward가 있어서 괜찮았지만, 없었다면 멈췄을 것)

## 4. Learning Resources

- [Anthropic 공식: Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide) — hook의 PreToolUse/PostToolUse/Notification 이벤트와 프롬프트 기반 hook 등 공식 문서. 새 hook 개발 시 참조용.
- [Anthropic 공식 plugin-dev](https://github.com/anthropics/claude-code/blob/main/plugins/README.md) — Anthropic이 직접 만든 plugin-dev 플러그인. `/plugin-dev:create-plugin`으로 8단계 가이드 워크플로우 제공, skill/hook/MCP 개발 전용 에이전트 포함. corca-plugins의 plugin-deploy와 보완적으로 사용 가능.
- [Skills + Hooks + Plugins: How Anthropic Redefined AI Coding Tool Extensibility](https://medium.com/@hunterzhang86/skills-hooks-plugins-how-anthropic-redefined-ai-coding-tool-extensibility-72fb410fef2d) — 2026년 기준 Claude Code 플러그인 생태계 전체 조감도. 500+ 플러그인, 270+ 빌트인 스킬 현황.

## 5. Relevant Skills

이 세션에서 plugin-deploy 스킬 자체가 새로 만들어졌으므로 추가 스킬 gap은 없음.

다만 Anthropic 공식 `plugin-dev` 플러그인이 존재함 (`/plugin-dev:create-plugin`). 이것은 "새 플러그인을 처음부터 만드는" 워크플로우이고, corca의 `plugin-deploy`는 "만든 후 배포 준비를 자동화"하는 것이라 보완 관계. 공식 plugin-dev를 설치해서 create → deploy 파이프라인을 만드는 것도 검토할 만함.
