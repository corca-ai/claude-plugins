# S13.5-B Handoff — Expert-in-the-Loop + Remaining Workstreams

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/project-context.md` — accumulated patterns (Provenance sidecar pattern added in S13.5-A)
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260209-24-s13.5-feedback-loop-infra/lessons.md` — S13.5-A lessons (12 entries including deferred actions)
5. `prompt-logs/260209-24-s13.5-feedback-loop-infra/retro.md` — deep retro with Meadows/Woods expert analysis
6. `prompt-logs/260208-23-s13-holistic-refactor/next-session.md` — original S13.5 scope (workstreams B, C, D still pending)
7. `plugins/cwf/references/skill-conventions.md` — Provenance Rule section (added in S13.5-A)

## Task Scope

S13.5 has 4 workstreams. A (self-healing provenance) is complete. This session covers B, C, D.

### B. Expert-in-the-Loop Workflow Design

Expert perspectives currently appear only in retro (post-hoc). Goal: expert agents participate DURING workflow stages.

#### B1. Design (use cwf:clarify)

- **Which stages?** clarify, review, impl — all or subset?
- **Integration pattern**: New sub-agent in existing skills, or separate "advisor" skill?
- **Expert selection**: Fixed per-stage or dynamic per-domain?
- **Constraint**: Sub-agents don't inherit skills — expert agents need reference docs in prompt

#### B2. Prototype

Pick one stage (likely cwf:review) and implement. Validate that in-stage expert feedback is more useful than post-hoc retro analysis.

### C. project-context.md Slimming

- Audit: actionable vs historical entries
- Deduplication across project-context.md, CLAUDE.md, skill-conventions.md
- Graduate entries to skill-specific Rules sections
- Apply self-healing question: "does this document know when it's stale?"

### D. Hook Infrastructure Improvements

- **D1**: Attention hook Slack threading (채널 전송 끄기, 멘션만으로 충분한지)
- **D2**: Hook script module abstraction (attention + prompt-logger 공유 로직 추출)

## Unresolved Items from S13.5-A

### From Deferred Actions

- [ ] Review skill Rule 5: save review results as files (synthesis + individual) in session directory
- [ ] Review skill `--base <branch>` flag for umbrella branch pattern
- [ ] Review skill individual reviewer files as default behavior
- [ ] Deterministic lint target filtering (extension-based, e.g., `git diff --name-only -- '*.md'`)
- [ ] Session start protocol: branch check step in handoff workflow
- [ ] Plan mode → session plan.md deadlock: ExitPlanMode hook to copy plan to session dir
- [ ] Retro session symlink: team run support (multiple agent logs)
- [ ] prompt-logger AskUserQuestion tool result logging (workstream D candidate)
- [ ] EnterPlanMode lessons.md enforcement hook
- [ ] README v3 overhaul with philosophy (assigned to S14)

### From Lessons

- [ ] Deep retro sub-agent delegation: sections 3-4 to sub-agents, main agent as "session summary + synthesis"
- [ ] Retro structured session summary: save to file at retro start for compact resilience
- [ ] Multi-phase skill intermediate artifact preservation: analyze applicability across retro, review, refactor, clarify, impl (S13.6 candidate)
- [ ] [carry-forward] Handoff always required regardless of branch structure — add explicit rule to handoff SKILL.md

## Don't Touch

- `scripts/provenance-check.sh` — reviewed and fixed in S13.5-A
- `plugins/cwf/skills/refactor/SKILL.md` Phase 1b — provenance check integrated in S13.5-A
- `plugins/cwf/skills/handoff/SKILL.md` Phase 4b — unresolved items propagation added in S13.5-A
- `plugins/cwf/references/skill-conventions.md` Provenance Rule — promoted in S13.5-A

## Lessons from Prior Sessions

1. **Feedback loop > case count** (S13): Install feedback loops immediately, don't wait for more cases
2. **Provenance sidecar pattern** (S13.5-A): `.provenance.yaml` alongside target documents, staleness via count proxy + agent scope eval
3. **impl → review → fix commit pattern** (S13.5-A): Self-documenting history as minimum unit
4. **Deterministic validation > behavioral instruction** (S13): Scripts beat rules in CLAUDE.md
5. **Handoff always required** (S13.5-A): Session boundary ≠ branch boundary. Every session creates next-session.md regardless of branch structure
6. **Ship 전 untracked 확인** (S13.5-A): `git status`로 untracked 파일 중 세션 아티팩트를 식별하여 커밋. `/ship` 스킬 미사용으로 이슈 누락/PR 영어 작성 실수도 발생 — 스킬이 있으면 반드시 사용

## Success Criteria

```gherkin
Given expert-in-the-loop is prototyped in one workflow stage
When the stage is executed
Then expert feedback is integrated during the stage (not post-hoc)

Given project-context.md is audited for staleness and duplication
When slimming is applied
Then no entry is duplicated across project-context.md, CLAUDE.md, and skill-conventions.md

Given attention hook and prompt-logger share parsing logic
When shared module is extracted
Then both hooks use the same implementation
```

## Dependencies

- Requires: S13.5-A completed (provenance system, handoff Phase 4b)
- Blocks: S13.6 (CWF protocol design — needs expert-in-the-loop pattern), S14 (merge)

## Branch Workflow

1. Create a feature branch from `marketplace-v3`: `git checkout -b s13.5-b-expert-loop marketplace-v3`
2. Merge S13.5-A first if not already merged: PR `s13.5-a-provenance` → `marketplace-v3`
3. Do all work on the feature branch
4. Use `/ship` to create PR from feature branch → `marketplace-v3`

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or the trigger list in skill descriptions. Use CWF skills for workflow stages instead of manual execution.

**Phase 4b dogfooding**: This handoff is the first to include "Unresolved Items" — verify the format works for the next session's agent.

## Start Command

```text
Read the context files above. Start with workstream B (expert-in-the-loop design)
using cwf:clarify to resolve design questions. Then implement prototype.
Move to C (project-context slimming) and D (hook improvements) based on time.
Use /ship throughout. Check the Unresolved Items section for carry-forward work.
```
