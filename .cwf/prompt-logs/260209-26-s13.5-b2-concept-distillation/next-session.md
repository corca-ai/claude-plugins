# Next Session: Concept-Based Analysis for Refactor

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260209-26-s13.5-b2-concept-distillation/concept-distillation.md` — the concept distillation (6 generic + 9 application concepts, synchronization map)
5. `plugins/cwf/skills/refactor/SKILL.md` — current refactor skill
6. `plugins/cwf/skills/refactor/references/review-criteria.md` — deep review criteria
7. `plugins/cwf/skills/refactor/references/holistic-criteria.md` — holistic analysis criteria

## Task Scope

Integrate concept-based analysis into the refactor skill. The concept distillation identified 6 generic concepts and 9 application concepts with a synchronization map. This analysis can enhance refactor's quality detection in three ways.

### What to Build

**Integration Point 1 — Deep Review: Concept Integrity criterion**

Add a criterion to `review-criteria.md` that verifies whether a skill's claimed concept composition matches its actual implementation. Example checks:
- If a skill synchronizes Expert Advisor, does it actually enforce contrasting frameworks?
- If a skill synchronizes Agent Orchestration, does it implement adaptive sizing?
- If a skill synchronizes Tier Classification, does it have T1/T2/T3 routing logic?

**Integration Point 2 — Holistic: Synchronization Analysis dimension**

Add a 4th dimension to `holistic-criteria.md` (currently 3: Pattern Propagation, Boundary Issues, Missing Connections):
- Do skills synchronizing the same generic concept implement it consistently?
- Under-synchronization: is a skill missing a concept it should synchronize?
- Over-synchronization: is a skill synchronizing a concept it doesn't need?

**Integration Point 3 — Concept Map as reference**

Create a reference document (or section within existing criteria) containing the synchronization map (9×6 table from distillation Section 4). This becomes the input for both Integration Points 1 and 2. Provenance metadata should be attached so staleness is detected when skills are added/changed.

### Key Design Points

- Whether to create a new `concept-map.md` reference in `plugins/cwf/references/` or embed the map within existing criteria documents
- How holistic sub-agents (currently 3 parallel) should incorporate the 4th dimension — add a 4th agent, or merge into existing agents
- Whether concept integrity checking in deep review should be a separate criterion section or woven into existing criteria

## Don't Touch

- Individual `plugins/cwf/skills/*/SKILL.md` files (except refactor)
- `plugins/cwf/references/expert-advisor-guide.md`, `expert-lens-guide.md`
- `scripts/` directory
- Hook configurations
- `README.md`, `README.ko.md`

## Lessons from Prior Sessions

1. **OP 작성 테스트** (S13.5-B2): Concept 후보 검증에 "OP를 써볼 것"이 효과적인 litmus test. OP가 기존 원칙을 반복하면 concept이 아니라 원칙의 적용
2. **Parnas의 은닉 결정 테스트** (S13.5-B2 retro): OP 테스트(behavioral independence)와 함께 "이 후보가 은닉하는 변경 가능한 설계 결정은 무엇인가?" (change independence) 병행 적용
3. **Provenance sidecar pattern** (S13.5-A): Reference 문서에 `.provenance.yaml`을 붙여 system state at creation time 기록. 새로 만드는 concept map reference에도 적용할 것
4. **Feedback loop existence over case count** (S13): 피드백 루프가 없으면 즉시 설치. Concept map provenance가 이 원칙의 적용

## Success Criteria

```gherkin
Given the 6 generic concepts and synchronization map from concept-distillation.md
When refactor --skill <name> runs deep review
Then the report includes a "Concept Integrity" section
  verifying claimed concept composition against actual implementation

Given the synchronization map
When refactor --skill --holistic runs cross-plugin analysis
Then the report includes a "Synchronization Analysis" section
  detecting under-synchronization and over-synchronization across skills

Given a concept map reference document with provenance metadata
When skills are added or the synchronization map changes
Then provenance-check.sh detects staleness in the concept map
```

## Dependencies

- Requires: S13.5-B2 (concept distillation — completed)
- Requires: S13.5-A (provenance system — completed)

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Start Command

```text
Read the concept distillation document and refactor criteria files, then design and implement the three integration points for concept-based analysis in the refactor skill.
```
