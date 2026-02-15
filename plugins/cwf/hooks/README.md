# Hooks Script Map

This file maps scripts under [plugins/cwf/hooks/scripts](scripts).

- [scripts/cwf-hook-gate.sh](scripts/cwf-hook-gate.sh): Shared enable/disable gate used by all hook scripts.
- [scripts/attention.sh](scripts/attention.sh): Sends attention notifications (idle and waiting states).
- [scripts/start-timer.sh](scripts/start-timer.sh): Starts waiting timer before `AskUserQuestion`.
- [scripts/cancel-timer.sh](scripts/cancel-timer.sh): Cancels waiting timer after `AskUserQuestion`.
- [scripts/heartbeat.sh](scripts/heartbeat.sh): Emits async heartbeat metadata during tool usage.
- [scripts/track-user-input.sh](scripts/track-user-input.sh): Records user prompt metadata.
- [scripts/log-turn.sh](scripts/log-turn.sh): Persists turn/session logs with sensitive token redaction.
- [scripts/parse-transcript.sh](scripts/parse-transcript.sh): Parses transcript structure for logging and exports.
- [scripts/read-guard.sh](scripts/read-guard.sh): Read guard for large files.
- [scripts/redirect-websearch.sh](scripts/redirect-websearch.sh): Redirects native web search flow to CWF gather flow.
- [scripts/check-markdown.sh](scripts/check-markdown.sh): Runs markdown lint checks after write/edit.
- [scripts/check-links-local.sh](scripts/check-links-local.sh): Runs local link checks for edited markdown files and blocks on broken links.
- [scripts/check-shell.sh](scripts/check-shell.sh): Runs shell lint checks after write/edit.
- [scripts/compact-context.sh](scripts/compact-context.sh): Injects live session state after compact recovery.
- [scripts/env-loader.sh](scripts/env-loader.sh): Loads environment variables for hook runtime.
- [scripts/slack-send.sh](scripts/slack-send.sh): Sends Slack webhook notifications.
- [scripts/text-format.sh](scripts/text-format.sh): Shared text formatting helpers for hook output.
