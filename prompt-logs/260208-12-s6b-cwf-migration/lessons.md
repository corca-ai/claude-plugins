# S6b Lessons

### attention.sh BASH_SOURCE guard removal

- **Expected**: Simply remove the `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then` wrapper and unindent
- **Actual**: Straightforward — the guard existed for sourcing in tests (attention.test.sh). CWF scripts are only executed, never sourced for testing, so the guard is unnecessary.
- **Takeaway**: CWF migration pattern simplifies scripts by removing the source/execute dual-mode pattern.

### slack-send.sh as sourced utility

- **Expected**: Need to adjust paths or add gate
- **Actual**: No changes needed — slack-send.sh is a pure function library with no `set -euo pipefail` at top level (correctly follows cheatsheet guidelines for sourced scripts). BASH_SOURCE guard only for `--diagnose` mode.

When migrating sourced utilities → copy verbatim, no gate needed.

### shellcheck not installed on this machine

- **Expected**: check-shell.sh test would catch shellcheck violations
- **Actual**: shellcheck not installed, so the `command -v` check correctly causes silent exit 0
- **Takeaway**: Graceful degradation works as designed. For full integration testing, shellcheck needs to be installed.

### track-user-input.sh uses `[ -z "$CWD" ] && CWD="$PWD"` pattern

- **Expected**: Per cheatsheet, `&&` chains under `set -e` are problematic
- **Actual**: Changed to `if [ -z "$CWD" ]; then CWD="$PWD"; fi` pattern during migration for safety under `set -e`
