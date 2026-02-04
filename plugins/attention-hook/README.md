# attention-hook

Slack notifications with threading when Claude Code is waiting for input.

All notifications from a single session are grouped into one Slack thread, keeping your channel clean even with multiple concurrent sessions.

## Features

- **Thread grouping**: First user prompt creates a parent message; all subsequent notifications appear as thread replies (also broadcast to channel for notifications)
- **Idle notification**: When Claude waits 60+ seconds for user input (`idle_prompt`)
- **AskUserQuestion notification**: When Claude asks a question and gets no response for 30+ seconds
- **Plan mode notification**: When Claude enters or exits plan mode and gets no response for 30+ seconds
- **Heartbeat status**: Periodic status updates during long autonomous operations (5+ min idle)
- **Backward compatible**: Falls back to webhook (no threading) if only `SLACK_WEBHOOK_URL` is configured

## Setup

### Option A: Slack App (Recommended — enables threading)

1. **Create a Slack App** at [api.slack.com/apps](https://api.slack.com/apps):
   - Click "Create New App" → "From scratch"
   - Name it (e.g., "Claude Code") and select your workspace

2. **Add Bot Token Scopes** under "OAuth & Permissions":
   - `chat:write` — post messages
   - `im:write` — send DM notifications

3. **Install the App** to your workspace (OAuth & Permissions → Install to Workspace)

4. **Copy the Bot Token** (`xoxb-...`) from the OAuth & Permissions page

5. **Get the Channel ID**:
   - **For DM notifications**: Open a DM with your bot in Slack → click the bot name at top → copy the Channel ID (starts with `D`)
   - **For channel notifications**: Right-click the channel → "View channel details" → copy the Channel ID (starts with `C`)
   - **Note**: Do NOT use your self-DM channel ID — use the DM channel between you and the bot

6. **Invite the bot** to the channel (skip for DM):
   ```
   /invite @Claude Code
   ```

7. **Configure** `~/.claude/.env`:
   ```bash
   SLACK_BOT_TOKEN="xoxb-your-bot-token"
   SLACK_CHANNEL_ID="D0123456789"  # Bot DM channel ID (or C... for channels)
   ```

### Option B: Incoming Webhook (Legacy — no threading)

1. Create a Slack Incoming Webhook at [api.slack.com/messaging/webhooks](https://api.slack.com/messaging/webhooks)

2. Configure `~/.claude/.env`:
   ```bash
   SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
   ```

### Install the plugin

```bash
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git
claude plugin install attention-hook@corca-plugins
```

Restart Claude Code after installing.

## How it works

### Message flow

```
User enters first prompt
  → track-user-input.sh posts parent message to Slack
  → Saves message ts for threading

Claude works autonomously for 5+ minutes
  → heartbeat.sh sends threaded status update with todo progress

Claude finishes and waits 60s
  → attention.sh sends threaded notification with full context
```

### Hook registrations

| Event | Script | Mode |
|-------|--------|------|
| `UserPromptSubmit` | `track-user-input.sh` | async |
| `Notification:idle_prompt` | `attention.sh` | async |
| `PreToolUse:AskUserQuestion` | `start-timer.sh` | sync |
| `PostToolUse:AskUserQuestion` | `cancel-timer.sh` | sync |
| `PreToolUse:EnterPlanMode` | `start-timer.sh` | sync |
| `PostToolUse:EnterPlanMode` | `cancel-timer.sh` | sync |
| `PreToolUse:ExitPlanMode` | `start-timer.sh` | sync |
| `PostToolUse:ExitPlanMode` | `cancel-timer.sh` | sync |
| `PreToolUse:*` | `heartbeat.sh` | async |

### Session-scoped state

Each session uses isolated state files at `/tmp/claude-attention-{hash}-*`:

| File | Purpose |
|------|---------|
| `thread-ts` | Slack message ts for threading |
| `last-user-ts` | Epoch of last user interaction |
| `heartbeat-ts` | Epoch of last heartbeat sent |
| `timer.pid` | Background timer PID (AskUserQuestion / plan mode) |
| `thread-lock/` | Atomic lock directory for thread creation |
| `input.json` | Cached hook input for timer |
| `last-hash` | Deduplication hash |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SLACK_BOT_TOKEN` | — | Bot token (`xoxb-...`) for Web API |
| `SLACK_CHANNEL_ID` | — | Channel ID for `chat.postMessage` |
| `SLACK_WEBHOOK_URL` | — | Legacy webhook (fallback, no threading) |
| `CLAUDE_ATTENTION_DELAY` | `30` | AskUserQuestion / plan mode notification delay (seconds) |
| `CLAUDE_ATTENTION_HEARTBEAT_USER_IDLE` | `300` | User idle time before heartbeat activates (seconds) |
| `CLAUDE_ATTENTION_HEARTBEAT_INTERVAL` | `300` | Minimum interval between heartbeats (seconds) |

## Requirements

- `jq` (JSON parsing)
- `bash` 4+
- `curl`

## Compatibility

This plugin parses Claude Code's internal transcript format via `jq`. The format is not a public API and may change between Claude Code versions. See script comments for tested version info.

## Troubleshooting

Run the built-in diagnostics to verify your Slack configuration:

```bash
./hooks/scripts/slack-send.sh --diagnose
```

This checks: env file, token validity, channel access, and sends a test message.

## Running tests

```bash
./hooks/scripts/attention.test.sh
```
