# Plan — Refactor Portability-Default Baseline for `cwf:refactor`

## Context

The current `refactor` skill has strong repository coupling, especially in `--docs` mode, where several checks assume CWF-specific files and policies (for example `.claude-plugin/marketplace.json` and `README.ko.md`).

This plan updates `refactor` so portability is a default review dimension, not an opt-in flag, and introduces a repository-local docs contract bootstrap flow for `--docs` first-run behavior.

## Goal

Make portability/repository-independence a default quality axis in `cwf:refactor` (deep/holistic/docs), and make docs review adaptable per repository via auto-bootstrapped contract.

## Scope Summary

- **Goal**: Refactor `plugins/cwf/skills/refactor` to enforce portability checks by default and add docs-contract bootstrap behavior.
- **Key Decisions**:
  - Keep portability as default axis (no new user-facing portability flag).
  - Resolve contract path from artifact root config/env first (`CWF_ARTIFACT_ROOT`), with `.cwf` fallback.
  - Auto-create draft contract only when absent; never overwrite existing contract.
  - On bootstrap write failure, continue review with in-memory defaults and explicit warning.
  - Keep CWF-specific checks available, but run them only when enabled/resolved via contract context (or when deterministic local rules already enforce them).
- **Known Constraints**:
  - Preserve existing mode routing and deterministic-first philosophy.
  - Avoid breaking current CWF workflows and references.
  - Keep documentation and scripts in English.

## Steps

1. **Define portability baseline and docs contract semantics**
   - Add explicit portability-default guidance to `refactor` skill docs and criteria references.
   - Define contract fields sufficient to gate repository-specific docs checks.
   - Define path resolution: `CWF_ARTIFACT_ROOT`-aware default contract location.
2. **Implement docs contract bootstrap script**
   - Add a script under `plugins/cwf/skills/refactor/scripts/` that creates `{artifact_root}/docs-contract.yaml` when absent.
   - Include conservative auto-detection (entry docs, inventory sources, locale mirrors) and draft-mode notes.
   - Enforce idempotency:
     - absent => create
     - present => do not overwrite
     - two consecutive runs keep stable output
3. **Refactor docs mode flow to be contract-aware**
   - Update `references/docs-review-flow.md` and `references/docs-criteria.md` so CWF-specific checks are conditional and portability checks are always-on.
   - Document failure behavior: if contract parse/bootstrap fails, proceed with best-effort portability baseline + warning.
   - Update `SKILL.md` docs mode summary to include contract bootstrap/use.
4. **Integrate portability as default in deep/holistic criteria**
   - Extend deep review criteria and holistic framework so repository independence is evaluated by default without extra flags.
   - Update relevant prompt/routing instructions in `SKILL.md`.
5. **Update file map and run deterministic validation**
   - Update `plugins/cwf/skills/refactor/README.md` for new references/scripts.
   - Run deterministic checks for touched scope:
     - `npx --yes markdownlint-cli2 "**/*.md"`
     - `bash plugins/cwf/skills/refactor/scripts/check-links.sh --local --json`
     - `node plugins/cwf/skills/refactor/scripts/doc-graph.mjs --json`
     - `bash plugins/cwf/scripts/provenance-check.sh --level inform --json`
     - `bash -n plugins/cwf/skills/refactor/scripts/bootstrap-docs-contract.sh`
6. **Run plugin deploy lifecycle check for modified plugin**
   - Execute local plugin-deploy consistency workflow for `cwf` and handle required follow-ups.
7. **Final gate re-run after plugin-deploy side effects**
   - Re-run deterministic checks to validate final tree state after any plugin-deploy edits.

## Files to Create/Modify

- Modify: `plugins/cwf/skills/refactor/SKILL.md`
- Modify: `plugins/cwf/skills/refactor/README.md`
- Modify: `plugins/cwf/skills/refactor/references/review-criteria.md`
- Modify: `plugins/cwf/skills/refactor/references/holistic-criteria.md`
- Modify: `plugins/cwf/skills/refactor/references/docs-criteria.md`
- Modify: `plugins/cwf/skills/refactor/references/docs-review-flow.md`
- Create: `plugins/cwf/skills/refactor/references/docs-contract.md`
- Create: `plugins/cwf/skills/refactor/scripts/bootstrap-docs-contract.sh`

### Conditional Files (plugin-deploy outcome)

- `plugins/cwf/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `README.md`
- `README.ko.md`

## Success Criteria

```gherkin
Given a repository where `cwf:refactor --skill <name>` runs
When deep review criteria are loaded
Then repository-independence/portability checks are included by default without extra flags.
```

```gherkin
Given a repository where `cwf:refactor --skill --holistic` runs
When holistic criteria are applied
Then portability risks (hardcoded paths, non-defensive coupling, missing graceful degradation) are evaluated as part of default analysis.
```

```gherkin
Given a repository with no docs contract file
When `cwf:refactor --docs` is executed
Then a draft docs contract is generated at artifact-root location and review continues using contract-aware conditional checks.
```

```gherkin
Given a repository where docs contract already exists
When `cwf:refactor --docs` runs again
Then bootstrap does not overwrite the existing contract and the run is idempotent.
```

```gherkin
Given contract bootstrap write fails due to filesystem policy
When `cwf:refactor --docs` runs
Then review proceeds with best-effort portability baseline and emits explicit contract warning metadata.
```

```gherkin
Given a repository that does not use CWF-specific files
When `cwf:refactor --docs` runs
Then CWF-specific consistency checks are treated as conditional/contract-driven rather than unconditional failures.
```

## Success Criteria — Qualitative

- The new contract bootstrap behavior is explicit, predictable, and reversible.
- Existing CWF workflows remain functional after the refactor.
- Documentation remains concise and avoids duplicating deterministic tool output.
- Report output includes machine-readable contract context (`CONTRACT_PATH`, `CONTRACT_STATUS`, `SKIPPED_CHECKS`).

## Don't Touch

- Unrelated skills outside `plugins/cwf/skills/refactor/`
- Existing run-stage gate behavior in `plugins/cwf/scripts/check-run-gate-artifacts.sh`

## Deferred Actions

- [ ] Session 2: Apply the updated portability-default `refactor` workflow across all CWF skills after re-entry/reload validation.
