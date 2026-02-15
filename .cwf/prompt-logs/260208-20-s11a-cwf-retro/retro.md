# Retro: S11a — Migrate retro → cwf:retro

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF v3는 harden 단계(S11-S13)에 진입했으며, S11a는 5번째 스킬 마이그레이션(gather → clarify → plan → impl → retro).
- 마이그레이션 패턴이 S7-S10에서 충분히 안정화되어, S11a는 plan의 3개 step을 거의 기계적으로 실행할 수 있었음.
- retro 스킬은 두 가지 고유 enhancement가 있었음: (1) deep mode의 2-batch parallel sub-agent, (2) persist step의 eval > state > doc hierarchy. 둘 다 S10 post-retro에서 도출된 finding.
- `agent-patterns.md`가 `plugins/cwf/references/`에 공유 참조로 존재하며, impl과 retro 모두 이를 참조. 스킬 간 공유 패턴 문서의 위치가 확립됨.

## 2. Collaboration Preferences

유저가 "Implement the following plan:"으로 상세 plan을 전달 → 구현 후 "cwf-state.yaml 등록하고 check-session.sh. Then retro"로 3개 작업을 한 줄에 지시. 이 세션에서 관찰된 패턴:

- **Plan 충실도 기대**: Plan이 상세할수록 유저는 plan 대로 실행만 기대함. 추가 확인 질문 없이 진행한 것이 적절했음.
- **체이닝 명령**: 후속 작업들을 한 문장으로 연결하는 스타일. check-session.sh FAIL은 예상된 것이었고, 이를 해소하기 위해 plan.md/lessons.md를 즉시 생성한 것이 맞았음.

### Suggested CLAUDE.md Updates

현재 CLAUDE.md가 이미 이 스타일을 잘 커버하고 있음. 추가 제안 없음.

## 3. Waste Reduction

이 세션은 전체적으로 낭비가 적었음. 상세한 plan + 안정화된 마이그레이션 패턴 덕분.

**관찰 1: Reference 파일 복사 방식**

Read+Write 대신 `cp` 명령으로 verbatim 복사가 가능했으나, Write 도구를 사용해 명시적으로 내용을 확인하며 작성함. 1-2 턴 차이로, 결과적으로 diff 검증에서 IDENTICAL 확인됨.

→ **5 Whys**: 왜 cp를 안 썼나? → Write가 더 안전하다고 판단 → 왜? → verbatim 복사의 확신 필요 → 사실 diff로 검증하면 cp도 동등하게 안전함.
→ **분류**: One-off judgment call. 2파일로 영향이 작아 process change 불필요.

**관찰 2: Plan이 check-session.sh의 FAIL 흐름을 예상하지 않음**

Plan의 "Deferred Actions"에 "Register S11a session in cwf-state.yaml (post-implementation)"이 있었지만, check-session.sh가 artifacts를 검증하므로 plan.md/lessons.md가 미리 존재해야 함. 유저가 "cwf-state.yaml 등록하고 check-session.sh"를 함께 지시했을 때 FAIL이 예상되었고, plan.md/lessons.md를 즉석에서 생성한 후 retro를 진행하는 것이 올바른 순서였음.

→ **5 Whys**: 왜 FAIL이 발생했나? → artifacts가 아직 없었음 → 왜? → check-session.sh는 artifacts 존재를 확인하는 validation tool → session 등록과 artifact 생성 순서가 plan에서 명시되지 않았음 → plan template에 "check-session.sh 전에 필수 artifact 생성" 단계가 없음.
→ **분류**: Process gap — 다만 이건 retro가 artifacts를 생성하므로, 자연스러운 순서(등록 → retro → check)로 하면 해결됨. 유저의 지시 순서가 "등록 → check → retro"였기에 중간 생성이 필요했던 것.

## 4. Critical Decision Analysis (CDM)

### CDM 1: SKILL.md를 새로 작성 vs v2.0.2를 edit으로 수정

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan이 "~280 lines"과 6개 변경 영역(3a-3g)을 명시. v2.0.2는 235줄이고 변경이 전체에 분산됨 |
| **Goals** | 정확성(plan의 모든 변경 반영) vs 속도(최소 수정) |
| **Options** | (A) v2.0.2를 cp 후 Edit으로 6개 영역 순차 수정, (B) plan의 변경사항을 통합해 Write로 한 번에 작성 |
| **Basis** | 변경이 frontmatter, Section 2, Section 4, Section 7(persist), Section 8, References, Rules로 전체에 걸쳐 있어서, edit 6-7회보다 한 번의 Write가 실수 가능성이 낮다고 판단 |
| **Hypothesis** | Edit 접근이었다면 각 수정 후 diff 검증이 필요해 턴 수가 2-3배 늘었을 것. 반면 잘못된 내용이 있었다면 한 번에 작성한 파일 전체를 재검토해야 하는 리스크 존재 |
| **Aiding** | 최종 verification에서 grep으로 핵심 패턴(cwf-state, agent-patterns, Batch, Tier, Section headers, bare fences)을 모두 확인 — Write 방식의 리스크를 보상 |

**Key lesson**: 변경 영역이 파일 전체에 분산되어 있을 때, 순차 edit보다 통합 Write + 패턴 기반 verification이 더 안전하고 빠르다.

### CDM 2: Verification 전략 — diff vs grep vs manual review

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan의 Verification 섹션이 6가지 체크리스트를 명시 (구조, convention, regression, enhancement, integration, lint) |
| **Goals** | 완전한 검증 vs 검증에 소모되는 컨텍스트 비용 |
| **Options** | (A) 전체 파일 re-read 후 수동 검토, (B) 핵심 패턴만 grep으로 spot-check, (C) diff v2.0.2 vs cwf:retro |
| **Basis** | (B) 선택 — grep으로 cwf-state, agent-patterns, Batch, Tier, Section headers, bare fences를 각각 검증. Reference 파일은 diff로 IDENTICAL 확인. 6개 verification 항목 전체 커버하면서 컨텍스트 최소화 |
| **Knowledge** | project-context.md의 "Tool-first verification for bulk changes" 패턴 적용 |
| **Tools** | `diff` (reference verbatim check), `grep` (pattern spot-check), `wc -l` (size check) — 3가지 도구 조합 |

**Key lesson**: Plan에 verification checklist가 있을 때, 각 항목을 커버하는 최소한의 자동 검증(grep, diff)을 설계하면 수동 review 대비 빠르고 누락 위험이 낮다.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

**Marketplace 스킬** (corca-plugins):

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| `retro` | 현재 실행 중. 이 세션의 산출물. |
| `gather-context` | 사용하지 않았음 — 외부 정보 수집 불필요한 세션이었음 |
| `clarify` | 사용하지 않았음 — plan이 이미 상세했음 |
| `refactor` | `/refactor --skill retro`로 새로 만든 cwf:retro SKILL.md를 review할 수 있었음. 다만 이 세션은 migration이라 별도 review보다 verification checklist가 더 적합했음 |

**로컬 스킬** (.claude/skills/):

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| `plugin-deploy` | CWF plugin version bump은 S12로 deferred — 이 세션에서는 해당 없음 |
| `ship` | 커밋/PR 생성 시 사용 가능. 이 세션에서는 아직 커밋하지 않았음 |
| `review` | 코드 리뷰 시 사용 가능. migration 작업에서는 verification checklist가 대체 |

### Skill Gaps

추가 스킬 갭 미발견. 이 세션은 잘 정의된 plan의 실행이었으므로, 기존 도구로 충분했음.
