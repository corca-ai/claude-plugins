# SoT Audit — README Claims vs Implementation

## Scope

Audited claims in `README.md` / `README.ko.md` related to:
- SoT policy alignment
- Context-deficit resilience
- Run-stage workflow gating
- Repo-agnostic and first-run contract behavior
- Scope-aware setup/codex integration

## Claim Matrix

| Claim | Evidence Checked | Status | Action |
|---|---|---|---|
| README.ko is user-facing SoT and implementation should match policy | README disclaimer + runtime hooks/scripts behavior | Partially mismatched before audit | Fixed concrete mismatches below |
| Context-deficit resilience survives compact/restart via persisted state | `plugins/cwf/hooks/scripts/compact-context.sh` | Risk found (jq hard dependency could break output) | Added dependency-degraded fallback output/extraction path |
| Workflow gate blocks ship/push/merge while run-stage gates unresolved | `plugins/cwf/hooks/scripts/workflow-gate.sh` | Mismatch found (only `review-code` checked) | Expanded to all run-closing gates (`review-code`, `refactor`, `retro`, `ship`) |
| Setup remains portable/adaptive across repositories | `plugins/cwf/scripts/next-prompt-dir.sh`, setup contract scripts | Risk found (root resolution fallback could bind to plugin host path) | Root resolution changed to caller-cwd ancestry with fail-fast on unresolved root |
| First-run setup contract status semantics (`created|existing|updated|fallback`) are deterministic | `bootstrap-setup-contract.sh`, `check-setup-contract-runtime.sh` | Verified | Runtime check passed |
| Scope-aware codex integration (`local > project > user`) with explicit guardrails | `detect-plugin-scope.sh`, setup SKILL/references, codex scripts | Verified in current contracts/docs | No code change required |

## Changes Applied

1. `plugins/cwf/hooks/scripts/workflow-gate.sh`
- Added run-closing gate set and pending-gate aggregation.
- Protected actions now blocked whenever any closing gate remains unresolved.

2. `plugins/cwf/hooks/scripts/compact-context.sh`
- Added `json_escape_string` and `extract_input_field` helpers.
- Added fallback JSON output path when `jq` is unavailable.
- Kept best-effort parsing behavior to avoid fail-closed compact context loss.

3. `plugins/cwf/scripts/next-prompt-dir.sh`
- Root resolver now prefers caller working-directory context.
- Supports explicit override via `CWF_PROJECT_ROOT`.
- Keeps compatibility fallback by walking script-location ancestors when caller cwd is outside the target repo.

4. `plugins/cwf/skills/run/SKILL.md`
- Corrected completion-phase provenance parsing to read `Gate Outcome` from the correct table column so skipped closing stages are not treated as executed.

5. `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh`
- Added fallback behavior for missing `sha256sum/shasum` and missing `perl` to avoid hard failure during hook rendering in dependency-degraded environments.

## Residual Notes

- Setup-contract repo-specific tool suggestion flow is documented as an explicit approval path in setup skill/reference contracts; runtime contract checks remain green.
- All modifications were rechecked with deterministic tooling and runtime contract checks.
