# Deep Review Batch E

Skills under review: `review` (universal review orchestrator) and `run` (pipeline orchestrator). Criteria 1‑9 from `plugins/cwf/skills/refactor/references/review-criteria.md` were applied to each skill.

## review

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 (Size) | SKILL.md spans 485 lines (2,781 words) so it stays below both the warning thresholds (500 lines, 3,000 words). | `plugins/cwf/skills/review/SKILL.md:1-485` | n/a |
| info | 2 (Progressive Disclosure) | Front matter contains only `name`/`description`/triggers and the body focuses on the review workflow rather than inserting “When to use” prose. | `plugins/cwf/skills/review/SKILL.md:1-39` | n/a |
| info | 3 (Duplication) | Heavy-weight guidance (prompt structure, CLI templates, synthesis rules) is sourced from references; the SKILL only assembles those artifacts rather than copying them. | `plugins/cwf/skills/review/SKILL.md:204-345` | n/a |
| warning | 4 (Resource Health) | Phase 2.2 detects `codex`/`npx` only by `command -v`; it still launches the CLI even when the binary is unauthenticated, which can cause repeated timeouts before the fallback Task agent runs. | `plugins/cwf/skills/review/SKILL.md:265-279` | Check authentication status (e.g., `codex auth status`/`npx @google/gemini-cli auth`) before invoking the CLI and treat unauthenticated results as immediate fallbacks so the review stage fails fast. |
| info | 5 (Writing Style) | Prompt-building, gating, and synthesis sections use imperative steps (“Build prompt,” “Run cross-check,” “Append provenance”) so agents follow low-freedom instructions. | `plugins/cwf/skills/review/SKILL.md:223-431` | n/a |
| info | 6 (Degrees of Freedom) | The workflow predefines reviewer slots, context-recovery contracts, failure flows, and artifact gates, keeping the review execution deterministic. | `plugins/cwf/skills/review/SKILL.md:188-420` | n/a |
| info | 7 (Anthropic Compliance) | Front matter sticks to the required fields and keeps the short description within the expected pattern. | `plugins/cwf/skills/review/SKILL.md:1-4` | n/a |
| info | 8 (Concept Integrity) | Agent Orchestration is satisfied by launching the six reviewers in a single batch with provenance files, and Expert Advisor is covered via the expert slots + roster update instructions pointing to `expert-advisor-guide.md`. | `plugins/cwf/skills/review/SKILL.md:188-408` | n/a |
| info | 9 (Repository Independence) | All scripts and helpers are resolved through `{CWF_PLUGIN_DIR}` (live-state helper, codex sync, `check-run-gate-artifacts`), so the skill adapts to any repository layout. | `plugins/cwf/skills/review/SKILL.md:224-428` | n/a |

### Prioritized actions
1. Before launching `codex`/`gemini`, run their auth-status commands (or similar lightweight checks) and skip the CLI attempt when they are unauthenticated so the workflow falls back immediately without CLI timeouts.

## run

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 (Size) | SKILL.md covers 492 lines (2,623 words) so it remains below the warning thresholds. | `plugins/cwf/skills/run/SKILL.md:1-492` | n/a |
| info | 2 (Progressive Disclosure) | Front matter only exposes name/description while the majority of the document stays on workflow orchestration. | `plugins/cwf/skills/run/SKILL.md:1-24` | n/a |
| info | 3 (Duplication) | Stage definitions, ambiguity handling, gating, and completion logic are described once in the SKILL; no duplicated reference material appears alongside them. | `plugins/cwf/skills/run/SKILL.md:27-441` | n/a |
| info | 4 (Resource Health) | The only external references (agent-patterns, plan-protocol) are credited at the end and reused to explain pattern expectations. | `plugins/cwf/skills/run/SKILL.md:489-492` | n/a |
| info | 5 (Writing Style) | Initialization, stage loop, and gate sections present commands and checklist items in imperative format so automation follows predictable steps. | `plugins/cwf/skills/run/SKILL.md:29-340` | n/a |
| info | 6 (Degrees of Freedom) | Worktree verification, ambiguity ledger, stage provenance, and review failure handling are scripted with little room for improvisation, matching low-degree-of-freedom needs. | `plugins/cwf/skills/run/SKILL.md:27-367` | n/a |
| info | 7 (Anthropic Compliance) | Front matter obeys metadata constraints while the description is concise and trigger-focused. | `plugins/cwf/skills/run/SKILL.md:1-4` | n/a |
| warning | 8 (Concept Integrity) | The skill claims Agent Orchestration but the implementation runs stages strictly sequentially (stage table + single-threaded execution loop) without documenting parallel batches or adaptive team sizing, so the asserted concept misaligns with the actual behavior. | `plugins/cwf/skills/run/SKILL.md:120-341` | Clarify that `cwf:run` is a sequential pipeline in the concept map (or add explicit parallel batching/adaptive sub-agents per stage) so the Agent Orchestration claim matches the documented execution model. |
| info | 9 (Repository Independence) | Scripts are invoked via `cwf-live-state.sh`, `check-run-gate-artifacts.sh`, and other `{CWF_PLUGIN_DIR}` helpers, avoiding hard-coded repo paths and keeping the skill portable. | `plugins/cwf/skills/run/SKILL.md:32-431` | n/a |

### Prioritized actions
1. Either adjust the concept-map claim to treat `cwf:run` as a sequential pipeline orchestrator or enrich the skill with explicit batch/agent-team descriptions (e.g., stage-level helper agents) to preserve the Agent Orchestration narrative.

<!-- AGENT_COMPLETE -->
