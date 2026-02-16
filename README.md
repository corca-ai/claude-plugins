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
- project config bootstrap (`.cwf/config.yaml`, `.cwf/config.local.yaml`)
- tool detection (Codex/Gemini/Tavily/Exa) and optional Codex integration
- optional index generation (improves agent routing and progressive-disclosure navigation)

For detailed flags, see [setup](#setup).

### Codex users (recommended)

If you also use Codex CLI, running only `cwf:setup` is enough to get guided defaults. Use the commands below when you want to re-apply Codex integration only:

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
- A composable skill framework built on shared concepts (Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, Handoff, Provenance Tracking).
- A roadmap toward lower user bottlenecks by chaining smaller approval units (for example, dark-factory-style operating patterns).

### What CWF Is Not

- Not a replacement for project-specific engineering standards, CI gates, or human product ownership decisions.
- Not a guarantee that every decision can be fully automated; subjective decisions still require user confirmation.
- While each skill can be invoked independently, CWF is intentionally designed as a tightly coupled system and works best when skills are used together.

### Assumptions

- Users work in repositories where session artifacts (.cwf/projects/, .cwf/cwf-state.yaml) are allowed and useful.
- Users accept progressive disclosure: start from AGENTS.md, then load deeper docs as needed.
- Users prefer deterministic validation scripts for recurring quality checks over relying on behavioral memory.
- Users assume tokens are already cheap and likely to get cheaper (CWF targets heavy coding-agent usage patterns, including Claude Code/Codex `$200 Max` plan users).

## Why CWF?

### Problem

AI coding sessions lose context at every boundary. When a session ends, the next one starts from scratch. When requirements shift from clarification to implementation, protocols and constraints are forgotten. When quality criteria are written for a five-skill system, they silently become irrelevant as the system grows.

As long-running work is parallelized, the final bottleneck shifts to human cognition and review throughput. Agent output can scale faster than human decision/verification capacity, so token minimization alone does not reduce end-to-end lead time.

### Approach

CWF addresses this with six building-block concepts that compose across thirteen skills.

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

The result: one plugin (`cwf`), thirteen skills, seven hook groups. Context survives session boundaries. Decisions are evidence-backed. Quality criteria evolve with the system.

## Core Concepts

Six reusable behavioral patterns that CWF skills compose. Each concept below describes a job CWF must do to keep long-running AI sessions reliable.

**Expert Advisor** — JTBD: re-check the same decision points through different expert frames so hidden assumptions and risks surface early. Decision Point structures what to decide; Expert Advisor strengthens how that decision is validated.

**Tier Classification** — JTBD: route each decision to the right authority at the right time. Evidence-backed decisions (T1/T2) stay autonomous; genuinely subjective decisions (T3) are escalated to the user.

**Agent Orchestration** — JTBD: increase throughput without losing consistency. The orchestrator sizes agent teams by complexity, executes dependency-aware batches, and synthesizes outputs into one coherent result.

**Decision Point** — JTBD: turn ambiguity into explicit, reviewable choices. Requirements are decomposed into concrete questions so every decision has recorded evidence and rationale.

**Handoff** — JTBD: prevent restart-from-zero at phase/session boundaries. Session handoffs preserve task context and lessons, while phase handoffs preserve protocols and constraints.

**Provenance Tracking** — JTBD: prevent stale standards from silently driving current work. Reference docs carry system-state metadata and are checked before reuse.

## The Workflow

CWF's default `cwf:run` chain is:

```text
gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship
```

| # | Skill | Trigger | What It Does |
|---|-------|---------|-------------|
| 1 | [gather](#gather) | `cwf:gather` | Acquire information — URLs, web search, local code exploration |
| 2 | [clarify](#clarify) | `cwf:clarify` | Turn vague requirements into precise specs via research + tier classification |
| 3 | [plan](#plan) | `cwf:plan` | Draft a research-backed implementation plan with BDD success criteria |
| 4 | [impl](#impl) | `cwf:impl` | Orchestrate parallel implementation from a plan |
| 5 | [retro](#retro) | `cwf:retro` | Extract durable learnings through CDM analysis and expert lens |
| 6 | [refactor](#refactor) | `cwf:refactor` | Multi-mode code and skill review — scan, tidy, deep review, holistic |
| 7 | [handoff](#handoff) | `cwf:handoff` | Generate session or phase handoff documents |
| 8 | [ship](#ship) | `cwf:ship` | Automate GitHub workflow — issues, PRs, and merge management |
| 9 | [review](#review) | `cwf:review` | Multi-perspective review with 6 parallel reviewers |
| 10 | [hitl](#hitl) | `cwf:hitl` | Human-in-the-loop diff/chunk review with resumable state and rule propagation |
| 11 | [run](#run) | `cwf:run` | Orchestrate full pipeline chaining from gather to ship with stage gates |
| 12 | [setup](#setup) | `cwf:setup` | Configure hook groups, detect tools, bootstrap env/index contracts |
| 13 | [update](#update) | `cwf:update` | Check and apply CWF plugin updates |

**Concept composition**: gather, clarify, plan, impl, retro, refactor, review, hitl, and run all synchronize Agent Orchestration. clarify is the richest composition — it synchronizes Expert Advisor, Tier Classification, Agent Orchestration, and Decision Point in a single workflow. review and hitl both combine human judgment with structured review orchestration at different granularity (parallel reviewers vs chunked interactive loop). handoff is the primary instantiation of the Handoff concept. refactor activates Provenance Tracking in holistic mode.

## Skills Reference

### [gather](plugins/cwf/skills/gather/SKILL.md)

JTBD: turn scattered external context into local, reusable artifacts before reasoning and implementation start.

```text
cwf:gather <url>                  # Auto-detect service (Google/Slack/Notion/GitHub/web)
cwf:gather --search <query>       # Web search (Tavily)
cwf:gather --search code <query>  # Code search (Exa)
cwf:gather --local <topic>        # Explore local codebase
```

Auto-detects Google Docs/Slides/Sheets, Slack threads, Notion pages, GitHub PRs/issues, and generic web URLs. It downloads source content into `.cwf/projects/`, normalizes outputs into agent-friendly markdown, and keeps provenance links. Google Docs and Notion exports require public/published sharing settings. The WebSearch redirect hook currently routes Claude's WebSearch to `cwf:gather --search` regardless of API-key presence; without `TAVILY_API_KEY`/`EXA_API_KEY`, it returns setup guidance for search while URL collection and `--local` continue to work. A future fallback mode will route back to Claude WebSearch when keys are missing.

### [clarify](plugins/cwf/skills/clarify/SKILL.md)

JTBD: prevent costly implementation churn by resolving ambiguity before planning.

```text
cwf:clarify <requirement>          # Research-first (default)
cwf:clarify <requirement> --light  # Direct Q&A, no sub-agents
```

Default mode decomposes requirements into decision points → parallel research (codebase + web) → expert analysis → tier classification (T1: codebase evidence, T2: standards/best practices, T3: preference/policy choices with no single correct answer) → persistent why-questioning. To fix the v1 pattern where agents asked users about discoverable facts too often, T1/T2 are handled autonomously by default and only T3 is escalated. Light mode keeps a faster interactive Q&A loop without sub-agents.

### [plan](plugins/cwf/skills/plan/SKILL.md)

JTBD: create an implementation contract that downstream implementation and review can enforce.

```text
cwf:plan <task description>
```

Parallel prior art + codebase research produce a structured plan with steps, files, and success criteria (BDD + qualitative), saved to `.cwf/projects/`. Recommended flow: run `cwf:review --mode plan` before implementation so plan-level concerns are resolved before `cwf:impl`.

### [impl](plugins/cwf/skills/impl/SKILL.md)

JTBD: convert an approved plan into predictable execution without losing constraints.

```text
cwf:impl                    # Auto-detect most recent plan.md
cwf:impl <path/to/plan.md>  # Explicit plan path
```

Loads the plan (+ phase handoff if present), decomposes work by domain and dependency, sizes an adaptive agent team (1-4), executes parallel batches, and verifies against BDD criteria. Typical sequence: `cwf:plan` → `cwf:review --mode plan` → `cwf:impl` → `cwf:review --mode code`.

### [retro](plugins/cwf/skills/retro/SKILL.md)

JTBD: convert one session's outcomes into durable operating improvements and capability decisions.

```text
cwf:retro            # Adaptive (deep by default)
cwf:retro --deep     # Full analysis with expert lens
cwf:retro --light    # Sections 1-4 + 7 only, no sub-agents
```

Sections: Context Worth Remembering, Collaboration Preferences, Waste Reduction (5 Whys), Critical Decision Analysis (CDM), Expert Lens (deep), Learning Resources (deep), Relevant Tools, and Tool Gaps. It separates currently used/usable tools from missing capabilities that cause repeated friction, then feeds those findings into setup/refactor/backlog decisions.

### [refactor](plugins/cwf/skills/refactor/SKILL.md)

JTBD: keep a growing skill/tool ecosystem coherent as teams install or author more capabilities.

```text
cwf:refactor                        # Quick scan all skills
cwf:refactor --code [branch]        # Commit-based tidying
cwf:refactor --skill <name>         # Deep review of a single skill
cwf:refactor --skill --holistic     # Cross-plugin analysis
cwf:refactor --docs                 # Documentation consistency review
```

Quick scan exists to catch global drift in a codebase where skills, scripts, docs, and code keep growing together. `--skill <name>` exists for focused diagnosis when one skill misbehaves or is being authored/customized. Code tidying analyzes commits for safe refactoring (Kent Beck's "Tidy First?"). Holistic mode detects cross-plugin pattern issues. Docs mode checks cross-document consistency.

### [handoff](plugins/cwf/skills/handoff/SKILL.md)

Generate session or phase handoff documents from project state and artifacts.

```text
cwf:handoff                # Generate next-session.md + register
cwf:handoff --register     # Register session in .cwf/cwf-state.yaml only
cwf:handoff --phase        # Generate phase-handoff.md (HOW context)
```

Session handoffs carry task scope, lessons, and unresolved items for the next session. Phase handoffs carry protocols, rules, and constraints for the next workflow phase (HOW), complementing plan.md (WHAT). `next-session.md` now also includes an execution contract so entering only the handoff file path can start directly, including branch gate (auto escape from base branch) and meaningful commit-unit policy.

### [ship](plugins/cwf/skills/ship/SKILL.md)

Automate GitHub workflow — issue creation, PR with structured templates, and merge management.

```text
cwf:ship                                   # Show usage
cwf:ship issue [--base B] [--no-branch]    # Create issue + feature branch
cwf:ship pr [--base B] [--issue N] [--draft]  # Create pull request
cwf:ship merge [--squash|--merge|--rebase]    # Merge approved PR
cwf:ship status                            # Show issues, PRs, and checks
```

Builds issue/PR bodies from session context (`plan.md`, `lessons.md`, `retro.md`) including CDM/decision summaries, verification checklist, and human-judgment guardrails for merge decisions. Default policy keeps final merge judgment human-gated; when there are no blocking issues and the user explicitly requests it, an exceptional merge path (for example, admin merge) can be used. Before merge, `cwf:hitl` can add one continuous human loop: agreement on key decisions and user concerns, followed by chunked change review.

### [review](plugins/cwf/skills/review/SKILL.md)

JTBD: apply a consistent quality gate at two leverage points: before implementation and after implementation.

```text
cwf:review                       # Review current changes (defaults to code mode)
cwf:review --mode code           # Review current changes (explicit code mode)
cwf:review --mode clarify        # Review clarified requirements
cwf:review --mode plan           # Review implementation plan
```

Use `--mode plan` after `cwf:plan` to validate scope/assumptions before code is written, and use `--mode code` after `cwf:impl` to catch regressions before shipping. The skill runs 6 parallel reviewers: 2 internal (Security, UX/DX) via Task agents + 2 external (Codex, Gemini) via CLI + 2 domain experts via Task agents. Provider routing is the same even when the main runtime agent is Codex; unavailable external CLIs fall back to Task-based reviewers.

### [hitl](plugins/cwf/skills/hitl/SKILL.md)

JTBD: inject deliberate human judgment through one resumable loop that combines agreement-round consensus and change review when automated review is insufficient.

```text
cwf:hitl                             # Start from default base (upstream/main)
cwf:hitl --base <branch>             # Review diff against explicit base
cwf:hitl --resume                    # Resume from saved cursor
cwf:hitl --rule "<rule text>"        # Add review rule for remaining queue
```

Default flow starts with an agreement round: collect major decision points and user concerns, record consensus in `hitl-scratchpad.md`, apply high-impact edits if needed, then proceed to chunk review. Runtime state is persisted under `.cwf/projects/<session-dir>/hitl/` (`hitl-scratchpad.md`, `state.yaml`, `rules.yaml`, `queue.json`, `fix-queue.yaml`, `events.log`). [`.cwf/cwf-state.yaml`](.cwf/cwf-state.yaml) stores only live pointer metadata to the active HITL session.

### [run](plugins/cwf/skills/run/SKILL.md)

JTBD: let users delegate end-to-end workflow orchestration without memorizing individual skills.

```text
cwf:run <task description>           # Full pipeline from scratch
cwf:run --from impl                  # Resume from impl stage
cwf:run --skip review-plan,retro     # Skip specific stages
```

Executes gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship, with human gates before implementation, automatic chaining after implementation by default, and user confirmation at `ship`. Including `refactor` in the default chain adds a maintainability pass for skill/docs/code drift before retrospective and shipping.

### [setup](plugins/cwf/skills/setup/SKILL.md)

JTBD: standardize environment and tool contracts once so later stages stay reproducible.

```text
cwf:setup                # Full setup (hooks + tools + optional repo-index prompt)
cwf:setup --hooks        # Hook group selection only
cwf:setup --tools        # External tool detection only
cwf:setup --env          # Environment variable migration/bootstrap only
cwf:setup --codex        # Link CWF skills/references into Codex user scope (~/.agents/*)
cwf:setup --codex-wrapper # Install codex wrapper for automatic session log sync
cwf:setup --cap-index    # Generate/refresh CWF capability index only (.cwf/indexes/cwf-index.md)
cwf:setup --repo-index   # Generate/refresh repository index output (explicit)
cwf:setup --repo-index --target agents # AGENTS.md managed block (for AGENTS-based repositories)
```

Interactive hook-group toggles, external AI CLI/API detection (Codex, Gemini, Tavily, Exa), env migration (legacy keys to canonical `CWF_*`), project config bootstrap (`.cwf/config.yaml`, `.cwf/config.local.yaml`), optional Codex integration (skills + wrapper), and optional index generation/refresh. Index generation exists to improve agent routing: capability index helps CWF-internal routing, repository index keeps AGENTS managed blocks aligned for progressive disclosure. Use `cwf:setup --cap-index` for capability index and `cwf:setup --repo-index --target agents` for repository index.

### [update](plugins/cwf/skills/update/SKILL.md)

JTBD: keep local workflow behavior aligned with the latest contracts, fixes, and guardrails.

```text
cwf:update               # Check + update if newer version exists
cwf:update --check       # Version check only
```

Update checks are frequent and easy to skip when done manually. `cwf:update` standardizes the sequence (`check -> user approval -> apply`) so version alignment becomes routine instead of ad hoc.

### Codex Integration

If Codex CLI is installed, recommended setup is:

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

What this enables:
- `~/.agents/skills/*` and `~/.agents/references` symlinked to local CWF (latest files auto-loaded)
- `~/.local/bin/codex` wrapper installation + PATH update (`~/.zshrc`, `~/.bashrc`)
- Every `codex` run auto-syncs session markdown logs into `.cwf/projects/sessions/` as `*.codex.md`
- Sync is anchored to the session updated during the current run (reduces wrong-session exports on shared cwd)
- Raw JSONL copy is opt-in (`--raw`); redaction still applies when raw export is enabled
- Wrapper scope is currently session-log sync. Codex does not expose Claude-style Pre/PostTool hook lifecycles, but session-level post-run automation (for example validation/state sync) can still be extended through the wrapper.

Verify:

```bash
bash scripts/codex/install-wrapper.sh --status
type -a codex
```

For one-time cleanup of existing session logs:

```bash
bash scripts/codex/redact-session-logs.sh
```

After install, open a new shell (or `source ~/.zshrc`). Aliases that call `codex` (for example `codexyolo='codex ...'`) also use the wrapper.

## Hooks

CWF includes 7 hook groups that run automatically. All are enabled by default; use `cwf:setup --hooks` to toggle individual groups.

| Group | Hook Type | What It Does |
|-------|-----------|-------------|
| `attention` | Notification, Pre/PostToolUse | Slack notifications on idle and AskUserQuestion |
| `log` | Stop, SessionEnd | Auto-log conversation turns to markdown |
| `read` | PreToolUse → Read | File-size aware reading guard (warn >500 lines, block >2000) |
| `lint_markdown` | PostToolUse → Write\|Edit | Markdown lint + local link validation — lint violations trigger self-correction, broken links reported async |
| `lint_shell` | PostToolUse → Write\|Edit | ShellCheck validation for shell scripts |
| `websearch_redirect` | PreToolUse → WebSearch | Redirect Claude's WebSearch to `cwf:gather --search` |
| `compact_recovery` | SessionStart → compact | Inject live session state after auto-compact for context recovery |

## Configuration

CWF runtime loads configuration in this priority order:

1. `.cwf/config.local.yaml` (local/secret, highest priority)
2. `.cwf/config.yaml` (team-shared defaults)
3. Process environment
4. Shell profiles (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bash_profile`, `~/.bashrc`, `~/.profile`)

`cwf:setup` environment flow migrates legacy keys to canonical `CWF_*`, bootstraps project config templates, and ensures `.cwf/config.local.yaml` is gitignored.

Use `.cwf/config.yaml` for shared non-secret defaults:

```yaml
# .cwf/config.yaml
# Optional artifact path overrides
# CWF_ARTIFACT_ROOT: ".cwf"
# CWF_PROJECTS_DIR: ".cwf/projects"
# CWF_STATE_FILE: ".cwf/cwf-state.yaml"

# Optional runtime overrides (non-secret)
# CWF_GATHER_OUTPUT_DIR: ".cwf/projects"
# CWF_READ_WARN_LINES: 500
# CWF_READ_DENY_LINES: 2000
# CWF_SESSION_LOG_DIR: ".cwf/projects/sessions"
# CWF_SESSION_LOG_ENABLED: true
# CWF_SESSION_LOG_TRUNCATE: 10
# CWF_SESSION_LOG_AUTO_COMMIT: false
```

Use `.cwf/config.local.yaml` for local/secret values:

```yaml
# .cwf/config.local.yaml
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
CWF_SESSION_LOG_DIR=".cwf/projects/sessions"       # default: .cwf/projects/sessions
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
