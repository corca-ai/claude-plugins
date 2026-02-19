# Retro: Retro v2 — Adaptive Session Retrospective

> Session date: 2026-02-06
> Mode: light

## 1. Context Worth Remembering

- Marketplace v2는 3개 phase로 구성: Phase 1 gather-context, Phase 2 clarify, Phase 3 retro. 이번 세션으로 전부 완료.
- `feat/marketplace-v2` 브랜치에서 3개 플러그인의 major version bump (모두 → 2.0.0)을 진행. PR #7로 main 머지 대기 중.
- retro v2의 핵심 설계: "light by default" — 에이전트가 세션 무게를 판단하여 모드 선택. Section 5(Expert Lens)와 6(Learning Resources)은 deep 전용.
- 설치된 플러그인 캐시(`~/.claude/plugins/cache/`)는 소스 수정만으로 반영되지 않음. `claude plugin update` 또는 `scripts/update-all.sh` 필요. 이번 세션에서 `/retro`가 v1.6.0으로 로드된 것이 그 증거.

## 2. Collaboration Preferences

- 유저가 상세한 plan을 제공하면 Claude는 확인 질문 없이 바로 구현에 들어간다. 이번 세션은 plan이 충분히 상세해서 이 패턴이 잘 작동했다.
- "이제 뭐가 남았는지 궁금하네요" — 구현 완료 후 전체 진행 상황을 요약해주는 것을 선호. 개별 파일이 아닌 phase 단위의 조감도.
- PR 설명에 "리뷰 포커스"를 명시적으로 요청 — 리뷰어 시간을 아끼는 구조화된 PR description을 중시.

### Suggested CLAUDE.md Updates

- `docs/project-context.md`의 retro 항목을 v2.0.0으로 업데이트 필요 (현재 v1.6.0으로 기술됨)

## 3. Waste Reduction

**전반적으로 낭비가 적은 세션.** Plan이 상세했고 구현이 직선적이었다.

- **컨텍스트 낭비 (경미)**: plugin-dev-cheatsheet.md를 초반에 읽었으나 실제로 참조한 건 version bump 규칙과 500줄 제한 정도. 이미 익숙한 내용이라 읽기를 생략해도 됐을 수 있지만, CLAUDE.md에서 "반드시 먼저 읽으라"고 지시하므로 프로토콜 준수 차원에서 정당.
- **놓친 지름길**: `update-all.sh`를 커밋 후 바로 실행하지 않았다. 유저가 PR을 먼저 요청했기 때문에 자연스러운 흐름이었지만, push 후 `update-all.sh`까지 한 번에 했다면 retro 시점에 v2.0.0이 캐시에 반영되어 있었을 것.
- **v1.6.0 로딩 이슈**: `/retro`를 실행했을 때 캐시에서 v1.6.0이 로드됨. v2 형식으로 작성하겠다고 선언하여 해결했지만, 이는 플러그인 업데이트를 커밋/푸시 후 바로 하지 않은 데서 온 결과. lessons.md의 "Skill loading is cache-based" 항목이 이미 이를 문서화하고 있음.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Version bump 1.6.0 → 2.0.0 (major)

| Probe | Analysis |
|-------|----------|
| **Cues** | Section 3 이름 변경("Prompting Habits" → "Waste Reduction")이 출력 형식의 breaking change를 구성 |
| **Knowledge** | plugin-dev-cheatsheet.md의 version bump 규칙: "Breaking change, renamed skill, changed API → major" |
| **Options** | (A) minor bump (1.7.0) — 기능 추가(--deep)에 초점, (B) major bump (2.0.0) — Section 이름 변경 + 출력 형식 변경에 초점 |
| **Basis** | Section 이름이 바뀌면 retro.md를 파싱하는 다운스트림 도구가 깨질 수 있음. 보수적으로 major를 선택. 또한 marketplace v2 phase 전체가 major bump 패턴을 따르고 있어 일관성도 고려. |
| **Hypothesis** | minor로 했다면 기능상 문제 없지만, 나중에 "왜 Section 3 이름이 바뀌었는데 minor인가"라는 의문이 생길 수 있음 |

**Key lesson**: 출력 형식의 구조적 변경(섹션 이름, 필드 추가/삭제)은 소비자 관점에서 breaking change. 의심스러우면 major로.

### CDM 2: SKILL.md에 Glob 추가

| Probe | Analysis |
|-------|----------|
| **Cues** | Section 7의 설치 스킬 스캔이 `~/.claude/plugins/*/skills/*/SKILL.md` 글로브 패턴을 사용 |
| **Knowledge** | SKILL.md frontmatter의 `allowed-tools`가 스킬 실행 시 사용 가능한 도구를 제한함 |
| **Options** | (A) Glob 추가, (B) Bash로 `ls` 또는 `find` 사용, (C) Task 서브에이전트에 위임 |
| **Basis** | Glob은 가장 직접적이고 도구 정책상 권장되는 방식. Bash find는 우회적이고, Task는 과도 |
| **Aiding** | v1.6.0의 allowed-tools 목록을 읽은 것이 Glob 누락을 발견하게 함 |

**Key lesson**: 새 워크플로우 단계를 추가할 때 해당 단계에 필요한 도구가 allowed-tools에 있는지 확인.

## 5. Expert Lens

> `/retro --deep` 실행 시 전문가 분석을 받을 수 있습니다.

## 6. Learning Resources

> `/retro --deep` 실행 시 학습 자료를 받을 수 있습니다.

## 7. Relevant Skills

### Installed Skills

현재 설치된 스킬 중 이번 세션에 관련된 것:

- **retro** (corca-plugins, v1.6.0 캐시): 이번 세션에서 업그레이드 대상이었던 스킬. 세션 종료 시 실행되었으나 캐시가 아직 v1.6.0.
- **plugin-deploy** (로컬 스킬, `.claude/skills/`): 플러그인 수정 후 배포 자동화 스킬. 이번 세션에서 사용하지 않았으나, version bump → marketplace sync → README 업데이트 → 테스트 과정을 자동화할 수 있었음. 다만 수동 과정이 충분히 짧아 실익은 크지 않았을 것.
- **refactor-skill** (로컬 스킬, `.claude/skills/`): SKILL.md 리팩토링 분석 스킬. retro v2의 SKILL.md가 223줄로 충분히 짧아 이번에는 불필요.

### Skill Gaps

이번 세션에서 새로운 스킬 갭은 식별되지 않음. 구현-커밋-푸시-PR 흐름이 기존 도구로 충분히 커버됨.
