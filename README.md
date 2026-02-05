# corca-plugins

[한국어](README.ko.md)

A Claude Code plugin marketplace maintained by Corca for the [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.md).

## Installation

### 1. Add and update the marketplace

```bash
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git
```

When new plugins are added or existing plugins are updated, update the marketplace first:
```bash
claude plugin marketplace update corca-plugins
```

Then install or update the plugin you need:
```bash
claude plugin install <plugin-name>@corca-plugins  # install
claude plugin update <plugin-name>@corca-plugins   # update
```

Restart Claude Code after installing/updating for changes to take effect.

To update the marketplace and **all** installed plugins at once:
```bash
bash scripts/update-all.sh
```

You can do the same from inside Claude Code (instead of your terminal):
```
/plugin marketplace add corca-ai/claude-plugins
/plugin marketplace update
```

### 2. Plugin overview

| Plugin | Type | Description |
|---------|------|-------------|
| [clarify](#clarify) | Skill | Unified requirement clarification: research-first or lightweight Q&A |
| [deep-clarify](#deep-clarify) | ~~Skill~~ | **Deprecated** — use clarify v2 |
| [interview](#interview) | ~~Skill~~ | **Deprecated** — use clarify v2 |
| [suggest-tidyings](#suggest-tidyings) | Skill | Suggest safe refactoring opportunities |
| [retro](#retro) | Skill | Adaptive session retrospective — light by default, deep (`--deep`) with expert lens |
| [gather-context](#gather-context) | Skill + Hook | Unified information acquisition: URL auto-detect, web search, local code exploration |
| [web-search](#web-search) | ~~Skill + Hook~~ | **Deprecated** — use gather-context v2 |
| [attention-hook](#attention-hook) | Hook | Send a Slack notification when idle/waiting |
| [plan-and-lessons](#plan-and-lessons) | Hook | Inject the Plan & Lessons Protocol when entering plan mode |
| [smart-read](#smart-read) | Hook | Enforce intelligent file reading based on file size |
| [prompt-logger](#prompt-logger) | Hook | Auto-log conversation turns to markdown for retrospective analysis |

## Skills

### [clarify](plugins/clarify/skills/clarify/SKILL.md)

**Install**: `claude plugin install clarify@corca-plugins` | **Update**: `claude plugin update clarify@corca-plugins`

Unified requirement clarification that merges the best of clarify v1, deep-clarify, and interview into a single skill. Two modes: research-first (default) and lightweight direct Q&A (`--light`). Originally based on Team Attention's [Clarify skill](https://github.com/team-attention/plugins-for-claude-natives/blob/main/plugins/clarify/SKILL.md).

**Usage**:
- `/clarify <requirement>` — research-first (default)
- `/clarify <requirement> --light` — direct Q&A, no sub-agents

**Default mode** (research-first):
1. Capture & decompose requirement into decision points
2. Parallel research: codebase exploration + web/best-practice research (uses gather-context if installed, falls back to built-in tools)
3. Tier classification: T1 (codebase-resolved) → auto-decide, T2 (best-practice-resolved) → auto-decide, T3 (subjective) → ask human
4. Advisory sub-agents argue opposing perspectives for T3 items
5. Persistent questioning with why-digging and tension detection
6. Output: decision table + clarified requirement

**--light mode** (direct Q&A):
- Iterative questioning via AskUserQuestion
- Why-digging on surface-level answers
- Tension detection between answers
- Before/After comparison output

**Key features**:
- Researches autonomously before asking — only asks about genuinely subjective decisions
- Integrates with gather-context for research (graceful fallback when not installed)
- Persistent questioning: why-digs 2-3 levels, detects contradictions
- Skips advisory and questioning phases entirely when all items are resolvable
- Adapts to user's language (Korean/English)

### [deep-clarify](plugins/deep-clarify/skills/deep-clarify/SKILL.md)

> **DEPRECATED**: This plugin has been superseded by [clarify](#clarify) v2, which includes all research-first functionality plus persistent questioning.

**Migration**:
```bash
claude plugin install clarify@corca-plugins
claude plugin update clarify@corca-plugins
```

**Command mapping**:
| Old (deep-clarify) | New (clarify) |
|---|---|
| `/deep-clarify <requirement>` | `/clarify <requirement>` |

### [interview](plugins/interview/skills/interview/SKILL.md)

> **DEPRECATED**: This plugin has been superseded by [clarify](#clarify) v2, which incorporates interview's persistent questioning methodology (why-digging, tension detection).

**Migration**:
```bash
claude plugin install clarify@corca-plugins
claude plugin update clarify@corca-plugins
```

**Command mapping**:
| Old (interview) | New (clarify) |
|---|---|
| `/interview <topic>` | `/clarify <requirement>` (default mode) |
| `/interview <topic>` (quick) | `/clarify <requirement> --light` |

### [suggest-tidyings](plugins/suggest-tidyings/skills/suggest-tidyings/SKILL.md)

**Install**: `claude plugin install suggest-tidyings@corca-plugins` | **Update**: `claude plugin update suggest-tidyings@corca-plugins`

A skill based on Kent Beck's "Tidy First?" philosophy. It analyzes recent commits and finds safe refactoring opportunities. It uses parallel sub-agents to review multiple commits at once.

**Usage**:
- Analyze the current branch: `/suggest-tidyings`
- Analyze a specific branch: `/suggest-tidyings develop`

**Key features**:
- Finds tidying opportunities from recent non-tidying commits
- Parallel per-commit analysis (Task tool + sub-agents)
- Applies 8 tidying techniques (guard clauses, dead code removal, extract helper, etc.)
- Safety check: excludes code that has already changed on HEAD
- Actionable suggestions in the format `file:line-range — description (reason: ...)`

**Core principles**:
- Safe changes that only improve readability (no logic changes)
- Atomic edits that can be separated into a single commit
- Simple diffs that are easy for anyone to review

### [retro](plugins/retro/skills/retro/SKILL.md)

**Install**: `claude plugin install retro@corca-plugins` | **Update**: `claude plugin update retro@corca-plugins`

Adaptive session retrospective. If `lessons.md` in the [Plan & Lessons Protocol](plugins/plan-and-lessons/protocol.md) is a progressively accumulated learning log, `retro` is a "full-session, bird's-eye" retrospective. Light by default (fast, low cost); use `--deep` for full expert analysis.

**Usage**:
- End of a session (light): `/retro`
- Full analysis with expert lens: `/retro --deep`
- With a specific directory: `/retro prompt-logs/260130-my-session`

**Modes**:
- **Light** (default): Sections 1-4 + 7. No sub-agents, no web search. Agent auto-selects based on session weight.
- **Deep** (`--deep`): Full 7 sections including Expert Lens (parallel sub-agents) and Learning Resources (web search).

**Key features**:
- Documents user/org/project context that will help future work
- Observes working style and collaboration patterns and suggests CLAUDE.md updates (applies only with user approval)
- Waste Reduction analysis: identifies wasted turns, over-engineering, missed shortcuts, context waste, and communication inefficiencies
- Analyzes critical decisions using Gary Klein's CDM (Critical Decision Method) with session-specific probes
- Expert Lens (deep only): parallel sub-agents adopt real expert identities to analyze the session through contrasting frameworks
- Learning Resources (deep only): web-searched resources tailored to the user's knowledge level
- Scans installed skills for relevance before suggesting external skill discovery

**Outputs**:
- `prompt-logs/{YYMMDD}-{NN}-{title}/retro.md` — saved alongside plan.md and lessons.md

### [gather-context](plugins/gather-context/skills/gather-context/SKILL.md)

**Install**: `claude plugin install gather-context@corca-plugins` | **Update**: `claude plugin update gather-context@corca-plugins`

Unified information acquisition layer with three modes: URL auto-detect, web search, and local codebase exploration. Absorbs all `web-search` functionality — a single plugin for all external information needs. Built-in converters for Google Docs, Slack, Notion, and GitHub content. Uses Tavily and Exa APIs for search.

**Usage**:
- URL gathering: `/gather-context <url>` (auto-detects Google, Slack, Notion, GitHub, or generic web)
- Web search: `/gather-context --search <query>` (Tavily)
- Code search: `/gather-context --search code <query>` (Exa)
- News/deep: `/gather-context --search --news <query>`, `/gather-context --search --deep <query>`
- Local exploration: `/gather-context --local <topic>`
- Help: `/gather-context` or `/gather-context help`

**Supported URL services**:

| URL pattern | Handler |
|----------|--------|
| `docs.google.com/{document,presentation,spreadsheets}/d/*` | Google Export (built-in script) |
| `*.slack.com/archives/*/p*` | Slack to MD (built-in script) |
| `*.notion.site/*`, `www.notion.so/*` | Notion to MD (built-in script) |
| `github.com/*/pull/*`, `github.com/*/issues/*` | GitHub (`gh` CLI) |
| Other URLs | Tavily extract → WebFetch fallback |

**Output directory**: default `./gathered/` (override with `CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR`; per-service env vars also supported)

**Requirements**:
- `TAVILY_API_KEY` — web search and URL extraction ([get a key](https://app.tavily.com/home))
- `EXA_API_KEY` — code search ([get a key](https://dashboard.exa.ai/api-keys))
- Set keys in `~/.zshrc` or `~/.claude/.env`

**Built-in WebSearch redirect** (Hook):
- Installing this plugin registers a `PreToolUse` hook that blocks Claude's built-in `WebSearch` tool and redirects to `/gather-context --search`.

**Caution**:
- Search queries are sent to external services. Do not include confidential code or sensitive information.

### [web-search](plugins/web-search/skills/web-search/SKILL.md)

> **DEPRECATED**: This plugin has been superseded by [gather-context](#gather-context) v2, which includes all web search, code search, and URL extraction functionality.

**Migration**:
```bash
claude plugin install gather-context@corca-plugins
claude plugin update gather-context@corca-plugins
# Optionally remove web-search to avoid duplicate hooks:
# claude plugin uninstall web-search@corca-plugins
```

**Command mapping**:
| Old (web-search) | New (gather-context) |
|---|---|
| `/web-search <query>` | `/gather-context --search <query>` |
| `/web-search code <query>` | `/gather-context --search code <query>` |
| `/web-search --news <query>` | `/gather-context --search --news <query>` |
| `/web-search --deep <query>` | `/gather-context --search --deep <query>` |
| `/web-search extract <url>` | `/gather-context <url>` |

## Hooks

### [attention-hook](plugins/attention-hook/README.md)

**Install**: `claude plugin install attention-hook@corca-plugins` | **Update**: `claude plugin update attention-hook@corca-plugins`

Slack notifications with threading when Claude Code is waiting for input. All notifications from a single session are grouped into one Slack thread, keeping your channel clean. Useful when running on a remote server. (Background: [blog post](https://www.stdy.blog/1p1w-03-attention-hook/))

**Key features**:
- **Thread grouping**: first user prompt creates a parent message; subsequent notifications appear as thread replies
- **Idle notification**: when Claude waits 60+ seconds for input (`idle_prompt`)
- **AskUserQuestion notification**: when Claude asks a question and gets no response for 30+ seconds (`CLAUDE_ATTENTION_DELAY`)
- **Plan mode notification**: when Claude enters or exits plan mode and gets no response for 30+ seconds
- **Heartbeat status**: periodic updates during long autonomous operations (5+ min idle)
- **Backward compatible**: falls back to webhook (no threading) if only `SLACK_WEBHOOK_URL` is set

> **Compatibility note**: this script parses Claude Code's internal transcript structure using `jq`. It may break when Claude Code updates. See the script comments for the tested version info.

**Requirements**:
- `jq` installed (for JSON parsing)
- Slack App with `chat:write` + `im:write` scopes (recommended) or Incoming Webhook URL

**Setup** (Slack App — enables threading):

1. Create a Slack App at [api.slack.com/apps](https://api.slack.com/apps), add `chat:write` and `im:write` scopes, install to workspace
2. Get the channel ID: open a DM with your bot → click the bot name → copy the Channel ID (starts with `D`). For channels, use `/invite @YourBotName` first.
3. Create `~/.claude/.env`:
```bash
# ~/.claude/.env
SLACK_BOT_TOKEN="xoxb-your-bot-token"
SLACK_CHANNEL_ID="D0123456789"  # Bot DM channel (or C... for channels)
CLAUDE_ATTENTION_DELAY=30  # AskUserQuestion notification delay in seconds (default: 30)
```

For legacy webhook setup (no threading), set `SLACK_WEBHOOK_URL` instead. See [plugin README](plugins/attention-hook/README.md) for details.

**Notification contents**:
- 📝 User request (first/last 5 lines, truncated)
- 🤖 Claude response (first/last 5 lines, truncated)
- ❓ Waiting on a question: AskUserQuestion prompt + choices (if any)
- ✅ Todo: counts of done/in-progress/pending items and their text
- 💓 Heartbeat: periodic status with todo progress during long tasks

**Examples**:

<img src="assets/attention-hook-normal-response.png" alt="Slack notification example 1 - normal response" width="600">

<img src="assets/attention-hook-AskUserQuestion.png" alt="Slack notification example 2 - AskUserQuestion" width="600">

### [plan-and-lessons](plugins/plan-and-lessons/hooks/hooks.json)

**Install**: `claude plugin install plan-and-lessons@corca-plugins` | **Update**: `claude plugin update plan-and-lessons@corca-plugins`

A hook that automatically injects the Plan & Lessons Protocol when Claude Code enters plan mode (via the `EnterPlanMode` tool call). The protocol defines a workflow that creates plan.md and lessons.md under `prompt-logs/{YYMMDD}-{NN}-{title}/`.

**How it works**:
- Uses a `PreToolUse` → `EnterPlanMode` matcher to detect plan-mode entry
- Injects the protocol document path via `additionalContext`
- Claude reads the protocol and follows it

**Notes**:
- If you enter plan mode directly via `/plan` or Shift+Tab, the hook won't fire (CLI mode toggle; no tool call happens)
- For better coverage, also referencing the protocol from `CLAUDE.md` is recommended

### [smart-read](plugins/smart-read/hooks/hooks.json)

**Install**: `claude plugin install smart-read@corca-plugins` | **Update**: `claude plugin update smart-read@corca-plugins`

A hook that intercepts Read tool calls and enforces intelligent file reading based on file size. Prevents context waste by warning on medium files and blocking full reads on large files, guiding Claude to use offset/limit or Grep instead.

**How it works**:
- Uses a `PreToolUse` → `Read` matcher to intercept file reads
- Checks file size (line count) before allowing full reads
- Small files (≤500 lines): allowed silently
- Medium files (500-2000 lines): allowed with `additionalContext` showing line count
- Large files (>2000 lines): denied with guidance to use `offset`/`limit` or `Grep`
- Binary files (PDF, images, notebooks): always allowed (Read handles these natively)

**Bypass**: Claude can bypass the deny by setting `offset` or `limit` explicitly — the hook only blocks when both are absent, so intentional partial reads always go through.

**Configuration** (optional):

Set thresholds in `~/.claude/.env`:
```bash
# ~/.claude/.env
CLAUDE_CORCA_SMART_READ_WARN_LINES=500   # Lines above which additionalContext is added (default: 500)
CLAUDE_CORCA_SMART_READ_DENY_LINES=2000  # Lines above which read is denied (default: 2000)
```

### [prompt-logger](plugins/prompt-logger/README.md)

**Install**: `claude plugin install prompt-logger@corca-plugins` | **Update**: `claude plugin update prompt-logger@corca-plugins`

A hook that auto-logs every conversation turn to markdown files. Uses `Stop` and `SessionEnd` hooks to incrementally capture turns as they happen — no model involvement, pure bash + jq processing.

**How it works**:
- `Stop` hook fires when Claude finishes responding → logs the completed turn
- `SessionEnd` hook fires on exit/clear → catches any unlogged final content
- Both call the same idempotent script with offset-based incremental processing

**Output**: One markdown file per session at `{cwd}/prompt-logs/sessions/{date}-{hash}.md`, containing:
- Session metadata (model, branch, CWD, Claude Code version)
- Each turn with timestamps, duration, and token usage
- Full user prompts (with `[Image]` placeholders for images)
- Truncated assistant responses (first 5 + last 5 lines if > threshold)
- Tool call summaries (tool name + key parameter)

**Configuration** (optional):

Set in `~/.claude/.env`:
```bash
# ~/.claude/.env
CLAUDE_CORCA_PROMPT_LOGGER_DIR="/custom/path"        # Output directory (default: {cwd}/prompt-logs/sessions)
CLAUDE_CORCA_PROMPT_LOGGER_ENABLED=false              # Disable logging (default: true)
CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=20                # Truncation threshold in lines (default: 10)
```

## Removed skills

The following skills were removed in v1.8.0. The same functionality is now built into [gather-context](#gather-context).

| Removed skill | Replacement |
|------------|------|
| `g-export` | `gather-context` (built-in Google Docs/Slides/Sheets) |
| `slack-to-md` | `gather-context` (built-in Slack thread export) |
| `notion-to-md` | `gather-context` (built-in Notion page export) |

**Migration**:
```bash
claude plugin install gather-context@corca-plugins
```

## License

MIT
