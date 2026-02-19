# Retro: CWF v3 Master Plan

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- 사용자는 AI 네이티브 워크플로우를 직접 구축하면서 학습하는 것을 중시함. 블랙박스를 거부하고, 모든 구성요소를 이해한 상태에서 통합하려 함.
- `../works` repo에 7-phase wf 스킬이 있으며, multi-agent 리뷰 패턴의 실전 레퍼런스로 사용 가능. codex 최신 모델은 `gpt-5.3-codex`.
- compound-engineering(EveryInc)과 superpowers(obra)가 성숙한 단일 플러그인 아키텍처의 레퍼런스.
- 사용자는 한국어로 소통하되, 코드/문서는 영어. CLAUDE.md에 이미 명시되어 있음.
- 세션 간 핸드오프를 매우 중요하게 생각함. "이 파일 하나만 멘션하면 바로 시작"이 기준.

## 2. Collaboration Preferences

- **철학 논의 선호**: 단순 기술 결정이 아닌, "왜 이 구조인가"에 대한 깊은 대화를 즐김.
- **솔직한 반론 기대**: "좋습니다"보다 "이건 문제가 있습니다"를 원함. 이번 세션에서 infra 통합, 프리픽스 중복 등에 대한 반론이 잘 받아들여짐.
- **점진적 정제**: 한 번에 완벽한 플랜보다, 피드백 루프를 돌면서 개선하는 걸 선호. clarify → 코멘트 → 리뷰 → 재수정 흐름이 자연스러웠음.
- **도구 사용 원칙 강조**: clarify 스킬 미발동을 직접 지적. CLAUDE.md 원칙 준수를 기대함.

### Suggested CLAUDE.md Updates

- "세션 결과물을 서브에이전트로 리뷰하는 것을 고려하라" — 이번 세션에서 플랜 리뷰가 중요한 이슈를 발견함. 큰 결정 후 관점 기반 리뷰를 프로토콜로 추가할 가치가 있음.
- "핸드오프 문서는 자기 완결적이어야 함. '이 디렉토리 읽어라'가 아닌, 필요한 컨텍스트를 인라인으로 포함" — Collaboration Style 섹션에 추가 가능.

## 3. Waste Reduction

### clarify 스킬 미발동 (약 2턴 낭비)

세션 초반에 요구사항 정리를 수동으로 했다가 사용자가 지적하여 clarify 발동. 2턴 정도의 비효율.

**5 Whys**:
1. 왜 clarify를 안 썼나? → 요구사항이 파일로 왔고, 바로 분석할 수 있다고 판단.
2. 왜 바로 분석이 가능하다고 봤나? → 스킬 없이도 질문을 던질 수 있다고 생각.
3. 왜 스킬 우선 원칙을 무시했나? → "겹치면 custom skill 우선" 규칙을 상황에 맞춰 해석.
4. 왜 상황에 맞춰 해석했나? → 규칙이 "겹칠 때"를 명시하지만, 수동 질문이 "겹치는 것"인지 애매하게 느낌.
5. **구조적 원인**: CLAUDE.md의 "겹치면 custom skill 우선"이 clarify의 경우를 명시적으로 커버하지 않음. "요구사항 정리 = /clarify 발동"이라는 직접 매핑이 없음.

**처방**: CLAUDE.md Collaboration Style에 "요구사항이 모호하거나 큰 범위일 때는 /clarify부터 시작" 추가. → **Process gap**.

### untracked 파일 삭제 (1턴 낭비 + 데이터 손실 위험)

initial-plan-req.md를 옮기지 않고 삭제. untracked라 git restore 불가.

**5 Whys**:
1. 왜 삭제했나? → "적절한 위치로 옮겨주세요"를 "옮기고 원본 제거"로 해석.
2. 왜 확인 안 했나? → 임시 파일이라 가치가 낮다고 판단.
3. 왜 가치가 낮다고 봤나? → 내용이 이미 clarify-result.md에 반영되었으므로.
4. 왜 사용자에게 물어보지 않았나? → 파일 정리는 자명한 작업이라 판단.
5. **구조적 원인**: "사용자 파일을 건드릴 때는 확인"이라는 원칙이 CLAUDE.md에 없음. 특히 untracked 파일은 복구 불가능하므로 더 주의 필요.

**처방**: CLAUDE.md에 "사용자가 작성한 파일은 삭제 전 반드시 확인. mv > rm." 추가. → **Process gap**.

### 외부 플러그인 리서치 타이밍

compound-engineering과 superpowers 리서치를 clarify Phase 2에서 했는데, Decision #1(단일 플러그인)이 이 리서치 결과에 의존했음. 만약 리서치를 안 했다면 잘못된 아키텍처 결정을 했을 것.

**교훈**: 아키텍처 결정 전 외부 레퍼런스 조사는 낭비가 아니라 필수. plan-and-lessons protocol의 "Prior Art Search"가 이를 커버하지만, clarify 단계에서도 적용해야 함.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 단일 플러그인 아키텍처 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | 시스템 프롬프트에서 `claude-dashboard:update` 같은 `{plugin}:{skill}` 패턴 발견. 사용자의 "cwf:gather 트리거" 요구. |
| **Knowledge** | Claude Code의 플러그인 시스템에서 스킬 트리거가 `{plugin}:{skill}`로 자동 생성된다는 점. compound-engineering, superpowers의 단일 플러그인 패턴. |
| **Goals** | `cwf:*` 네이밍 (사용자 요구) vs 모듈성 (기존 9개 플러그인의 장점) vs 유지보수성. |
| **Options** | (A) 단일 플러그인, (B) 다중 플러그인 + cwf orchestrator, (C) 다중 플러그인 + dash 네이밍 (cwf-gather). |
| **Basis** | 콜론 네이밍이 단일 플러그인을 요구함 (기술적 제약). B는 의존성이 복잡하고, C는 사용자의 네이밍 의도와 다름. |
| **Hypothesis** | 다중 플러그인을 유지했다면 `cwf-gather@corca-plugins` 같은 장황한 이름이 되고, 사용자의 워크플로우 통합 비전과 어긋났을 것. |

**Key lesson**: 트리거 네이밍 같은 UX 요구사항이 아키텍처를 결정할 수 있다. 설계 초기에 플랫폼의 네이밍 규칙을 확인해야 함.

### CDM 2: 플랜 자체를 서브에이전트로 리뷰

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 "에이전트 팀 어댑티브니스가 플랜에 충분히 반영되어 있나?"라고 물은 후, "이 플랜 자체를 리뷰 시켜보고 싶다"고 제안. |
| **Knowledge** | wf 스킬의 Phase 4(spec review) 패턴. clarify의 advisory α/β 패턴. |
| **Options** | (A) 2 서브에이전트 (관점 기반), (B) 4-reviewer 풀 팀, (C) codex/gemini 외부 리뷰, (D) 리뷰 없이 바로 진행. |
| **Basis** | 플랜 문서는 코드가 아니라 codex/gemini 불필요. 2개 관점(feasibility vs philosophy)이 가성비 최적. |
| **Experience** | 덜 경험 있는 팀은 D(리뷰 없이 진행)를 선택했을 것. 리뷰 결과 세션 의존성 역전, under-scoped 세션 3개, install.sh 리라이트 누락 등 중요 이슈 발견. |
| **Aiding** | cwf v3 완성 후에는 `cwf:review --mode plan`이 이 역할을 자동화할 것. |

**Key lesson**: "만들 도구를 만들기 전에 먼저 써본다" — dogfooding이 설계 검증과 도구 설계 모두에 기여함.

### CDM 3: infra 스킬 4개를 setup 서브커맨드로 축소

| Probe | Analysis |
|-------|----------|
| **Cues** | Feasibility 리뷰어의 "14 skills is too many. infra config viewers are low value" 지적. |
| **Knowledge** | 각 스킬이 시스템 프롬프트에 description을 추가함 → 컨텍스트 오버헤드. infra 스킬의 실제 사용 빈도가 낮을 것. |
| **Goals** | 완전성 (모든 것에 트리거) vs 실용성 (필요한 것만 트리거). |
| **Options** | (A) 14 스킬 유지, (B) 10 스킬로 축소 (infra → setup 서브커맨드), (C) infra 스킬은 있되 숨김 (description 없이). |
| **Basis** | 사용자가 B를 즉시 수용. "cwf:setup 서브커맨드로 대체 좋네요." 실용적 판단. |
| **Situation Assessment** | 초기 설계에서 "모든 곳에 스킬"을 적용하려다 과도해짐. 리뷰어의 외부 시선이 이를 교정. |

**Key lesson**: 스킬 개수 자체가 비용. 독립 트리거가 필요한 것만 스킬로, 나머지는 기존 스킬의 서브커맨드로.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 이번 세션에서의 역할 |
|-------|-------------------|
| **clarify** | Phase 2에서 발동. 요구사항 정리에 핵심 기여. 초반 미발동은 waste로 기록. |
| **gather-context** | clarify 내부에서 web researcher 서브에이전트가 사용 (compound-engineering, superpowers 조사). |
| **refactor** | 직접 사용 안 함. 하지만 리팩터 리뷰(`260208-01`) 결과가 플랜의 S1-S2 기반이 됨. |
| **retro** | 지금 사용 중. |
| **plugin-deploy** (local) | 사용 안 함. v3에서는 cwf:setup이 일부 역할 대체. |
| **plan-and-lessons** (hook) | EnterPlanMode 시 프로토콜 주입. 플랜 파일 + lessons 파일 생성 가이드. |

### Skill Gaps

이번 세션에서 발견된 워크플로우 갭:

1. **cwf:review** (v3에서 구현 예정) — 플랜 리뷰를 수동으로 서브에이전트 2개 구성하여 실행. v3에서는 `cwf:review --mode plan`으로 자동화됨.
2. **cwf:handoff** (v3에서 구현 예정) — 핸드오프 문서를 수동 작성. v3에서는 cwf-state.yaml에서 자동 생성.

기존 외부 스킬로 대체 가능한 것은 없음 — 이 갭들은 cwf v3의 핵심 동기와 정확히 일치.

---

*이 세션은 중요한 아키텍처 결정, 철학 논의, multi-agent 리뷰 프로토타이핑이 있었습니다. `/retro --deep`으로 expert analysis와 learning resources를 확인할 수 있습니다.*
