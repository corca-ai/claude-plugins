# CWF (Corca Workflow Framework)

[한국어](README.ko.md)

A Claude Code plugin that turns structured development sessions into a repeatable workflow — from gathering context through retrospective analysis. Maintained by [Corca](https://www.corca.ai/) for [AI-Native Product Teams](AI_NATIVE_PRODUCT_TEAM.md).

## Why CWF?

AI coding sessions lose context at every boundary. When a session ends, the next one starts from scratch. When requirements shift from clarification to implementation, protocols and constraints are forgotten. When quality criteria are written for a five-skill system, they silently become irrelevant as the system grows to nine.

CWF addresses this with six building-block concepts that compose across nine skills. Rather than nine independent tools, CWF is one integrated plugin where each skill synchronizes the same underlying behavioral patterns — expert advisors surface blind spots in both requirement clarification and session retrospectives; tier classification routes decisions to evidence or humans consistently; agent orchestration parallelizes work from research through implementation.

The result: one plugin (`cwf`), eleven skills, seven hook groups. Context survives session boundaries. Decisions are evidence-backed. Quality criteria evolve with the system.

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
| 10 | [setup](#setup) | `cwf:setup` | Configure hook groups, detect tools, generate project index |
| 11 | [update](#update) | `cwf:update` | Check and apply CWF plugin updates |

**Concept composition**: gather, clarify, plan, impl, retro, refactor, and review all synchronize Agent Orchestration. clarify is the richest composition — it synchronizes Expert Advisor, Tier Classification, Agent Orchestration, and Decision Point in a single workflow. review synchronizes Expert Advisor and Agent Orchestration with external CLI integration. handoff is the primary instantiation of the Handoff concept. refactor activates Provenance in holistic mode.

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
cwf:update
```

### Standalone plugins (legacy)

As of v3.0.0, standalone plugins (gather-context, clarify, retro, refactor, attention-hook, smart-read, prompt-logger, markdown-guard, plan-and-lessons) have been removed from the marketplace. If you have any installed, uninstall them and install `cwf` instead.

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

Parallel prior art + codebase research → structured plan with steps, files, success criteria (BDD + qualitative) → saved to `prompt-logs/` session directory.

Full reference: [SKILL.md](plugins/cwf/skills/plan/SKILL.md)

### impl

Implementation orchestration from a structured plan.

```text
cwf:impl                    # Auto-detect most recent plan.md
cwf:impl <path/to/plan.md>  # Explicit plan path
```

Loads plan (+ phase handoff if present) → decomposes into work items by domain and dependency → sizes agent team adaptively (1-4 agents) → executes in parallel batches → verifies against BDD criteria.

Full reference: [SKILL.md](plugins/cwf/skills/impl/SKILL.md)

### retro

Adaptive session retrospective — light by default, deep on request.

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

Session handoffs carry task scope, lessons, and unresolved items for the next session. Phase handoffs carry protocols, rules, and constraints for the next workflow phase (HOW), complementing plan.md (WHAT).

Full reference: [SKILL.md](plugins/cwf/skills/handoff/SKILL.md)

### ship

Automate GitHub workflow — issue creation, PR with structured templates, and merge management.

```text
cwf:ship                   # Interactive: choose issue, PR, or merge
cwf:ship --issue           # Create GitHub issue
cwf:ship --pr              # Create pull request
cwf:ship --merge           # Merge current PR
```

Generates structured PR descriptions with lessons learned, critical decision summaries, and test checklists. Supports Korean PR templates and autonomous merge decision matrix.

Full reference: [SKILL.md](plugins/cwf/skills/ship/SKILL.md)

### review

Multi-perspective review with 6 parallel reviewers.

```text
cwf:review                       # Review current changes (code mode)
cwf:review --mode clarify        # Review clarified requirements
cwf:review --mode plan           # Review implementation plan
```

6 parallel reviewers: 2 internal (Security, UX/DX) via Task agents + 2 external (Codex, Gemini) via CLI + 2 domain experts via Task agents. Graceful fallback when external CLIs are unavailable.

Full reference: [SKILL.md](plugins/cwf/skills/review/SKILL.md)

### setup

Initial CWF configuration.

```text
cwf:setup                # Full setup (hooks + tools + index)
cwf:setup --hooks        # Hook group selection only
cwf:setup --tools        # External tool detection only
cwf:setup --index        # Generate project index.md
```

Interactive hook group toggle, external AI CLI and API key detection (Codex, Gemini, Tavily, Exa), and progressive disclosure index generation. CWF hooks work without running setup — this skill is for customization.

Full reference: [SKILL.md](plugins/cwf/skills/setup/SKILL.md)

### update

Check and apply CWF plugin updates.

```text
cwf:update               # Check + update if newer version exists
cwf:update --check       # Version check only
```

Full reference: [SKILL.md](plugins/cwf/skills/update/SKILL.md)

## Hooks

CWF includes 7 hook groups that run automatically. All are enabled by default; use `cwf:setup --hooks` to toggle individual groups.

| Group | Hook Type | What It Does |
|-------|-----------|-------------|
| `attention` | Notification, Pre/PostToolUse | Slack notifications on idle and AskUserQuestion |
| `log` | Stop, SessionEnd | Auto-log conversation turns to markdown |
| `read` | PreToolUse → Read | File-size aware reading guard (warn >500 lines, block >2000) |
| `lint_markdown` | PostToolUse → Write\|Edit | Markdown validation — lint violations trigger self-correction |
| `lint_shell` | PostToolUse → Write\|Edit | ShellCheck validation for shell scripts |
| `websearch_redirect` | PreToolUse → WebSearch | Redirect Claude's WebSearch to `cwf:gather --search` |
| `compact_recovery` | SessionStart → compact | Inject live session state after auto-compact for context recovery |

Notification examples:

<img src="assets/attention-hook-normal-response.png" alt="Slack notification — normal response" width="600">

<img src="assets/attention-hook-AskUserQuestion.png" alt="Slack notification — AskUserQuestion" width="600">

## Configuration

Set environment variables in `~/.claude/.env`:

### Slack notifications (attention hook)

```bash
SLACK_BOT_TOKEN="xoxb-your-bot-token"       # Slack App with chat:write + im:write scopes
SLACK_CHANNEL_ID="D0123456789"               # Bot DM channel ID (or C... for channels)
CLAUDE_CORCA_ATTENTION_DELAY=30              # AskUserQuestion notification delay (seconds)
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
