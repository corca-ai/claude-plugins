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
| 2 | Breaking change | Old plugins fully deprecated at merge. Migration script in final session. |
| 3 | Umbrella branch | `marketplace-v3` branch + feature branches per task → main merge |
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

## Skill & Hook Inventory (Target)

### Workflow Stage Skills (10 skills)

| Trigger | Source | Type | Notes |
|---------|--------|------|-------|
| `cwf:setup` | **New** | Skill | Initial config: hook selection, external tool detection (codex/gemini). Infra hook management as subcommands. Generates `cwf-hooks-enabled.sh`. |
| `cwf:update` | **New** | Skill | Version update, changelog, new feature notification |
| `cwf:gather` | gather-context | Skill + Hook | Enhanced: adaptive agent team (broad→parallel, specific→single) |
| `cwf:clarify` | clarify | Skill | Output validation via `cwf:review --mode clarify` |
| `cwf:plan` | plan-and-lessons (hook) | **Skill + Hook** | New skill: agent team for plan drafting. Calls `cwf:review --mode plan`. |
| `cwf:impl` | **New** | Skill | Clarify domain experts → plan decomposition → agent team impl. Calls `cwf:review --mode code`. |
| `cwf:review` | **New** | Skill | Universal review: `--mode clarify/plan/code`. 4-reviewer pattern. Graceful degradation. |
| `cwf:retro` | retro | Skill | Enhanced: parallel sub-agents per analysis section |
| `cwf:refactor` | refactor | Skill | Enhanced: parallel sub-agents per review perspective |
| `cwf:handoff` | **New** | Skill | Auto-generate session handoff from `cwf-state.yaml` + artifacts |

### Infrastructure (hooks only, managed by `cwf:setup`)

| Hook | Source | Event | Notes |
|------|--------|-------|-------|
| attention | attention-hook | Multiple PreToolUse/PostToolUse | Slack notification on idle |
| log | prompt-logger | Stop, SessionEnd | Auto-log turns + auto-commit |
| read | smart-read | PreToolUse:Read | File-size aware reading |
| lint-markdown | markdown-guard | PostToolUse:Write/Edit | Markdown validation |
| lint-shell | **New** (from shell-guard) | PostToolUse:Write/Edit | ShellCheck integration for `.sh` files |
| websearch-redirect | gather-context | PreToolUse:WebSearch | Block built-in → cwf:gather |
| plan-protocol | plan-and-lessons | PreToolUse:EnterPlanMode | Inject Plan & Lessons Protocol |

### Cross-Cutting

| Component | Notes |
|-----------|-------|
| `~/.claude/cwf-config.json` | Config for skills to read (hook states, tool status, preferences) |
| `~/.claude/cwf-hooks-enabled.sh` | Shell-sourceable hook flags for zero-cost runtime checks |
| `cwf-state.yaml` | **Persistent workflow state**: current stage, session history, tool availability |
| `plugins/cwf/hooks/hooks.json` | Unified hook definitions |
| `plugins/cwf/.claude-plugin/plugin.json` | Single plugin metadata |
| `plugins/cwf/references/agent-patterns.md` | Shared agent team reference for all skills |

## Persistent Workflow State

```yaml
# cwf-state.yaml (project root or ~/.claude/)
workflow:
  current_stage: plan            # gather → clarify → plan → impl → review → retro
  started_at: "2026-02-08T..."

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
  plan_protocol: true
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
│       ├── enter-plan-mode.sh
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
│   └── handoff/
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
| **S0** (this) | main | Clarify + master plan | Plan reviewed by 2 sub-agents |
| **S1** | main | Refactor: critical fixes + `set -euo pipefail` + shebang | Test each fixed script. Update project-context.md. |
| **S2** | main | Refactor: bare code fences + env var migration + description sync + CLAUDE.md/project-context.md refactoring | Lint check. Update READMEs if affected. |
| **S3** | marketplace-v3 | Scaffold `plugins/cwf/`, plugin.json, hooks.json, `cwf-hook-gate.sh`, `cwf-state.yaml` | Verify plugin loads in clean session. |
| **S4a** | feat/cwf-review | Build `cwf:review` — internal reviewers (security + ux via Task) | Test with sample plan/code input. |
| **S4b** | feat/cwf-review | `cwf:review` — external CLI integration (codex + gemini) + fallback | Test with/without CLIs installed. |
| **S5a** | feat/cwf-infra | Migrate simple infra hooks (read, log, lint-markdown) + `cwf-hook-gate.sh` wiring | Test hook enable/disable via config. |
| **S5b** | feat/cwf-infra | Migrate attention-hook (8 scripts, complex state) + add check-shell.sh | Test all attention-hook event paths. |
| **S6** | feat/cwf-gather | Migrate gather-context → `cwf:gather` with adaptive team | Test single + team modes. |
| **S7** | feat/cwf-clarify | Migrate clarify → `cwf:clarify` + `cwf:review --mode clarify` integration | End-to-end clarify → review flow. |
| **S8** | feat/cwf-plan | Migrate plan-and-lessons hook + new plan skill with agent team | Test plan drafting + review. |
| **S9** | feat/cwf-impl | Build `cwf:impl` (domain experts → decompose → team) | Test with a real small task. |
| **S10a** | feat/cwf-retro | Migrate retro with parallel sub-agent enhancement | Compare output quality vs v2. |
| **S10b** | feat/cwf-refactor | Migrate refactor with parallel sub-agent enhancement | Compare output quality vs v2. |
| **S11** | feat/cwf-setup | Build `cwf:setup` + `cwf:update` + `cwf:handoff`. Rewrite `install.sh` + `update-all.sh`. Migration script. | Full setup flow on clean machine (or simulated). |
| **S12** | marketplace-v3 | Holistic refactor review on entire cwf plugin | Use `cwf:refactor --holistic` on itself. |
| **S13** | marketplace-v3 | Integration test, deprecate old plugins, final docs, merge to main | Full workflow end-to-end test. |

### Session Dependencies

```text
S1 → S2 → S3 (scaffold)
              ↓
         S4a → S4b (review must exist first)
              ↓
         S5a → S5b (infra hooks)
              ↓
         S6 → S7 → S8 → S9 (workflow stages, review available)
              ↓
         S10a, S10b (can be parallel)
              ↓
         S11 (setup/update/handoff, needs all skills)
              ↓
         S12 → S13
```

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
4. If architecture decisions changed, edit THIS master-plan.md and record in lessons.md

### Start Command
@{previous session dir}/next-session.md 시작합니다
```

## Handoff Convention

- **master-plan.md**: Single source of truth in this directory. Edited in place, tracked by git.
- **next-session.md**: Created in each session's own directory. Next session @mentions only this file.
- **Chain**: S0/next-session.md → S1/next-session.md → S2/next-session.md → ...
- **Current**: See `next-session.md` in this directory (points to S1).
