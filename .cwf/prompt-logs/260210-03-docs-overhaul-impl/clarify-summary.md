# Clarification Summary: L1-L3 Implementation

## Before (Original)

"Implement L1-L3 from S32 lessons: impl git awareness, clarify completion gate, state-tracked commits"

## After (Clarified)

**Goal**: cwf:impl에 git workflow integration을, cwf:clarify에 durable state
tracking을 추가하여 clarify→impl→ship pipeline을 resilient하게 만든다.

**Scope**:
- Included: impl SKILL.md (Phase 0.5 Branch Gate, Phase 3 Commit Gate, Phase 1
  Clarify Pre-condition), clarify SKILL.md (file-based result persistence,
  cwf-state.yaml completion tracking)
- Excluded: ship SKILL.md (no changes), hook additions, new skill creation

**Constraints**:
- cwf-state.yaml schema: extend existing `live` section (no breaking changes)
- Commits follow Conventional Commits format (existing repo convention)
- `--skip-clarify` override flag for hard-block bypass
- Clarify research results stored in session directory files (not cwf-state.yaml)

## Expert Analysis

| Expert | Framework | Key Insight |
|--------|-----------|-------------|
| David Parnas | Information hiding, modular decomposition (1972) | Git commit granularity is impl's "hidden design decision" — current design is a processing-order decomposition error. impl must own the full contract: branches, commits, completion tracking. |
| David Woods | Resilience engineering, graceful extensibility (2018) | CWF exhibits "cliff of brittleness" in 3 places. Commits = adaptive capacity markers. In-memory-only results = boundary blindness. Hard-block with override provides regime-awareness diagnostic. |

## All Decisions

| # | Decision Point | Decision | Decided By | Evidence |
|---|---------------|----------|------------|----------|
| 1 | Branch Gate trigger | **Always feature branch** — impl creates feature branch if on base branch. No warn-only mode. | Human | "무조건 feature branch. 그럴 일이 아니라면 유저가 cwf 스킬 없이 하라고 명시할듯." |
| 2 | Commit granularity | **Fine-grained per work-item** — commit per work item (not per batch). If lessons emerge during impl, record them and create separate commits showing lesson-driven changes. | Human | "더 잘게 쪼개도 됨. 구현하다가 레슨이 생겼다면 기록하고 그 결과로 인해 바뀌었음이 나오면 더 좋음." |
| 3 | Commit message format | `{type}[scope]: {description}` + body with step descriptions + `Co-Authored-By` trailer | Agent (T1) | Git log convention (commit 0040222) |
| 4 | State tracking location | Completion metadata → cwf-state.yaml; results → clarify-research.md in session dir | Agent (T2) | Temporal durable execution, Parnas verifiable invariant |
| 5 | Clarify pre-condition | Hard-block with `--skip-clarify` override + state visibility message | Agent (T2) | Parnas/Woods/Fowler consensus on irreversible action gating |
| 6 | Context loss recovery | **Maximize file persistence** — all clarify results, intermediate states, sub-agent outputs saved to files as persistent memory | Human | "최대한 파일에 저장해서 persistent memory로 씀." |

## Workflow

This implementation follows the full CWF workflow:

```text
clarify (done) → plan → review → impl → review → refactor → retro
```
