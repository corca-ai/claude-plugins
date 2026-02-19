# Clarify Result — Pre-release Refactor Audit

## Original Requirement
"Before public release, run a thorough sequence:
1) fix findings from `cwf:refactor --codebase`
2) run deep review for all skills and fix findings
3) run `--docs` and fix findings
4) deeply verify README SoT promises vs actual CWF behavior (especially repo-agnostic and first-run contract behavior), considering recent skill changes.
If a user decision is needed, stop and discuss trade-offs.
Start with clarify + plan, then implement, then review, then retro."

## Decision Points
1. Scope of "all skills deep": apply to `plugins/cwf/skills/*` only, not external global skills.
2. Scope of docs review: repository-wide docs, with CWF contract docs as primary focus.
3. Acceptance threshold: treat all High/Medium findings as must-fix for this session; Low findings are fixed when low-risk and localized.
4. SoT audit baseline: README/README.ko claims are normative; if code intentionally diverges, update docs and/or implementation to remove ambiguity.

## Classification and Resolution
| # | Tier | Resolution | Evidence |
|---|------|------------|----------|
| 1 | T1 | Use `plugins/cwf/skills/*` as the deep skill set | Repository structure + user wording focused on CWF plugin |
| 2 | T1 | Run docs review on whole repository; prioritize CWF-owned docs/contracts | `cwf:refactor --docs` flow and repo deployment context |
| 3 | T2 | Fix High/Medium by default; fix Low when cheap and safe | Release-readiness best practice |
| 4 | T3 | Resolve by implementation-time evidence: compare README SoT claims with runtime scripts and contracts | Requires full scan + code/docs audit |

## Human Decision Queue
- None blocking at clarify stage.

## Execution Notes
- If a structural trade-off appears during implementation (e.g., strict behavior vs backward compatibility), pause and ask for a decision with concrete options.
