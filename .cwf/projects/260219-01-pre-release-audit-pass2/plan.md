# Plan — pre-release-audit-pass2

## Task
"Pre-release pass: run `cwf:refactor --codebase`, deep-review all skills, run `cwf:refactor --docs`, fix discovered issues, perform deep SoT/repo-agnostic/contract-first audit, then run `cwf:review` and `cwf:retro` with meaningful commit units."

## Scope Summary
- **Goal**: Raise CWF v3 release readiness by converging implementation, deterministic gates, and documentation promises.
- **Key Decisions**:
  - Prefer v3 cleanliness over preserving v2 compatibility shims.
  - Keep deterministic checks/contracts as pass/fail authority.
  - Stop for user decision only on true architectural trade-offs.
- **Known Constraints**:
  - Use sub-agents aggressively for parallel analysis.
  - Keep docs/code in English; user-facing conversation in Korean.
  - Do not delete user-created files without explicit confirmation.

## Inputs and Evidence
- `.cwf/projects/260219-01-pre-release-audit-pass2/clarify-result.md`
- `.cwf/projects/260219-01-pre-release-audit-pass2/plan-codebase-analysis.md`
- `.cwf/projects/260219-01-pre-release-audit-pass2/plan-claim-map.md`
- `.cwf/projects/260219-01-pre-release-audit-pass2/plan-prior-art-research.md`

## Files to Create/Modify
- Session artifacts under `.cwf/projects/260219-01-pre-release-audit-pass2/`
- Code/docs/contracts/hooks/scripts touched by findings from:
  - `cwf:refactor --codebase`
  - `cwf:refactor --skill <name>` for all CWF skills
  - `cwf:refactor --docs`
  - SoT/portability/contract-first deep audit checks

## Execution Steps
1. **Codebase scan + fix cycle**
- Bootstrap codebase contract and run codebase scan scripts.
- Persist scan output and summary in current session directory.
- Fix actionable findings, then re-run scan/gates until clean.

2. **Deep review all skills + fix cycle**
- Build CWF skill inventory from `plugins/cwf/skills/*`.
- Run deep review in parallel batches across all skills using sub-agents.
- Aggregate findings; apply fixes with consistent conventions/provenance discipline.
- Re-run targeted checks after each batch.

3. **Docs review + fix cycle**
- Bootstrap docs contract and run deterministic docs toolchain (`markdownlint`, links, doc-graph).
- Apply doc fixes for consistency, portability, and drift.
- Re-run docs deterministic checks to green.

4. **SoT + repo-agnostic + contract-first deep audit**
- Cross-check README SoT claims vs actual behavior in skills/hooks/scripts/contracts.
- Validate host-repo independence and first-run contract bootstrap behavior.
- Remove or simplify unnecessary backward-compat code paths that weaken v3 clarity.
- Run portability fixtures and contract gates.

5. **Code review + fix cycle**
- Run `cwf:review --mode code` on final diff state.
- Fix material concerns and regenerate review artifacts.

6. **Retro and persistence recommendations**
- Run deep retro.
- Produce concrete persist candidates (agent guide/docs/contracts/scripts).

## Commit Strategy
- **Per concern boundary** (explicit):
  1. Codebase-scan finding fixes
  2. Skill-deep finding fixes
  3. Docs finding fixes
  4. Systemic SoT/repo-agnostic/back-compat cleanup
  5. Review follow-up fixes (if any)
  6. Retro artifact updates (if separated)
- Enforce checkpoint after first completed unit: inspect `git status --short`, confirm boundary, commit before moving to next major unit.

## Decision Log
| # | Decision Point | Evidence / Source (artifact or URL + confidence) | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|---------------------------------------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | v3 cleanliness vs v2 compatibility | `clarify-result.md` + SemVer/Go/Cargo prior-art (high) | Keep compatibility shims longer | Prefer v3 cleanliness; remove nonessential compatibility baggage | resolved | user directive + assistant | 2026-02-18T22:35:35Z |
| 2 | Proof bar for portability/SoT | `plan-claim-map.md`, `plan-codebase-analysis.md` (high) | Narrative-only verification | Deterministic checks + file:line evidence + contract/provenance cross-check | resolved | assistant | 2026-02-18T22:45:00Z |
| 3 | Skill deep-review execution model | `refactor` skill deep-flow references (high) | Sequential per skill | Parallel sub-agent batches with persisted artifacts | resolved | assistant | 2026-02-18T22:45:00Z |
| 4 | Removal scope for backward-compat paths | Runtime findings during implementation (medium) | Keep all legacy paths | TBD only where behavior/safety trade-offs are substantial | open | TBD | TBD |

## Success Criteria

```gherkin
Given codebase quick/deep scans are run
When implementation is complete
Then all actionable findings in scope are either fixed or explicitly deferred with rationale in session artifacts

Given deep reviews are executed for every skill under plugins/cwf/skills
When implementation is complete
Then each skill has resolved findings or documented defer decisions with evidence

Given docs review deterministic tools are run
When implementation is complete
Then markdownlint, link checks, and doc graph checks pass for the modified scope

Given README/README.ko SoT and portability claims
When implementation is complete
Then claims map to concrete behavior in skills/hooks/scripts/contracts without repo-specific hard dependency

Given the requested workflow includes review and retro
When implementation is complete
Then review and retro artifacts exist and pass required run-gate checks
```

## Qualitative Criteria
- Deterministic gates remain authoritative; prose does not override checks.
- Prefer simplification/removal over compatibility indirection for unshipped v3.
- Keep changes auditable and isolated by commit boundary.
- Preserve repo-agnostic operation with contract-based adaptation.

## Deferred Actions
- [ ] Decide any high-impact backward-compat removal that materially changes public behavior (ask user with options/trade-offs when encountered).
