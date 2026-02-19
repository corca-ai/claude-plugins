# Retro: cwf-review-internal (S5a)

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- `/review` 스킬은 `.claude/skills/review/`에 로컬 스킬로 작성됨 (dev 단계 dogfooding). S14에서 `plugins/cwf/skills/review/`로 마이그레이션 예정.
- 두 내부 리뷰어(Security, UX/DX)를 `Task(subagent_type="general-purpose")`로 병렬 실행하는 패턴이 안정적으로 동작함. 약 65초 내 완료.
- 리뷰어에게 구조화된 출력 포맷(Concerns/Suggestions/Criteria/Provenance)을 제공하면 일관된 형식으로 응답함.
- Severity 정의 없이 시작하면 리뷰어마다 다르게 분류함 → 정의 추가 후 해결.

## 2. Collaboration Preferences

- 사전 설계된 플랜(S5a plan)이 있었기 때문에 세션이 매우 효율적으로 진행됨. 5단계 플랜 → 실행 → 자체 리뷰 → 수정 → wrap-up까지 한 세션에 완료.
- 에이전트가 플랜을 직접 받으면(사용자가 plan 전체를 전달) 확인 질문 없이 바로 실행 가능 → 빠른 피드백 루프.

### Suggested CLAUDE.md Updates

없음. 현재 CLAUDE.md의 "After large multi-file changes, consider running parallel sub-agent reviews" 가이드라인이 이미 이 세션의 패턴과 일치함.

## 3. Waste Reduction

**전반적으로 낭비가 적은 세션.** 5단계 플랜이 미리 설계되어 있었고, 순서대로 실행함.

하나의 minor waste: `Write` 도구를 `allowed-tools`에서 누락한 것. Rule 5("don't write files unless asked")를 literal하게 해석해서 도구 자체를 제거했으나, "unless asked" 경우를 위해 capability는 필요했음.

**5 Whys**:
1. 왜 Write를 누락했나? → 플랜에 "Write 제외 — 리뷰 결과는 대화에 출력, 파일 저장은 사용자 선택"이라고 명시되어 있었음.
2. 왜 플랜이 그렇게 적혔나? → "사용자 선택"이라는 자체 문구와 "Write 제외"가 모순이지만 놓침.
3. 왜 모순을 놓쳤나? → 플랜 작성 시 "default behavior"와 "capability"를 구분하지 않았음.

**분류**: one-off mistake. "default behavior(기본 동작)와 capability(도구 권한)를 혼동하지 말 것" — 기본 동작을 제한하려면 Rules 섹션에 적고, 도구 자체는 필요시 사용 가능하게 두는 것이 맞음. 이미 수정 완료.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 자체 리뷰(self-review)를 테스트 방법으로 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | 플랜 Step 4에 "Test with sample plan/code input"이라고 되어 있었으나, 별도의 테스트 파일을 만드는 대신 방금 작성한 SKILL.md 자체를 리뷰 대상으로 사용 |
| **Goals** | 스킬 동작 검증 + 스킬 품질 개선의 두 목표를 동시에 달성 |
| **Options** | (1) 별도 테스트 파일 작성, (2) 기존 코드의 known issue 사용, (3) 자체 리뷰 |
| **Basis** | 자체 리뷰가 가장 현실적인 입력이고, dogfooding 원칙에 부합. 두 마리 토끼: 테스트 + 품질 개선. |
| **Hypothesis** | 별도 테스트 파일이었으면 스킬 동작은 검증했겠지만, SKILL.md 자체의 3가지 concern(hardcoded branch, missing Write, undefined scenarios)은 발견하지 못했을 것. |

**Key lesson**: 새로 만든 도구를 자기 자신에게 적용하는 것이 가장 현실적이고 유익한 첫 번째 테스트. "Review the reviewer" 패턴.

### CDM 2: 리뷰 concern 전부 반영 vs 선별 반영

| Probe | Analysis |
|-------|----------|
| **Cues** | Security 리뷰어가 0 concern + 4 suggestion, UX/DX 리뷰어가 3 concern + 7 suggestion 제출 |
| **Goals** | SKILL.md 품질 개선 vs 세션 시간 효율 vs S5b에서 다시 수정될 부분 중복 작업 방지 |
| **Options** | (1) 모든 concern + suggestion 반영, (2) concern만 반영 + suggestion은 기록만, (3) concern 중 핵심만 반영 |
| **Basis** | concern(blocking) 3개 + suggestion 중 S7(일관성), S1(순서), S3(severity 정의), S4(criteria 검색)를 반영. Phase 4 관련(S2, S4)은 S5b에서 구현 시 반영. |
| **Experience** | 경험 많은 개발자라면 suggestion 중 구조적 개선(S3: severity 정의)은 concern과 같은 우선순위로 취급했을 것 — 실제로 그렇게 함. |
| **Aiding** | 리뷰 합성의 verdict 알고리즘(moderate concern → Conditional Pass)이 자동으로 "전부 무시하면 안 됨" 신호를 줌. |

**Key lesson**: concern은 전부, suggestion은 "현재 세션에서 즉시 가치 있는 것"만 반영. 미래 세션에서 다시 다룰 부분은 의도적으로 남겨두는 것이 효율적.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| 스킬 | 이 세션에서의 관련성 |
|------|---------------------|
| `/review` (방금 생성) | 세션의 핵심 산출물. 자체 리뷰로 dogfooding 완료. |
| `/refactor --skill review` | 향후 SKILL.md 구조 검증에 사용 가능. 이 세션에서는 `/review` 자체 테스트가 같은 역할을 했으므로 불필요했음. |
| `/ship pr` | 세션 완료 후 PR 생성에 사용 가능. |
| `/plugin-deploy` | 현재 로컬 스킬이므로 해당 없음. S14 마이그레이션 시 사용. |

### Skill Gaps

현재 워크플로에서 식별된 추가 스킬 갭 없음. `/review`가 이 세션의 핵심 갭을 채웠음.
