# CWF (Corca Workflow Framework)

> **Disclaimer (SoT)**  
> `README.ko.md` is the single source of truth for CWF user-facing policy. If docs and implementation diverge, fix the plugin to match docs and report the mismatch via issue/PR.

[한국어](README.ko.md)

A Claude Code plugin that turns structured development sessions into a repeatable workflow — from gathering context through retrospective analysis. Maintained by [Corca](https://www.corca.ai/) for [AI-Native Product Teams](AI_NATIVE_PRODUCT_TEAM.md).

## Installation

### Quick start

```bash
# Add the marketplace
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

# Install CWF
claude plugin install cwf@corca-plugins

# Restart Claude Code for hooks to take effect
```

After restart, run one-time bootstrap in Claude Code / Codex CLI:

```text
cwf:setup
```

`cwf:setup` standardizes first-run behavior by handling:

- legacy env migration to canonical `CWF_*` keys
- project config bootstrap (`.cwf-config.yaml`, `.cwf-config.local.yaml`)
- tool detection (Codex/Gemini/Tavily/Exa) and optional Codex integration
- local runtime dependency checks with install prompts (`shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`)
- optional index generation (improves agent routing and progressive-disclosure navigation)

For detailed flags, see [setup](#setup).

### Codex users (recommended)

If you also use Codex CLI, running only `cwf:setup` is enough to get guided defaults. Codex integration now follows the active plugin scope by default (`local > project > user`). Use the commands below when you want to re-apply Codex integration only:

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

### First workflow scenario

In Claude Code / Codex CLI, start with a plain prompt:

```text
I need to solve <problem>. Please use CWF and drive the workflow.
```

The agent can invoke `cwf:run` and chain gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship. If automated review is not enough, switch to `cwf:hitl` to document key decision points and user concerns first, then continue chunk-by-chunk review.

You do not need to memorize every skill. The sections below explain why each skill exists and when to use it.

### Update to latest version

```bash
claude plugin marketplace update corca-plugins
claude plugin update cwf@corca-plugins
```

Or from inside Claude Code / Codex CLI:

```text
cwf:update               # Check + update if newer version exists
cwf:update --check       # Version check only
```

### Standalone plugins (legacy)

As of v3.0.0, legacy standalone plugins have been removed from the marketplace. If pre-v3.0 standalone plugins are installed, uninstall them and install `cwf` instead.

## Operating Principles

### What CWF Is

- A single workflow plugin (`cwf`) that integrates context gathering, requirement clarification, planning, implementation, review, retrospective, handoff, and shipping.
- A stateful workflow system where .cwf/cwf-state.yaml, session-log artifacts, and hooks preserve context across phase/session boundaries.
- A composable skill framework built on shared concepts (Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, Handoff, Provenance Tracking, Adaptive Setup Contract).
- A cross-skill context-deficit resilience contract: after auto-compact/session restart, skills recover from persisted state/artifacts/handoff files instead of implicit chat memory.
- A roadmap toward lower user bottlenecks by chaining smaller approval units (for example, dark-factory-style operating patterns).

### What CWF Is Not

- Not a replacement for project-specific engineering standards, CI gates, or human product ownership decisions.
- Not a guarantee that every decision can be fully automated; subjective decisions still require user confirmation.
- While each skill can be invoked independently, CWF is intentionally designed as a tightly coupled system and works best when skills are used together.

### Assumptions

- Users work in repositories where session artifacts (.cwf/projects/, .cwf/cwf-state.yaml) are allowed and useful.
- Users accept progressive disclosure: start from AGENTS.md, then load deeper docs as needed.
- Users prefer deterministic validation scripts for recurring quality checks over relying on behavioral memory.
- Users expect missing prerequisites to trigger an install/configure prompt with retry, not a passive unavailable-only message.
- Users expect skills to remain operable when prior conversation context is missing, using persisted state/artifacts/handoff contracts.
- Users assume tokens are already cheap and likely to get cheaper (CWF targets heavy coding-agent usage patterns, including Claude Code/Codex `$200 Max` plan users).

## Why CWF?

### Problem

AI coding sessions lose context at every boundary. When a session ends, the next one starts from scratch. When requirements shift from clarification to implementation, protocols and constraints are forgotten. When quality criteria are written for a five-skill system, they silently become irrelevant as the system grows.

As long-running work is parallelized, the final bottleneck shifts to human cognition and review throughput. Agent output can scale faster than human decision/verification capacity, so token minimization alone does not reduce end-to-end lead time.

### Approach

CWF addresses this with seven building-block concepts that compose across thirteen skills.

Design choices behind this approach:

1. **Unified plugin over standalone plugins**
   - Why: prevent context loss and protocol drift between phases.
2. **Pre-impl human gates, post-impl autonomous chaining (`run`)**
   - Why: keep high-judgment decisions human-controlled while preserving execution speed after scope is fixed.
3. **File-path-only handoff start contracts**
   - Why: make session continuation deterministic and reduce startup ambiguity.
4. **Provenance Tracking checks for concept/review references**
   - Why: detect stale criteria when skill/hook inventory changes.

CWF prioritizes effectiveness over immediate token efficiency. It spends tokens to reduce human review bottlenecks up front, uses agent assistance during human review (`cwf:hitl`), then improves efficiency over repeated sessions through retro-driven iteration.

### Result

The result: one plugin (`cwf`), thirteen skills, nine hook groups. Context survives session boundaries. Decisions are evidence-backed. Quality criteria evolve with the system.

## Core Concepts

Seven reusable behavioral patterns that CWF skills compose. Each concept below describes a job CWF must do to keep long-running AI sessions reliable.

**Expert Advisor** — JTBD: re-check the same decision points through different expert frames so hidden assumptions and risks surface early. Decision Point structures what to decide; Expert Advisor strengthens how that decision is validated.

**Tier Classification** — JTBD: route each decision to the right authority at the right time. Evidence-backed decisions (T1/T2) stay autonomous; genuinely subjective decisions (T3) are escalated to the user.

**Agent Orchestration** — JTBD: increase throughput without losing consistency. The orchestrator sizes agent teams by complexity, executes dependency-aware batches, and synthesizes outputs into one coherent result.

**Decision Point** — JTBD: turn ambiguity into explicit, reviewable choices. Requirements are decomposed into concrete questions so every decision has recorded evidence and rationale.

**Handoff** — JTBD: prevent restart-from-zero at phase/session boundaries. Session handoffs preserve task context and lessons, while phase handoffs preserve protocols and constraints.

**Provenance Tracking** — JTBD: prevent stale standards from silently driving current work. Reference docs carry system-state metadata and are checked before reuse.

**Adaptive Setup Contract** — JTBD: keep setup portable while still adapting to each repository's real toolchain. First-run setup bootstraps a contract with core deterministic dependencies plus repo-specific tool suggestions for explicit approval.

## The Workflow

CWF's default `cwf:run` chain is:

```text
gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship
```

| # | Skill | Trigger | What It Does |
|---|-------|---------|-------------|
| 1 | [gather](#gather) | `cwf:gather` | Acquire information — URLs, web search, local code exploration |
| 2 | [clarify](#clarify) | `cwf:clarify` | Turn vague requirements into precise specs via research + tier classification |
| 3 | [plan](#plan) | `cwf:plan` | Draft a research-backed implementation plan with explicit testable success criteria |
| 4 | [impl](#impl) | `cwf:impl` | Orchestrate parallel implementation from a plan |
| 5 | [retro](#retro) | `cwf:retro` | Extract durable learnings through CDM analysis and expert lens |
| 6 | [refactor](#refactor) | `cwf:refactor` | Multi-mode code and skill review — scan, tidy, deep review, holistic |
| 7 | [handoff](#handoff) | `cwf:handoff` | Generate session or phase handoff documents |
| 8 | [ship](#ship) | `cwf:ship` | Automate GitHub workflow — issues, PRs, and merge management |
| 9 | [review](#review) | `cwf:review` | Multi-perspective review with 6 parallel reviewers |
| 10 | [hitl](#hitl) | `cwf:hitl` | Human-in-the-loop diff/chunk review with resumable state and rule propagation |
| 11 | [run](#run) | `cwf:run` | Orchestrate full pipeline chaining from gather to ship with stage gates |
| 12 | [setup](#setup) | `cwf:setup` | Configure hooks/tools, bootstrap setup/env/index contracts, and propose repo-specific setup dependencies |
| 13 | [update](#update) | `cwf:update` | Check and apply CWF plugin updates |

## Skills Reference

This section is outcome-focused by design.

- It defines each skill by intent (`why`) and expected behavior (`what happens`).
- It omits detailed flag matrices, edge-case command flows, and rollback internals.
- For full execution contracts, read each linked `SKILL.md` and its local references.
- This summary format is standardized in [skill-conventions](plugins/cwf/references/skill-conventions.md#readme-skill-summary-format).

### [gather](plugins/cwf/skills/gather/SKILL.md)

Primary trigger: `cwf:gather`

**Why**

Turn scattered external context into local, reusable evidence before reasoning and implementation start.

**What Happens**

Collects URL/web/local context, normalizes it into artifact files under `.cwf/projects/`, and preserves provenance so downstream stages reason from files rather than memory.

**Expected Outcomes**

1. Scattered documents and links are converted into normalized local artifacts with source traceability.
2. If external web-search keys are missing, setup guidance is reported while available collection paths continue.
3. Downstream skills can reference explicit gathered evidence instead of implicit chat memory.

### [clarify](plugins/cwf/skills/clarify/SKILL.md)

Primary trigger: `cwf:clarify`

**Why**

Resolve ambiguity early so implementation does not absorb avoidable rework.

**What Happens**

Decomposes requirements into decision points, classifies them by tier (evidence/standards/subjective), resolves what can be resolved autonomously, and escalates only true preference/policy choices.

**Expected Outcomes**

1. Vague requests are transformed into explicit decision points.
2. Evidence-backed questions produce autonomous answers with rationale.
3. Remaining preference or policy choices are returned to the user with concrete trade-offs.

### [plan](plugins/cwf/skills/plan/SKILL.md)

Primary trigger: `cwf:plan`

**Why**

Create an execution contract that implementation and review can enforce consistently.

**What Happens**

Builds a structured `plan.md` with scope, file-level changes, and testable success criteria, then records carry-forward lessons for later phases.

**Expected Outcomes**

1. `plan.md` includes explicit scope, target files, and testable success criteria.
2. Unresolved assumptions are surfaced as open items instead of being embedded silently.
3. `cwf:review --mode plan` can validate contract quality before coding starts.

### [impl](plugins/cwf/skills/impl/SKILL.md)

Primary trigger: `cwf:impl`

**Why**

Convert an approved plan into predictable execution without losing constraints.

**What Happens**

Decomposes approved work into dependency-aware execution units, runs safe parallel batches, and validates completion against the plan's success criteria.

**Expected Outcomes**

1. Produced changes map back to approved plan work units.
2. Order-sensitive tasks remain sequenced while independent tasks are parallelized.
3. Unresolved risks and follow-up actions are captured with supporting evidence.

### [retro](plugins/cwf/skills/retro/SKILL.md)

Primary trigger: `cwf:retro`

**Why**

Turn a single session into durable operating improvements instead of one-off notes.

**What Happens**

Analyzes session evidence, captures causes and decisions, and routes actionable improvements into reusable documentation/check/process changes.

**Expected Outcomes**

1. `retro.md` records what happened, why it happened, and what should change next.
2. Repeated friction patterns are categorized by enforcement tier.
3. Deep mode persists expert-lens outputs and learning resources alongside core retro artifacts.

### [refactor](plugins/cwf/skills/refactor/SKILL.md)

Primary trigger: `cwf:refactor`

**Why**

Control drift across code, skills, docs, hooks, and scripts as capability surface grows.

**What Happens**

Runs quick/deep/docs-oriented inspections and produces concrete findings and fix targets so maintainability can be recovered systematically.

**Expected Outcomes**

1. Structural and quality drift is reported with explicit severity and impacted scope.
2. Docs mode surfaces consistency, link, and provenance issues deterministically.
3. Re-runs after fixes show warning/error convergence with traceable evidence.

### [handoff](plugins/cwf/skills/handoff/SKILL.md)

Primary trigger: `cwf:handoff`

**Why**

Preserve continuity across session and phase boundaries without relying on conversational memory.

**What Happens**

Generates session or phase handoff artifacts from persisted state and outputs, capturing scope, constraints, unresolved items, and restart instructions.

**Expected Outcomes**

1. The next session gets an explicit file-based starting contract.
2. Phase handoff adds HOW-level constraints that complement WHAT-level planning artifacts.
3. After compact/restart events, execution can resume from artifacts without hidden memory assumptions.

### [ship](plugins/cwf/skills/ship/SKILL.md)

Primary trigger: `cwf:ship`

**Why**

Standardize issue/PR/merge preparation while keeping final human judgment explicit.

**What Happens**

Transforms validated session artifacts into structured issue/PR/merge-ready outputs with clear guardrails for unresolved risk.

**Expected Outcomes**

1. Issue and PR materials include decision context and verification evidence.
2. Unresolved blocking items hold progression and are surfaced explicitly.
3. Merge remains actionable only with explicit user approval and a clean state.

### [review](plugins/cwf/skills/review/SKILL.md)

Primary trigger: `cwf:review`

**Why**

Apply one consistent quality gate at high-leverage points before and after implementation.

**What Happens**

Runs parallel multi-perspective review (internal, external, domain experts), synthesizes findings into a verdict, and records deterministic gate outcomes.

**Expected Outcomes**

1. Plan-mode review exposes specification risks before code is written.
2. Code-mode review synthesizes regression, security, and architecture concerns into explicit findings.
3. Fallback routing preserves gate semantics when external providers are unavailable.

### [hitl](plugins/cwf/skills/hitl/SKILL.md)

Primary trigger: `cwf:hitl`

**Why**

Inject deliberate human judgment where automated review is insufficient.

**What Happens**

Starts with an agreement round, then runs resumable chunk-based review with persisted rules/state so long review sessions remain controllable.

**Expected Outcomes**

1. Large diffs are reviewed as resumable chunks with persisted cursor/state.
2. New review rules are propagated to the remaining queue behavior.
3. Interrupted review sessions can restore progress and rationale from artifacts.

### [run](plugins/cwf/skills/run/SKILL.md)

Primary trigger: `cwf:run`

**Why**

Delegate end-to-end workflow orchestration without manually chaining individual skills.

**What Happens**

Orchestrates the default stage chain with human gates before implementation and autonomous chaining after implementation, while persisting stage state for safe continuation.

**Expected Outcomes**

1. The pipeline progresses stage by stage with explicit gates.
2. Unresolved pre-implementation ambiguity triggers user decisions before irreversible execution.
3. Persisted run-state checkpoints support reliable resume after compact/restart events.

### [setup](plugins/cwf/skills/setup/SKILL.md)

Primary trigger: `cwf:setup`

**Why**

Standardize runtime/tool contracts once so later workflow runs stay reproducible.

**What Happens**

Guides initial contract bootstrap for hooks, dependencies, environment, config, and optional integrations, then persists the chosen baseline for deterministic operation.

**Expected Outcomes**

1. Baseline setup artifacts and policy context are created for a fresh repository.
2. Missing required dependencies trigger interactive install-now prompts and deterministic rechecks.
3. Selected Codex integration reports reconciled scope-aware links and wrapper state.

### [update](plugins/cwf/skills/update/SKILL.md)

Primary trigger: `cwf:update`

**Why**

Keep installed CWF behavior aligned with the latest contracts, fixes, and guardrails.

**What Happens**

Checks scope-specific installed vs latest state, requires explicit confirmation before mutation, applies updates, and reconciles scope-aware Codex linkage when needed.

**Expected Outcomes**

1. A newer version requires explicit user confirmation before mutation.
2. Check mode reports status without installation or reconcile mutations.
3. Reconcile reports before/after integration state when install-path drift exists.

### Codex Integration

If Codex CLI is installed, recommended setup is:

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

What this enables:
- Script map for Codex/session helpers: [plugins/cwf/scripts/README.md](plugins/cwf/scripts/README.md)
- Scope-aware target resolution (active plugin scope precedence: `local > project > user`)
- User scope targets: `~/.agents/skills/*`, `~/.agents/references`, `~/.local/bin/codex`
- Project/local scope targets: `{projectRoot}/.codex/skills/*`, `{projectRoot}/.codex/references`, `{projectRoot}/.codex/bin/codex`
- Non-user runs do not mutate user-global Codex paths unless explicitly confirmed
- Every `codex` run auto-syncs session markdown logs into `.cwf/sessions/` as `*.codex.md`
- Session log sync is append-first with checkpointed incremental updates to reduce exit-time latency; if state is missing/inconsistent, it safely falls back to full rebuild
- Session artifact directories (`plan.md`, `retro.md`, `next-session.md`) remain under `.cwf/projects/{YYMMDD}-{NN}-{title}/`
- Sync is anchored to the session updated during the current run (reduces wrong-session exports on shared cwd)
- Raw JSONL copy is opt-in (`--raw`); redaction still applies when raw export is enabled
- Post-run quality checks on changed files (markdownlint, local link checks, shellcheck when available, live state check, `apply_patch via exec_command` hygiene detection, and HITL scratchpad sync detection for doc edits) with `warn|strict` mode control
- `cwf:update` reconciles stale Codex symlink/wrapper targets for the selected scope after plugin update
- Runtime controls:
  - `CWF_CODEX_POST_RUN_CHECKS=true|false` (default: `true`)
  - `CWF_CODEX_POST_RUN_MODE=warn|strict` (default: `warn`)
  - `CWF_CODEX_POST_RUN_QUIET=true|false` (default: `false`)

Verify:

```bash
bash plugins/cwf/scripts/codex/install-wrapper.sh --scope user --status
# or for project/local scope
bash plugins/cwf/scripts/codex/install-wrapper.sh --scope project --project-root "$PWD" --status
type -a codex
```

For one-time cleanup of existing session logs:

```bash
bash plugins/cwf/scripts/codex/redact-session-logs.sh
```

After install, open a new shell (or `source ~/.zshrc`). Aliases that call `codex` (for example `codexyolo='codex ...'`) also use the wrapper.

## Hooks

CWF includes 9 hook groups that run automatically. All are enabled by default; use `cwf:setup --hooks` to toggle individual groups.

| Group | Hook Type | What It Does |
|-------|-----------|-------------|
| `attention` | Notification, Pre/PostToolUse | Slack notifications on idle and AskUserQuestion |
| `log` | Stop, SessionEnd | Auto-log conversation turns to markdown |
| `read` | PreToolUse → Read | File-size aware reading guard (warn >500 lines, block >2000) |
| `lint_markdown` | PostToolUse → Write\|Edit | Markdown lint + local link validation — lint violations trigger self-correction, broken links reported async |
| `lint_shell` | PostToolUse → Write\|Edit | ShellCheck validation for shell scripts |
| `deletion_safety` | PreToolUse → Bash | Block risky deletion commands and require policy-compliant justification |
| `workflow_gate` | UserPromptSubmit | Block ship/push/merge intents when run-stage gates are unresolved |
| `websearch_redirect` | PreToolUse → WebSearch | Redirect Claude's WebSearch to `cwf:gather --search` |
| `compact_recovery` | SessionStart → compact, UserPromptSubmit | Inject live session state after auto-compact and guard session↔worktree binding on prompts |

## Configuration

CWF runtime loads configuration in this priority order:

1. `.cwf-config.local.yaml` (local/secret, highest priority)
2. `.cwf-config.yaml` (team-shared defaults)
3. Process environment
4. Shell profiles (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bash_profile`, `~/.bashrc`, `~/.profile`)

`cwf:setup` environment flow migrates legacy keys to canonical `CWF_*`, bootstraps project config templates, and ensures `.cwf-config.local.yaml` is gitignored.

Use `.cwf-config.yaml` for shared non-secret defaults:

```yaml
# .cwf-config.yaml
# Optional artifact path overrides
# CWF_ARTIFACT_ROOT: ".cwf"
# CWF_PROJECTS_DIR: ".cwf/projects"
# CWF_STATE_FILE: ".cwf/cwf-state.yaml"

# Optional runtime overrides (non-secret)
# CWF_GATHER_OUTPUT_DIR: ".cwf/projects"
# CWF_READ_WARN_LINES: 500
# CWF_READ_DENY_LINES: 2000
# CWF_SESSION_LOG_DIR: ".cwf/sessions"
# CWF_SESSION_LOG_ENABLED: true
# CWF_SESSION_LOG_TRUNCATE: 10
# CWF_SESSION_LOG_AUTO_COMMIT: false
```

Use `.cwf-config.local.yaml` for local/secret values:

```yaml
# .cwf-config.local.yaml
SLACK_BOT_TOKEN: "xoxb-your-bot-token"
SLACK_CHANNEL_ID: "D0123456789"
TAVILY_API_KEY: "tvly-your-key"
EXA_API_KEY: "your-key"
# SLACK_WEBHOOK_URL: "https://hooks.slack.com/services/..."
```

If you prefer global fallback defaults, environment variables are still supported:

```bash
# Required — Slack notifications (attention hook)
SLACK_BOT_TOKEN="xoxb-your-bot-token"           # Slack App with chat:write + im:write scopes
SLACK_CHANNEL_ID="D0123456789"                  # Bot DM channel ID (or C... for channels)
# SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."  # Optional fallback, no threading

# Required — search APIs (gather)
TAVILY_API_KEY="tvly-..."                       # Web search and URL extraction (https://app.tavily.com)
EXA_API_KEY="..."                               # Code search (https://dashboard.exa.ai)

# Optional overrides — attention
CWF_ATTENTION_DELAY=45                          # default: 30
CWF_ATTENTION_REPLY_BROADCAST=true              # default: false
CWF_ATTENTION_TRUNCATE=20                       # default: 10
CWF_ATTENTION_USER_ID="U0123456789"             # default: unset
# CWF_ATTENTION_USER_HANDLE="your-handle"       # default: unset
# CWF_ATTENTION_PARENT_MENTION="<@U0123456789>" # default: unset

# Optional overrides — gather/read/session log
CWF_GATHER_OUTPUT_DIR=".cwf/projects"               # default: .cwf/projects
CWF_READ_WARN_LINES=700                            # default: 500
CWF_READ_DENY_LINES=2500                           # default: 2000
CWF_SESSION_LOG_DIR=".cwf/sessions"                # default: .cwf/sessions
CWF_SESSION_LOG_ENABLED=false                      # default: true
CWF_SESSION_LOG_TRUNCATE=20                        # default: 10
CWF_SESSION_LOG_AUTO_COMMIT=true                   # default: false

# Optional overrides — artifact layout (advanced)
# CWF_ARTIFACT_ROOT=".cwf-data"                    # default: .cwf
# CWF_PROJECTS_DIR=".cwf/projects"                 # default: {CWF_ARTIFACT_ROOT}/projects
# CWF_STATE_FILE=".cwf/custom-state.yaml"          # default: {CWF_ARTIFACT_ROOT}/cwf-state.yaml
```

## License

MIT
