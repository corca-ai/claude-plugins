# Coverage Matrix

- RANGE: 42d2cd9..01293b3e2501153789e40699c09777ac6df64624

| matrix_id | target_type | target_ref | status | evidence_paths | history_note |
|---|---|---|---|---|---|
| M-001 | master-plan-decision | #1 Single cwf plugin | Implemented | prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md; plugins/cwf/.claude-plugin/plugin.json | Single-plugin structure is active in code and docs. |
| M-002 | master-plan-decision | #2 Breaking change | Implemented | prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md; docs/v3-migration-decisions.md | v2 plugins removed from v3 marketplace scope. |
| M-003 | master-plan-decision | #3 Umbrella branch strategy | Implemented | prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md; cwf-state.yaml | Session history records marketplace-v3 + feature branches. |
| M-004 | master-plan-decision | #4 Hook selective activation | Implemented | plugins/cwf/skills/setup/SKILL.md; plugins/cwf/hooks/scripts/cwf-hook-gate.sh | Setup-generated hook control and gate script are present. |
| M-005 | master-plan-decision | #5 Infra = hooks + setup subcommands | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/skills/setup/SKILL.md | Infra controls are hook-based and setup-managed. |
| M-006 | master-plan-decision | #6 setup + update separated | Implemented | plugins/cwf/skills/setup/SKILL.md; plugins/cwf/skills/update/SKILL.md | Setup/update split into distinct skills. |
| M-007 | master-plan-decision | #7 universal review mode | Implemented | plugins/cwf/skills/review/SKILL.md | clarify/plan/code modes are defined in review skill. |
| M-008 | master-plan-decision | #8 wf reference only | Implemented | prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md; docs/v3-migration-decisions.md | wf is treated as reference pattern, not runtime dependency. |
| M-009 | master-plan-decision | #9 agent team enhancements | Implemented | plugins/cwf/skills/gather/SKILL.md; plugins/cwf/skills/plan/SKILL.md; plugins/cwf/skills/impl/SKILL.md | Stage-specific team orchestration is encoded in skills. |
| M-010 | master-plan-decision | #10 CLI fallback = sub-agent | Implemented | plugins/cwf/skills/review/SKILL.md | External CLI fallback routes to Task reviewers. |
| M-011 | master-plan-decision | #11 pre-merge holistic refactor | Implemented | prompt-logs/260208-23-s13-holistic-refactor/session.md; plugins/cwf/skills/refactor/SKILL.md | Holistic refactor session and criteria artifacts exist. |
| M-012 | master-plan-decision | #12 persistent workflow state | Implemented | cwf-state.yaml | State file tracks sessions, live state, tools, hooks. |
| M-013 | master-plan-decision | #13 cwf:handoff skill | Implemented | plugins/cwf/skills/handoff/SKILL.md | Handoff skill exists and is documented. |
| M-014 | master-plan-decision | #14 shell-guard to lint-shell | Implemented | plugins/cwf/hooks/scripts/check-shell.sh; plugins/cwf/hooks/hooks.json | lint-shell hook script integrated into CWF hooks. |
| M-015 | master-plan-decision | #15 per-session discipline | Partial | scripts/check-session.sh; cwf-state.yaml | Forced checks exist, but adherence depends on execution practice. |
| M-016 | master-plan-decision | #16 scenario-driven verification | Implemented | plugins/cwf/skills/plan/SKILL.md; plugins/cwf/skills/review/SKILL.md | BDD + qualitative criteria pipeline is codified. |
| M-017 | master-plan-decision | #17 narrative review verdicts | Implemented | plugins/cwf/skills/review/SKILL.md; docs/v3-migration-decisions.md | Pass/Conditional/Revise narrative format is explicit. |
| M-018 | master-plan-decision | #18 progressive disclosure index | Implemented | cwf-index.md; plugins/cwf/skills/setup/SKILL.md | Index generation and index artifact are present. |
| M-019 | master-plan-decision | #19 shift-work auto transitions | Implemented | plugins/cwf/skills/run/SKILL.md; docs/v3-migration-decisions.md | Human-gated pre-impl and auto post-impl behavior specified. |
| M-020 | master-plan-decision | #20 deliberate naivete | Partial | prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md; docs/v3-migration-decisions.md | Philosophy is documented; deterministic enforcement is limited. |
| M-021 | v3-migration-decision | #1 Single Plugin | Implemented | docs/v3-migration-decisions.md; plugins/cwf/.claude-plugin/plugin.json | Mirrors master-plan decision #1 with implementation evidence. |
| M-022 | v3-migration-decision | #2 Breaking Change | Implemented | docs/v3-migration-decisions.md; prompt-logs/260210-03-docs-overhaul-impl/session.md | Session artifacts describe deletion/reset migration behavior. |
| M-023 | v3-migration-decision | #3 Umbrella Branch Strategy | Implemented | docs/v3-migration-decisions.md; cwf-state.yaml | Branch patterns are visible across session entries. |
| M-024 | v3-migration-decision | #4 Hook Selective Activation | Implemented | docs/v3-migration-decisions.md; plugins/cwf/hooks/scripts/cwf-hook-gate.sh | Hook gating implemented via shared script and setup flow. |
| M-025 | v3-migration-decision | #5 Infra as Hooks | Implemented | docs/v3-migration-decisions.md; plugins/cwf/hooks/hooks.json | Infra functions are encoded as hooks. |
| M-026 | v3-migration-decision | #14 Shell Guard Direct Integration | Implemented | docs/v3-migration-decisions.md; plugins/cwf/hooks/scripts/check-shell.sh | shell guard functionality lives inside CWF hook set. |
| M-027 | v3-migration-decision | #7 Universal Review | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/review/SKILL.md | Universal review skill is implemented with mode routing. |
| M-028 | v3-migration-decision | #9 Agent Team Patterns | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/impl/SKILL.md | Team sizing, decomposition, and reviewer orchestration are present. |
| M-029 | v3-migration-decision | #10 CLI Fallback = Sub-Agent | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/review/SKILL.md | Fallback behavior defined for Codex/Gemini failures. |
| M-030 | v3-migration-decision | #12 Persistent Workflow State | Implemented | docs/v3-migration-decisions.md; cwf-state.yaml | Live/session/tool/hook state all persisted. |
| M-031 | v3-migration-decision | #19 Shift Work (Human Gates) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/run/SKILL.md | Run orchestration defines gate behavior by stage. |
| M-032 | v3-migration-decision | #15 Per-Session Discipline | Partial | docs/v3-migration-decisions.md; scripts/check-session.sh | Mechanism exists; compliance still process-dependent. |
| M-033 | v3-migration-decision | #16 Scenario-Driven Verification | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/plan/SKILL.md; plugins/cwf/skills/review/SKILL.md | Criteria handoff from plan to review is explicit. |
| M-034 | v3-migration-decision | #17 Narrative Verdicts | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/review/SKILL.md | Review verdict contract is narrative, not numeric. |
| M-035 | v3-migration-decision | #20 Deliberate Naivete | Partial | docs/v3-migration-decisions.md; prompt-logs/260208-08-sw-factory-discussion/next-session.md | Intent is documented but not mechanically enforced. |
| M-036 | v3-migration-decision | #6 Setup / Update Separation | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/setup/SKILL.md; plugins/cwf/skills/update/SKILL.md | Setup/update split is reflected in skill boundaries. |
| M-037 | v3-migration-decision | #13 Auto-Generated Handoff | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/handoff/SKILL.md | Handoff generation defined and used in sessions. |
| M-038 | v3-migration-decision | #18 Progressive Disclosure Index | Implemented | docs/v3-migration-decisions.md; cwf-index.md | Index behavior and artifact exist. |
| M-039 | v3-migration-decision | Expert-in-the-Loop (S13.5-B) | Implemented | docs/v3-migration-decisions.md; cwf-state.yaml | Expert roster and related session lineage exist. |
| M-040 | v3-migration-decision | Concept Distillation (S13.5-B2) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/references/concept-map.md | Concept artifacts exist with provenance. |
| M-041 | v3-migration-decision | Compact Recovery (S29) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/hooks/scripts/compact-context.sh | Compact recovery hook script and live-state use exist. |
| M-042 | v3-migration-decision | Context Recovery Protocol (S32-impl) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/references/context-recovery-protocol.md | Shared protocol extracted and referenced by skills. |
| M-043 | v3-migration-decision | Decision Journal (S33) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/impl/SKILL.md; cwf-state.yaml | Decision journal rule and live field are present. |
| M-044 | v3-migration-decision | Auto-Chaining cwf:run (S33) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/run/SKILL.md | Full stage chain orchestration exists. |
| M-045 | v3-migration-decision | Review Fail-Fast (S33) | Implemented | docs/v3-migration-decisions.md; plugins/cwf/skills/review/SKILL.md | CAPACITY/INTERNAL/AUTH handling is documented in review flow. |
| M-046 | inventory-skill | cwf:setup | Implemented | plugins/cwf/skills/setup/SKILL.md | Inventory target exists as active skill. |
| M-047 | inventory-skill | cwf:update | Implemented | plugins/cwf/skills/update/SKILL.md | Inventory target exists as active skill. |
| M-048 | inventory-skill | cwf:gather | Implemented | plugins/cwf/skills/gather/SKILL.md | Inventory target exists as active skill. |
| M-049 | inventory-skill | cwf:clarify | Implemented | plugins/cwf/skills/clarify/SKILL.md | Inventory target exists as active skill. |
| M-050 | inventory-skill | cwf:plan | Implemented | plugins/cwf/skills/plan/SKILL.md | Inventory target exists as active skill. |
| M-051 | inventory-skill | cwf:impl | Implemented | plugins/cwf/skills/impl/SKILL.md | Inventory target exists as active skill. |
| M-052 | inventory-skill | cwf:review | Implemented | plugins/cwf/skills/review/SKILL.md | Inventory target exists as active skill. |
| M-053 | inventory-skill | cwf:retro | Implemented | plugins/cwf/skills/retro/SKILL.md | Inventory target exists as active skill. |
| M-054 | inventory-skill | cwf:refactor | Implemented | plugins/cwf/skills/refactor/SKILL.md | Inventory target exists as active skill. |
| M-055 | inventory-skill | cwf:handoff | Implemented | plugins/cwf/skills/handoff/SKILL.md | Inventory target exists as active skill. |
| M-056 | inventory-skill | cwf:ship | Implemented | plugins/cwf/skills/ship/SKILL.md | Inventory target exists as active skill. |
| M-057 | inventory-hook | attention | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/attention.sh | Hook inventory target exists and is wired. |
| M-058 | inventory-hook | log | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/log-turn.sh | Hook inventory target exists and is wired. |
| M-059 | inventory-hook | read | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/smart-read.sh | Hook inventory target exists and is wired. |
| M-060 | inventory-hook | lint-markdown | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/check-markdown.sh | Hook inventory target exists and is wired. |
| M-061 | inventory-hook | lint-shell | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/check-shell.sh | Hook inventory target exists and is wired. |
| M-062 | inventory-hook | websearch-redirect | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/redirect-websearch.sh | Hook inventory target exists and is wired. |
| M-063 | inventory-hook | compact-recovery | Implemented | plugins/cwf/hooks/hooks.json; plugins/cwf/hooks/scripts/compact-context.sh | Hook inventory target exists and is wired. |
| M-064 | milestone | S13.5-A | Implemented | cwf-state.yaml; prompt-logs/260209-24-s13.5-feedback-loop-infra/session.md | Canonical ID retained. |
| M-065 | milestone | S13.5-B | Implemented | cwf-state.yaml; prompt-logs/260209-25-s13.5-b-expert-loop/session.md | Canonical ID retained. |
| M-066 | milestone | S13.5-B2 | Implemented | cwf-state.yaml; prompt-logs/260209-26-s13.5-b2-concept-distillation/session.md | Canonical ID retained. |
| M-067 | milestone | S13.5-B3 | Implemented | cwf-state.yaml; prompt-logs/260209-27-s13.5-b3-concept-refactor/session.md | Canonical ID retained. |
| M-068 | milestone | post-B3 | Implemented | cwf-state.yaml; prompt-logs/260209-28-post-b3-housekeeping/next-session.md | Legacy label normalized to canonical post-B3. |
| M-069 | milestone | S29 | Implemented | cwf-state.yaml; prompt-logs/260209-29-live-state-compact-recovery/session.md | Canonical ID retained. |
| M-070 | milestone | S32-impl | Implemented | cwf-state.yaml; prompt-logs/260210-03-docs-overhaul-impl/session.md | Legacy S32 mapped to canonical S32-impl. |
| M-071 | milestone | S33 | Implemented | cwf-state.yaml; prompt-logs/260210-04-s33-cdm-auto-chain/session.md | Canonical ID retained. |
| M-072 | milestone | S14 | Implemented | cwf-state.yaml; prompt-logs/260211-01-s14-integration-test/session.md | Canonical ID retained. |
| M-073 | milestone | S15 | Implemented | cwf-state.yaml; prompt-logs/260211-02-s15-agent-browser-integration/session.md | Canonical ID retained. |
| M-074 | milestone | S16 | Superseded | cwf-state.yaml; prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md; prompt-logs/260211-04-s17-next-session-hardening/plan.md | S16 handoff baseline was revised/hardened by S17 before execution. |
