# S6b: Migrate Attention Hook + check-shell.sh + enter-plan-mode.sh into CWF

## Steps

- [x] Copy utility scripts (slack-send.sh, parse-transcript.sh)
- [x] Migrate attention.sh (remove BASH_SOURCE guard, flatten)
- [x] Migrate start-timer.sh, cancel-timer.sh, heartbeat.sh, track-user-input.sh
- [x] Copy protocol.md → references/plan-protocol.md
- [x] Migrate enter-plan-mode.sh
- [x] Implement check-shell.sh (new, follows check-markdown.sh pattern)
- [x] chmod +x all new/modified scripts
- [x] Verification (diffs + functional tests)
- [x] Bump plugin.json version (0.1.0 → 0.2.0)
