# Portability Audit Details — CWF Skills

## clarify
- Status: Remediated
- Finding: Mode selection treated `next-session.md` as a default read input.
- Risk: Fresh repos/sessions without handoff artifacts could be over-coupled to prior-session file presence.
- Hardening:
  - `plugins/cwf/skills/clarify/SKILL.md`: Mode selection now treats `next-session.md` as optional context and always parses user-provided requirement input.

## gather
- Status: Remediated
- Finding: Output write path behavior was described but not explicitly guarded for missing/non-writable default directories.
- Risk: Runtime layout variance could cause write failures before artifacts are produced.
- Hardening:
  - `plugins/cwf/skills/gather/SKILL.md`: Added explicit output-dir resolution order, writable fallback (`./gather-output`), mandatory `mkdir -p`, and error-handling prompt behavior.

## handoff
- Status: Remediated
- Finding: Next/phase handoff context rules required AGENTS/cheatsheet/state files unconditionally.
- Risk: Repositories without those files would fail strict assumptions instead of degrading.
- Hardening:
  - `plugins/cwf/skills/handoff/SKILL.md`: Core context files are now included when present; missing files must be recorded and processing continues.

## hitl
- Status: Pass
- Finding: None requiring remediation under Criterion 9.

## impl
- Status: Pass
- Finding: None requiring remediation under Criterion 9.

## plan
- Status: Pass
- Finding: None requiring remediation under Criterion 9.

## review
- Status: Remediated
- Finding: Quick-reference example used repository-specific base branch (`marketplace-v3`).
- Risk: Encodes host-repo policy into generic usage guidance.
- Hardening:
  - `plugins/cwf/skills/review/SKILL.md`: Replaced with generic `--base <base-branch>` example.

## run
- Status: Pass
- Finding: None requiring remediation in this phase.

## retro
- Status: Pass
- Finding: None requiring remediation in this phase.

## setup
- Status: Remediated
- Finding: Repository index output guidance was AGENTS-only.
- Risk: Contractless assumption for repos without AGENTS-managed index usage.
- Hardening:
  - `plugins/cwf/skills/setup/SKILL.md`: Added explicit `--target <agents|file|both>` routing.
  - `plugins/cwf/skills/setup/references/runtime-and-index-phases.md`: Added context-aware target resolution, dual-target write flow, and per-target coverage validation.

## ship
- Status: Remediated
- Finding: Base branch default was hardcoded to `main`.
- Risk: Breakage on repositories using `master`, `trunk`, or custom defaults.
- Hardening:
  - `plugins/cwf/skills/ship/SKILL.md`: Defaults and workflows now resolve base branch via `origin/HEAD` then `main` then `master`, with user prompt fallback.

## update
- Status: Remediated
- Finding: Marketplace cache lookup used hardcoded `~/.claude/plugins/cache` only.
- Risk: Non-default Claude home/cache locations fail metadata resolution.
- Hardening:
  - `plugins/cwf/skills/update/SKILL.md`: Cache lookup now uses `CLAUDE_HOME`-aware roots with explicit fallback guidance.
  - `plugins/cwf/skills/update/references/scope-reconcile.md`: Added Phase 1 cache-resolution details for consistent execution.

## Cross-Cutting Runtime Check
- Status: Added
- Gap addressed: executable E2E check for docs-contract parsing/runtime behavior under `cwf:refactor --docs`.
- Added files/updates:
  - `plugins/cwf/skills/refactor/scripts/check-docs-contract-runtime.sh`
  - `plugins/cwf/skills/refactor/SKILL.md`
  - `plugins/cwf/skills/refactor/references/docs-review-flow.md`
  - `plugins/cwf/skills/refactor/README.md`
