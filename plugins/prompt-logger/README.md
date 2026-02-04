# prompt-logger

A hook-only plugin that auto-logs every conversation turn to markdown files for retrospective analysis.

## How It Works

The plugin uses `Stop` and `SessionEnd` hooks to incrementally capture conversation turns:

| Hook | When | Purpose |
|------|------|---------|
| `Stop` | Claude finishes responding | Log the completed turn |
| `SessionEnd` | Exit/clear/Ctrl+C | Catch any unlogged final content |

Both hooks call the same idempotent script. If `Stop` already logged everything, `SessionEnd` finds no new lines and exits fast.

## Output

Each session produces one markdown file at `{cwd}/prompt-logs/sessions/{date}-{hash}.md`:

```markdown
# Session: abc12345
Model: claude-opus-4-5-20251101 | Branch: main
CWD: /Users/ted/codes/project
Started: 2026-02-04 14:30:00 | Claude Code v2.1.31

---
## Turn 1 [14:30:05 → 14:31:22] (77s) | Tokens: 5394↑ 1283↓

### User
Fix the login bug in auth.ts

### Assistant (15 lines → truncated)
first 5 lines...

...(5 lines truncated)...

last 5 lines...

### Tools
1. Read `/src/auth/login.ts`
2. Bash `git log --oneline -5`
3. Task[Explore] "find auth error handlers"
4. Edit `/src/auth/login.ts`
```

### Features

- **Incremental logging** — only new JSONL entries are processed each time
- **Turn grouping** — user message + all assistant responses grouped as one turn
- **Tool summaries** — each tool shows name + key parameter (file path, command, pattern, etc.)
- **Text truncation** — long assistant responses show first 5 + last 5 lines
- **Image handling** — image content replaced with `[Image]`
- **Thinking blocks** — skipped entirely
- **Race-safe** — atomic mkdir lock prevents concurrent Stop/SessionEnd conflicts
- **Auto-commit** — session log is committed automatically at session end (no untracked leftovers)

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CORCA_PROMPT_LOGGER_DIR` | `{cwd}/prompt-logs/sessions` | Output directory |
| `CLAUDE_CORCA_PROMPT_LOGGER_ENABLED` | `true` | Enable/disable logging |
| `CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE` | `10` | Line threshold for assistant text truncation |
| `CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT` | `true` | Auto-commit session log at session end |

Set in `~/.claude/.env` or shell profile:

```bash
export CLAUDE_CORCA_PROMPT_LOGGER_DIR="$HOME/prompt-logs"
export CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=20
```

## Install

```bash
claude mcp add-plugin prompt-logger ./plugins/prompt-logger
```

Or via marketplace:

```bash
claude plugin install prompt-logger
```

## Dependencies

- `bash`, `jq` (standard on macOS/Linux)
- No model involvement — pure bash processing
