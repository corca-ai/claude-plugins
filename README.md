# CWF (Corca Workflow Framework)

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

### Update

```bash
claude plugin marketplace update corca-plugins
claude plugin update cwf@corca-plugins
```

Or from inside Claude Code:

```text
cwf:update               # Check + update if newer version exists
cwf:update --check       # Version check only
```

### Standalone plugins (legacy)

As of v3.0.0, standalone plugins (gather-context, clarify, retro, refactor, attention-hook, smart-read, prompt-logger, markdown-guard, plan-and-lessons) have been removed from the marketplace. If you have any installed, uninstall them and install `cwf` instead.

## Framing Contract

### What CWF Is

- A single workflow plugin (`cwf`) that integrates context gathering, requirement clarification, planning, implementation, review, retrospective, handoff, and shipping.
- A stateful workflow system where `cwf-state.yaml`, prompt-log artifacts, and hooks preserve context across phase/session boundaries.
- A composable skill framework built on shared concepts (Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, Handoff, Provenance).

### What CWF Is Not

- Not a replacement for project-specific engineering standards, CI gates, or human product ownership decisions.
- Not a guarantee that every decision can be fully automated; subjective decisions still require user confirmation.
- Not a generic plugin bundle where each skill is isolated; CWF skills are intentionally interdependent.

### Assumptions

- Users work in repositories where session artifacts (`prompt-logs/`, `cwf-state.yaml`) are allowed and useful.
- Users accept progressive disclosure: start from [AGENTS.md](AGENTS.md), then load deeper docs as needed.
- Teams prefer deterministic validation scripts for recurring quality checks over relying on behavioral memory.

### Key Decisions and Why

1. **Unified plugin over standalone plugins**
   - Why: prevent context loss and protocol drift between phases.
2. **Pre-impl human gates, post-impl autonomous chaining (`run`)**
   - Why: keep high-judgment decisions human-controlled while preserving execution speed after scope is fixed.
3. **Mention-only handoff execution contracts**
   - Why: make session continuation deterministic and reduce startup ambiguity.
4. **Provenance checks for concept/review references**
   - Why: detect stale criteria when skill/hook inventory changes.

## Why CWF?

AI coding sessions lose context at every boundary. When a session ends, the next one starts from scratch. When requirements shift from clarification to implementation, protocols and constraints are forgotten. When quality criteria are written for a five-skill system, they silently become irrelevant as the system grows.

CWF addresses this with six building-block concepts that compose across twelve skills. Rather than independent tools, CWF is one integrated plugin where each skill synchronizes the same underlying behavioral patterns — expert advisors surface blind spots in both requirement clarification and session retrospectives; tier classification routes decisions to evidence or humans consistently; agent orchestration parallelizes work from research through implementation.

The result: one plugin (`cwf`), twelve skills, seven hook groups. Context survives session boundaries. Decisions are evidence-backed. Quality criteria evolve with the system.

## Core Concepts

Six reusable behavioral patterns that CWF skills compose. Understanding these explains why the skills work together, not just what each one does.

**Expert Advisor** — Reduce blind spots by introducing contrasting expert frameworks. Two domain experts with different analytical lenses evaluate problems independently; their disagreements surface hidden assumptions.

**Tier Classification** — Route decisions to the right authority. Codebase evidence (T1) and best-practice consensus (T2) are resolved autonomously; genuinely subjective decisions (T3) are queued for the human.

**Agent Orchestration** — Parallelize work without sacrificing quality. The orchestrator assesses complexity, spawns the minimum agents needed, executes in dependency-respecting batches, and synthesizes results.

**Decision Point** — Capture ambiguity explicitly. Requirements are decomposed into concrete questions before anyone decides, ensuring every choice has recorded evidence and rationale.

**Handoff** — Preserve context across boundaries. Session handoffs carry task scope and lessons; phase handoffs carry protocols and constraints. The next agent starts informed, not blank.

**Provenance** — Detect criteria staleness. Reference documents carry metadata about the system state when they were written; skills check this before applying outdated standards.

## The Workflow

CWF skills follow a natural arc from context gathering to learning extraction:

```text
gather → clarify → plan → impl → retro
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
| 10 | [run](#run) | `cwf:run` | Orchestrate full pipeline chaining from gather to ship with stage gates |
| 11 | [setup](#setup) | `cwf:setup` | Configure hook groups, detect tools, optionally generate project index |
| 12 | [update](#update) | `cwf:update` | Check and apply CWF plugin updates |

**Concept composition**: gather, clarify, plan, impl, retro, refactor, review, and run all synchronize Agent Orchestration. clarify is the richest composition — it synchronizes Expert Advisor, Tier Classification, Agent Orchestration, and Decision Point in a single workflow. review synchronizes Expert Advisor and Agent Orchestration with external CLI integration. handoff is the primary instantiation of the Handoff concept. refactor activates Provenance in holistic mode.

## Skills Reference

### gather

Unified information acquisition — URLs, web search, local code exploration.

```text
cwf:gather <url>                  # Auto-detect service (Google/Slack/Notion/GitHub/web)
cwf:gather --search <query>       # Web search (Tavily)
cwf:gather --search code <query>  # Code search (Exa)
cwf:gather --local <topic>        # Explore local codebase
```

Auto-detects Google Docs/Slides/Sheets, Slack threads, Notion pages, GitHub PRs/issues, and generic web URLs. Built-in WebSearch redirect hook routes Claude's WebSearch to `cwf:gather --search`.

Full reference: [SKILL.md](plugins/cwf/skills/gather/SKILL.md)

### clarify

Research-first requirement clarification with autonomous decision-making.

```text
cwf:clarify <requirement>          # Research-first (default)
cwf:clarify <requirement> --light  # Direct Q&A, no sub-agents
```

Default mode: decomposes requirements into decision points → parallel research (codebase + web) → expert analysis → tier classification (T1/T2 auto-decide, T3 ask human) → persistent questioning with why-digging. Light mode: iterative Q&A without sub-agents.

Full reference: [SKILL.md](plugins/cwf/skills/clarify/SKILL.md)

### plan

Agent-assisted plan drafting with parallel research and BDD success criteria.

```text
cwf:plan <task description>
```

Parallel prior art + codebase research → structured plan with steps, files, success criteria (BDD + qualitative) → saved to `prompt-logs/` session directory. Recommended flow: run `cwf:review --mode plan` before implementation so plan-level concerns are resolved before `cwf:impl`.

Full reference: [SKILL.md](plugins/cwf/skills/plan/SKILL.md)

### impl

Implementation orchestration from a structured plan.

```text
cwf:impl                    # Auto-detect most recent plan.md
cwf:impl <path/to/plan.md>  # Explicit plan path
```

Loads plan (+ phase handoff if present) → decomposes into work items by domain and dependency → sizes agent team adaptively (1-4 agents) → executes in parallel batches → verifies against BDD criteria. Typical sequence: `cwf:plan` → `cwf:review --mode plan` → `cwf:impl` → `cwf:review --mode code`.

Full reference: [SKILL.md](plugins/cwf/skills/impl/SKILL.md)

### retro

Adaptive session retrospective — deep by default; use `--light` for lightweight mode.

```text
cwf:retro            # Adaptive (deep by default)
cwf:retro --deep     # Full analysis with expert lens
cwf:retro --light    # Sections 1-4 + 7 only, no sub-agents
```

Sections: Context Worth Remembering, Collaboration Preferences, Waste Reduction (5 Whys), Critical Decision Analysis (CDM), Expert Lens (deep), Learning Resources (deep), Relevant Skills. Persists findings to project-level documents.

Full reference: [SKILL.md](plugins/cwf/skills/retro/SKILL.md)

### refactor

Multi-mode code and skill review with five operating modes.

```text
cwf:refactor                        # Quick scan all skills
cwf:refactor --code [branch]        # Commit-based tidying
cwf:refactor --skill <name>         # Deep review of a single skill
cwf:refactor --skill --holistic     # Cross-plugin analysis
cwf:refactor --docs                 # Documentation consistency review
```

Quick scan runs structural checks. Code tidying analyzes commits for safe refactoring (Kent Beck's "Tidy First?"). Deep review evaluates against progressive disclosure criteria. Holistic mode detects cross-plugin pattern issues. Docs mode checks cross-document consistency.

Full reference: [SKILL.md](plugins/cwf/skills/refactor/SKILL.md)

### handoff

Generate session or phase handoff documents from project state and artifacts.

```text
cwf:handoff                # Generate next-session.md + register
cwf:handoff --register     # Register session in cwf-state.yaml only
cwf:handoff --phase        # Generate phase-handoff.md (HOW context)
```

Session handoffs carry task scope, lessons, and unresolved items for the next session. Phase handoffs carry protocols, rules, and constraints for the next workflow phase (HOW), complementing plan.md (WHAT). `next-session.md` now also includes an execution contract so mention-only start can run directly, including branch gate (auto escape from base branch) and meaningful commit-unit policy.

Full reference: [SKILL.md](plugins/cwf/skills/handoff/SKILL.md)

### ship

Automate GitHub workflow — issue creation, PR with structured templates, and merge management.

```text
cwf:ship                                   # Show usage
cwf:ship issue [--base B] [--no-branch]    # Create issue + feature branch
cwf:ship pr [--base B] [--issue N] [--draft]  # Create pull request
cwf:ship merge [--squash|--merge|--rebase]    # Merge approved PR
cwf:ship status                            # Show issues, PRs, and checks
```

Builds issue/PR bodies from session context (`plan.md`, `lessons.md`, `retro.md`) including CDM/decision summaries, verification checklist, and human-judgment guardrails for merge decisions.

Full reference: [SKILL.md](plugins/cwf/skills/ship/SKILL.md)

### review

Multi-perspective review with 6 parallel reviewers.

```text
cwf:review                       # Review current changes (defaults to code mode)
cwf:review --mode code           # Review current changes (explicit code mode)
cwf:review --mode clarify        # Review clarified requirements
cwf:review --mode plan           # Review implementation plan
```

6 parallel reviewers: 2 internal (Security, UX/DX) via Task agents + 2 external (Codex, Gemini) via CLI + 2 domain experts via Task agents. Graceful fallback when external CLIs are unavailable.

Full reference: [SKILL.md](plugins/cwf/skills/review/SKILL.md)

### run

Full CWF pipeline auto-chaining with configurable stage gates.

```text
cwf:run <task description>           # Full pipeline from scratch
cwf:run --from impl                  # Resume from impl stage
cwf:run --skip review-plan,retro     # Skip specific stages
```

Executes gather → clarify → plan → review(plan) → impl → review(code) → retro → ship, with human gates before implementation, automatic chaining after implementation by default, and user confirmation at `ship`.

Full reference: [SKILL.md](plugins/cwf/skills/run/SKILL.md)

### setup

Initial CWF configuration.

```text
cwf:setup                # Full setup (hooks + tools + optional repo-index prompt)
cwf:setup --hooks        # Hook group selection only
cwf:setup --tools        # External tool detection only
cwf:setup --codex        # Link CWF skills/references into Codex user scope (~/.agents/*)
cwf:setup --codex-wrapper # Install codex wrapper for automatic session log sync
cwf:setup --cap-index    # Generate/refresh CWF capability index only (cwf-index.md)
cwf:setup --repo-index   # Generate/refresh repository index output (explicit)
cwf:setup --repo-index --target agents # AGENTS.md managed block (for AGENTS-based repositories)
```

Interactive hook group toggle, external AI CLI and API key detection (Codex, Gemini, Tavily, Exa), optional Codex integration (skills + wrapper), and optional index generation. CWF capability index generation is explicit via `cwf:setup --cap-index`. Repository index regeneration updates the managed block in [AGENTS.md](AGENTS.md) via `cwf:setup --repo-index --target agents`.

Full reference: [SKILL.md](plugins/cwf/skills/setup/SKILL.md)

### Codex Integration

If Codex CLI is installed, recommended setup is:

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

What this enables:
- `~/.agents/skills/*` and `~/.agents/references` symlinked to local CWF (latest files auto-loaded)
- `~/.local/bin/codex` wrapper installation + PATH update (`~/.zshrc`, `~/.bashrc`)
- Every `codex` run auto-syncs session markdown logs into `prompt-logs/sessions/` as `*.codex.md`
- Sync is anchored to the session updated during the current run (reduces wrong-session exports on shared cwd)
- Raw JSONL copy is opt-in (`--raw`); redaction still applies when raw export is enabled

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

Notification behavior:

Screenshots were deprecated in v3 and removed from the repository. Refer to the hook table above and [plugins/cwf/hooks/scripts/attention.sh](plugins/cwf/hooks/scripts/attention.sh) for behavior details.

## Configuration

Set environment variables in your shell profile (`~/.zshrc` or `~/.bashrc`). Legacy fallback (`~/.claude/.env`) is still supported.

### Slack notifications (attention hook)

```bash
SLACK_BOT_TOKEN="xoxb-your-bot-token"       # Slack App with chat:write + im:write scopes
SLACK_CHANNEL_ID="D0123456789"               # Bot DM channel ID (or C... for channels)
CLAUDE_CORCA_ATTENTION_DELAY=30              # AskUserQuestion notification delay (seconds)
CLAUDE_CORCA_ATTENTION_REPLY_BROADCAST=false # Thread replies also visible in channel timeline (default: false)
CLAUDE_CORCA_ATTENTION_TRUNCATE=10           # Max lines per Request/Response section (default: 10)
# Optional parent mention (first prompt only):
CLAUDE_CORCA_ATTENTION_USER_ID="U0123456789" # Recommended: Slack user ID => <@U...>
# CLAUDE_CORCA_ATTENTION_USER_HANDLE="your-handle"
# CLAUDE_CORCA_ATTENTION_PARENT_MENTION="<@U0123456789>"  # Raw override
```

For legacy webhook setup (no threading), set `SLACK_WEBHOOK_URL` instead.

### Search APIs (gather skill)

```bash
TAVILY_API_KEY="tvly-..."                    # Web search and URL extraction (https://app.tavily.com)
EXA_API_KEY="..."                            # Code search (https://dashboard.exa.ai)
```

### Gather output

```bash
CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR="./gathered"  # Default output directory
```

### Smart-read thresholds

```bash
CLAUDE_CORCA_SMART_READ_WARN_LINES=500      # Lines above which a warning is shown (default: 500)
CLAUDE_CORCA_SMART_READ_DENY_LINES=2000     # Lines above which full read is blocked (default: 2000)
```

### Prompt logger

```bash
CLAUDE_CORCA_PROMPT_LOGGER_DIR="/custom/path"  # Output directory (default: {cwd}/prompt-logs/sessions)
CLAUDE_CORCA_PROMPT_LOGGER_ENABLED=false       # Disable logging (default: true)
CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=20         # Truncation threshold in lines (default: 10)
```

## License

MIT
