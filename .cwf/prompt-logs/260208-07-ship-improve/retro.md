# Retro: S4.5 /ship Skill Improvement

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- `/ship`은 local skill (`.claude/skills/ship/`)이며 marketplace plugin이 아님 — 따라서 `/plugin-deploy` 불필요, 버전 관리 없음
- ship 스킬의 템플릿 변수 체계: `{VARIABLE}` placeholder를 SKILL.md가 치환 지침으로 문서화하는 패턴. 템플릿 ↔ SKILL.md 간 변수명 일관성이 핵심
- moonlight의 `document-pr-process`를 참조 기준으로 사용 — 한글 PR, 결정 근거, 검증 절차, 인간 판단 분리 등의 패턴
- autonomous merge 설계: `인간 판단 필요 사항` 섹션 내용 + branch protection 상태로 2x2 decision matrix 구성

## 2. Collaboration Preferences

- 유저는 이전 세션에서 plan을 완성해두고, 구현 세션에서는 "Implement the following plan:" 으로 즉시 시작하는 패턴을 사용
- plan이 충분히 구체적일 때 추가 확인 없이 바로 구현 진행하는 것을 선호
- retro까지 자율적으로 수행하길 기대 — 명시적 요청 전에 완료되어야 함

### Suggested CLAUDE.md Updates

- `Plan Mode` 섹션의 step 3 "Run `/retro`"를 더 명시적으로: "Run `/retro` autonomously after updating lessons.md — do not wait for user to request it"

## 3. Waste Reduction

이 세션은 짧고 효율적이었음 (plan 실행 + 3 파일 수정). 주요 낭비 없음.

유일한 마찰: **retro를 유저가 직접 요청해야 했음**. CLAUDE.md step 3에 `/retro`가 이미 있지만, 실제로는 유저가 "retro 하고 나머지 합시다"라고 말해야 실행됨.

**5 Whys**:
1. 왜 유저가 retro를 요청해야 했나? → 에이전트가 구현 완료 후 자동으로 retro를 실행하지 않았음
2. 왜 자동 실행하지 않았나? → CLAUDE.md에 step이 있지만, "complete the full workflow" 지시가 충분히 강제적이지 않음
3. 왜 강제적이지 않나? → 현재 문구가 "After implementing a plan, complete the full workflow"로 되어 있어 에이전트가 유저 확인을 기다리는 것이 자연스러운 해석
4. 왜 유저 확인을 기다리나? → 구현 결과를 보고한 후 다음 단계로 넘어가기 전에 피드백을 받는 것이 일반적인 에이전트 행동
5. **근본 원인**: CLAUDE.md의 워크플로우 지시가 "do not stop between steps" 수준의 명시성이 부족. 또한 CWF 스킬(ship 등) 자체가 post-implementation 단계를 자동화하는 설계가 되어 있지 않음

**분류**: Process gap — CLAUDE.md 문구 강화 + CWF 스킬 설계 방향에 반영 필요

## 4. Critical Decision Analysis (CDM)

### CDM 1: PR 템플릿의 한글 섹션명 설계

| Probe | Analysis |
|-------|----------|
| **Cues** | plan의 "English output (should be Korean)" 문제 정의와 moonlight PR 예시 |
| **Goals** | 리뷰어 가독성 (한글) vs 기술 정확성 (코드/경로는 원문) vs 국제 협업 가능성 |
| **Options** | (1) 전체 한글, (2) 섹션명 한글 + 내용 혼합, (3) 영어 유지 + 한글 설명 추가 |
| **Basis** | solo project이므로 국제 협업 고려 불필요. moonlight 패턴이 검증됨. 코드/경로만 원문 유지하는 것이 가장 자연스러운 한글 기술 문서 작성 방식 |
| **Hypothesis** | 영어 유지를 선택했다면 원래 문제("low-quality output")가 해결되지 않았을 것 |

**Key lesson**: 문서 언어 결정은 실제 독자를 기준으로 — solo project은 작성자 언어, 팀 project은 팀 공용어.

### CDM 2: Autonomous merge의 2x2 decision matrix 설계

| Probe | Analysis |
|-------|----------|
| **Cues** | plan의 "no autonomous merge for solo projects" 문제 정의. solo project에서 매번 review approval을 기다리는 것이 불필요한 마찰 |
| **Goals** | 자동화 효율 vs 안전장치 유지. branch protection이 있는 경우 무시하면 안 됨 |
| **Options** | (1) 항상 autonomous, (2) human judgment 기반 conditional, (3) flag로 opt-in |
| **Basis** | `인간 판단 필요 사항` 섹션을 PR 작성 시점에 에이전트가 자기평가하므로, merge 시점에 이를 재활용하는 것이 자연스러움. branch protection은 repo 소유자의 의도이므로 존중 |
| **Aiding** | `gh api repos/.../branches/.../protection` — GitHub API로 branch protection 상태를 프로그래밍적으로 확인 가능 |
| **Hypothesis** | 항상 autonomous를 선택했다면 protected branch에서 실패하거나, 의도적 보호를 우회하는 위험 |

**Key lesson**: Autonomous 자동화는 "언제 사람이 필요한가"를 명시적으로 구조화할 때 안전해진다. 조건을 코드에 넣지 말고 문서(PR body)에 넣으면 투명성도 확보됨.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

- **`/retro`**: 이 세션의 retro에 사용됨
- **`/ship`**: 수정 대상. 다음 세션에서 `/ship pr`로 이번 변경사항의 PR을 생성하여 실제 검증 가능
- **`/plugin-deploy`**: 이번 변경은 local skill이므로 불필요 — marketplace plugin 변경 시에만 사용
- **`/refactor --skill ship`**: ship 스킬 수정 후 품질 점검에 사용 가능했으나, 변경이 plan 기반의 명확한 범위여서 이번에는 불필요

### Skill Gaps

**자율 워크플로우 완료 (post-implementation automation)** — 구현 완료 후 lessons 업데이트 → retro → commit → push → deploy의 전 과정을 하나의 skill/trigger로 자동화하는 것이 반복 패턴. 현재 CLAUDE.md에 step으로만 존재하며, 에이전트가 놓칠 수 있음. `/ship` 또는 새로운 `/wrap-up` 스킬로 통합하는 것을 고려할 수 있음. (다만 이는 CWF 설계 범위의 이슈이므로 next-session에 기록)
