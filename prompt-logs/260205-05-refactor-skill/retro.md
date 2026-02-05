# Retro: refactor-skill + holistic cross-plugin analysis

> Session date: 2025-02-05

## 1. Context Worth Remembering

- 사용자는 "로컬 옵티멈이 아닌 글로벌 옵티멈"을 지향함. 개별 플러그인 최적화보다 전체 생태계의 일관성과 연결성에 관심이 높음.
- skill-creator가 `~/.codex/skills/.system/`에 있음 (Codex 기반). `~/.claude/plugins/marketplaces/`에 없음.
- 전체 SKILL.md 합산 ~4,300 words — 한 컨텍스트에서 전부 읽기에 부담 없는 양.
- gather-context의 비전: "더 좋은 응답을 위해 필요한 맥락을 다 가져오는 통합 레이어." URL 변환기를 넘어서 코드베이스 탐색, 웹 리서치까지 포괄.

## 2. Collaboration Preferences

- 사용자는 분석 결과를 바로 실행하기보다 토론을 거쳐 정제하길 원함. 이번 세션에서 7개 액션 중 3개가 토론 후 방향이 바뀜.
- "충분히 똑똑하다는 걸 믿습니다" — 사용자는 에이전트에게 높은 자유도를 주되, 렌즈(관점)는 명확히 제공하길 원함. 형식을 강제하면 창의성이 줄어든다는 우려.
- 솔직한 카운터 의견을 환영함. gather-context 확장에 대한 우려를 제시했을 때 "질문은 스스로 잘 결정하셨습니다"로 수용.

### Suggested CLAUDE.md Updates

- `docs/project-context.md`의 Plugins 섹션에 추가: "gather-context의 장기 방향은 통합 맥락 수집 레이어 (URL + 코드베이스 + 웹 리서치). web-search 흡수 예정."

## 3. Prompting Habits

이 세션은 프롬프팅 효율이 높았음. 주목할 패턴:

- **"같이 토론해봅시다"로 시작한 디자인 토론**: 분석 → 의견 → 결정의 흐름이 자연스러웠고, 에이전트가 먼저 구조화된 분석을 제시한 후 사용자가 방향을 잡는 방식이 효과적.
- **중간에 새 아이디어 삽입**: "잠시만요. 이렇게 해보니..." — 세션 중 떠오른 아이디어(holistic 모드)를 바로 반영. 이 패턴은 좋지만, 미리 "이 세션의 scope"를 정하고 시작했으면 새 아이디어를 다음 세션으로 넘길지 판단이 쉬웠을 것.
- **피드백의 구체성**: "retro prompting에서 예시를 너무 자세히 주면 창의성이 줄어든다" — 이런 수준의 메타 피드백이 스킬 개선에 매우 효과적.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 전체 SKILL.md를 한 컨텍스트에서 읽을 것인가

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자의 "로컬 옵티멈이 아닌 글로벌 옵티멈" 발언 + "토큰이 많이 들어도 전체를 봐야 할 것 같은데" |
| **Goals** | 토큰 효율 vs 분석 품질. cross-plugin 패턴은 부분 읽기로 발견 불가. |
| **Options** | (A) 전부 읽기, (B) 점진적 읽기, (C) quick-scan 결과만으로 분석 |
| **Basis** | quick-scan 결과에서 전체 SKILL.md가 ~4,300w임을 확인. 부담 없는 양. |
| **Hypothesis** | 점진적으로 읽었으면 "clarify vs deep-clarify vs interview" 경계 문제를 놓쳤을 가능성 높음. |

**핵심 교훈**: 전체를 보는 비용을 먼저 측정하라. 직감적으로 "비싸다"고 느껴도 실제 측정하면 충분히 감당 가능한 경우가 많다.

### CDM 2: gather-context에 web-search를 흡수하는 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 에이전트의 초기 제안은 "gather-context의 WebFetch fallback에서 web-search extract를 호출"이었음. 사용자가 더 과감하게 "아예 흡수"를 제안. |
| **Goals** | 개념적 깔끔함 (하나의 정보 수집 레이어) vs 플러그인 독립성 (작은 단위 설치). |
| **Options** | (A) 연결만 추가, (B) 부분 흡수 (extract만), (C) 완전 흡수 (검색까지) |
| **Basis** | 사용자: "결국 더 좋은 응답을 위해 필요한 맥락 정보를 다 가져와서 저장하겠다는 것" — gather-context의 철학이 이미 이 방향. |
| **Experience** | 에이전트는 mega-plugin 우려를 제시. 사용자는 SKILL.md가 라우팅만 하고 핸들러는 독립 스크립트이므로 괜찮다고 판단. |
| **Aiding** | 분석 결과표(Plugin Map)가 규모 판단에 도움. 각 스크립트가 독립적임을 시각적으로 확인. |

**핵심 교훈**: 에이전트가 보수적 대안을 제시하고, 사용자가 과감한 방향을 선택하는 것은 건강한 패턴. 단, 에이전트의 우려를 무시한 게 아니라 trade-off를 이해한 위에서 결정한 것.

### CDM 3: retro prompting habits 렌즈 교체

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자: "요즘 좋은 제안을 못 받고 있습니다" — 직접적 불만 표현. |
| **Goals** | actionable한 개선 vs 형식적 분석. |
| **Options** | (A) 기존 "오해 방지" 렌즈 유지 + 예시 강화, (B) "waste 감소" 렌즈로 교체 + 리지드 포맷, (C) 렌즈 교체 + 자유 포맷 |
| **Basis** | 사용자가 C를 명시적으로 선택. "이미 당신은 충분히 똑똑하다는 걸 믿습니다." |
| **Knowledge** | skill-creator의 "degrees of freedom" 원칙과 일치. 분석 작업은 high freedom이 적절. |

**핵심 교훈**: 스킬의 자유도를 설정할 때, 무엇을 분석할지(렌즈)는 지정하되, 어떻게 표현할지(포맷)는 열어두는 것이 고품질 결과를 만든다.

## 5. Expert Lens

이번 세션의 핵심은 플러그인 생태계의 아키텍처 결정. 간략 retro이므로 sub-agent 없이 핵심만.

**Conway's Law 관점** (Mel Conway): gather-context가 web-search를 흡수하는 결정은 "정보 수집"이라는 하나의 관심사를 하나의 조직 단위(플러그인)로 통합하는 것. Conway's Law의 역적용 — 원하는 아키텍처에 맞게 조직(플러그인 경계)을 재편하는 "Inverse Conway Maneuver." 이 방향이 맞다면 deep-clarify → gather-context 의존도 자연스러움.

**Kent Beck의 Tidy First? 관점**: 이번 세션은 "구조 변경을 행동 변경과 분리"하는 원칙을 따름. holistic 분석(구조 이해) → 결정(방향 설정) → 구현(별도 세션). 구조 변경의 비용을 먼저 이해하고, 변경의 순서를 정한 것.

## 6. Learning Resources

간략 retro — 생략. 이번 세션은 지식 격차보다 설계 토론 중심.

## 7. Relevant Skills

이번 세션에서 refactor-skill의 `--holistic` 모드를 만들었고, 첫 분석 결과를 생성함. 스킬 격차보다는 기존 스킬의 사용 확대가 포인트:

- **이번 세션에서 활용했으면 좋았을 것**: 없음. 설계 토론은 에이전트와 직접 대화가 가장 효과적이었음.
- **앞으로 써볼 만한 것**: `/refactor-skill --holistic`을 주기적으로 실행해서 플러그인 생태계 건강 상태를 체크. 특히 gather-context 리팩터 이후.
