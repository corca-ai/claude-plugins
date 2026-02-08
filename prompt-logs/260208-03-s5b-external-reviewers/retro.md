# Retro: S5b External CLI Reviewers (Codex + Gemini)

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- `/review` 스킬은 4-리뷰어 구조로 확장됨: Security(Task), UX/DX(Task), Correctness(Codex CLI), Architecture(Gemini CLI). 외부 CLI 없으면 Task fallback으로 동일 관점 유지.
- SKILL.md 500줄 제한 하에서 외부 리뷰어 상세는 `references/external-review.md`로 분리하는 패턴이 효과적.
- Codex는 `codex review` (코드 모드) vs `codex exec` (plan/clarify 모드)로 명령어가 다름. Gemini는 `npx @google/gemini-cli`로 모드 무관 동일 명령어.
- Bash에서 외부 CLI 실행 시 `timeout 280` (inner) + `Bash(timeout=300000)` (outer) 이중 타임아웃 패턴으로 안전하게 시간 제한.

## 2. Collaboration Preferences

- 사전 설계된 플랜을 받아 구현하는 패턴이 매우 효율적이었음. 7단계 플랜 → 4개 태스크로 압축 후 순차 실행.
- 구현 후 즉시 `/retro` → 커밋 워크플로우를 자율적으로 진행하는 패턴이 확립됨.

### Suggested CLAUDE.md Updates

없음. 현재 CLAUDE.md의 워크플로우 지침이 이 세션에 잘 맞음.

## 3. Waste Reduction

**낭비 없음.** 이 세션은 사전 설계된 플랜의 직접 구현으로, 미리 설계 단계에서 모호성이 제거되어 있었음.

한 가지 미세한 관찰:
- 플랜의 Step 3~6이 모두 SKILL.md 수정이므로 하나의 태스크로 병합한 것은 적절했음. 별도 태스크로 나눴다면 파일을 반복 읽기/쓰기하는 낭비가 발생했을 것.

**근본 원인**: 해당 없음 (낭비가 미미하거나 없음).

## 4. Critical Decision Analysis (CDM)

### CDM 1: 플랜의 7단계를 SKILL.md 4-phase 구조로 매핑

| Probe | Analysis |
|-------|----------|
| **Cues** | 플랜은 "Phase 2 → Launch ALL 4" / "Phase 3 → Collect + Fallback" / "Phase 4 → Synthesize"로 이미 3-phase 구조를 제시했지만 구현 Step은 7개로 분리되어 있었음 |
| **Goals** | SKILL.md의 가독성 (실행하는 에이전트가 따라가기 쉬운 흐름) vs 플랜 원문 충실도 |
| **Options** | (a) 7단계를 그대로 SKILL.md에 반영 (b) 4-phase로 압축 (현재 선택) (c) 6-phase (각 Step별) |
| **Basis** | SKILL.md는 에이전트가 실행하는 문서이므로 명확한 phase 구분이 중요. 7단계를 그대로 넣으면 "Step 2: Prepare prompts", "Step 3: Detect CLI", "Step 4: Launch" 같이 세분화가 과도해짐 |
| **Hypothesis** | 7단계를 그대로 반영했다면 SKILL.md가 ~450줄 이상이 되고, 실행 에이전트가 "지금 어느 step인지" 추적하기 어려웠을 것 |

**핵심 교훈**: 설계 플랜의 단위(Step)와 실행 문서의 단위(Phase)는 다를 수 있음. 플랜은 구현자를 위한 체크리스트이고, SKILL.md는 실행 에이전트를 위한 워크플로우.

### CDM 2: Provenance 포맷 통일 (`duration_ms`, `command` 필드를 내부 리뷰어에도 추가)

| Probe | Analysis |
|-------|----------|
| **Cues** | 외부 리뷰어만 `duration_ms`/`command`가 있으면 합성 단계에서 조건 분기가 필요 |
| **Goals** | 합성 로직 단순화 vs 내부 리뷰어에 불필요한 필드 추가 방지 |
| **Options** | (a) 외부만 추가 필드 (b) 모든 리뷰어에 통일 (값은 `—`) (c) 별도 외부 전용 Provenance 포맷 |
| **Basis** | `—` 값이라도 필드가 존재하면 합성 에이전트가 동일 파서로 처리 가능. 필드 유무로 분기하는 것보다 단순 |
| **Aiding** | "스키마 일관성 > 최소 스키마" 원칙. API 설계에서도 optional field보다 consistent field가 downstream 처리를 단순화함 |

**핵심 교훈**: 여러 소스의 출력을 합성할 때, 공통 스키마에 빈 값(`—`)을 포함하는 것이 조건 분기를 추가하는 것보다 낫다.

## 5. Expert Lens

> `/retro --deep`로 전문가 분석을 실행하세요.

## 6. Learning Resources

> `/retro --deep`로 학습 자료를 확인하세요.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| `/review` | 이 세션에서 수정한 대상 스킬. 구현 후 바로 self-review 가능 |
| `/refactor --skill review` | 수정된 review 스킬의 deep review에 활용 가능 |
| `/plugin-deploy` | review는 local skill이라 plugin-deploy 대상 아님 (marketplace 플러그인만 해당) |

### Skill Gaps

추가 스킬 갭 없음. 이 세션은 local skill 수정이므로 기존 워크플로우로 충분.
