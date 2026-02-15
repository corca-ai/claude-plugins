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

### Handoff gap: master-plan.md roadmap not updated after S5a/S5b

- **Expected**: Each session marks its roadmap entry as "(done)" before handoff
- **Actual**: S5a and S5b completed but master-plan.md roadmap still showed them unmarked. Next session agent (S6b) had to guess project status from branch state.
- **Takeaway**: The handoff template says "edit THIS master-plan.md" but doesn't enforce roadmap status updates. Two fixes needed: (1) always mark session as "(done)" in roadmap before committing, (2) implement `cwf-state.yaml` as machine-readable SSOT so agents don't depend on scanning markdown for status. This is scheduled as the next session task.
