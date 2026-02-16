# Workflow Coherence Analysis (Function)

> Date: 2026-02-16
> Scope: 13 skills + 7 hook lifecycle events
> Pipeline: gather -> clarify -> plan -> review(plan) -> impl -> review(code) -> refactor -> retro -> ship

---

## 3a. Data Flow Completeness

### 3a.1 Pipeline Data Flow Map

The following map traces each skill's primary outputs and which downstream skills consume them.

| Producer Skill | Primary Output | Expected Consumer(s) | Connection Documented? | Format Compatible? |
|---|---|---|---|---|
| gather | `{OUTPUT_DIR}/*.md` (URL artifacts, search results, local exploration) | clarify, plan (as input context) | PARTIAL — clarify/plan do not explicitly reference gather output paths; relies on user copy-paste or file mention | YES (markdown) |
| clarify | `clarify_completed_at` + `clarify_result_file` in live-state; Clarification Summary file | plan (input context), impl (Phase 1.0 gate), review (`--mode clarify`) | YES for impl gate (`clarify_completed_at` checked by impl Phase 1.0); PARTIAL for plan (no explicit input-file contract); YES for review | YES |
| plan | `.cwf/projects/{dir}/plan.md`, `lessons.md`; research files (`plan-prior-art-research.md`, `plan-codebase-analysis.md`) | impl (Phase 1 loads plan.md), review (`--mode plan`), handoff (reads plan.md), ship (reads plan.md for issue/PR body) | YES — impl, review, handoff, ship all document plan.md consumption | YES |
| plan | Sub-agent research outputs (`plan-prior-art-research.md`, `plan-codebase-analysis.md`) | plan itself only (synthesis input) | N/A — internal to plan | YES |
| impl | Committed code changes; `lessons.md` updates; BDD coverage report | review (`--mode code` reads git diff), retro (reads session artifacts), ship (reads git log) | YES — review uses git diff; retro reads lessons.md; ship reads git log | YES |
| review | Review synthesis (conversation output); 6 review verdict files in session_dir | impl (if Revise verdict -> auto-fix loop in cwf:run), ship (PR body references review), retro (reads session review artifacts) | PARTIAL — review outputs to conversation by default, not to a file. Ship and retro reference review but have no guaranteed file path to read from. The 6 individual reviewer files exist in session_dir but the synthesis is ephemeral. | ISSUE (see Finding F-1) |
| hitl | `hitl-scratchpad.md`, `state.yaml`, `rules.yaml`, `fix-queue.yaml` | No documented downstream consumer | ORPHAN candidates (see Finding F-2) |
| retro | `retro.md` in session dir; expert roster updates in `cwf-state.yaml` | handoff (reads retro.md for action items), ship (PR body `{CDM}` field reads retro.md) | YES — handoff Phase 1.3 reads retro.md; ship PR template reads CDM section | YES |
| handoff | `next-session.md` or `phase-handoff.md` | impl (Phase 1.1b reads phase-handoff.md); next session agent (reads next-session.md) | YES — impl documents phase-handoff consumption; next-session.md is the session bootstrap contract | YES |
| ship | GitHub issue URL, PR URL, merge confirmation | No downstream CWF skill (terminal) | N/A — terminal action | N/A |
| refactor | Quick scan table, deep review report, holistic analysis report, tidy suggestions, docs findings | No automatic downstream consumer; user-driven action | Orphan by design — refactor is advisory. Reports are persisted in session dir. | YES |
| setup | `cwf-hooks-enabled.sh`, `cwf-state.yaml` updates, config files | All hooks (read cwf-hooks-enabled.sh); all skills (read cwf-state.yaml) | YES — hooks gate on env vars; skills read cwf-state.yaml | YES |
| update | Updated plugin installation | setup (may need re-run after update) | NO explicit link — update does not suggest re-running setup | Minor gap |
| run | Pipeline orchestration (no unique output) | N/A — run produces no unique artifact; it delegates to constituent skills | N/A | N/A |

### 3a.2 Data Flow Findings

#### F-1 [MODERATE]: Review synthesis is ephemeral -- no persisted synthesis file

**What**: `cwf:review` Rule 5 states "Output to conversation -- review results are communication, not state. Do not write files unless the user explicitly asks." However, multiple downstream consumers need the review synthesis:

- `cwf:run` Phase 2 Review Failure Handling needs to extract concerns from review output to construct a fix plan.
- `cwf:ship` PR template `{CDM}` and `{LESSONS}` fields need to reference review findings.
- `cwf:retro` reads session artifacts for retrospective analysis.

The 6 individual reviewer verdict files ARE persisted in the session directory, but the **merged synthesis** (the verdict, concerns list, and suggestions) exists only in the conversation. When context is compacted or a new session starts, the synthesis is lost.

**Impact**: `cwf:run`'s auto-fix loop depends on extracting concerns from the review, but after compaction this information is unavailable from files. The context recovery protocol has no entry for the review synthesis itself.

**Proposal**: Add an optional `--persist` flag (or make persistence default within `cwf:run` invocations) that writes `review-synthesis-{mode}.md` to the session directory. This preserves context-deficit resilience for the review -> impl auto-fix loop.

---

#### F-2 [LOW]: HITL artifacts are orphaned from the main pipeline

**What**: `cwf:hitl` produces rich state artifacts (`hitl-scratchpad.md`, `state.yaml`, `rules.yaml`, `fix-queue.yaml`, `events.log`), but no other skill in the pipeline reads these outputs. The hitl skill is not part of the default `cwf:run` pipeline (gather -> clarify -> plan -> review -> impl -> review -> refactor -> retro -> ship).

**Impact**: Low, because HITL is intentionally a manual side-loop for human-judgment insertion. However:
- `cwf:retro` could benefit from reading `hitl-scratchpad.md` for decisions/agreements made during HITL review.
- `cwf:ship` PR body could reference HITL decisions.

**Proposal**: Document HITL as an optional pipeline spur. Consider having retro scan for `hitl/hitl-scratchpad.md` in the session directory as an additional evidence source during Step 2 (Read Existing Artifacts).

---

#### F-3 [MODERATE]: gather -> clarify output path is implicit

**What**: `cwf:gather` saves artifacts to `CWF_GATHER_OUTPUT_DIR` (default `.cwf/projects`), but `cwf:clarify` does not document any mechanism to auto-discover or load gather output artifacts. The connection relies on the user mentioning gathered files or the agent having them in conversational context.

When `cwf:run` orchestrates gather -> clarify, the gather outputs may be in conversation context. But after compaction or session restart, gather artifacts are not automatically loaded by clarify.

**Impact**: In the `cwf:run` pipeline, gather outputs should flow into clarify's decision point analysis. Without explicit file discovery, compaction between stages could break this data flow.

**Proposal**:
1. Have `cwf:gather` register output file paths in live-state (`live.gather_artifacts: [list of paths]`).
2. Have `cwf:clarify` Phase 1 check `live.gather_artifacts` and auto-read those files before decomposing decision points.

---

#### F-4 [LOW]: clarify -> plan output path partially implicit

**What**: `cwf:clarify` writes a clarification summary file and records `clarify_result_file` in live-state. However, `cwf:plan` does not document reading `clarify_result_file` from live-state. Plan's Phase 1 "Parse & Scope" records the task description from user input, not from clarify's output file.

**Impact**: When `cwf:run` chains clarify -> plan, the clarify output may be in conversational context. But the file-based data flow is not documented. Plan's sub-agents do independent codebase and web research, which partially compensates, but clarify's decision resolutions (T1/T2/T3 outcomes) are not explicitly forwarded.

**Proposal**: Have `cwf:plan` Phase 1 check `live.clarify_result_file` and auto-read the clarification summary as input context alongside the user's task description.

---

#### F-5 [LOW]: update -> setup re-run not suggested

**What**: After `cwf:update` installs a new plugin version, it advises "Restart Claude Code for changes to take effect" but does not suggest re-running `cwf:setup` to sync hooks, tools, or capability index with the new version.

**Impact**: New hooks or tools introduced in an update would not be configured until the user independently runs setup.

**Proposal**: Add a post-update suggestion: "Run `cwf:setup` to sync hook toggles and tool detection with the updated version."

---

#### F-6 [LOW]: refactor outputs not consumed by any remediation skill

**What**: `cwf:refactor` (all modes) produces analysis reports with prioritized action items, but there is no automated path to convert these into a plan or implementation. The user must manually invoke `cwf:plan` or act directly.

**Impact**: Low, because refactor is intentionally advisory. The offer-to-apply step in deep review mode partially addresses this for single-skill fixes.

**Proposal**: For holistic mode, consider generating a skeleton `plan.md` from the "Prioritized Actions" table that users can feed into `cwf:impl`.

---

### 3a.3 Orphaned Output Summary

| Artifact | Producer | Consumed By | Status |
|---|---|---|---|
| Review synthesis (conversation) | review | run (auto-fix), retro (evidence) | EPHEMERAL -- not file-persisted |
| HITL scratchpad/state | hitl | None | ORPHAN (by design -- manual side-loop) |
| Refactor analysis reports | refactor | None (user-driven) | ORPHAN (by design -- advisory) |
| gather output artifacts | gather | clarify (implicit only) | PARTIAL -- no file-based discovery contract |

---

## 3b. Trigger Clarity

### 3b.1 Skill Trigger Analysis

Each skill declares triggers in its frontmatter `description` field. The following analysis checks for ambiguity.

| Skill | Declared Triggers | Potential Ambiguity |
|---|---|---|
| setup | `cwf:setup`, `setup hooks`, `configure cwf` | Clear -- unique intent |
| gather | `cwf:gather`, URL detection, search requests, code search | Clear -- gather is the only URL/search skill |
| clarify | `cwf:clarify`, `clarify this`, `refine requirements` | **AMBIGUITY with review `--mode clarify`** (see F-7) |
| plan | `cwf:plan`, `plan this task` | Clear -- unique intent |
| impl | `cwf:impl`, `implement this plan` | Clear -- unique intent |
| review | `/review` | **OVERLAP with hitl** for "review" intent (see F-8) |
| hitl | `cwf:hitl`, `hitl`, `interactive review`, `human review`, `cwf:review --human` | **OVERLAP**: `cwf:review --human` is documented as a hitl alias, but review skill does not document forwarding to hitl. (see F-8) |
| retro | `/retro`, `retro`, `retrospective`, `회고` | Clear -- unique intent |
| ship | `/ship` | Clear -- unique intent |
| run | `cwf:run`, `run workflow` | Clear -- unique intent |
| handoff | `cwf:handoff`, `handoff`, `핸드오프`, `다음 세션`, `phase handoff` | Clear -- unique intent |
| refactor | `cwf:refactor`, `/refactor`, `tidy`, `review skill`, `cleanup code`, `check docs consistency` | **AMBIGUITY**: `review skill` could conflict with `/review` for "review" intent. `tidy` is generic. (see F-9) |
| update | `cwf:update`, `update cwf`, `check for updates` | Clear -- unique intent |

### 3b.2 Trigger Findings

#### F-7 [LOW]: "clarify" vs "review --mode clarify" intent overlap

**What**: A user saying "review my clarified requirements" could trigger either:
- `cwf:clarify` (which creates the clarification)
- `cwf:review --mode clarify` (which reviews an existing clarification)

**Resolution**: The skills serve different purposes (creation vs. evaluation), and `cwf:clarify` explicitly suggests running `cwf:review --mode clarify` as a follow-up. The overlap is in naming, not in function. The `--mode clarify` qualifier disambiguates sufficiently.

**Severity**: Low. The current design is intentional: clarify produces, review evaluates. No action needed if the user uses the documented command forms. A brief disambiguation note in clarify's follow-up suggestion would reinforce this.

---

#### F-8 [MODERATE]: "review" vs "hitl" overlap for human review intent

**What**: `cwf:hitl` declares `cwf:review --human` as a compatibility alias, but the `cwf:review` SKILL.md does not document this alias or any forwarding mechanism. A user typing `cwf:review --human` expects human-in-the-loop review but would likely trigger the review skill, which has no `--human` flag in its mode routing table.

Additionally, both skills use the word "review" in their trigger descriptions:
- `cwf:review` = automated multi-perspective review
- `cwf:hitl` = interactive human review of diffs

**Impact**: Users seeking human review may invoke `/review --human` and receive an automated review instead, or get an error for an unrecognized flag.

**Proposal**:
1. Add explicit routing in `cwf:review`: if `--human` flag is detected, output "For interactive human review, use `cwf:hitl`."
2. Alternatively, add `--human` as a recognized flag in review's mode routing that forwards to hitl.

---

#### F-9 [LOW]: refactor "review skill" trigger is ambiguous

**What**: `cwf:refactor` lists `review skill` as a trigger. This could be confused with `/review` (the quality gate review skill). A user saying "review this skill" is ambiguous between:
- `cwf:refactor --skill <name>` (structural/quality assessment of a skill definition)
- `cwf:review` (quality gate review of code/plan/requirements)

**Impact**: Low. In practice, the `--skill <name>` argument and the word "refactor" disambiguate. But the bare trigger "review skill" without a skill name could cause confusion.

**Proposal**: Change the trigger from `review skill` to `refactor skill` or `audit skill` to avoid overlap with the review skill's namespace.

---

### 3b.3 Hook Conflict Analysis

| Lifecycle Event | Matchers | Conflict? |
|---|---|---|
| SessionStart | `compact` | No conflict -- single hook |
| UserPromptSubmit | `""` (catch-all) | No conflict -- single async hook |
| Notification | `idle_prompt` | No conflict -- single hook |
| PreToolUse | `AskUserQuestion`, `Read`, `WebSearch`, `""` (catch-all) | **No conflict** -- each matcher is distinct. The catch-all `heartbeat.sh` runs async alongside specific matchers. The `AskUserQuestion` matcher (start-timer) and `Read` matcher (read-guard) and `WebSearch` matcher (redirect-websearch) are non-overlapping. |
| PostToolUse | `AskUserQuestion`, `Write\|Edit` | **No conflict** -- `AskUserQuestion` has cancel-timer; `Write\|Edit` has three hooks (check-markdown, check-shell, check-links-local) that run sequentially. These are complementary, not conflicting. |
| Stop | `""` (catch-all) | No conflict -- single async hook |
| SessionEnd | `""` (catch-all) | No conflict -- single async hook |

**Hook Conflict Finding**: No conflicting hooks detected. All matchers are either unique or complementary. The `PreToolUse` catch-all (`heartbeat.sh`, async) coexists with specific matchers because it serves a different purpose (heartbeat tracking vs. tool-specific gating).

---

### 3b.4 Hook-Skill Interaction: WebSearch Redirect

**What**: The `redirect-websearch.sh` hook (PreToolUse on `WebSearch`) redirects WebSearch invocations to `cwf:gather --search`. This is documented in `cwf:setup` Phase 1.2 as the `websearch_redirect` hook group.

**Observation**: This is a well-designed hook-to-skill bridge. When enabled, it ensures web search goes through gather's query intelligence and API routing rather than the built-in WebSearch tool. The hook is toggleable via setup, which prevents conflicts when the user wants direct WebSearch.

---

## 3c. Workflow Automation Opportunities

### 3c.1 Currently Automated Sequences

| Automation | Mechanism | Status |
|---|---|---|
| Full pipeline (gather -> ship) | `cwf:run` | IMPLEMENTED |
| WebSearch -> gather redirect | PreToolUse hook | IMPLEMENTED |
| Plan -> review suggestion | plan Phase 5 | IMPLEMENTED (suggestion only) |
| Impl -> review suggestion | impl Phase 4.6 | IMPLEMENTED (suggestion only) |
| Review failure -> auto-fix | cwf:run Phase 2 | IMPLEMENTED (1 retry) |
| Clarify -> impl gate | impl Phase 1.0 | IMPLEMENTED (hard gate) |
| Context recovery across compaction | context-recovery-protocol | IMPLEMENTED |
| Session bootstrap | next-prompt-dir.sh --bootstrap | IMPLEMENTED |
| Live state tracking | cwf-live-state.sh | IMPLEMENTED |
| Session completeness check | check-session.sh | IMPLEMENTED |
| Compact context recovery | SessionStart hook + compact-context.sh | IMPLEMENTED |

### 3c.2 Automation Opportunity Findings

#### F-10 [MODERATE]: gather -> clarify file handoff could be automated

**What**: When `cwf:run` orchestrates gather -> clarify, the gather artifacts should be automatically discoverable by clarify. Currently, this depends on conversational context.

**Current flow**: gather saves files -> user/agent mentions files in conversation -> clarify reads them from conversation context.

**Proposed flow**: gather saves files AND registers paths in `live.gather_artifacts` -> clarify auto-reads `live.gather_artifacts` from live-state.

**Mechanism**: Use existing `cwf-live-state.sh set` infrastructure. Gather already has access to the live-state helper. Add a list field `gather_artifacts` to the live-state schema.

**Defensive check**: If `live.gather_artifacts` is empty or missing, clarify proceeds as it does today (user-provided context only).

---

#### F-11 [LOW]: plan -> review auto-chain is suggestion-only

**What**: After plan drafts `plan.md`, it suggests `cwf:review --mode plan` but does not auto-invoke it. This is intentional outside of `cwf:run` (user may want to skip review). Inside `cwf:run`, the auto-chain works correctly.

**Impact**: Low. The `cwf:run` pipeline handles this. For standalone plan usage, the suggestion is appropriate since not all plans need formal review.

**Assessment**: Working as designed. No action needed.

---

#### F-12 [MODERATE]: Duplicate research patterns across skills

**What**: Multiple skills perform their own internal web/codebase research via sub-agents:

| Skill | Research Activity |
|---|---|
| gather | Web search (Tavily/Exa), codebase exploration (--local) |
| clarify | Phase 2: codebase researcher + web researcher sub-agents |
| plan | Phase 2: prior art researcher + codebase analyst sub-agents |
| review | N/A (reviewers analyze, not research) |
| retro | Phase 4 (deep): learning resources sub-agent does web search |

While each skill's research serves a different purpose, the sub-agent patterns are structurally similar (launch Task with web research protocol, write to session dir, validate with sentinel).

**Impact**: Not a data flow problem per se, but a missed opportunity for `cwf:gather` to serve as a shared research backend. Currently, clarify and plan each spin up their own web research sub-agents rather than invoking gather's `--search` or `--local` capabilities.

**Proposal**: This is a design trade-off. Using gather as a shared backend would add a dependency and reduce skill autonomy. The current approach (each skill does its own research) is more resilient but creates structural duplication. Consider:
1. Extract the "Web Research Protocol" from `agent-patterns.md` into a reusable sub-agent prompt template that all research-launching skills share.
2. Alternatively, have clarify/plan optionally invoke `cwf:gather --search` via the Skill tool for their web research phase, with fallback to embedded sub-agents.

The first option (shared prompt template) is lower risk and maintains skill autonomy.

---

#### F-13 [LOW]: No hook bridge between impl completion and review

**What**: After `cwf:impl` completes, it suggests running `cwf:review --mode code` but there is no automated trigger. A PostToolUse or Stop hook could detect that impl has finished (by checking `live.phase == "impl"` and commit existence) and auto-suggest or auto-invoke review.

**Impact**: Low. Inside `cwf:run`, the pipeline handles this automatically. For standalone usage, the suggestion is appropriate since the user may want to inspect changes before review.

**Assessment**: This would require a "phase transition" hook that does not currently exist in the hooks infrastructure (hooks are tool-lifecycle events, not skill-lifecycle events). The current design is appropriate.

---

#### F-14 [LOW]: retro evidence collection could include review synthesis

**What**: `cwf:retro` Step 2 runs `retro-collect-evidence.sh` and reads `plan.md`, `lessons.md`, and `cwf-state.yaml`. It could also read the 6 individual review verdict files from the session directory (which ARE persisted, unlike the synthesis).

**Impact**: Low. The retro already reads `lessons.md` which captures major findings. But the full review verdict files contain richer evidence that could improve the CDM analysis and waste reduction sections.

**Proposal**: Have `retro-collect-evidence.sh` scan for `review-*-{mode}.md` files in the session directory and include them in the evidence set.

---

#### F-15 [MODERATE]: refactor not bridged to post-impl quality loop

**What**: In the `cwf:run` pipeline, `refactor` runs after `review(code)` as stage 7. However, refactor's findings (docs drift, skill drift, code tidying opportunities) have no automated path back into the pipeline. If refactor finds issues:
- Quick scan flags are displayed but not acted upon.
- There is no mechanism for refactor findings to trigger additional impl or review cycles.

**Impact**: In `cwf:run`, refactor silently produces a report and the pipeline continues to retro/ship. Drift issues flagged by refactor may ship unaddressed.

**Proposal**:
1. Have `cwf:run` check refactor output for critical flags.
2. If critical drift is detected, insert a user gate: "Refactor found N critical issues. Address before shipping?"
3. This preserves the auto/manual gate design (Decision #19) since it occurs post-impl.

---

#### F-16 [LOW]: No automation for HITL -> fix application

**What**: `cwf:hitl` builds a `fix-queue.yaml` of approved edits during review, but there is no batch-apply mechanism. Each fix is either applied immediately during the review loop or left in the queue.

**Impact**: Low. The fix-queue serves as a tracking mechanism, and the review loop handles most immediate fixes. A batch-apply command could be useful for large HITL sessions with many deferred fixes.

**Proposal**: Add `cwf:hitl --apply-fixes` subcommand that reads `fix-queue.yaml` and applies all pending items with individual commit units.

---

## Summary of Findings

### By Severity

| Severity | Count | Finding IDs |
|---|---|---|
| MODERATE | 5 | F-1, F-3, F-8, F-10, F-15 |
| LOW | 8 | F-2, F-4, F-5, F-6, F-7, F-9, F-14, F-16 |

### Prioritized Action Items

| Priority | Finding | Action | Effort | Impact | Affected Skills |
|---|---|---|---|---|---|
| 1 | F-1 | Persist review synthesis to session dir file (at minimum within cwf:run context) | Small | High -- enables context-deficit resilience for review -> impl auto-fix | review, run |
| 2 | F-3 + F-10 | Register gather artifacts in live-state; have clarify auto-discover them | Small | Medium -- completes gather -> clarify data flow | gather, clarify |
| 3 | F-8 | Add `--human` routing in review to forward to hitl (or document incompatibility) | Small | Medium -- eliminates trigger confusion | review, hitl |
| 4 | F-15 | Add refactor-findings gate in cwf:run before retro/ship | Small | Medium -- prevents shipping with known drift | run, refactor |
| 5 | F-4 | Have plan read `clarify_result_file` from live-state | Small | Low -- clarify -> plan context mostly flows via conversation | plan, clarify |
| 6 | F-5 | Add post-update setup suggestion | Small | Low -- minor UX improvement | update |
| 7 | F-2 | Document HITL as optional pipeline spur; have retro scan hitl artifacts | Small | Low -- enriches retro evidence | retro, hitl |
| 8 | F-12 | Extract shared web research prompt template | Medium | Low -- reduces structural duplication but each skill works fine independently | clarify, plan, retro, gather |
| 9 | F-9 | Rename "review skill" trigger to "refactor skill" or "audit skill" | Small | Low -- minor naming clarity | refactor |
| 10 | F-14 | Have retro evidence collector scan review verdict files | Small | Low -- enriches retro analysis | retro |
| 11 | F-7 | Add disambiguation note in clarify follow-up suggestion | Small | Low -- already disambiguated by command form | clarify |
| 12 | F-16 | Add `cwf:hitl --apply-fixes` batch command | Medium | Low -- nice-to-have for large HITL sessions | hitl |

### Overall Assessment

The CWF pipeline has strong workflow coherence overall. The `cwf:run` orchestrator correctly sequences all stages, hooks are non-conflicting and well-scoped, and most data flows are documented. The primary gaps are:

1. **Ephemeral review synthesis** (F-1) is the most impactful finding -- it breaks context-deficit resilience for the review -> impl auto-fix loop, which is a declared operating invariant.

2. **gather -> clarify implicit handoff** (F-3/F-10) is the most common pattern gap -- the live-state infrastructure already exists to solve it, and the fix is straightforward.

3. **Trigger overlap** between review/hitl (F-8) is the most user-facing ambiguity -- the `--human` alias is declared by hitl but not handled by review.

4. **refactor findings not gated** in cwf:run (F-15) means drift could ship unaddressed, but this is mitigated by the fact that review catches most code-level issues before refactor runs.

Hook infrastructure is clean with no conflicts. The WebSearch redirect hook is a good example of hook-to-skill bridging. No new hooks are needed; the identified automation opportunities are better solved through live-state data flow and skill-level routing.

<!-- AGENT_COMPLETE -->
