---
name: retro
description: "Comprehensive session retrospective that turns one session's outcomes into persistent improvements. Adaptive depth: deep by default, with light mode via --light (and tiny-session auto-light). Triggers: \"cwf:retro\", \"retro\", \"retrospective\", \"회고\""
---

# Session Retrospective

Adaptive end-of-session review that converts outcomes into durable process/context/tool improvements. Deep by default; light mode is used with `--light` or for tiny routine sessions. Produces `retro.md` alongside `plan.md` and `lessons.md` in the session artifact directory.

**Language**: Write retro.md in the user's language. Communicate with the user in their prompt language.

## Quick Start

```text
/retro [path]            # adaptive (deep by default)
/retro --deep [path]     # full analysis with expert lens
/retro --from-run [path] # internal flag when invoked by cwf:run
```

- `path`: optional override for output directory
- `--deep`: force full 7-section analysis (expert lens, learning resources, web search)
- `--from-run`: internal invocation context flag; enables compact report for run-chain orchestration

## Workflow

### 0. Update Live State

Run:

```bash
bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . phase="retro"
```

### 1. Locate Output Directory

Resolution order:
1. If `[path]` argument provided, use it
2. Reuse `.cwf/projects/` path already used in this session (plan.md/lessons.md writes)
3. If reused session path date prefix (`YYMMDD`) differs from today's local date, AskUserQuestion:
   - Continue existing session directory (recommended for same logical session across midnight/day rollover)
   - Start a new dated directory for today
4. If user selects a new dated directory, run `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh --bootstrap <title>`, then copy `plan.md` and `lessons.md` from the previous session directory when present so retro context is preserved.
5. If multiple candidates exist, AskUserQuestion with candidates
6. Otherwise run `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh --bootstrap <title>`

### 2. Read Existing Artifacts

Before reading artifacts, run the evidence collector:

```bash
bash {CWF_PLUGIN_DIR}/scripts/retro-collect-evidence.sh --session-dir "{output-dir}"
```

Then read `retro-evidence.md` (if generated), `plan.md`, `lessons.md` (if they exist in target dir), AGENTS.md from project root (plus CLAUDE.md when runtime-specific behavior matters), project context document (e.g. docs/project-context.md), and `cwf-state.yaml` (if it exists) — to understand session goals, project stage, and avoid duplicating content.

### 3. Select Mode

Parse the `--deep` flag from the invocation arguments.

**If `--deep` is present**: mode = deep (full 7 sections).

**If `--deep` is absent**: assess session weight to decide mode:
- **Light** (Sections 1-4 + 7): Only when `--light` is explicitly specified, OR session < 3 turns with routine/simple tasks (config changes, small fixes, doc edits)
- **Default bias**: Deep. Invoking retro is itself a signal that the session warrants analysis. Use `--light` to explicitly request lightweight mode when cost savings is desired.

### 3.1 Detect Invocation Context

Determine invocation context from arguments and live task:

- **Run-chain invocation**: `--from-run` present, or live task explicitly indicates `cwf:run`.
- **Direct user invocation**: all other cases.

Persist this as:

```yaml
invocation_mode: run_chain | direct
```

### 4. Draft Retro

Draft everything internally before writing to file.

#### Light Mode Path

Analyze the full conversation to produce sections 1-4 and 7 inline. No sub-agents.

#### Deep Mode Path

Draft sections 1-3 inline (these require full conversation access), then launch parallel sub-agents in two batches.

**Resolve session directory**: Resolve the effective live-state file, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files before launching each batch:

| Batch | Agent | Output file |
|-------|-------|-------------|
| 1 | CDM Analysis | `{session_dir}/retro-cdm-analysis.md` |
| 1 | Learning Resources | `{session_dir}/retro-learning-resources.md` |
| 2 | Expert α | `{session_dir}/retro-expert-alpha.md` |
| 2 | Expert β | `{session_dir}/retro-expert-beta.md` |

Stage-tier policy for deep mode outputs:
- **Critical (hard gate)**: `{session_dir}/retro-cdm-analysis.md`
- **Non-critical (soft gate)**: `{session_dir}/retro-learning-resources.md`,
  `{session_dir}/retro-expert-alpha.md`, `{session_dir}/retro-expert-beta.md`

For all outputs: bounded retry = 1 for missing/invalid files.

**Batch 1** — launch in a single message with 2 parallel Task calls (only for agents whose result files are missing or invalid):

- **Agent A — CDM Analysis**: `subagent_type: general-purpose`, `max_turns: 16`. Prompt: "Read `{SKILL_DIR}/references/cdm-guide.md`. Analyze the following session summary using CDM methodology. Session summary: {Sections 1-3 summary}. cwf-state context: {relevant cwf-state.yaml content}. Output Section 4 content. **Output Persistence**: Write your complete analysis to: `{session_dir}/retro-cdm-analysis.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`"
- **Agent B — Learning Resources**: `subagent_type: general-purpose`, `max_turns: 20`. Prompt: "Based on the following session summary, search the web for 2-3 learning resources calibrated to the user's knowledge level. Follow the Web Research Protocol in {CWF_PLUGIN_DIR}/references/agent-patterns.md (discover URLs via WebSearch, fetch with WebFetch then agent-browser fallback for JS-rendered pages). You have Bash access for agent-browser CLI commands. Session summary: {Sections 1-3 summary}. For each resource: title + URL, 2-3 sentence summary of key takeaways, and why it matters for the user's work. Output Section 6 content. **Output Persistence**: Write your complete findings to: `{session_dir}/retro-learning-resources.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`"

Wait for Batch 1 to complete. Read output files from session directory:
- `{session_dir}/retro-cdm-analysis.md` — CDM analysis (needed by Batch 2 experts)
- `{session_dir}/retro-learning-resources.md` — Learning resources

Gate behavior after Batch 1:
- If `retro-cdm-analysis.md` remains invalid after retry: **hard fail** deep retro.
- If `retro-learning-resources.md` remains invalid after retry: continue with
  warning and render Section 6 with explicit omission note.
- Record gate path in output (`PERSISTENCE_GATE=HARD_FAIL` or
  `PERSISTENCE_GATE=SOFT_CONTINUE`, or equivalent wording).

**Batch 2** — launch in a single message with 2 parallel Task calls (after Batch 1, only for agents whose result files are missing or invalid):

- **Agent C — Expert alpha**: `subagent_type: general-purpose`, `max_turns: 20`. Prompt: "Read `{SKILL_DIR}/references/expert-lens-guide.md`. You are Expert alpha. Session summary: {Sections 1-4 summary, including CDM results from Agent A}. Deep-clarify experts: {names or 'not available'}. Analyze through your framework. Use web search to verify expert identity and cite published work (follow Web Research Protocol in {CWF_PLUGIN_DIR}/references/agent-patterns.md; you have Bash access for agent-browser fallback). Output your Expert alpha section. **Output Persistence**: Write your complete analysis to: `{session_dir}/retro-expert-alpha.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`"
- **Agent D — Expert beta**: `subagent_type: general-purpose`, `max_turns: 20`. Prompt: "Read `{SKILL_DIR}/references/expert-lens-guide.md`. You are Expert beta. Session summary: {Sections 1-4 summary, including CDM results from Agent A}. Deep-clarify experts: {names or 'not available'}. Analyze through your framework. Use web search to verify expert identity and cite published work (follow Web Research Protocol in {CWF_PLUGIN_DIR}/references/agent-patterns.md; you have Bash access for agent-browser fallback). Output your Expert beta section. **Output Persistence**: Write your complete analysis to: `{session_dir}/retro-expert-beta.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`"

After Batch 2: read output files from session directory (`{session_dir}/retro-expert-alpha.md`, `{session_dir}/retro-expert-beta.md`). Draft Section 7 inline (capability/tool scan), then integrate all results into retro.md.

Gate behavior after Batch 2:
- If either expert file remains invalid after retry: continue with warning and
  render Section 5 from available expert output(s) plus explicit omission note.
- Record soft gate path in output (`PERSISTENCE_GATE=SOFT_CONTINUE` or equivalent).

**Rationale for 2-batch design**: Expert Lens requires CDM results ("Sections 1-4 provided by orchestrator" per expert-lens-guide.md). CDM and Learning Resources are independent → Batch 1 parallel. Expert alpha and Expert beta both need CDM results → Batch 2 after Batch 1.

#### Section 1: Context Worth Remembering

User, org, and project facts useful for future sessions: domain knowledge, tech stack, conventions, team structure, decision-making patterns. Only genuinely useful items.

#### Section 2: Collaboration Preferences

Work style and communication observations; compare against current AGENTS.md (and CLAUDE.md when runtime-specific). If warranted, draft `### Suggested Agent-Guide Updates` as a bullet list (omit if none). **Right-placement check**: if a learning belongs to a doc already referenced by AGENTS/adapter docs, suggest updating that doc instead.

#### Section 3: Waste Reduction

Identify all forms of wasted effort in the session. Broader than prompting habits — covers the full spectrum of inefficiency:

- **Wasted turns**: Misunderstandings, wrong assumptions, rework
- **Over-engineering**: Unnecessary complexity, premature abstractions
- **Missed shortcuts**: Existing tools/patterns/code that could have been used
- **Context waste**: Large file reads, redundant searches, information not reused
- **Communication waste**: Ambiguous instructions that caused wrong-direction work

Format: free-form analysis citing specific session moments. No table required. Frame constructively with actionable suggestions.

**Root cause drill-down (5 Whys)**: For each significant waste item, don't stop at the symptom. Ask "why did this happen?" repeatedly until you reach a structural or systemic cause. The goal is to distinguish:
- **One-off mistake** (no action needed beyond noting it)
- **Knowledge gap** (persist as context or learning resource)
- **Process gap** (suggest tool, checklist, or protocol change)
- **Structural constraint** (persist to project-context or agent-guide docs)

Shallow analysis (stopping at "we should have done X") misses persist-worthy structural insights. Always drill to the level where you can recommend a durable fix.

#### Section 4: Critical Decision Analysis (CDM)

- **Light mode**: Draft inline. Read `{SKILL_DIR}/references/cdm-guide.md` for methodology.
- **Deep mode**: Produced by Agent A (Batch 1). Integrate the agent's output here.

Identify 2-4 critical decision moments from the session. Apply CDM probes to each. This section is unconditional — every retro-worthy session has decisions worth analyzing.

#### Section 5: Expert Lens

**Mode: deep only.** In light mode, output: "Run `/retro --deep` for expert analysis."

Condition: Does the session contain decisions that domain experts would analyze differently? If the session is too lightweight (simple config changes, routine tasks), skip this section with a brief note.

**Expert selection**:
1. Scan the conversation for `/deep-clarify` invocations. If found, extract expert names and use them as preferred starting points.
2. If no deep-clarify experts available, select independently per `{SKILL_DIR}/references/expert-lens-guide.md`.

**Execution** (deep mode): Produced by Agent C (Expert alpha) and Agent D (Expert beta) from Batch 2. Integrate both results into Section 5.

#### Section 6: Learning Resources

**Mode: deep only.** In light mode, output: "Run `/retro --deep` for learning resources."

Condition: Does the session contain topics where the user showed knowledge gaps or genuine curiosity? If the session is too lightweight (simple config changes, routine tasks), skip this section with a brief note.

**Execution** (deep mode): Produced by Agent B from Batch 1. Integrate the agent's output here. Each resource: title + URL, 2-3 sentence summary of key takeaways, and why it matters for the user's work.

#### Section 7: Relevant Tools (Capabilities Included)

**Step 1 — Inventory available capabilities** (always, both modes):

1. Scan installed agent skills first:
   - Marketplace: `~/.claude/plugins/*/skills/*/SKILL.md`
   - Local: `.claude/skills/*/SKILL.md`
   - For each: read frontmatter (name, description, triggers)
2. Inventory deterministic repo tools/checks already available (hooks, linters, validators, scripts).
3. Summarize what was used vs available-but-unused in this session.

**Step 2 — Tool gap analysis** (if workflow gap or repetition identified):

Assess whether the session reveals a repeated or high-impact gap not covered by current capabilities. If no clear gap: state "No additional tool gaps identified."

When a gap exists, classify proposals by category:
- Missing or underused **agent skill**
- Missing **static analysis** check/tool
- Missing **validation/reachability** check
- Missing **indexing/search/dedup** utility
- Missing **workflow automation** (hook/CI/script)

For each proposal, include:
- Problem signal from this session
- Candidate (skill and/or external tool)
- Integration point (hook, script, CI, or manual command)
- Expected gain and risk/cost
- Pilot scope (small, reversible first step)

**Step 3 — Action path by category**:

- If primarily a skill gap:
  - **Finding existing skills**: Use `/find-skills` to search for existing solutions and report findings.
  - Record command/result evidence in Section 7. If unavailable, record explicit evidence (`command -v find-skills`) and fallback rationale.
  - **Creating new skills**: If no existing skill fits, use `/skill-creator` to describe and scaffold the needed skill.
- If primarily a non-skill tool gap:
  - Recommend concrete tool candidates with a minimal pilot integration plan.
- **Prerequisite check**:
  - If `find-skills` (by Vercel) or `skill-creator` (by Anthropic) are not installed, recommend installing them from https://skills.sh/ when relevant.

### 5. Write retro.md

Write to `{output-dir}/retro.md` using the format below.

### 6. Link Session Log

Discover runtime logs under:

1. Preferred: `.cwf/sessions/`
2. Legacy fallback: `.cwf/projects/sessions/`

- Prefer suffix files: `{YYMMDD}-*.claude.md`, `{YYMMDD}-*.codex.md`
- Also allow unsuffixed files: `{YYMMDD}-*.md`

Then:
1. Filter out already-symlinked candidates.
2. Read a sample of each candidate to verify it matches the current session.
3. Ensure `{output-dir}/session-logs/` exists.
4. For each verified log, create a relative symlink:
   ```bash
   ln -s "{relative-log-path}/{filename}" "{output-dir}/session-logs/{filename}"
   ```
5. Compatibility alias: if `{output-dir}/session-log.md` is missing (or already a symlink), point it to one representative file in `session-logs/` (prefer latest).
6. If no candidates or directories do not exist, skip silently.

### 7. Persist Findings

retro.md is session-specific. Persist findings to project-level documents using the **eval > state > doc** hierarchy.

For each finding, evaluate enforcement mechanisms strongest-first:

1. **Tier 1: Eval/Hook** (deterministic) — Can a script/hook catch this?
   - `check-session.sh` / `session_defaults` for missing artifacts
   - PreToolUse/PostToolUse hook for tool usage patterns
   - Lint rule for style enforcement

2. **Tier 2: State** (structural) — Does this change workflow state?
   - `cwf-state.yaml` schema (new artifacts, stage transitions)
   - `session_defaults` (new always/milestone artifacts)

3. **Tier 3: Doc** (behavioral, last resort) — Only for judgment calls
   - `project-context.md` for architectural patterns
   - AGENTS.md or runtime adapter docs only for rules that can't be automated

**Per-section persist actions**:

- **S1 Context** → `project-context.md` (Tier 3 — context is inherently behavioral). Offer to append new context.
- **S2 Collaboration** → Evaluate each suggestion through tiers individually. AskUserQuestion "Apply?" for AGENTS.md/adapter changes.
- **S3 Waste / Root causes** → For each 5 Whys structural cause, present: "**Finding**: X. **Recommended tier**: {1|2|3}. **Mechanism**: {specific change}." Right-placement check: AGENTS.md (or runtime adapters) for behavioral rules, `project-context.md` for architectural patterns, protocol/skill docs for process changes.
- **S4 CDM** → Key lessons through tiers (most → Tier 3 `project-context.md`).
- **S7 Tools** → AskUserQuestion "Implement now?" for actionable capability improvements.

**Expert Roster Maintenance** (deep mode only, when Section 5 was produced):

1. Extract expert names from Section 5 (Expert Lens) output
2. Read `cwf-state.yaml` `expert_roster:`
3. For each expert used in Section 5:
   - If already in roster: increment `usage_count` by 1
   - If new: add entry with `name`, `domain`, `source`, `rationale`, `introduced: {current session}`, `usage_count: 1`
4. Analyze the session's domain for roster gaps — are there frameworks or disciplines
   that would have been valuable but are not represented in the roster?
5. Apply all changes directly to `cwf-state.yaml` `expert_roster:` section:
   - usage_count increments: apply automatically
   - New expert additions: apply automatically
   - Gap recommendations: add automatically if the expert has a clear published framework
6. Report changes to the user in the retro output (Section 5 or post-section note)
   for visibility, but do not gate on approval

This is fully automatic: both usage tracking and roster expansion are applied without requiring user confirmation. The retro output provides visibility into all changes made.

### 8. Direct Invocation Report (Mandatory)

After writing `retro.md`, always report outcomes to the user.

If `invocation_mode=direct` (user-triggered `/retro` or `cwf:retro`):

1. Provide `Retro Brief` with 4-6 bullets:
   - session objective/result
   - top waste/root-cause signal
   - most important CDM lesson
   - critical tool/capability takeaway
2. Provide `Persist Proposals` with 2-5 concrete items:
   - Finding
   - Recommended tier (`Eval-Hook`, `State`, `Doc`)
   - Target file/script
   - Apply-now recommendation
3. Ask whether to apply persist proposals now (yes/no).

If `invocation_mode=run_chain`:

- Provide compact 1-2 bullet completion report (pipeline continuity first).
- Still include a short `Persist Proposals` pointer (at least 1 line) so persistence opportunities are not dropped.

### 9. Post-Retro Discussion

The user may continue the conversation after the retro. During post-retro discussion:
- Update `retro.md` — append under `### Post-Retro Findings`
- Update `lessons.md` with new learnings
- **Persistence check** — for each new learning, evaluate through the eval > state > doc hierarchy: Can it be a hook/eval? A state change? Only then a doc rule.
- If plugin code was changed, follow normal release procedures (version bump, CHANGELOG)

Do not prompt the user to start this discussion.

## Output Format

### Light mode

```markdown
# Retro: {session-title}

> Session date: {YYYY-MM-DD}
> Mode: light

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested Agent-Guide Updates
## 3. Waste Reduction
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
> Run `/retro --deep` for expert analysis.
## 6. Learning Resources
> Run `/retro --deep` for learning resources.
## 7. Relevant Tools (Capabilities Included)
### Installed Capabilities
### Tool Gaps
```

### Deep mode

```markdown
# Retro: {session-title}

> Session date: {YYYY-MM-DD}
> Mode: deep

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested Agent-Guide Updates
## 3. Waste Reduction
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
## 6. Learning Resources
## 7. Relevant Tools (Capabilities Included)
### Installed Capabilities
### Tool Gaps
```

## Rules

1. Never duplicate content already in lessons.md
2. Be specific — cite session moments, not generic advice
3. Keep each section focused — if nothing to say, state that briefly
4. AGENTS.md/runtime adapter changes require explicit user approval
5. If early session context is unavailable due to conversation length, focus on what is visible and note the limitation
6. CDM analysis (Section 4) is unconditional — every session has decisions to analyze
7. Expert Lens (Section 5) is deep-mode only — in light mode, output a one-line pointer to `--deep`
8. Learning Resources (Section 6) is deep-mode only — in light mode, output a one-line pointer to `--deep`
9. Section 7 always inventories installed capabilities first (skills + deterministic repo tools), before suggesting new external tools
10. When writing code fences in retro.md or any markdown output, always include a language specifier (`bash`, `json`, `yaml`, `text`, `markdown`, etc.). Never use bare code fences.
11. In deep mode, analysis sections (CDM, Expert Lens, Learning Resources) run as parallel sub-agents in two batches. Do not run them inline.
12. Persist findings follow the eval > state > doc hierarchy. Never suggest adding a doc rule when a deterministic check is possible.
13. Read cwf-state.yaml (if it exists) during artifact reading to understand project lifecycle context.
14. Apply stage-tier persistence gates in deep mode: CDM output hard-fails when invalid after bounded retry; Expert/Learning outputs use warning + explicit omission notes.
15. Deep mode contract must be mode-accurate: if retro.md is labeled `Mode: deep`, ensure all four deep artifact files exist and each ends with `<!-- AGENT_COMPLETE -->`; otherwise downgrade to light mode with explicit reason.
16. In deep mode, Section 6 must include external web resources (URLs) discovered during this run; internal repository docs can only be supplemental.
17. If Section 7 includes a skill-gap branch, run `/find-skills` first and record command/result (or explicit tool-unavailable evidence).
18. `retro-collect-evidence.sh` is the default evidence path; include its output (`retro-evidence.md`) in the evidence set when available.
19. If retro is directly invoked by the user (not run-chain), the assistant response must include both `Retro Brief` and `Persist Proposals`; do not end with file-write confirmation only.

## References

- `{SKILL_DIR}/references/cdm-guide.md` — CDM probe methodology and output format
- `{SKILL_DIR}/references/expert-lens-guide.md` — Expert identity, grounding, and analysis format
- [agent-patterns.md](../../references/agent-patterns.md) — Shared agent orchestration patterns
