# CWF v3 Migration Decisions

Key architecture and process decisions made during the CWF v3 consolidation (S0-S33, 24 sessions across marketplace-v3 branch).

## Architecture

### #1 Single Plugin

All 9 standalone plugins consolidated into one `cwf` plugin. Claude Code's `{plugin}:{skill}` naming gives `cwf:gather`, `cwf:clarify`, etc. for free. Reference: compound-engineering (16 skills) and superpowers (13 skills) both use this pattern.

**Trade-off**: Monorepo-style plugin vs. independent release cycles. Single plugin won because naming convention requires it and coordination cost of 9 separate plugins exceeded the coupling cost.

### #2 Breaking Change

Old plugins deleted entirely (S32: 93 files, -7479 lines). `marketplace.json` reset to v3.0.0 with CWF only. No migration path from v2 — clean install.

### #3 Umbrella Branch Strategy

`marketplace-v3` as integration branch + feature branches per task. Development done as repo-level skills (`.claude/skills/`) for immediate dogfooding, converted to plugin structure at merge. This eliminated the "develop blind, test later" anti-pattern.

### #4 Hook Selective Activation

Dual-file config: `cwf-config.json` (skills read) + `cwf-hooks-enabled.sh` (hooks source). `cwf:setup` generates both. Hooks check their group flag via `cwf-hook-gate.sh` at startup — zero-cost when disabled.

### #5 Infra as Hooks

No standalone infra skills. Infrastructure (markdown lint, shell check, smart read, log, attention, compact recovery, websearch redirect) lives entirely in hooks managed by `cwf:setup`.

### #14 Shell Guard Direct Integration

`check-shell.sh` built directly as CWF hook, not as standalone plugin first. Avoided the create-then-migrate waste pattern seen in v2.

## Workflow Design

### #7 Universal Review

Single `cwf:review` skill with `--mode clarify/plan/code`. 6 parallel reviewers: 2 internal (Security, UX/DX via Task), 2 external (Codex, Gemini via CLI), 2 domain experts (via Task). Replaces per-stage cross-check with unified review.

### #9 Agent Team Patterns

Each stage has a characteristic agent pattern:
- **gather**: Adaptive (broad → parallel team, specific → single)
- **clarify**: 4 sub-agents (2 research + 2 expert advisory)
- **plan/impl**: Agent team with review integration
- **review**: 6 parallel reviewers
- **retro/refactor**: Parallel sub-agents per perspective

### #10 CLI Fallback = Sub-Agent

External CLI not found → Task agent with same perspective prompt. Never falls back to main agent inline (would lose parallelism and perspective isolation). Provenance tracks source: `REAL_EXECUTION` vs `FALLBACK`.

### #12 Persistent Workflow State

[`.cwf/cwf-state.yaml`](../.cwf/cwf-state.yaml) is the single source of truth: current stage, 24-session history, tool availability, hook config, and live session state. Read by compact recovery hook, handoff skill, and check-session.sh.

### #19 Shift Work (Human Gates)

Pre-impl stages (gather, clarify, plan) require human input — decisions are open-ended. Post-impl stages (review, retro, ship) chain automatically — the spec is fixed, execution is mechanical. `cwf:run` implements this as `auto: true/false` per stage.

## Quality Philosophy

### #15 Per-Session Discipline

Each session reviews its own output, tests, and updates docs. Quality is not deferred to a final session. Enforced by `check-session.sh` as a forced function (not optional memory).

### #16 Scenario-Driven Verification

Plan's success criteria flow into review as verification input. Two layers:
- **Behavioral (BDD)**: Given/When/Then — mechanically verifiable
- **Qualitative**: Narrative assessment — reviewer judgment

This creates a contract pipeline: plan → impl → review.

### #17 Narrative Verdicts

Review outputs structured prose (Pass / Conditional Pass / Revise), not numerical scores. Trust intelligent agents over false precision. The stricter reviewer wins when reviewers disagree.

### #20 Deliberate Naivete

Never reduce review depth or agent count for cost reasons. All 6 reviewers always run. Challenge "too expensive" assumptions — the cost of missed issues exceeds the cost of thorough review.

## Process Innovations

### #6 Setup / Update Separation

`cwf:setup` = initial config + hook selection + external tool detection. `cwf:update` = version check + changelog. Separated because setup is one-time interactive, update is periodic automated.

### #13 Auto-Generated Handoff

`cwf:handoff` generates session handoff from [`.cwf/cwf-state.yaml`](../.cwf/cwf-state.yaml) + artifacts. Also supports `--phase` mode for phase-to-phase context transfer (HOW context separate from plan WHAT).

### #18 Progressive Disclosure Index

`cwf:setup` now separates two index outputs:

- Capability index: optional artifact generated only on explicit command (`cwf:setup --cap-index`), not by default full setup.
- Repository index: [AGENTS.md](../AGENTS.md) managed block (`cwf:setup --repo-index --target agents`).

Repository index content remains "when to read what" pointers, not summaries.

## Emergent Decisions (S13.5-S33)

These decisions emerged during hardening, not in the original plan.

### Expert-in-the-Loop (S13.5-B)

Domain expert sub-agents (roster in [`.cwf/cwf-state.yaml`](../.cwf/cwf-state.yaml)) participate in clarify, review, and retro. Two experts with contrasting frameworks provide analytical tension. Expert roster evolves semi-automatically.

### Concept Distillation (S13.5-B2)

Applied Jackson's Essence of Software: 6 generic concepts (Plan, Decision, Gate, Reviewer, Session, Expert) + 9 application concepts. Review criteria restructured around Form/Meaning/Function triad.

### Compact Recovery (S29)

`SessionStart(compact)` hook injects live state after auto-compaction: session metadata, key files, decisions, recent turns, and (during impl phase) plan summary + decision journal. Provides structural memory when conversational memory is lost.

### Context Recovery Protocol (S32-impl)

Shared protocol for sub-agent file persistence: agents write results to session directory files with `<!-- AGENT_COMPLETE -->` sentinel. On compact recovery, orchestrator checks for existing valid results before re-launching agents. 5 skills use this protocol.

### Decision Journal (S33)

During impl phase, significant decisions are appended to [`.cwf/cwf-state.yaml`](../.cwf/cwf-state.yaml) `live.decision_journal`. The compact recovery hook reads this field to restore decision context. One-line entries, max ~80 chars.

### Auto-Chaining — cwf:run (S33)

Full pipeline orchestration: gather → clarify → plan → review(plan) → impl → review(code) → retro → ship. Configurable with `--from` and `--skip` flags. Max 1 auto-fix attempt on review failure before escalating to user.

### Review Fail-Fast (S33)

Error-type classification checks stderr BEFORE exit code:
- **CAPACITY** (429, quota): immediate fallback, no retry
- **INTERNAL** (500): 1 retry then fallback
- **AUTH** (401): abort with setup hint

Prevents wasting time on retries that cannot succeed.

## Session Journey

| Phase | Sessions | Key Milestone |
|-------|----------|---------------|
| Clarify | S0 | Master plan with 20 decisions |
| Refactor | S1-S2 | Fixed critical issues on main |
| Scaffold | S3-S4.6 | Ship skill, CWF plugin skeleton, SW Factory analysis |
| Review | S5a-S5b | 4-reviewer pattern with external CLI integration |
| Build | S6a-S10 | 7 hooks migrated, 5 skills built |
| Harden | S11-S33 | Retro/refactor migration, holistic review, concept distillation, compact recovery, auto-chaining |
| Launch | S14 | Integration test + this document |

Total: 24 sessions, 11 skills, 7 hook groups, ~120 files in `plugins/cwf/`.
