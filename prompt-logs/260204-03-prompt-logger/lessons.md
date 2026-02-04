# Lessons: prompt-logger Plugin

## Implementation Lessons

1. **`date -j` stdout leak**: Using `if date -j ... 2>/dev/null; then` as a test condition prints the date to stdout even when used inside an if statement. The `if` tests the exit code, but stdout still goes through. Fix: always capture via `$(...)` command substitution with `||` fallback chain instead.

2. **State file cleanup between tests**: `/tmp/` state files persist between test runs. The offset file from a previous run causes the script to think everything is already logged. Always clean state dir before testing, or use unique session IDs.

3. **JSONL transcript structure**: Claude Code JSONL entries have these key types:
   - `type: "user"` with `message.content` as string (user text) or array (with text/image blocks)
   - `type: "assistant"` with `message.content` as array containing `text`, `tool_use`, and `thinking` blocks
   - `isMeta: true` for system-injected entries (should be skipped for turn grouping)
   - Snapshot entries (`isSnapshotUpdate`) exist but are filtered by the user/assistant type filter

4. **Token fields**: `message.usage.input_tokens` and `message.usage.output_tokens` are the key fields. Cache-related fields (`cache_creation_input_tokens`, `cache_read_input_tokens`) exist but aren't needed for basic turn logging.

5. **Stop + SessionEnd hooks both provide**: `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`. SessionEnd also has `reason` field.
