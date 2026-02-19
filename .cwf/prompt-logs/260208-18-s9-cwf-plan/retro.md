# Retro: S9 cwf:plan 마이그레이션

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF v3 마이그레이션이 S9까지 진행됨. S7(gather), S8(clarify), S9(plan) 순서로 스킬 마이그레이션 완료
- cwf:plan은 기존 플러그인(plan-and-lessons)의 hook 부분(S6b에서 마이그레이션)과 별개로 **새로운 스킬**로 설계됨
- hook(패시브, EnterPlanMode 트리거)과 skill(액티브, 사용자 호출)의 보완적 관계가 확립됨

## 2. Collaboration Preferences

- 사전에 완성된 상세 플랜을 제공하면 세션이 효율적으로 진행됨 — 이번 세션은 플랜 읽기 → 즉시 구현으로 연결
- 유저가 plan mode에서 나온 직후 구현을 지시하면 별도 확인 없이 바로 진행해도 됨

### Suggested CLAUDE.md Updates

없음 — 현재 CLAUDE.md가 이 워크플로우를 잘 커버하고 있음

## 3. Waste Reduction

### Markdown lint 코드 펜스 중첩 문제

SKILL.md의 plan 템플릿에서 ` ```markdown ` 안에 ` ```gherkin ` 를 넣으니 외부 코드 펜스가 조기 종료되어 lint 에러 발생. 4-backtick 펜스(` ```` `)로 수정.

**5 Whys**:
1. 왜 lint 에러? → 3-backtick 중첩으로 코드 펜스 파싱 혼란
2. 왜 3-backtick 사용? → cwf:clarify의 패턴을 참조했지만, clarify는 중첩 코드 펜스가 없었음
3. 왜 사전에 못 잡았나? → 코드 펜스 중첩은 작성 시 쉽게 놓치는 패턴

**분류**: 지식 갭 (one-off이 아님 — 향후 SKILL.md 템플릿 작성 시 반복 가능)

**교훈**: 마크다운 템플릿에 코드 펜스를 포함할 때는 항상 4-backtick 외부 펜스 사용. lessons.md에 기록함.

### heading 아래 빈 줄 누락

`## Don't Touch`와 `## Deferred Actions` 아래 빈 줄 없이 바로 리스트가 시작됨 (MD022).

**분류**: One-off — markdownlint hook이 즉시 잡아주므로 구조적 대응 불필요

## 4. Critical Decision Analysis (CDM)

### CDM 1: cwf:plan의 phase 구조를 cwf:clarify와 다르게 설계

| Probe | 분석 |
|-------|------|
| **Cues** | 플랜에서 "advisory/persistent-questioning이 불필요"라는 지침 |
| **Goals** | cwf:clarify 패턴 활용 vs. cwf:plan 고유 목적에 최적화 |
| **Options** | (A) clarify의 5-phase 그대로 적용, (B) plan 목적에 맞게 5-phase 재설계 |
| **Basis** | plan은 "연구 종합 → 구조화된 문서 생성"이 핵심. 분류/질문/어드바이저리는 과잉 |
| **Analogues** | S8의 cwf:clarify 마이그레이션 — 거기서는 원본 구조를 유지하는 게 맞았음 |
| **Experience** | 경험 많은 설계자라면 "패턴 참조"와 "패턴 복사"를 명확히 구분했을 것 |

**핵심 교훈**: 스킬 간 구조적 일관성보다 각 스킬의 핵심 가치(value proposition)에 맞는 설계가 우선

### CDM 2: plan-protocol.md 동기화 범위 결정

| Probe | 분석 |
|-------|------|
| **Cues** | 원본(plan-and-lessons/protocol.md)에 Handoff Document 섹션(105-113행)이 있으나 CWF 버전에 없음 |
| **Goals** | CWF 버전의 완전성 vs. 최소 변경 |
| **Options** | (A) Handoff Document 섹션만 추가, (B) 전체 diff 후 모든 차이 동기화 |
| **Basis** | 플랜에서 명시적으로 Handoff Document 섹션만 언급. `/gather-context` → `cwf:gather` 치환은 이미 S6b에서 완료 |
| **Situation Assessment** | 정확 — diff 결과 기대한 차이만 존재 확인 |

**핵심 교훈**: 마이그레이션에서 "무엇을 동기화하고 무엇을 안 하는지" 플랜에 명시하면 구현 시 판단 비용이 줄어듦

## 5. Expert Lens

> `/retro --deep`으로 전문가 분석을 받을 수 있습니다.

## 6. Learning Resources

> `/retro --deep`으로 학습 리소스를 받을 수 있습니다.

## 7. Relevant Skills

### Installed Skills

- **cwf:review** (`/review --mode plan`): cwf:plan의 출력물을 리뷰하는 데 직접적으로 연관. SKILL.md에서 Phase 5로 연결됨
- **plugin-deploy** (`/plugin-deploy`): version bump 후 marketplace 동기화에 사용 가능했으나, marketplace-v3 브랜치에서는 main merge 전까지 불필요
- **refactor** (`/refactor --skill plan`): 새로 만든 cwf:plan SKILL.md의 품질 리뷰에 사용 가능

### Skill Gaps

이번 세션에서 추가 스킬 갭은 식별되지 않음.
