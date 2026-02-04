# attention-hook v2.1.0: Bug Fixes + Plan Mode Notification

## Success Criteria

```gherkin
Given two rapid UserPromptSubmit events (user interrupts and re-types)
When both async track-user-input.sh instances run concurrently
Then only ONE Slack parent message is created (no duplicate DMs)

Given attention.sh runs on idle_prompt notification
When the script sends a Slack message and exits
Then NO 400 API error occurs (conversation is not corrupted)

Given Claude calls EnterPlanMode or ExitPlanMode
When the user does not respond within 30 seconds
Then a Slack thread reply notification is sent

Given a timer is running (from AskUserQuestion/EnterPlanMode/ExitPlanMode)
When the user interrupts and sends a new prompt (UserPromptSubmit)
Then the pending timer is cancelled (no stale notification)
```

## Changes

### ✅ Commit 1: Bug fixes (race condition + async + timer cancel)

**File: `plugins/attention-hook/hooks/scripts/track-user-input.sh`**
- Wrap thread-creation block in atomic `mkdir` lock
- Add timer cancellation after `last-user-ts` update

**File: `plugins/attention-hook/hooks/hooks.json`**
- Add `"async": true` to `Notification:idle_prompt` → `attention.sh`

### ✅ Commit 2: Plan mode notification hooks

**File: `plugins/attention-hook/hooks/hooks.json`**
- Add PreToolUse/PostToolUse hooks for EnterPlanMode and ExitPlanMode
- Reuse existing start-timer.sh / cancel-timer.sh (tool-name-agnostic)

### ✅ Commit 3: Docs + version bump

- plugin.json: 2.0.0 → 2.1.0
- Plugin README: features, hook table, state table
- Root README.md / README.ko.md: add plan mode bullet

## Deferred Actions

- [ ] None
