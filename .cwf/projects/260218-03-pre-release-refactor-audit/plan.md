# Plan — pre-release-refactor-audit

## Task
"퍼블릭 배포 전 점검: refactor --codebase 수정, --skill 전체 deep 수정, --docs 수정, README SoT/계약/독립성 심층 검증, clarify→plan→구현→review→retro 수행"

## Scope Summary
- **Goal**: Ship CWF plugin in a release-ready state with code/docs/contracts aligned to stated SoT promises.
- **Key Decisions**: skill deep-review scope, docs review scope, severity threshold, SoT mismatch handling (code vs docs).
- **Known Constraints**:
  - Do not delete user files without confirmation.
  - Preserve deterministic gates as source of truth.
  - Keep CWF repo-agnostic from plugin side (host repo assumptions must be defensive).

## Prior Art / Reference Inputs
- `plugins/cwf/skills/refactor/SKILL.md`
- `plugins/cwf/skills/review/SKILL.md`
- `plugins/cwf/skills/retro/SKILL.md`
- `plugins/cwf/references/plan-protocol.md`
- `plugins/cwf/references/context-recovery-protocol.md`
- `README.md`, `README.ko.md` (SoT claims)

## Files to Create/Modify
- Session artifacts in `.cwf/projects/260218-03-pre-release-refactor-audit/`
- CWF plugin code/docs/scripts touched by findings (exact files determined after scans)

## Execution Steps
1. Run `cwf:refactor --codebase` deterministic scan, classify findings, and patch code/scripts.
2. Run deep review across all `plugins/cwf/skills/*` and patch findings (structure, quality, portability).
3. Run `cwf:refactor --docs` deterministic + semantic checks and patch docs/contracts.
4. Audit README SoT claims against runtime behavior (state handling, contract bootstrap, repo-agnostic execution); patch code/docs mismatches.
5. Run `cwf:review --mode code` against produced diff; fix blocking findings.
6. Run `cwf:retro` and persist retrospective artifacts.

## Commit Strategy
- Strategy: **Per step**
- Commit boundaries:
  1. Codebase scan fixes
  2. Skill deep-review fixes
  3. Docs review fixes + SoT alignment
  4. Post-review blocking fixes (if any)
  5. Retro artifacts (optional separate commit)

## Success Criteria

```gherkin
Given the repository state before this session
When `cwf:refactor --codebase` is executed and fixes are applied
Then no unresolved High/Medium findings remain in the resulting codebase summary.
```

```gherkin
Given all skills under `plugins/cwf/skills/*`
When deep review is executed for each skill and fixes are applied
Then identified structural/quality/portability issues are resolved or explicitly documented with rationale.
```

```gherkin
Given repository documentation
When docs review checks run (`markdownlint`, local link check, doc graph, semantic review)
Then deterministic failures are resolved and semantic inconsistencies are addressed with concrete edits.
```

```gherkin
Given README/README.ko SoT claims about contracts and portability
When implementation and scripts are audited
Then each claim is either verifiably true in code/contracts or corrected in documentation.
```

```gherkin
Given all implementation changes are complete
When `cwf:review --mode code` is run
Then blocking concerns are fixed before finishing the session.
```

## Qualitative Criteria
- Changes remain contract-driven and deterministic-gate friendly.
- No hidden coupling from CWF plugin to this specific repository structure.
- Session artifacts are sufficient for compact recovery.

## Decision Log

| # | Decision Point | Evidence / Source (artifact or URL + confidence) | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|---------------------------------------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | "All skills" scope | User request + repo structure (`plugins/cwf/skills/*`) (high) | Include external local/global skills | CWF plugin skills only | resolved | agent | 2026-02-18T00:00:00Z |
| 2 | Handling SoT mismatch | README/README.ko + implementation audit (pending) | Code-first only, docs-first only | Fix code and/or docs based on evidence | open | TBD | TBD |

## Deferred Actions
- [ ] Ask user only if a high-impact architectural trade-off appears during implementation.
