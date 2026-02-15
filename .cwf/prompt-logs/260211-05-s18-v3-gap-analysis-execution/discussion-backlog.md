# Discussion Backlog

- RANGE: 42d2cd9..01293b3e2501153789e40699c09777ac6df64624

## A: Likely Missing Implementation

| backlog_id | linked_gap_id list | impact | confidence | required decision question | minimal next action |
|---|---|---|---|---|---|
| BL-001 | GAP-001 | Holdout validation remains declarative, so hidden-scenario verification cannot be exercised in real reviews. | High | Should `cwf:review --scenarios <path>` be implemented in v3 scope now or explicitly deferred to v4? | Add explicit decision row to next implementation plan and either implement flag parsing or mark intentional defer with owner/date. |
| BL-002 | GAP-002 | Umbrella-branch teams can still produce noisy/wrong diffs during code review. | High | Do we add `--base <branch>` to `cwf:review` or adopt strict upstream-branch detection as the canonical fix? | Draft one-step patch plan and add BDD example for marketplace-v3 base selection. |
| BL-003 | GAP-005 | Codex logs are captured but not first-class review/retro/handoff evidence, creating blind spots. | Medium | Should `sessions-codex/*.md` be added to mandatory input sources for retro/handoff (and optionally review)? | Update source-discovery sections in `plugins/cwf/skills/retro/SKILL.md` and `plugins/cwf/skills/handoff/SKILL.md`. |

## B: Insufficiently Discussed / Under-specified

| backlog_id | linked_gap_id list | impact | confidence | required decision question | minimal next action |
|---|---|---|---|---|---|
| BL-004 | GAP-003 | Concept-analysis outcomes may drift from refactor criteria due to incomplete integration contract. | Medium | Is the S13.5-B2 integration target “fully delivered”, “partially delivered”, or “needs new dedicated session”? | Run a focused trace from S13.5-B2 integration points to current `plugins/cwf/skills/refactor/references/*.md`. |
| BL-005 | GAP-006 | Recurring sub-agent persistence misses can invalidate downstream synthesis despite protocol presence. | Medium | Do we need a hard fail gate when expected `AGENT_COMPLETE` artifacts are missing? | Add a deterministic validation step to orchestrator stages that depend on persisted sub-agent files. |

## C: Intent Drift Worth Explicit Reconfirmation

| backlog_id | linked_gap_id list | impact | confidence | required decision question | minimal next action |
|---|---|---|---|---|---|
| BL-006 | GAP-004 | Decision #20 may remain aspirational without enforceable behavior constraints. | Medium | Should Decision #20 remain philosophical guidance or be converted into script-level pass/fail checks? | Propose one measurable enforcement candidate (e.g., required reviewer count/mode gate) and evaluate feasibility. |
| BL-007 | GAP-014 | “Per-session discipline” can pass artifact checks while missing stronger semantic quality controls. | Medium | Do we extend `check-session.sh` beyond artifact presence into semantic checks for critical workflows? | Define a minimal semantic gate spec and evaluate false-positive risk on recent sessions. |

## Decision Updates

| decision_id | backlog_id | decision | decided_at | implementation note |
|---|---|---|---|---|
| DEC-001 | BL-001 | `GAP-001` must be implemented in v3 before merge (no v4 defer). | 2026-02-11 | Use `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md` as implementation contract source. |
| DEC-002 | BL-002 | `GAP-002` uses dual strategy: upstream-aware default + `--base <branch>` override. | 2026-02-11 | Implement in `cwf:review` with deterministic branch resolution trace in output/provenance. |
| DEC-003 | BL-004 | Keep `GAP-003` as `Unknown` until dedicated closure trace is completed. | 2026-02-11 | Perform focused evidence trace from S13.5-B2 integration points to current refactor criteria files. |
| DEC-004 | BL-006 | Keep Decision #20 as policy guidance only; no additional hard gate in v3 pre-merge. | 2026-02-11 | Accepted-policy risk; monitor via standard review/retro rather than enforcement script. |
| DEC-005 | BL-003 | Unify logs into `prompt-logs/sessions/` with runtime suffix (`*.codex.md`, `*.claude.md`) and temporary legacy read support. | 2026-02-11 | Implement naming/output migration + dual-path source discovery in retro/handoff until legacy removal criteria are met. |
| DEC-006 | BL-005 | Use hybrid gate policy for sub-agent persistence: hard on critical stages, soft on non-critical stages. | 2026-02-11 | Define stage tiers and enforce deterministic fail on critical artifact loss. |
| DEC-007 | BL-007 | Extend `check-session.sh` with a minimal semantic set first (option 2), then expand if needed. | 2026-02-11 | First wave: GAP-open-to-BL closure + CW-to-GAP mapping; optional RANGE consistency check. |
