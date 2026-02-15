# Retro: `/retro` Skill 만들기

> Session date: 2026-01-30

## 1. Context Worth Remembering

- **프로젝트 성격**: corca-plugins는 "AI Native Product Team"을 위한 Claude Code 플러그인 마켓플레이스. 스킬, 훅, export 도구 등이 포함됨
- **스킬 설계 철학**: SKILL.md는 Claude에게 "무엇을 하라"만 알려주고, "어떻게 분석하라"는 설명하지 않음 (skills-guide.md 원칙: "don't explain what Claude already knows")
- **Plan & Lessons Protocol**: 이 프로젝트에서는 plan mode 진입 시 `prompt-logs/{YYMMDD}-{title}/` 디렉토리에 plan.md와 lessons.md를 생성하는 프로토콜이 있음. 시스템의 plan mode와 별개로 수행해야 함
- **문서 언어 규칙**: 영어가 기본이되, README.md와 AI_NATIVE_PRODUCT_TEAM.md는 한국어. lessons.md와 retro.md는 유저의 언어를 따름
- **개밥먹기 문화**: 새로 만든 도구를 그 세션 안에서 바로 테스트하는 것을 중시함

## 2. Collaboration Preferences

- **한국어 대화, 영어 코드**: 유저는 한국어로 소통하지만 코드와 기술 문서(docs/)는 영어로 작성하길 기대함
- **의도 확인 먼저**: 유저가 "의도를 이해하셨나요?"라고 묻는 패턴이 있음. 구현 전 이해도 확인을 중시함
- **프로토콜 준수 기대**: CLAUDE.md에 적힌 프로토콜(Plan & Lessons 등)이 자동으로 따라지길 기대함. 별도 지시 없이도
- **간결한 리뷰 포인트**: 유저의 피드백은 핵심을 짧게 짚음 ("Language 지시는 별도 섹션으로 분리해야 눈에 띈다" 등). 장황한 설명보다 한 문장 질문으로 문제를 드러냄

### Suggested CLAUDE.md Updates

- `## Plan Mode` 섹션에 시스템 plan mode와 프로젝트 프로토콜의 관계를 명시: "시스템이 지정하는 plan file에 쓰는 것과 별개로, `prompt-logs/` 디렉토리에 plan.md와 lessons.md를 생성할 것"

## 3. Prompting Habits

- **잘 된 점**: 초기 프롬프트에 실제 사용하는 회고 프롬프트 원문을 포함시킨 것이 효과적이었음. 추상적 설명보다 구체적 예시가 의도를 정확히 전달함
- **잘 된 점**: "그런데 이게 가능한지 모르겠네요"라며 불확실한 부분을 솔직히 표시한 것. Claude가 가능/불가능을 판단하는 데 도움이 됨
- **개선 가능한 점**: Plan & Lessons Protocol을 따를 것이라는 기대가 암묵적이었음. "Plan & Lessons Protocol을 따라서 진행해주세요"라고 명시하면 프로토콜 누락을 방지할 수 있음. 다만 이건 CLAUDE.md의 지시가 더 강력해지면 해결될 문제이기도 함

## 4. Learning Resources

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — PostToolUse 훅으로 EnterPlanMode 후 자동 알림을 만들 수 있는지 확인하는 데 유용. 유저가 언급한 "hook으로 Plan & Lessons Protocol을 강제"하는 아이디어와 직결
- [Extend Claude with skills](https://code.claude.com/docs/en/skills) — 공식 스킬 문서. SKILL.md frontmatter, progressive disclosure, 스킬 발견 메커니즘에 대한 정확한 레퍼런스
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) — Anthropic의 공식 모범 사례. CLAUDE.md 작성, 컨텍스트 관리 등
- [Awesome Claude Code Skills](https://github.com/travisvn/awesome-claude-skills) — 커뮤니티 스킬 모음. 다른 팀들이 어떤 스킬을 만들어 쓰는지 참고하기 좋음

## 5. Relevant Skills

이번 세션 자체가 스킬을 만드는 세션이었으므로 추가 스킬 갭은 크지 않음. 다만:

- **url-export 스킬**: `prompt-logs/260130-bring-notion2md/url-export.md`에 이미 계획된 통합 URL export 스킬이 미구현 상태. g-export, slack-to-md, notion-to-md를 하나의 진입점으로 통합하는 스킬로, 완성되면 자료 조사 단계의 워크플로우가 단순해질 것
- **Plan & Lessons Protocol 자동화**: 유저가 언급한 "EnterPlanMode hook" 아이디어가 실현되면, 스킬보다는 훅으로 구현하는 게 자연스러움. PostToolUse 훅에서 EnterPlanMode를 매칭해 `prompt-logs/` 디렉토리 생성을 자동 리마인드하는 방식

---

## Post-Retro 핑퐁에서 추가된 것

### Retro 산출물의 영속화

retro.md만 쓰고 끝내면 세션별 기록에 그침. 유저의 원래 의도는:
- **Section 1(Context)** → 프로젝트 레벨 영속 문서(`docs/project-context.md`)에 누적
- **Section 2(Collaboration Style)** → CLAUDE.md에 반영

이를 반영해 SKILL.md의 Step 5를 "Offer CLAUDE.md Updates" → "Persist Findings"로 확장함.

### EnterPlanMode 프로젝트 훅

Plan & Lessons Protocol 누락을 구조적으로 방지하기 위해 `.claude/hooks.json`에 `PostToolUse > EnterPlanMode` 훅을 추가함. 프로토콜의 구체적 행동을 훅에 적지 않고 "Follow the Plan & Lessons Protocol (docs/plan-and-lessons.md)"로만 안내하여, 프로토콜 변경 시 훅은 수정 불필요.

### SKILL.md Step 2 보강

기존 project context 문서를 Step 2에서 읽도록 추가. 이미 영속화된 컨텍스트와 중복 작성을 방지.
