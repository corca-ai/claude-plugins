# Next Session: S5a — cwf:review Internal Reviewers

## What This Is

`cwf:review` 스킬의 첫 번째 구현 세션. 내부 리뷰어(Security + UX/DX)를
Task tool로 구현하고, Review Synthesis 출력 형식을 확립한다.

Full context: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`

## Background

S4.6에서 SW Factory 분석을 통해 다음 설계가 확정됨:
- **Narrative verdict** (Pass/Conditional Pass/Revise) — 수치 점수 아님
- **Two-layer success criteria** — behavioral (BDD) + qualitative 입력
- **Deliberate naivete** — 비용 이유로 리뷰어 수 축소 금지

이 설계를 반영한 `cwf:review` 내부 리뷰어를 먼저 구현한다.
외부 CLI (Codex, Gemini) 통합은 S5b에서.

## Scope

### 1. SKILL.md 작성 (`plugins/cwf/skills/review/SKILL.md`)

Dev 단계이므로 `.claude/skills/review/SKILL.md`에 작성하여 dogfooding.

- `--mode clarify/plan/code` 3개 모드
- Plan의 success criteria (behavioral + qualitative) 수신 인터페이스
- `--scenarios <path>` 인터페이스 예약 (미구현, 향후 S10+)
- 리뷰 결과를 Review Synthesis Format으로 출력

### 2. Internal reviewers (2개 Task agents)

```text
Internal (Task tool):
├── Security: vulnerabilities, auth, data exposure
└── UX/DX: API design, error messages, developer experience
```

- 각 리뷰어의 perspective prompt 작성 (`references/prompts.md`)
- 모드별 (`clarify/plan/code`) 프롬프트 분기
- 2개를 병렬 Task tool로 실행
- 각 리뷰어 출력에 provenance metadata 포함

### 3. Review Synthesis 로직

- 2개 리뷰어 결과를 수집하여 단일 synthesis 생성
- Verdict 판정: Pass / Conditional Pass / Revise
- Concerns + Suggestions + Confidence Note 구조
- Behavioral criteria가 제공된 경우 체크리스트로 검증

### 4. agent-patterns.md 참조 연결

- SKILL.md에서 `plugins/cwf/references/agent-patterns.md` 참조
- Review Synthesis Format, Provenance Tracking, Graceful Degradation 섹션 활용

## Don't Touch

- External CLI integration (Codex, Gemini) — S5b에서
- Graceful degradation fallback logic — S5b에서
- 기존 hook/skill 코드
- `cwf-state.yaml` 실제 읽기/쓰기 (S12에서)

## Success Criteria

### Behavioral

```text
Given: plan.md with behavioral criteria (Given/When/Then)
When: cwf:review --mode code is invoked
Then: 2 internal reviewers run in parallel via Task tool
  AND output includes Review Synthesis with verdict
  AND behavioral criteria appear as checked/unchecked items

Given: code with obvious security issue (e.g., SQL injection)
When: cwf:review --mode code is invoked
Then: Security reviewer flags the issue in Concerns section
  AND verdict is Conditional Pass or Revise

Given: cwf:review invoked with --mode plan
When: plan has no clear success criteria
Then: UX/DX reviewer flags missing criteria in Concerns
```

### Qualitative

- SKILL.md is under 500 lines and self-contained
- Perspective prompts are specific enough to produce differentiated reviews
- Review Synthesis is useful for a human reader (not boilerplate)

## Dependencies

- Requires: S4 completed (scaffold), S4.6 completed (design decisions)
- Blocks: S5b (external CLI integration)

## Reference

- master-plan.md: Architecture Decision #7, #16, #17, #20
- agent-patterns.md: Multi-Agent Review Pattern, Review Synthesis Format, Design Principles
- SW Factory analysis: `references/sw-factory/analysis.md` (origin/main)

## After Completion

1. Create session dir: `prompt-logs/{YYMMDD}-{NN}-cwf-review-internal/`
2. Write plan.md, lessons.md
3. Write next-session.md (S5b handoff — external CLI integration)
4. `/retro`
5. Commit & push

## Start Command

```text
@prompt-logs/260208-08-sw-factory-discussion/next-session.md S5a 시작합니다
```
