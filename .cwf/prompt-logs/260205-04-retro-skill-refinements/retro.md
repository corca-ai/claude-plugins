# Retro: retro 스킬 정밀화

> Session date: 2026-02-05

## 1. Context Worth Remembering

- 사용자는 retro 스킬의 토큰 효율성을 지속적으로 개선 중. "토큰 대비 가치"가 핵심 평가 기준.
- `find-skills` (Vercel), `skill-creator` (Anthropic) — 두 외부 스킬을 retro의 Skill Gap 워크플로에 통합. 설치 경로: https://skills.sh/
- 사용자는 "스킬 리팩토링"이 자신의 반복 패턴임을 인지하고 있음. 향후 이 패턴이 더 반복되면 전용 스킬/체크리스트로 발전시킬 후보.
- skill-creator의 Progressive Disclosure 철학(Metadata → SKILL.md <5k words → References as needed)이 스킬 설계의 기준 프레임워크로 확립됨.

## 2. Collaboration Preferences

- 사용자는 변경 전 의도 확인("의도를 이해하셨나요?")을 선호하되, 확인 후에는 빠른 실행을 기대함. 이번 세션에서 이 패턴이 잘 작동했음.
- 비효율적인 도구 선택을 즉시 지적하고 근본 원인 분석까지 진행함 ("왜 오래 걸렸는가?" → "다음에 줄이려면?"). 단순 지적이 아닌 구조적 개선으로 연결하는 스타일.
- "retro 하고 한번에 처리합시다" — 여러 후속 작업(retro, persist, commit)을 한 흐름으로 묶는 것을 선호.

### Suggested CLAUDE.md Updates

없음. 현재 CLAUDE.md의 Collaboration Style 섹션이 이미 이 패턴들을 잘 반영하고 있음.

## 3. Prompting Habits

- "web-research 단계는 패스" — 명확하고 효율적. retro 스킬의 어떤 섹션이 웹 리서치를 필요로 하는지 사용자가 정확히 파악하고 축약 지시를 줌.
- "skill-creator skill을 참조하여" — 외부 스킬을 평가 기준으로 참조하라는 지시. 다만 Claude 입장에서 해당 스킬의 위치를 모르면 탐색 비용이 발생할 수 있음. `~/.claude/plugins/` 경로 컨벤션이 project-context.md에 기록되면 이 비용이 줄어듦.

## 4. Critical Decision Analysis (CDM)

### CDM 1: retro Section 7을 외부 스킬에 위임

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 "기존 스킬 찾는 건 find-skills, 새 스킬 만드는 건 skill-creator" 라고 명확히 구분하여 지시 |
| **Goals** | retro의 Skill Gap 섹션을 실행 가능(actionable)하게 만들기 vs 불필요한 의존성 추가 방지 |
| **Options** | (A) 기존 generic 문구 유지 (B) 특정 스킬 이름 명시 (C) 스킬 호출까지 자동화 |
| **Basis** | B 선택 — 이름을 명시하면 Claude가 바로 행동할 수 있고, 미설치 시 안내도 가능. C는 retro가 스킬 설치까지 책임지게 되어 과함 |
| **Hypothesis** | A를 유지했다면 매번 "어떤 스킬로 찾지?" 판단 비용이 반복됐을 것 |

**Key lesson**: 반복되는 판단을 프롬프트에 하드코딩하면 실행 비용이 줄어든다. 단, 외부 의존성 이름을 명시할 때는 미설치 fallback을 반드시 포함할 것.

### CDM 2: Expert Lens의 관찰자 vs 실행자 시점

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자: "전문가가 이 세션을 했다면 어떻게 했을까?" — 현재 프롬프트가 이 의도를 반만 살리고 있다고 판단 |
| **Knowledge** | Expert Lens 가이드는 "분석하라"(analyze)에 집중, "했을 것이다"(would have done)가 빠져 있었음 |
| **Options** | (A) 가이드 전면 재작성 (B) Analysis Approach에 한 step 추가 (C) SKILL.md에서 지시 |
| **Basis** | B 선택 — step 4 한 줄 추가로 실행자 시점 전환. 가이드의 나머지 구조(grounding, constraints)는 그대로 유효 |
| **Experience** | 프롬프트 엔지니어링 경험상, 전면 재작성보다 최소 개입이 의도치 않은 부작용을 줄임 |

**Key lesson**: 프롬프트 수정은 최소 단위로. "분석하라" → "분석하고, 당신이라면 어떻게 했을지 말하라"는 한 줄 차이지만 출력의 시점이 완전히 바뀐다.

### CDM 3: 도구 선택 실수 — Explore agent vs Glob

| Probe | Analysis |
|-------|----------|
| **Cues** | "skill-creator skill을 참조하여" → 설치된 스킬 파일을 찾아야 함 |
| **Goals** | 정확한 파일 내용 확보 vs 빠른 응답 |
| **Options** | (A) `Glob **/skill-creator**/SKILL.md` (B) Task(Explore) 에이전트 (C) 경로 직접 추측 |
| **Basis** | B를 선택했으나 잘못된 판단. "파일 위치를 모른다"고 가정했지만, 설치된 스킬은 `~/.claude/plugins/` 하위 예측 가능 경로에 있음 |
| **Aiding** | project-context.md에 설치 경로 컨벤션이 기록되어 있었다면 A를 즉시 선택했을 것 |
| **Situation Assessment** | "특정 파일 이름으로 찾기"를 "탐색이 필요한 미지의 구조"로 과대평가함 |

**Key lesson**: "이름을 아는 파일 찾기"는 항상 Glob 먼저. Explore는 "어디에 뭐가 있는지 모를 때"만. 설치된 플러그인/스킬 경로는 project-context.md에 기록하여 세션 간 지식 유실 방지.

## 5. Expert Lens

웹 리서치 스킵 (사용자 요청).

## 6. Learning Resources

경량 세션 — 스킵.

## 7. Relevant Skills

사용자가 직접 인지한 반복 패턴: **"스킬 리팩토링"** — 스킬의 프롬프트를 skill-creator 철학 기준으로 평가하고 경량화하는 작업.

현재 빈도: 아직 전용 스킬로 만들기에는 이름. 2-3회 더 반복되면 `/find-skills`로 skill-linter/skill-audit 유사 도구를 검색하고, 없으면 `/skill-creator`로 scaffold하는 것을 권장.
