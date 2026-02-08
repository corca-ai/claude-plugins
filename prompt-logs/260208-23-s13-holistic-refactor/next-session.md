# S13.5 Handoff — Feedback Loop Infrastructure

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/project-context.md` — accumulated patterns (especially "Feedback loop existence over case count" and "Agent autonomy requires boundary awareness")
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-23-s13-holistic-refactor/retro.md` — deep retro with Meadows/Woods expert analysis on self-healing
5. `prompt-logs/260208-23-s13-holistic-refactor/lessons.md` — "Rule of three vs feedback loop" lesson
6. `plugins/cwf/references/skill-conventions.md` — current conventions + "Future Consideration: Self-Healing Criteria" section
7. `plugins/cwf/skills/refactor/references/holistic-criteria.md` — provenance header (first implementation)
8. `plugins/cwf/skills/refactor/SKILL.md` — holistic mode workflow (where provenance check will go)

## Task Scope

Three workstreams, unified theme: **feedback loop infrastructure for agent autonomy**.

### A. Self-Healing Criteria Design + Implementation

Design and implement self-healing for ALL documents and code that agents rely on — not just skill criteria files. Provenance metadata (holistic-criteria.md) is one PoC, not the mandated pattern. The design phase should explore what self-healing looks like for different artifact types (SKILL.md, reference docs, project-context.md, CLAUDE.md, hook scripts, conventions docs). Each may need different metadata and different staleness signals.

#### A1. Design (use cwf:clarify)

Key design questions:
- **Provenance schema**: What metadata fields? (skill count, hook count, written session, last reviewed). YAML frontmatter vs HTML comment vs separate metadata file?
- **Comparison logic**: Where does the runtime check live? In each skill individually, or in a shared "provenance checker" referenced by skill-conventions?
- **Threshold**: What constitutes "significant change"? (Meadows warns against over-sensitivity → alarm fatigue. Woods says threshold should be conservative.)
- **Adaptive response menu**: When staleness is detected, what options does the agent present? (a) Request user review, (b) Apply criteria with gap report, (c) Skip criteria and flag. (Woods: detection without response options is incomplete.)

#### A2. Implementation

- Upgrade `holistic-criteria.md` provenance from HTML comment to chosen schema
- Add provenance to ALL reference/criteria files in `plugins/cwf/`
- Add provenance check to `refactor/SKILL.md` holistic mode (Phase 2, before analysis)
- Update `skill-conventions.md`: promote "Future Consideration" to formal rule
- Test: modify provenance artificially, verify the check triggers correctly

### B. Expert-in-the-Loop Workflow Design

Currently, expert perspectives appear only in retro (after the fact). The user wants expert agents to participate DURING workflow stages for faster feedback loops.

#### B1. Design (use cwf:clarify)

Key design questions:
- **Which stages?** clarify (challenge assumptions), review (framework-based review), impl (design advisor)? All or subset?
- **Integration pattern**: New sub-agent in existing skills, or separate "advisor" skill that other skills invoke?
- **Expert selection**: Fixed per-stage experts, or dynamic selection based on session domain?
- **Constraint**: Sub-agents don't inherit skills — expert agents need reference docs in their prompt. How to keep this lightweight?

#### B2. Prototype

Pick one stage (likely cwf:clarify or cwf:review) and implement expert-in-the-loop as a proof of concept. Validate that the feedback loop is actually shorter and more useful than post-hoc retro analysis.

### C. project-context.md Slimming

`project-context.md` is accumulating good principles but risks becoming too long, overfitted, and siloed. It is itself a self-healing target:
- Audit: which entries are still actionable vs. historical?
- Are entries duplicated across project-context.md, CLAUDE.md, and skill-conventions.md?
- Should some entries graduate to skill-specific Rules sections and be removed from the central doc?
- Apply the same "does this document know when it's stale?" question to project-context.md itself

### D. Hook Infrastructure Improvements

#### C1. Attention hook Slack threading

Current issue: "채널로도 전송"을 켜놔서 알림이 어지러움. Test:
- 채널로 전송을 끄고 알림이 정상적으로 오는지 확인
- 첫 부모 메시지에서 멘션(@user)만으로 충분한지 테스트
- Slack user ID / handle을 attention hook이 알고 있는지 확인 (env var 또는 설정)

#### C2. Hook script module abstraction

Problem: attention hook과 prompt-logger가 유사한 로직(빈 줄 처리, transcript 파싱)을 독립적으로 구현. prompt-logger에서 고친 빈 줄 문제가 attention hook에는 전파되지 않음.

- Audit: 두 훅이 공유하는 로직을 식별 (transcript parsing, blank line trimming, session hash, etc.)
- Extract: 공통 로직을 `hooks/shared/` 모듈로 추출
- This is the same pattern extraction principle from S13, but for scripts instead of skills

## Don't Touch

- `prompt-logs/` 기존 세션 — read-only
- Architecture decisions in `master-plan.md`
- S14 범위 (review + merge) — S13.5는 S14에 필요한 인프라를 준비하는 것

## Lessons from Prior Sessions

1. **Feedback loop > case count** (S13): 피드백 루프가 없는 실패는 사례 수에 관계없이 즉시 루프 설치
2. **Agent autonomy requires boundary awareness** (S13): 도구가 자기 유효성을 판단하지 못하면, 자율성 위임은 brittleness를 키운다
3. **Reporting principle** (S13): 정량적 보고에서 독자의 외부 지식 의존 최소화 — skill-conventions.md에 성문화됨
4. **Pattern extraction for scripts** (S13): 3+ 스킬/훅이 동일 로직을 반복하면 공유 모듈 추출
5. **Provenance as information infrastructure** (S13 Meadows): provenance는 주석이 아니라 작동하는 피드백 루프의 일부

## Success Criteria

```gherkin
Given provenance metadata is designed and implemented
When a criteria file's provenance shows significant system change
Then the skill flags staleness to the user before proceeding

Given expert-in-the-loop is prototyped in one workflow stage
When the stage is executed
Then expert feedback is integrated during the stage (not post-hoc)

Given project-context.md is audited for staleness and duplication
When slimming is applied
Then no entry is duplicated across project-context.md, CLAUDE.md, and skill-conventions.md

Given attention hook blank line issue is identified
When shared module is extracted
Then both attention and prompt-logger use the same logic
```

## Dependencies

- Requires: S13 completed (holistic refactor, conventions established)
- Blocks: S14 (review + merge) — S13.5 output becomes part of what S14 reviews

## Dogfooding

Use CWF skills: `cwf:clarify` for design questions, `cwf:plan` for implementation planning, `cwf:impl` for execution, `cwf:retro` for session review.

## Start Command

```text
Read the context files listed above, especially the deep retro's Meadows/Woods analysis
and the lessons.md "Rule of three vs feedback loop" entry. Start with workstream A
(self-healing design) using cwf:clarify to resolve design questions. Then implement.
Move to B (expert-in-the-loop) and C (hook improvements) based on time available.
```
