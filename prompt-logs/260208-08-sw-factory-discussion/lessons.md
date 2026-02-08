# S4.6 Lessons — SW Factory Analysis + CWF v3 Design Discussion

## Session Context

- **Type**: Design discussion (no implementation)
- **Goal**: Read SW Factory analysis, identify concepts for CWF v3, design scenario testing approach
- **Inputs**: `references/sw-factory/analysis.md`, master-plan.md, agent-patterns.md

## Lessons

### 1. Holdout scenarios — defer to S10+, but design interfaces now

Holdout sets prevent reward hacking when the same agent writes code AND tests.
In our current setup (`cwf:review` reviews human/agent code), the motivation
is weaker. But CWF is a general-purpose plugin — other users' `cwf:impl` →
`cwf:review` pipelines will have this risk. Reserve `--scenarios <path>` in
`cwf:review` interface now, implement later.

### 2. Narrative > numerical for review verdicts

Numerical scores (8/10, 77%) create false precision and invite mechanical
thresholds. Structured prose (Pass/Conditional Pass/Revise + concerns +
suggestions) preserves context and trusts intelligent agents. The reviewing
agent's judgment matters more than aggregated numbers.

### 3. "Progressive disclosure index" beats "pyramid summaries"

User insight: "index.md" that tells agents "when to read what" (pointers)
is better than "summaries" (compressed/lossy content). Key properties:
- No information loss — links, not compression
- Agent-friendly — explicit "when to read" guidance
- Low maintenance — valid as long as structure doesn't change
- Natural fit with `cwf:gather` workflow

### 4. Shift Work maps directly to cwf-state.yaml auto-transitions

StrongDM's "interactive vs non-interactive" division maps cleanly to CWF stages:
- Interactive (auto: false): gather, clarify, plan — human refines intent
- Autonomous (auto: true): impl → review → retro → commit — fixed spec, agent chains

### 5. BDD-style success criteria connect plan to review naturally

Plan's success criteria in two categories:
- Behavioral (Given/When/Then) → `cwf:review` checks mechanically
- Qualitative (prose) → `cwf:review` addresses in narrative verdict

This creates a contract between stages without extra ceremony.

### 6. /ship S4.5 improvements verified

All three S4.5 requirements confirmed in skill files:
- Issue template: Korean + 배경/문제/목표/작업 범위 structure ✅
- PR template: 결정사항 table + 검증 방법 + 인간 판단 필요 사항 ✅
- Merge logic: decision matrix (human judgment × branch protection) ✅
- Language rule: "Issue/PR body는 한글로 작성" in SKILL.md ✅

Runtime test deferred — requires actual issue/PR creation in a real session.
