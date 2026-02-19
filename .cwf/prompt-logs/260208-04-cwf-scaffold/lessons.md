# S4 Lessons — CWF Scaffold

## Implementation Learnings

### Gate mechanism — sourced script exit behavior
The `exit 0` in cwf-hook-gate.sh terminates the *calling* script (since it's sourced, not executed). This is the intended design — when a hook group is disabled, the entire hook script exits immediately. Verified this works correctly: disabled hooks exit 0 silently, enabled hooks continue past the gate.

### hooks.json — combining multiple hooks per matcher
EnterPlanMode PreToolUse entry has two hooks in its array: `start-timer.sh` (attention) + `enter-plan-mode.sh` (plan protocol). This is the correct pattern for combining hooks from different source plugins into one matcher entry. Similarly, `Write|Edit` PostToolUse combines `check-markdown.sh` + `check-shell.sh`.

### Stub pattern for incremental migration
All 11 stub scripts follow identical structure: shebang → strict mode → set HOOK_GROUP → source gate → consume stdin → exit 0. This makes S6 migration straightforward — replace the `cat > /dev/null; exit 0` with actual logic from source plugins.

### printenv for Bash 3.2 compatibility
Used `printenv "$_CWF_FLAG_NAME"` instead of `${!var}` (nameref) in the gate script. This is critical for macOS compatibility where Bash 3.2 is the default.
