## Context Files to Read

1. [AGENTS.md](../../../AGENTS.md)
2. [README.ko.md](../../../README.ko.md)
3. [README.md](../../../README.md)
4. [plugins/cwf/skills/retro/SKILL.md](../../../plugins/cwf/skills/retro/SKILL.md)
5. [plugins/cwf/skills/hitl/SKILL.md](../../../plugins/cwf/skills/hitl/SKILL.md)
6. [plugins/cwf/skills/setup/SKILL.md](../../../plugins/cwf/skills/setup/SKILL.md)
7. [plugins/cwf/scripts/codex/post-run-checks.sh](../../../plugins/cwf/scripts/codex/post-run-checks.sh)
8. [plugins/cwf/scripts/codex/codex-with-log.sh](../../../plugins/cwf/scripts/codex/codex-with-log.sh)
9. [.cwf/projects/260216-02-hitl-readme/hitl/hitl-scratchpad.md](./hitl/hitl-scratchpad.md)
10. [.cwf/projects/260216-02-hitl-readme/retro.md](./retro.md)

## Current Status

- This session finished README/README.ko + setup-wrapper wording sync and wrapper option-2 implementation (`post-run-checks`).
- `retro.md` was written as `Mode: deep` but did not fully follow deep-mode execution contract (no deep sub-agent batch outputs, no `/find-skills` execution for tool-gap skill path).
- Core policy was clarified: "all skills must remain operable under context-deficit conditions (including compact boundaries) using state/artifact/handoff contracts, not conversational memory."
- User requested:
  - Next session: implement all previously proposed fixes **except item 3 (scope lock)**.
  - Next session: verify README.ko SoT intent is fully reflected in external docs.
  - This session: only explain why retro contract was broken and prepare corrective handoff.

## Task Scope (Next Session)

Implement these items (skip item 3):

0. Promote "context-deficit resilience" to a cross-skill invariant (not retro-only behavior):
   - define contract language once
   - reflect it in SoT docs + relevant skill contracts
   - verify each affected skill has a deterministic fallback/recovery path
1. Retro fact cleanup and mode-accuracy fixes in `retro.md`.
2. HITL `intent_resync_required` flow (state + enforcement before next chunk).
4. Tool hygiene gate: detect/flag `apply_patch` via `exec_command`.
5. HITL sync gate: doc changes require scratchpad update.
6. Retro evidence collector automation (`retro-collect-evidence` path).

Also run a full SoT propagation check:
- `README.ko.md` -> `README.md` + related skill docs consistency.

## Non-Negotiable Process Guardrails

### A. Cross-Skill Invariant (SoT + Handoff)

Treat this as a global contract across CWF skills:
- Skills must work even when prior conversational context is missing/truncated.
- Recovery must rely on persistent state + artifacts + handoff files.
- Any skill behavior requiring implicit prior chat memory is a contract violation.
- Do not encode this as retro-only HOW; encode as shared philosophy and enforceable contracts.

### B. Retro deep-mode contract

If `retro.md` remains `Mode: deep`, execution must include deep artifacts:
- `retro-cdm-analysis.md`
- `retro-learning-resources.md`
- `retro-expert-alpha.md`
- `retro-expert-beta.md`

Each deep artifact must end with:

```html
<!-- AGENT_COMPLETE -->
```

If deep batch cannot run, downgrade retro to light mode and state the reason explicitly.

### C. Learning resources must include external search when deep

For Section 6 in deep mode:
- run web search/fetch workflow per retro skill protocol
- include external references, not internal docs only
- internal docs can be supplemental, not substitute

### D. Skill-gap branch requires `/find-skills` execution

When Section 7 proposes a skill gap:
- run `/find-skills` first and record result
- if unavailable, record explicit "tool unavailable" evidence and fallback rationale

### E. No silent scope expansion

For user requests like "N only":
- do not include out-of-scope changes without explicit user approval
- if safety/integrity requires wider edits, stop and ask before applying

## Pending Worktree Snapshot

Current dirty files at handoff:

- `.cwf/cwf-state.yaml`
- `.cwf/projects/260216-02-hitl-readme/hitl/hitl-scratchpad.md`
- `.cwf/projects/260216-02-hitl-readme/retro.md`
- `README.ko.md`
- `README.md`
- `plugins/cwf/scripts/README.md`
- `plugins/cwf/scripts/check-growth-drift.sh`
- `plugins/cwf/scripts/codex/codex-with-log.sh`
- `plugins/cwf/skills/setup/SKILL.md`
- `scripts/codex/codex-with-log.sh`
- `.cwf/projects/260216-02-hitl-readme/session-state.yaml` (new)
- `plugins/cwf/scripts/codex/post-run-checks.sh` (new)
- `scripts/codex/post-run-checks.sh` (new)

## Success Criteria

```gherkin
Given retro is marked as deep mode
When retrospective execution is completed
Then deep artifact files are present with AGENT_COMPLETE markers and Section 6 includes external resources.
```

```gherkin
Given any CWF skill runs after context loss or compact recovery
When required prior chat context is unavailable
Then the skill still executes correctly using persisted state/artifacts/handoff inputs.
```

```gherkin
Given tool-gap analysis suggests a skill path
When Section 7 is finalized
Then /find-skills result (or explicit unavailable evidence) is recorded.
```

```gherkin
Given README.ko is SoT
When sync verification is run
Then README.md and related skill docs reflect the same intent without unresolved mismatch.
```

## Execution Contract (Mention-Only Safe)

If the user provides only this file path, treat it as instruction to resume with:
1) retro contract correction first,
2) then implementation items (2,4,5,6),
3) then SoT external reflection verification.

- Branch gate: avoid base branch direct implementation.
- Commit gate: commit by logical unit.
- Staging gate: include only intended files per commit.

## Start Command

```text
Resume from this handoff: fix retro deep-contract correctness first, then implement items 2/4/5/6 (skip 3), then verify README.ko SoT reflection across external docs.
```
