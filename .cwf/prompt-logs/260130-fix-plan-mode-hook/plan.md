# Fix Plan Mode Hook

## Context

The project had a `PreToolUse` hook on `EnterPlanMode` using `type: "prompt"` intended to inject a reminder to follow the Plan & Lessons Protocol. Testing revealed this didn't work as expected.

## Success Criteria

```gherkin
Given the project .claude/settings.json has a PreToolUse hook on EnterPlanMode
When the assistant calls the EnterPlanMode tool
Then the assistant receives additionalContext with the Plan & Lessons Protocol reminder

Given the hook uses type "command" with JSON additionalContext output
When the echo command runs
Then the hookSpecificOutput.additionalContext is injected into the assistant's context
```

## What Was Done

1. Discovered `type: "prompt"` sends the prompt to Haiku for ok/block evaluation — does NOT inject text into the assistant's context
2. Changed to `type: "command"` outputting JSON with `hookSpecificOutput.additionalContext`
3. Verified with `HOOK_TEST_MARKER_7X9Q` — assistant confirmed receiving the marker
4. Tested `/plan` (user-initiated) — confirmed it does NOT trigger `EnterPlanMode` tool, so the hook only covers assistant-initiated plan mode entry
5. Removed unnecessary `UserPromptSubmit` hook and `.claude/hooks/plan-mode-prompt.sh`

## Final Configuration

`.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "EnterPlanMode",
      "hooks": [{
        "type": "command",
        "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"READ and FOLLOW the Plan & Lessons Protocol (docs/plan-and-lessons.md).\"}}'"
      }]
    }]
  }
}
```

## Deferred Actions

- [ ] Consider covering user-initiated plan mode (`/plan`, Shift+Tab) if Claude Code adds a hook event for mode toggles in the future
