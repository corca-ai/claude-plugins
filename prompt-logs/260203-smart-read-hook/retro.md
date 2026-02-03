# Retro: smart-read Hook Plugin

> Session date: 2026-02-03

## 1. Context Worth Remembering

- 유저는 별도 세션(exported.txt)에서 `@` 파일 첨부 vs 경로 텍스트의 차이를 탐구하다가, 파일 크기 기반 지능적 읽기 전략을 구상했음. CLAUDE.md에 규칙으로 넣는 방안까지 도출했으나, hook 플러그인이 더 효과적이라는 결론에 도달.
- 유저는 이전 세션의 아이디어를 exported.txt로 내보내고, 새 세션에서 구현을 이어가는 패턴을 사용. 이때 "이 대화를 hook으로 만들 여지가 있을지" 같은 탐색적 질문으로 시작하여, 타당성 확인 후 구현으로 진행.
- `PreToolUse` hook의 `updatedInput`, `additionalContext`, `permissionDecision` 세 가지 출력이 이 플러그인의 핵심 도구. 특히 `additionalContext`가 CLAUDE.md 방식의 상위 호환(턴 소모 없이 정보 주입)이라는 점이 핵심 인사이트.

## 2. Collaboration Preferences

- 유저는 아이디어 탐색 → 타당성 검증 → plan mode → 구현의 흐름을 선호. 이 세션에서도 "만들 여지가 있을지"라는 열린 질문으로 시작, 에이전트가 분석 결과를 표로 정리해 보여주자 "브랜치 파서 plan mode 거쳐서 만들어봅시다"로 자연스럽게 전환.
- plan mode에서 AskUserQuestion으로 핵심 설계 결정 3개(이름, deny 전략, 환경변수)를 한 번에 물어본 것이 효율적이었음. 유저가 모든 항목에서 Recommended를 선택 — 에이전트가 제안한 기본값이 유저의 의도와 잘 맞았음을 의미.
- 유저는 구현 완료 후 retro와 lesson을 명시적으로 요청("끝나면 retro도 해주세요. 중간에 lesson 작성도 잘 해주시고요") — CLAUDE.md의 워크플로우를 따르되 리마인더를 줌.

### Suggested CLAUDE.md Updates

- "After implementing a plan" 워크플로우 목록에 "commit and push" 전에 `/plugin install`로 로컬 테스트 검증 단계를 명시적으로 추가할 것을 제안. 현재는 "update the marketplace and verify globally installed plugin versions"만 있어서, 커밋 전 로컬 설치 테스트가 빠져 있음.

## 3. Prompting Habits

- **exported.txt 활용이 효과적**: 이전 세션의 대화를 텍스트로 내보내 새 세션에서 참조한 것은 좋은 패턴. 다만 exported.txt 전체를 첨부하기보다, 핵심 결론만 요약해서 전달하면 컨텍스트를 더 절약할 수 있음.
  - 현재: "별도 세션에서 @exported.txt 와 같은 대화를 나눴습니다"
  - 개선안: "이전 세션에서 파일 크기 기반 지능적 읽기 전략을 논의했습니다. 핵심: (1) @은 전체 인라인, (2) Read도구는 hook 가능, (3) CLAUDE.md보다 hook이 강제성/효율성 우위. exported.txt에 전문 있음."
  - 이렇게 하면 에이전트가 exported.txt를 읽어야 할지 즉시 판단 가능

## 4. Learning Resources

- [Hooks Reference - Claude Code Docs](https://code.claude.com/docs/en/hooks) — 공식 hook 문서. `PreToolUse`의 `updatedInput`, `additionalContext`, `permissionDecision` 등 전체 출력 스키마 참조.
- [Hook Development Skill (anthropics/claude-code)](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md) — Anthropic이 제공하는 hook 개발 가이드 skill. hook 작성 패턴과 베스트 프랙티스 포함.
- [Understanding Claude Code's Context Window](https://damiangalarza.com/posts/2025-12-08-understanding-claude-code-context-window/) — 컨텍스트 윈도우의 작동 원리와 토큰 소비 구조 설명. smart-read hook이 해결하려는 문제의 배경 이해에 도움.
- [My Claude Code Context Window Strategy (Reddit)](https://www.reddit.com/r/ClaudeAI/comments/1p05r7p/my_claude_code_context_window_strategy_200k_is/) — 실제 사용자의 컨텍스트 윈도우 관리 전략. "200k가 부족한 게 아니라 태우는 방식이 문제"라는 관점이 smart-read의 철학과 일치.

## 5. Relevant Skills

이 세션에서 새로운 skill gap은 발견되지 않았음. smart-read 자체가 hook 플러그인으로 구현되었으며, 기존 플러그인 생태계(plan-and-lessons, web-search 등)의 패턴을 잘 따랐음.

한 가지 향후 고려사항: smart-read hook이 실제 사용에서 어떤 패턴으로 deny/warn이 발생하는지 로깅하는 기능이 있으면 임계값 튜닝에 도움될 수 있음. 이는 별도 세션에서 검토할 사항.

### Post-Retro Findings

- 로컬 플러그인 테스트 시 `claude plugin install`이 아닌 `claude --plugin-dir ./plugins/<name>` 플래그를 사용해야 함. 에이전트가 이 방법을 모르고 `plugin install` → `plugin validate` 등을 시도하다 실패 — 유저가 직접 알려줌. CLAUDE.md나 docs/modifying-plugin.md에 로컬 테스트 명령어를 명시하면 재발 방지 가능.
