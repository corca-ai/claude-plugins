# Clarification: Expert-in-the-Loop Workflow Design

## Original Requirement

"Expert perspectives currently appear only in retro (post-hoc). Goal: expert agents participate DURING workflow stages (clarify, review, impl)."

## Clarified Requirement

**Goal**: Build an Expert-in-the-Loop pattern for CWF skills where domain expert sub-agents provide analysis during workflow execution, not just post-hoc in retro.

**Scope**:

- Design a common expert advisory pattern, codified in a shared `expert-advisor-guide.md` reference doc
- Prototype in TWO stages (clarify + review) to validate the pattern generalizes
- Expert roster stored in YAML, evolving semi-automatically: retro records experts used per session → recommends additions → user approves
- Standalone `cwf:advise` skill is OUT of prototype scope (follow-up)

**Constraints**:

- Sub-agents don't inherit skills → deliver domain knowledge via reference docs in `references/` directory
- Default behavior: always-on. `--light` flag to reduce expert involvement
- Expert selection: dynamic per session domain (extending retro's expert-lens-guide.md pattern)
- Expert roster YAML must record: expert name, domain, recommendation rationale

**Success Criteria**:

```gherkin
Given expert-advisor-guide.md is created as a shared reference
When both clarify and review skills reference it
Then expert sub-agents provide domain analysis during stage execution

Given the expert roster YAML exists
When retro completes a session
Then experts used in that session are recorded with domain and rationale

Given expert-in-the-loop is always-on by default
When a user runs clarify or review without --light
Then domain expert analysis is included in the output
```

## Decisions

| # | Decision Point | Decision | Decided By | Evidence |
|---|---------------|----------|------------|----------|
| 1 | Target stages | clarify + review (both prototype) | Human | "Minimum 2 stages to validate pattern" |
| 2 | Integration pattern | Shared reference doc (expert-advisor-guide.md) | Human | "Shared doc only" — advise skill is follow-up |
| 3 | Expert selection | Dynamic + evolving roster (YAML) | Human | "Grow organically, store in YAML" |
| 4 | Reference doc delivery | `references/` directory pattern | Agent (T1) | 10+ reference files use this pattern |
| 5 | Output format | expert-lens-guide.md format (Framework, Source, Why, Analysis, Recommendations) | Agent (T1) | Retro expert α/β format established |
| 6 | Interaction model | One-shot advisory | Agent (T2) | Codebase + external examples all use one-shot |
| 7 | Default behavior | Always-on + --light option | Human | "Default bias toward expert participation" |
| 8 | Roster evolution | Semi-automatic (retro records → recommends → user approves) | Human | "Record expert domain + recommendation rationale in YAML" |

## Research Summary

### Codebase Patterns (from Explore agent)

- **6 skills use sub-agents**, all with perspective-based parallel division
- **Clarify**: advisory α/β for T3 decisions (fixed side-assignment: conservative vs innovative)
- **Retro**: expert α/β in deep mode (dynamic selection, contrasting frameworks, web-verified)
- **Review**: 4 parallel reviewers (fixed roles: Security, UX/DX, Correctness, Architecture)
- **Impl**: domain-adaptive agent team (file pattern → domain signal)
- **Refactor**: perspective-based parallel (structural vs quality, or pattern/boundary/connection)
- Reference docs in `references/` are the universal context delivery mechanism

### External Research (from Web researcher)

- Google Cloud patterns: Review & Critique (quality gates), Coordinator (adaptive routing)
- Expert agents highest value at **clarify** and **review** stages; lowest at impl
- Cost patterns: conditional routing, model right-sizing (Haiku for triage, Opus for analysis)
- Anthropic context engineering: sub-agents return condensed summaries, context stays isolated
- AI Advisory Council (published case study): disagreement between experts is itself a valuable signal

### Key Sources

- [Google Cloud: Agentic AI Design Patterns](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system)
- [Nick Tune: Coding Agent Development Workflows](https://medium.com/nick-tune-tech-strategy-blog/coding-agent-development-workflows-af52e6f912aa)
- [Niraj Kumar: AI Advisory Council for Code Review](https://medium.com/@nirajkvinit/i-built-an-ai-advisory-council-for-code-review-heres-what-actually-works-c3b531ca4b65)
- [Anthropic: Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Claude Code: Custom Subagents](https://code.claude.com/docs/en/sub-agents)
