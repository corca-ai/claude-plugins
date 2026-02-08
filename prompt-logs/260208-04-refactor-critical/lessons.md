# S1: Refactor Critical Fixes — Lessons

## Implementation Learnings

1. **`jq -Rs .` includes trailing newline from `echo`**: When using `echo "$var" | jq -Rs .` to encode a string as JSON, `echo` appends `\n` which gets included in the output (e.g., `"value\n"` instead of `"value"`). Use `printf '%s' "$var" | jq -Rs .` instead. For arrays, the `printf '%s\n' "${arr[@]}" | jq -Rs '[split("\n")[:-1][]]'` pattern works correctly because the trailing newline is handled by `[:-1]`.

2. **`set -euo pipefail` in sourced scripts**: When a script is designed to be both sourced (for testing) and executed directly, `set -euo pipefail` should go inside the `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` guard, not at the top level. Otherwise, it propagates strict mode to all callers (same reason `slack-send.sh` was excluded from strict mode addition).

3. **`|| true` placement matters with `&&` chains**: The pattern `[ -z "$VAR" ] && eval "..." || true` doesn't protect the eval from `set -e` — the `|| true` only catches the entire chain failure, not the eval itself. This was the original unsafe pattern in prompt-logger that masked eval failures.

4. **`grep -shm1` is the safe extraction pattern**: `-s` suppresses errors, `-h` suppresses filenames, `-m1` stops after first match. Combined with parameter expansion `${_line#*=}` and quote stripping `${VAR#[\"\']}` / `${VAR%[\"\']}`, this provides eval-free config loading.

5. **`find -mmin +1` is portable**: Works on both macOS and Linux for stale lock detection. The lock dir's mtime updates on creation, so `find -mmin +1` correctly identifies locks older than 1 minute.

## Deferred Items

- prompt-logger stale lock cleanup (same pattern as attention-hook, lower risk)
- check-consistency.sh heredoc string interpolations (controlled values, low priority)
- gather-context scripts (g-export.sh, csv-to-toon.sh, slack-to-md.sh) still use `#!/bin/bash` — not in scope for this session
