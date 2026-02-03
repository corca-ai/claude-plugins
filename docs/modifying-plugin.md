# Modifying/Testing/Deploying Plugins

Workflow for modifying plugins in this repo:

## 1. Modify

- Edit files in the `plugins/<plugin-name>/` directory.
- Update the plugin version appropriately in plugin.json.

## 2. Test

Testing methods vary by plugin type:

### Hook scripts (unit test)

Test hook logic by piping JSON to stdin. This works in the current session without any installation:

```bash
# Example: test a PreToolUse hook for Read
echo '{"tool_input":{"file_path":"/path/to/file.txt"}}' | plugins/<name>/hooks/scripts/<script>.sh
```

Check exit code and stdout JSON to verify behavior.

If a dedicated test script exists (e.g., `attention-hook`), run it:
```bash
plugins/attention-hook/hooks/scripts/attention.test.sh
```

### Skills

Apply locally and run directly to verify behavior.

### Integration test (hook fires on real tool calls)

Hook plugins require Claude Code to load the hook at startup. There is no hot-reload — hooks are **snapshot at session start** (see [official docs](https://code.claude.com/docs/en/hooks)).

Options for integration testing:

1. **`--plugin-dir` (recommended)**: Start a new Claude Code session with the local plugin:
   ```bash
   claude --plugin-dir ./plugins/<name> --dangerously-skip-permissions --resume
   ```

2. **`/hooks` menu**: Add the hook manually via `/hooks` in the current session, pointing to the local script path. Changes go through a review process before taking effect.

## 3. Apply Locally

Plugins are copied to cache on installation, so you must reinstall after making changes:
```bash
/plugin install <plugin-name>@corca-plugins
```

## 4. Deploy

Once modifications are complete, commit & push. Inform users as follows:
```
The plugin has been updated. To apply:
1. /plugin marketplace update
2. /plugin install <plugin-name>@corca-plugins
```
