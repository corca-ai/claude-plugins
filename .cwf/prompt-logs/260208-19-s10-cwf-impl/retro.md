# Retro: S10 cwf:impl Skill

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF v3 build sequence: S7 (gather) → S8 (clarify) → S9 (plan) → **S10 (impl)** → S11+ (review, retro, etc.)
- impl is the first **autonomous stage** skill — prior skills (gather, clarify, plan) are interactive. This marks the shift where the plan becomes the fixed contract and human is no longer in the loop.
- The plan for impl was designed in the prior session (S10 plan session, `cedceacf`). Implementation was a separate session with the plan provided as input.
- cwf skills have a consistent structure: SKILL.md frontmatter (name, description, allowed-tools), phases, rules, references section. Reference files hold domain knowledge; SKILL.md is a thin orchestrator.

## 2. Collaboration Preferences

- User provided a detailed, pre-approved plan and expected autonomous execution. The plan included all design decisions, file paths, and BDD criteria. This "hand off plan, execute autonomously" pattern is the intended cwf:impl workflow.
- Session was efficient: 3 reference files read in parallel, all 4 deliverables written in parallel where possible, verification ran immediately after.

### Suggested CLAUDE.md Updates

None — current CLAUDE.md conventions were followed correctly.

## 3. Waste Reduction

**Minimal waste in this session.** The pre-designed plan eliminated the biggest source of implementation waste (ambiguity). A few observations:

- **Bare code fence verification**: Initial grep pattern `^```$` matched closing fences, requiring a second pass to distinguish opening vs closing. A more precise first-pass pattern (e.g., checking lines that are *only* three backticks and verifying the preceding line isn't a code block) would have caught this in one pass.
  - **Root cause**: The markdown lint check approach (grep for bare fences) is inherently imprecise for distinguishing opening vs closing fences. A structural parser would be more reliable.
  - **Structural fix**: The `markdown-guard` plugin already handles this via `markdownlint-cli2`. For future manual checks, the two-grep pattern (one for `^```\s*$` to find candidates, one for `^```[a-z]` to count opening fences) is the reliable approach.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Executing plan directly vs entering plan mode

| Probe | Analysis |
|-------|----------|
| **Cues** | User provided a fully-specified plan with BDD criteria, file paths, and design decisions already resolved. The plan was marked as approved from a prior session. |
| **Goals** | Execute efficiently vs verify plan quality before implementation. |
| **Options** | (1) Enter plan mode to review/refine, (2) Execute directly from the provided plan. |
| **Basis** | Plan was comprehensive and pre-approved. Entering plan mode would duplicate work already done in the S10 plan session. |
| **Experience** | A less experienced agent might re-plan or ask clarifying questions on an already-specified plan. The plan-as-contract principle (from agent-patterns.md "Shift Work") gives confidence to proceed directly. |
| **Aiding** | The CWF workflow stage model (interactive → autonomous) made this clear: impl executes, doesn't re-plan. |

**Key lesson**: When a plan is provided with full specificity (BDD criteria, file paths, design rationale), execution should begin immediately. Re-planning is waste.

### CDM 2: Parallel file creation vs sequential

| Probe | Analysis |
|-------|----------|
| **Cues** | 4 files to create: SKILL.md, agent-prompts.md, lessons.md, plan.md. None depend on each other's content. |
| **Goals** | Speed vs correctness. Writing all in parallel risks inconsistency between files. |
| **Options** | (1) Write all 4 in parallel, (2) Write SKILL.md first then reference file, then session artifacts. |
| **Basis** | The plan fully specified content for each file. No file references another's generated content. SKILL.md references agent-prompts.md by path but doesn't need its content at write time. |
| **Hypothesis** | Sequential writing would have been correct but slower. The parallel approach produced correct output in fewer turns. |

**Key lesson**: When plan specifies file contents independently, parallel creation is safe and faster. Dependencies between files (file A includes content generated in file B) would require sequential creation.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | Relevance |
|-------|-----------|
| **cwf:plan** (marketplace) | Created the plan consumed by this session. Working as designed. |
| **cwf:review** (local) | Suggested as next step (`cwf:review --mode code`). Should be used to verify impl output quality. |
| **plugin-deploy** (local) | Not needed — cwf:impl is not a deployed plugin yet (it's being built on marketplace-v3 branch). |
| **retro** (marketplace) | Currently running. |
| **refactor** (marketplace) | Could be used post-review to check skill quality (`/refactor --skill impl`). |
| **clarify** (marketplace) | Not needed — requirements were fully specified in the plan. |
| **gather-context** (marketplace) | Not needed — no external research required for this implementation session. |

### Skill Gaps

No additional skill gaps identified. The CWF skill pipeline (plan → impl → review → retro) covered this session's needs. The impl skill itself is the new addition filling the "autonomous execution from plan" gap.

---

### Post-Retro Findings

#### next-session.md 누락 재발 — S8과 동일한 실수

S8 lessons.md에 기록된 교훈("next-session.md 생성 누락")이 S10에서 반복됨.

**초기 진단 오류**: "CLAUDE.md 체크리스트가 불완전해서"라고 분석했으나, 이는 표면적 원인. 실제 원인은 S8 lessons.md를 읽지 않았기 때문. lessons.md가 write-only 아티팩트로 기능하고 있었음.

**구조적 원인 2가지**:
1. **check-session.sh가 session_defaults를 사용하지 않음** — `session_defaults.milestone: [next-session.md]`가 정의되어 있었으나 스크립트가 파싱하지 않음
2. **실행 순서** — cwf-state.yaml 세션 등록이 check-session.sh 이후에 일어남 → 스크립트가 S9를 체크하고 PASS 반환

**적용한 수정**:
- check-session.sh: explicit artifacts가 없으면 session_defaults (always + milestone)로 fallback
- CLAUDE.md: cwf-state.yaml 등록을 check-session.sh 이전으로 재배치

#### 핵심 원칙: 결정론적 검증 > 행동 지침

이 사례가 보여주는 일반 원칙: 반복되는 실수를 방지할 때 **행동 지침 추가**(CLAUDE.md에 "next-session.md 잊지 마세요")보다 **결정론적 검증**(check-session.sh가 session_defaults로 자동 감지)이 더 효과적.

- 행동 지침: 읽히지 않을 수 있음, 맥락에 따라 해석이 달라짐, 규칙이 늘수록 효과 감소
- 결정론적 검증: 항상 실행됨, pass/fail이 명확, 규모에 무관하게 동작

이 원칙을 project-context.md "Design Principles"에 persist함.
