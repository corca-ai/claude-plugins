# CWF v3 Marketplace — Clarification & Handoff

## Original Requirement

Consolidate 9 individual plugins into a single `cwf` (corca-workflow) plugin
with `cwf:*` trigger naming, multi-agent review integration, and selective
infra hook activation. Full plan first, then one session per task.

## Key Discovery

Claude Code's `{plugin}:{skill}` naming means a single plugin named `cwf`
with skills named `gather`, `clarify`, etc. automatically produces
`cwf:gather`, `cwf:clarify` triggers. No platform changes needed.

Reference: compound-engineering (16 skills, v2.30.0) and superpowers
(13 skills, v4.2.0) both use single-plugin architecture.

## Architecture Decisions

| # | Decision | Detail |
|---|----------|--------|
| 1 | Single `cwf` plugin | All skills + hooks in `plugins/cwf/`. Required for `cwf:*` naming. |
| 2 | Breaking change | Old plugins deleted from marketplace-v3 (S32). marketplace.json v3.0.0 with CWF only. |
| 3 | Umbrella branch | `marketplace-v3` branch + feature branches per task → main merge. **Dev as repo-level skills** (`.claude/skills/`) for dogfooding; convert to plugin structure at merge. |
| 4 | Hook selective activation | Dual-file: `cwf-config.json` (skills read) + `cwf-hooks-enabled.sh` (hooks source). `cwf:setup` generates both. |
| 5 | Infra = hooks + setup subcommands | No standalone infra skills. `cwf:setup` manages hook config. |
| 6 | setup + update separated | `cwf:setup` = initial config + hook selection. `cwf:update` = version update + changelog. |
| 7 | `cwf:review` as universal review | Mode-based: `--mode clarify/plan/code`. Replaces clarify cross-check. |
| 8 | wf reference only | Adopt multi-agent review patterns. cwf v3 eventually replaces wf. |
| 9 | Agent team enhancements | gather: adaptive. plan/impl: team + review. retro/refactor: parallel sub-agents. |
| 10 | CLI fallback = sub-agent | CLI not found → Task agent with perspective prompt (not main agent inline). |
| 11 | Pre-merge holistic refactor | Run holistic refactor on entire cwf plugin before merging to main. |
| 12 | Persistent workflow state | `cwf-state.yaml` tracks stage, sessions, tool availability, hook config. |
| 13 | `cwf:handoff` skill | Auto-generate handoff documents from state + session artifacts. |
| 14 | shell-guard → `cwf:lint-shell` | Built as part of cwf (not standalone) to avoid create-then-migrate waste. |
| 15 | Per-session discipline | Each session: review own output, test, update docs. Not deferred to final session. |
| 16 | Scenario-driven verification | Plan's success criteria flow into review as verification input. Two layers: behavioral (BDD) + qualitative (narrative). See dedicated section below. |
| 17 | Narrative review verdicts | `cwf:review` outputs structured prose (Pass/Conditional/Revise), not numerical scores. Trust intelligent agents over false precision. |
| 18 | Progressive disclosure index | `cwf:setup` generates `index.md` — "when to read what" pointers, not summaries. `cwf:retro` checks for structural updates. |
| 19 | Shift Work auto-transitions | `cwf-state.yaml` encodes `auto: true/false` per stage. Post-impl stages chain automatically; pre-impl stages require human input. |
| 20 | Deliberate naivete | Design principle: never reduce review depth or agent count for cost reasons. Challenge "too expensive" assumptions. (From SW Factory analysis, S4.6.) |

## Skill & Hook Inventory (Target)

### Workflow Stage Skills (11 skills)

| Trigger | Source | Type | Notes |
|---------|--------|------|-------|
| `cwf:setup` | **New** | Skill | Initial config: hook selection, external tool detection (codex/gemini). Infra hook management as subcommands. Generates `cwf-hooks-enabled.sh`. Generates `index.md` (progressive disclosure codebase index). |
| `cwf:update` | **New** | Skill | Version update, changelog, new feature notification |
| `cwf:gather` | gather-context | Skill + Hook | Enhanced: adaptive agent team (broad→parallel, specific→single). Reads `index.md` first for progressive disclosure. |
| `cwf:clarify` | clarify | Skill | Output validation via `cwf:review --mode clarify` |
| `cwf:plan` | plan-and-lessons (hook) | **Skill + Hook** | New skill: agent team for plan drafting. Success criteria in behavioral (BDD) + qualitative format. Calls `cwf:review --mode plan`. |
| `cwf:impl` | **New** | Skill | Clarify domain experts → plan decomposition → agent team impl. Calls `cwf:review --mode code`. |
| `cwf:review` | **New** | Skill | Universal review: `--mode clarify/plan/code`. 4-reviewer pattern. Graceful degradation. Narrative verdict (Pass/Conditional/Revise). Future: `--scenarios <path>` for holdout validation. |
| `cwf:retro` | retro | Skill | Enhanced: parallel sub-agents per analysis section |
| `cwf:refactor` | refactor | Skill | Enhanced: parallel sub-agents per review perspective |
| `cwf:handoff` | **New** | Skill | Auto-generate session handoff from `cwf-state.yaml` + artifacts |
| `cwf:ship` | `/ship` repo skill | Skill | GitHub workflow automation: issue creation, PR with lessons/CDM/checklist, merge management |

### Infrastructure (hooks only, managed by `cwf:setup`)

| Hook | Source | Event | Notes |
|------|--------|-------|-------|
| attention | attention-hook | Multiple PreToolUse/PostToolUse | Slack notification on idle |
| log | prompt-logger | Stop, SessionEnd | Auto-log turns + auto-commit |
| read | smart-read | PreToolUse:Read | File-size aware reading |
| lint-markdown | markdown-guard | PostToolUse:Write/Edit | Markdown validation |
| lint-shell | **New** (from shell-guard) | PostToolUse:Write/Edit | ShellCheck integration for `.sh` files |
| websearch-redirect | gather-context | PreToolUse:WebSearch | Block built-in → cwf:gather |
| compact-recovery | **New** | SessionStart:compact | Inject live state after auto-compact |

### Cross-Cutting

| Component | Notes |
|-----------|-------|
| `~/.claude/cwf-config.json` | Config for skills to read (hook states, tool status, preferences) |
| `~/.claude/cwf-hooks-enabled.sh` | Shell-sourceable hook flags for zero-cost runtime checks |
| `cwf-state.yaml` | **Persistent workflow state**: current stage, session history, tool availability, auto-transitions |
| `index.md` | **Progressive disclosure codebase index**: "when to read what" pointers. Generated by `cwf:setup`, maintained by `cwf:retro`. |
| `plugins/cwf/hooks/hooks.json` | Unified hook definitions |
| `plugins/cwf/.claude-plugin/plugin.json` | Single plugin metadata |
| `plugins/cwf/references/agent-patterns.md` | Shared agent team reference for all skills |

## Persistent Workflow State

```yaml
# cwf-state.yaml (project root or ~/.claude/)
workflow:
  current_stage: plan            # gather → clarify → plan → impl → review → retro
  started_at: "2026-02-08T..."
  stages:                        # Shift Work: interactive vs autonomous (Decision #19)
    gather:    { next: clarify, auto: false }
    clarify:   { next: plan,    auto: false }
    plan:      { next: impl,    auto: false }   # human approves plan
    impl:      { next: review,  auto: true }    # spec is fixed — autonomous from here
    review:    { next: retro,   auto: true }
    retro:     { next: commit,  auto: true }

sessions:
  - id: "260208-03"
    title: "cwf-v3-master-plan"
    stage: clarify
    artifacts:
      - prompt-logs/260208-03-cwf-v3-master-plan/clarify-result.md
      - prompt-logs/260208-03-cwf-v3-master-plan/lessons.md
    completed_at: "2026-02-08T..."
    review_notes: "Plan reviewed by 2 sub-agents (feasibility, philosophy)"

tools:
  codex: available               # cwf:setup preflight result
  gemini: available
  codex_model: gpt-5.3-codex

hooks:
  attention: true
  log: true
  read: true
  lint_markdown: true
  lint_shell: true
  websearch_redirect: true
  compact_recovery: true

live:
  session_id: ""             # Current active session
  dir: ""                    # prompt-logs directory
  branch: ""                 # Git branch
  phase: ""                  # clarify | plan | impl | review | retro | freeform
  task: ""                   # One-line summary
  key_files: []              # Files to read after compact
  dont_touch: []             # Modification boundaries
```

Skills read/write this file. `cwf:handoff` generates handoff documents from it.

## Agent Team Strategy Per Stage

| Stage | Agent Pattern | Notes |
|-------|--------------|-------|
| `cwf:setup` | Single | Interactive config |
| `cwf:update` | Single | Version check |
| `cwf:gather` | **Adaptive** | Broad → parallel team (codebase + web + docs). Specific → single |
| `cwf:clarify` | 4 sub-agents | 2 research + 2 advisory. Output → `cwf:review --mode clarify` |
| `cwf:plan` | **Agent team** | Team drafting + `cwf:review --mode plan` |
| `cwf:impl` | **Agent team** | Clarify domain experts → decompose plan → team impl + `cwf:review --mode code` |
| `cwf:review` | **4 parallel** | codex + gemini + security + ux. CLI fallback → Task agent. |
| `cwf:retro` | **Parallel sub-agents** | Per analysis section (collaboration, waste, CDM, expert lens) |
| `cwf:refactor` | **Parallel sub-agents** | Per review perspective (code quality, docs, structure) |
| `cwf:handoff` | Single | State file reader + doc generator |
| `cwf:ship` | Single | GitHub workflow automation (issue → PR → merge) |

### Shared Agent Patterns Reference

`plugins/cwf/references/agent-patterns.md` — all skills reference this file:

- **Decision criteria**: When single vs adaptive team vs full parallel
- **Adaptive sizing**: Task complexity detection → team composition
- **Parallel execution**: Bash background (external CLI) vs Task tool (internal)
- **Graceful degradation**: CLI unavailable → Task agent fallback (never main agent inline)
- **Provenance tracking**: Source (REAL_EXECUTION | FALLBACK), timestamps, commands

## Multi-Agent Review Pattern (from wf)

```text
4 parallel reviewers:
├── External (Bash background, timeout 300s)
│   ├── Codex: gpt-5.3-codex, reasoning=xhigh (code) / high (spec)
│   └── Gemini: npx @google/gemini-cli
└── Internal (Task tool)
    ├── Security: vulnerabilities, auth, data
    └── UX/DX: API design, error messages

Modes:
- --mode clarify: requirement validation (intent alignment, completeness, ambiguity)
- --mode plan: spec/plan review (feasibility, edge cases, best practices)
- --mode code: implementation review (correctness, simplicity, security, performance)

Graceful degradation:
- CLI not found → Task agent with same perspective prompt (NOT main agent inline)
- Timeout → mark FAILED, spawn Task agent fallback
- All 4 reviews always run in parallel regardless of execution method
- Provenance tracking on all review outputs (Source: REAL_EXECUTION | FALLBACK)
```

## Scenario-Driven Verification

Inspired by StrongDM's SW Factory analysis (S4.6 discussion).

### Concept

Plan's success criteria become review's verification input. This creates
a natural pipeline: `cwf:plan` → `cwf:impl` → `cwf:review`, where the
plan's criteria are the contract between stages.

### Two-Layer Success Criteria

`cwf:plan` writes success criteria in two categories:

**Behavioral (BDD-style, mechanically verifiable)**:

```text
Given: user calls API with expired token
When: /api/protected endpoint is accessed
Then: 401 returned with refresh token guidance message
```

- `cwf:review` uses these as a checklist
- Agent can verify pass/fail for each scenario
- Naturally maps to test cases

**Qualitative (reviewer judgment required)**:

```text
- Error messages should include cause and resolution steps
- Backward compatibility with existing API maintained
- Code duplication reduced meaningfully
```

- `cwf:review` addresses these in narrative verdict
- No false precision — trust the reviewing agent's judgment

### Review Synthesis Format

`cwf:review` outputs structured narrative, not numerical scores (Decision #17):

```text
## Review Synthesis

### Verdict: [Pass | Conditional Pass | Revise]
[1-2 sentence summary]

### Concerns (must address)
- [Reviewer: specific concern]

### Suggestions (optional)
- [Reviewer: improvement suggestion]

### Confidence Note
[Disagreements between reviewers, if any]
```

### Future: Holdout Scenario Layer (S10+)

- Separate scenarios that `cwf:impl` agent cannot access
- Managed by humans or a separate agent
- Structural defense against reward hacking
- Interface reserved: `cwf:review --scenarios <path>`
- Two-layer structure: visible criteria (plan) + hidden validation (holdout)

### Affected Skills

| Skill | Change |
|-------|--------|
| `cwf:plan` | Success criteria format: behavioral (BDD) + qualitative |
| `cwf:review` | Receives plan's behavioral criteria as verification input; narrative verdict output |
| `cwf:impl` | References behavioral criteria; no access to holdout scenarios (future) |
| `cwf:retro` | Checks if `index.md` needs structural updates |
| `cwf:setup` | Generates initial `index.md` for progressive disclosure |

## Progressive Disclosure Index

`cwf:setup` generates `index.md` in the project root — a codebase navigation
guide that tells agents "when to read what" rather than summarizing content.

### Structure

```markdown
# Codebase Index

## Auth (src/auth/)
- **When to read**: Authentication/authorization changes
- **Entry point**: src/auth/middleware.ts
- **Key decisions**: JWT + refresh token (see ADR-003)
- **Dependencies**: src/db/users.ts, src/config/auth.yaml

## API (src/api/)
- **When to read**: Adding/modifying endpoints
- **Entry point**: src/api/routes/index.ts
...
```

### Properties

- **No information loss** — pointers, not summaries
- **Agent-friendly** — explicit "when to read" guides agent decisions
- **Low maintenance** — valid as long as structure doesn't change
- **Lifecycle**: generated by `cwf:setup`, checked by `cwf:retro`

### Integration with `cwf:gather`

```text
1. Read index.md (always)
2. Match user request to relevant areas
3. Read entry points of matched areas only
4. Expand along dependencies as needed
```

## Directory Structure (Target)

```text
plugins/cwf/
├── .claude-plugin/
│   └── plugin.json
├── references/
│   └── agent-patterns.md          # Shared agent team patterns for all skills
├── hooks/
│   ├── hooks.json                 # All hook definitions (7 hook groups)
│   └── scripts/
│       ├── cwf-hook-gate.sh       # Shared: source cwf-hooks-enabled.sh, exit if disabled
│       ├── redirect-websearch.sh
│       ├── smart-read.sh
│       ├── compact-context.sh       # NEW: context recovery after auto-compact
│       ├── log-turn.sh
│       ├── check-markdown.sh
│       ├── check-shell.sh         # NEW: shellcheck integration
│       ├── track-user-input.sh
│       ├── attention.sh
│       ├── start-timer.sh
│       ├── cancel-timer.sh
│       └── heartbeat.sh
├── skills/
│   ├── setup/
│   │   └── SKILL.md
│   ├── update/
│   │   └── SKILL.md
│   ├── gather/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   └── scripts/
│   ├── clarify/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── plan/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── impl/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── review/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── prompts.md
│   │   │   └── external-review.md
│   │   └── scripts/
│   ├── retro/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── refactor/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   └── scripts/
│   ├── handoff/
│   │   └── SKILL.md
│   └── ship/
│       └── SKILL.md
└── README.md
```

## Refactor Review (Pre-requisite on main)

Before starting v3 work, fix these on main branch:

### Critical (4)

- JSON escaping bugs in refactor/quick-scan.sh, plugin-deploy/check-consistency.sh
- Shell safety: unsafe `eval "$(grep ...)"` in gather-context scripts
- Stale lock cleanup in attention-hook/track-user-input.sh

### Important (12)

- `set -euo pipefail` missing in 11 hook scripts
- `#!/bin/bash` → `#!/usr/bin/env bash` in 11 scripts
- Bare code fences (~25 files)
- Marketplace description sync
- Env var naming migration (CLAUDE_ATTENTION_* → CLAUDE_CORCA_ATTENTION_*)

Note: shell-guard is NOT created as standalone. ShellCheck integration goes
directly into cwf as `check-shell.sh` hook (Decision #14).

Source: `prompt-logs/260208-01-refactor-review/`

## Session Roadmap

| Session | Branch | Task | Review/Test/Docs |
|---------|--------|------|------------------|
| **S0** (done) | main | Clarify + master plan | Plan reviewed by 2 sub-agents |
| **S1** (done) | main | Refactor: critical fixes + `set -euo pipefail` + shebang | Test each fixed script. Update project-context.md. |
| **S2** (done) | main | Refactor: bare code fences + env var migration + description sync + CLAUDE.md/project-context.md refactoring | `/refactor --docs` for validation. Update READMEs if affected. |
| **S3** (done) | marketplace-v3 | **Build `/ship` skill** — gh CLI workflow automation: issue creation (purpose/success criteria), PR creation (lessons/CDM/review checklist), auto-merge on approval. Repo-level skill (`.claude/skills/ship/`). | Test: create issue → branch → PR → merge cycle. |
| **S4** (done) | marketplace-v3 | Scaffold `plugins/cwf/`, plugin.json, hooks.json, `cwf-hook-gate.sh`, `cwf-state.yaml` | Verify plugin loads in clean session. |
| **S4.5** (done) | marketplace-v3 | Improve `/ship` skill — Korean templates, decision extraction, autonomous merge | Test: full ship cycle with new templates. |
| **S4.6** (done) | marketplace-v3 | SW Factory analysis — scenario-driven verification, narrative verdicts, progressive disclosure index | Analysis documented in master-plan.md decisions #16–#20. |
| **S5a** (done) | feat/cwf-review | Build `cwf:review` — internal reviewers (security + ux via Task) | Test with sample plan/code input. |
| **S5b** (done) | feat/cwf-review | `cwf:review` — external CLI integration (codex + gemini) + fallback | Test with/without CLIs installed. **Gemini**: test error handling first (not logged in) → login → test normal flow. |
| **S6a** (done) | marketplace-v3 | Migrate simple infra hooks (read, log, lint-markdown) into cwf stubs | 8/8 tests pass, byte-identical diff verified. |
| **S6b** (done) | feat/cwf-infra | Migrate attention-hook (8 scripts, complex state) + add check-shell.sh + enter-plan-mode + check-shell | Test all attention-hook event paths. |
| **S7** (done) | feat/cwf-gather | Migrate gather-context → `cwf:gather` with adaptive team | Test single + team modes. |
| **S8** (done) | feat/cwf-clarify | Migrate clarify → `cwf:clarify` + `cwf:review --mode clarify` integration | End-to-end clarify → review flow. |
| **S9** (done) | feat/cwf-plan | Migrate plan-and-lessons hook + new plan skill with agent team | Test plan drafting + review. |
| **S10** (done) | feat/cwf-impl | Build `cwf:impl` (domain experts → decompose → team) | Test with a real small task. |
| **S11a** (done) | feat/cwf-retro | Migrate retro with parallel sub-agent enhancement | Compare output quality vs v2. |
| **S11b** (done) | feat/cwf-refactor | Migrate refactor with parallel sub-agent enhancement | Compare output quality vs v2. |
| **S12** (done) | feat/cwf-setup | Build `cwf:setup` + `cwf:update` + `cwf:handoff`. Rewrite `install.sh` + `update-all.sh`. Migration script. | Full setup flow on clean machine (or simulated). |
| **S13** (done) | marketplace-v3 | Holistic refactor review on entire cwf plugin | Use `cwf:refactor --holistic` on itself. |
| **S13.5** (done) | s13.5-*-* | Self-healing criteria (A), expert-in-the-loop + phase handoff (B), concept distillation + README v3 (B2), concept-refactor integration (B3), plan mode removal + live state + compact recovery (C1), docs restructure + hook infra + orphan recovery (C2DE). All 7 workstreams complete. | Provenance check triggers on stale criteria. |
| **S32** (done) | marketplace-v3 | **Docs overhaul W1-W9**: CLAUDE.md rewrite (66→44), cheatsheet merge (5 docs→1), project-context + architecture-patterns trim, standalone plugin deletion (9 dirs), marketplace v3.0.0, clarify Path B removal, refactor --docs enhancement, cwf-state auto-init, README sync (EN+KO) | markdownlint 0 errors. 93 files, -7479/+446 lines. |
| **S32-impl** (done) | marketplace-v3 | **L1-L3+L9 impl**: Branch gate (impl Phase 0.5), clarify completion gate (Phase 1.0), sub-agent file persistence with context recovery protocol (5 skills: clarify/plan/review/retro/refactor), log-turn.sh fix, review error observability (stderr capture). Extracted shared `context-recovery-protocol.md`. | Full pipeline: clarify→plan→review(plan)→impl(4 agents)→review(code, 6 reviewers)→fix 3 concerns→commit. Deep retro with Brooks + Ousterhout. |
| **S33** | marketplace-v3 | **CDM improvements + S13.6 auto-chaining**: (1) Plan template cross-cutting pattern check, (2) impl commit strategy branching for cross-cutting changes, (3) phase-aware compact recovery (impl auto-loads plan.md), (4) review Phase 3.2 fail-fast for CAPACITY errors, (5) S13.6 auto-chaining protocol design (gather→clarify→plan→review→impl→retro→ship). | CDM items verified by retro re-check. Auto-chaining tested with a real task. |
| **S14** | marketplace-v3 | Integration test, deprecate old plugins, merge to main. **Produce `docs/v3-migration-decisions.md`** — synthesize all key decisions and lessons from S0-S14 into a single document. PR body gets the summary, doc gets the details. README v3 philosophy moved to S13.5-B2. | Full workflow end-to-end test. |

### Session Dependencies

```text
S1 → S2 → S3 (ship skill — enables workflow for all v3 sessions)
              ↓
         S4 (scaffold)
              ↓
         S5a → S5b (review must exist first)
              ↓
         S6a → S6b (infra hooks)
              ↓
         S7 → S8 → S9 → S10 (workflow stages, review available)
              ↓
         S11a, S11b (can be parallel)
              ↓
         S12 (setup/update/handoff, needs all skills)
              ↓
         S13 → S13.5-A → S13.5-B → S13.5-B2 → S13.5-C/D/E → S32 (docs overhaul) → S32-impl (L1-L3+L9) → S33 (CDM + S13.6) → S14
```

### S13.5 Workstream Details

| Workstream | Branch | Scope | Status |
|------------|--------|-------|--------|
| **A** | s13.5-a-provenance | Self-healing provenance system | ✅ Done |
| **B** | s13.5-b-expert-loop | Expert-in-the-loop (clarify, review, retro roster) + phase handoff (`--phase` mode) | ✅ Done |
| **B2** | marketplace-v3 (no feature branch — #15) | Concept distillation (6 generic + 9 application concepts) + README v3 rewrite. Identified 3 refactor integration points (unimplemented). #16 | ✅ Done |
| **B3** | feat/concept-refactor-integration (→ marketplace-v3, PR #18) | Concept-based refactor integration: Form/Meaning/Function triadic framework, concept-map.md, exit-plan-mode.sh hook | ✅ Done |
| **C1** | marketplace-v3 | Plan mode removal + live state + compact recovery hook (S29). Also: session log turn injection into compact recovery. | ✅ Done |
| **C2** | s13.5-c2de-docs-infra | project-context.md slimming (audit, dedup, graduation) | ✅ Done |
| **D** | s13.5-c2de-docs-infra | Hook infrastructure (Slack reply_broadcast env) | ✅ Done |
| **E** | s13.5-c2de-docs-infra | prompt-logger: orphaned session log recovery + AskUserQuestion logging | ✅ Done |

## Handoff Template (for S1+)

Each session's handoff should follow this structure:

```markdown
## Handoff: Next Session (S{N})

### Context
- Read: {files to read for context}
- cwf-state.yaml: {current state summary}

### Task
{One-line description}

### Scope
1. {Specific item with file paths}
2. ...

### Don't Touch
- {Files that will be rewritten in later sessions}

### Success Criteria
- {How to verify the work is done}

### Dependencies
- Requires: S{N-1} completed
- Blocks: S{N+1}

### After Completion
1. Create next session dir: `prompt-logs/{YYMMDD}-{NN}-{title}/`
2. Write plan.md, lessons.md in that dir
3. Write next-session.md (S{N+1} handoff) in that dir
4. Update `cwf-state.yaml`: add session entry, update `workflow.current_stage` if needed
5. If architecture decisions changed, edit THIS master-plan.md and record in lessons.md

### Start Command
@{previous session dir}/next-session.md 시작합니다
```

## Handoff Convention

- **master-plan.md**: Single source of truth in this directory. Edited in place, tracked by git.
- **next-session.md**: Created in each session's own directory. Next session @mentions only this file.
- **Chain**: S0/next-session.md → S1/next-session.md → S2/next-session.md → ...
- **cwf-state.yaml**: Machine-readable SSOT for session history. Updated at each session completion.
- **Current**: See `next-session.md` in this directory (points to S1).
