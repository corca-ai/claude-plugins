# Portability Audit Summary — CWF Skills

Scope: `plugins/cwf/skills/*/SKILL.md` excluding `refactor` (already covered in phase 1).
Baseline: `refactor` Criterion 9 (Repository Independence and Portability).

| Skill | Result | Action |
|---|---|---|
| clarify | Remediated | Optionalize `next-session.md` dependency; user input remains required primary signal. |
| gather | Remediated | Added output-dir resolution + writable fallback + mandatory `mkdir -p` guard. |
| handoff | Remediated | Core context files (`AGENTS.md`, `cwf-state.yaml`, cheatsheet) become presence-gated with explicit omission notes. |
| hitl | Pass | No portability-default remediation required. |
| impl | Pass | No portability-default remediation required. |
| plan | Pass | No portability-default remediation required. |
| review | Remediated | Replaced repository-specific `--base marketplace-v3` example with generic `<base-branch>`. |
| run | Pass | No additional portability remediation required in this phase. |
| retro | Pass | No additional portability remediation required in this phase. |
| setup | Remediated | Repository-index target is now context/flag-resolved (`agents|file|both`) instead of AGENTS-only assumption. |
| ship | Remediated | Base branch default changed from hardcoded `main` to auto-detection (`origin/HEAD -> main -> master`). |
| update | Remediated | Marketplace cache lookup now checks context-aware cache roots (`CLAUDE_HOME` + fallback roots). |

Cross-cutting addition:
- Added executable docs-contract runtime check for `cwf:refactor --docs`: `plugins/cwf/skills/refactor/scripts/check-docs-contract-runtime.sh`.
