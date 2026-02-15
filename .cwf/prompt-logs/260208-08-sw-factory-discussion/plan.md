# S4.6 Plan — SW Factory Analysis + CWF v3 Design Discussion

## Session Type

Design discussion — no code changes.

## Agenda

### 1. SW Factory 핵심 개념 정리 및 CWF v3 적용 가능성 논의

분석 문서의 핵심 개념들:
- Scenario Testing + Holdout Set
- Satisfaction spectrum (boolean → probabilistic)
- Shift Work (interactive vs non-interactive)
- Pyramid Summaries
- Deliberate Naivete
- Gene Transfusion

### 2. CWF v3에 반영할 개념 식별

특히 `cwf:review`와 `agent-patterns.md`에:
- 시나리오 기반 검증을 어떻게 적용할 것인가?
- 홀드아웃 세트의 실현 가능성
- 만족도(satisfaction) 측정

### 3. S4.5에서 추가된 논의 사항

- Post-implementation 자율 워크플로우
- /ship 개선 검증

### 4. 산출물

- 논의 결과 정리 → 이 파일에 반영
- master-plan.md 또는 agent-patterns.md 업데이트 항목 목록
- next-session.md (S5a 핸드오프)

## Status

- [x] Agenda 1: SW Factory 개념 논의
- [x] Agenda 2: CWF v3 반영 항목
- [x] Agenda 3: S4.5 추가 논의
- [x] Agenda 4: 산출물 작성

## Discussion Results

### Architecture Decisions Added (#16–#20)

| # | Decision | Source Concept |
|---|----------|---------------|
| 16 | Scenario-driven verification | Scenario Testing + BDD |
| 17 | Narrative review verdicts | Satisfaction spectrum (rejected numerical, chose prose) |
| 18 | Progressive disclosure index | Pyramid Summaries (reframed as pointers, not summaries) |
| 19 | Shift Work auto-transitions | Shift Work |
| 20 | Deliberate naivete | Deliberate Naivete |

### Documents Updated

- `master-plan.md`: Decisions #16–#20, Scenario-Driven Verification section,
  Progressive Disclosure Index section, cwf-state.yaml stages with auto flag,
  skill notes for setup/gather/plan/review
- `agent-patterns.md`: Review Synthesis Format, Design Principles
  (Deliberate Naivete + Shift Work)

### /ship S4.5 Verification

All requirements confirmed in skill files (design-level verification):
- Korean language + 배경/문제/목표 structure ✅
- Decision table + verification steps + human judgment section ✅
- Autonomous merge decision matrix ✅
- Runtime test deferred to next implementation session

### Concepts NOT Applied

| Concept | Reason |
|---------|--------|
| Gene Transfusion | Already implicit in our workflow (referencing moonlight patterns). No explicit mechanism needed. |
| Digital Twin Universe | Not applicable — we don't depend on external SaaS APIs to test. |
| Semport | No cross-language porting in our plugin development. |
