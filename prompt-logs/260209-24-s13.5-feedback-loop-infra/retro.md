# Retro: S13.5-A Self-Healing Provenance System

> Session date: 2026-02-09
> Mode: light

## 1. Context Worth Remembering

- 유저는 "구현 → 리뷰 커밋 → 수정 커밋" 히스토리 패턴을 워크플로우 규칙으로 확립하고자 함. 커밋 히스토리가 자기설명적이어야 한다는 원칙
- 리뷰 결과는 conversation이 아닌 파일로 남아야 한다 — 각 리뷰어 개별 파일 + 합성 파일
- `marketplace-v3` 브랜치가 umbrella, 그 위에 워크스트림별 sub-branch 생성이 기대 패턴
- 유저는 워크플로우 자율화/자동화를 지속적으로 지향 — "이건 앞으로도 워크플로우에 반영할 규칙입니다"

## 2. Collaboration Preferences

- 유저가 규칙의 근거를 묻는 것은 "왜?"를 중시하는 사고방식 — Rule 5 조사를 요청한 것이 그 예. 규칙이 있으면 이유가 있어야 한다
- 유저는 발견한 문제를 즉시 시스템에 반영하길 원함 — "이번에 복구하기 쉬우면 그렇게 하고, 아니면 넘어갑시다. 앞으로는 그렇게 되면 됩니다"
- 리뷰 전 커밋, 리뷰 후 커밋 — 순서에 대한 명확한 기대가 있음

### Suggested CLAUDE.md Updates

- 없음 — 이번 세션 발견 사항은 주로 review/ship 스킬 수정 대상

## 3. Waste Reduction

### `.sh` 파일을 markdownlint에 넘긴 실수

markdownlint 검증 시 `scripts/provenance-check.sh`를 대상에 포함. 39개 "에러"가 모두 bash 주석을 markdown heading으로 오인한 것.

**5 Whys**:
1. 왜? → 수정한 파일 목록을 수동으로 나열할 때 `.sh` 파일을 포함
2. 왜? → lint 대상 결정이 "수정된 파일 중 markdown 파일"이라는 필터 없이 전체 수정 파일 목록을 사용
3. 왜? → lint 대상 선정에 결정론적 알고리즘이 없음 — 에이전트 재량에 의존
4. **근본 원인**: lint 대상을 확장자 기반으로 필터링하는 단계가 워크플로우에 없음

**해결 방향**: 수정 파일 대상으로 lint 돌릴 때, 확장자 필터를 결정론적으로 적용하는 helper (예: `git diff --name-only '*.md'` 패턴) 를 스크립트 또는 리뷰 스킬에 내장. 에이전트 지능은 "어떤 lint를 돌릴지" 판단에 쓰고, "어떤 파일에 돌릴지"는 알고리즘이 보조.

### 리뷰 커밋 시 handoff SKILL.md 되돌림

`git add`로 lessons.md를 staging할 때 다른 파일(handoff SKILL.md)이 이전 상태로 함께 커밋됨. 수정 사항이 사라진 것을 이후 Concern 수정 단계에서 발견.

**5 Whys**:
1. 왜? → `git add`가 의도하지 않은 파일 상태를 포함
2. 왜? → working tree에 아직 staging되지 않은 변경과 이미 커밋된 변경이 혼재
3. 왜? → 리뷰 파일 커밋 시 `git status`로 전체 상태를 확인하지 않음
4. **근본 원인**: 커밋 전 `git diff --cached --stat` 확인을 일관되게 하지 않음

### Sub-branch 생성 누락

핸드오프에 명시된 브랜치 워크플로우를 세션 시작 시 따르지 않음. 세션 중간에야 발견.

**5 Whys**: lessons.md에 이미 분석 완료 — 세션 시작 프로토콜에 "브랜치 확인" 단계 부재.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Review 스킬 Rule 5를 즉시 수정하지 않고 deferred action으로 남긴 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저가 "리뷰 결과가 무조건 파일로 남는다고 생각했습니다" — 기대와 실제의 괴리 발견 |
| **Goals** | Rule 5 근거 조사 vs 즉시 수정 vs 현재 세션 스코프 유지 |
| **Options** | (1) Rule 5 즉시 수정 + 리뷰 스킬 업데이트 (2) 이번 세션만 파일로 남기고 수정은 deferred (3) 무시하고 conversation 출력 |
| **Basis** | 유저가 "이번 리뷰는 파일로 남기고, Rule 5 수정은 deferred"로 명시적 판단. 현재 세션 스코프(provenance 시스템) 유지 우선 |
| **Aiding** | deferred action 목록이 lessons.md에 명시적으로 기록되어 있어서 유실 방지 장치가 작동 |

**Key lesson**: 발견된 문제의 즉시 수정 vs deferred 판단에서, 현재 세션 스코프와 수정 범위의 비례성이 기준이 됨. 작은 수정이면 즉시, 스킬 전체 수정이면 deferred.

### CDM 2: 리뷰 결과를 "합성 1파일"에서 "개별 4파일 + 합성"으로 확장한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저: "각 리뷰어의 리뷰가 개별 파일이 아닌 것 같은데" — 암묵적 기대 표면화 |
| **Goals** | 리뷰 추적성 (누가 뭘 말했는지) vs 파일 수 최소화 |
| **Options** | (1) 합성만 유지 (2) 개별 파일 추가 (3) 개별만, 합성 없음 |
| **Basis** | 합성은 verdict와 우선순위를 제공하고, 개별은 원본 추적성을 제공 — 둘 다 필요. 복구가 쉬운 상황이어서 즉시 적용 |
| **Hypothesis** | 합성만 남겼다면 — 나중에 "Security 리뷰어가 정확히 뭐라고 했지?" 질문에 답할 수 없었을 것 |
| **Aiding** | review 스킬에 "개별 리뷰어 파일 저장" 규칙이 있었다면 처음부터 올바르게 작동 |

**Key lesson**: 리뷰 산출물은 합성(verdict) + 개별(provenance/원본) 양쪽 모두 필요. 합성만으로는 추적성이 부족하고, 개별만으로는 우선순위 판단이 어려움.

### CDM 3: "구현 → 리뷰 → 수정"을 별도 커밋으로 쌓기로 한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저: "커밋 히스토리만 봐도 무슨 일이 일어났었는지 알 수 있게" |
| **Goals** | git history 가독성 vs 커밋 수 최소화 |
| **Options** | (1) squash merge (깔끔하지만 이력 유실) (2) 단계별 커밋 (이력 보존) (3) amend (위험) |
| **Basis** | 유저가 이력 보존을 명시적으로 요구. "앞으로도 워크플로우에 반영할 규칙" |
| **Analogues** | provenance 시스템 자체가 "맥락 유실 방지" — 커밋 히스토리도 같은 원칙 적용 |

**Key lesson**: `impl → review → fix` 커밋 패턴은 self-documenting history의 최소 단위. 워크플로우 규칙으로 성문화 대상.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

- **cwf:refactor** — provenance check가 holistic mode에 통합됨. 다음 holistic 실행 시 자동으로 staleness 감지가 작동하는지 확인 필요
- **cwf:handoff** — Phase 4b (Unresolved Items)가 추가됨. 다음 핸드오프 실행 시 deferred actions 추출이 작동하는지 dogfooding 필요
- **/review** — 이번 세션에서 발견된 3개 deferred action (Rule 5 파일 저장, base branch 감지, 개별 리뷰어 파일)이 다음 세션에서 수정 대상

### Skill Gaps

- **Lint 대상 결정론적 필터링**: 수정 파일 기반으로 lint 돌릴 때 확장자 필터를 자동 적용하는 메커니즘이 없음. review 스킬 또는 별도 helper script에 `git diff --name-only -- '*.md'` 패턴을 내장하면 `.sh` → markdownlint 같은 실수 방지
- **세션 시작 프로토콜**: 핸드오프 문서의 브랜치 워크플로우, 컨텍스트 파일 읽기 등을 체크리스트로 강제하는 메커니즘 부재. cwf:impl이나 별도 `cwf:start` 스킬에 세션 시작 체크리스트를 넣는 것이 구조적 해결
