# Retro — 260217-10 Refactor Portability Default

- Date: 2026-02-17
- Mode: light
- Session dir: `.cwf/projects/260217-10-refactor-portability-default`

## 1. Context Worth Remembering

- This session established portability as a default quality axis for `cwf:refactor` across deep/holistic/docs paths.
- `--docs` now has a repository-local contract bootstrap flow (`docs-contract.yaml`) with idempotent create behavior.
- Contract-driven checks were separated from always-on portability baseline checks to reduce host-repo coupling.

## 2. Collaboration Preferences

- The user prefers direct, candid trade-off discussion before design lock-in.
- Portability should be default behavior, not hidden behind extra flags.
- Stage-by-stage execution with explicit review gates (plan review, impl review, retro, handoff) is preferred.

## 3. Waste Reduction

- Initial implementation left mismatch between documented fallback policy and bootstrap script behavior.
- Initial markdown path formatting fix triggered a second-order lint conflict (`CORCA001` vs `CORCA004`), causing avoidable rework.
- Durable reduction: align script outputs and docs contracts first, then run full deterministic gates once to avoid iterative churn.

## 4. Critical Decision Analysis (CDM)

1. Keep portability as default, no user-facing portability flag:
- Why: avoids drift between repositories and removes optional-compliance ambiguity.
- Outcome: criteria and flow documents now treat portability as baseline behavior.

2. Add contract bootstrap fallback status in script output:
- Why: docs flow required fallback continuation metadata, but implementation did not expose it.
- Outcome: script now emits `fallback` + warning and returns success for degraded paths.

3. Gate conditional docs checks with explicit `checks.*` keys:
- Why: contract fields were defined but not operationalized in procedure flow.
- Outcome: flow now states exact gating and `SKIPPED_CHECKS` reason mapping.

## 5. Expert Lens

Run `/retro --deep` for expert analysis.

## 6. Learning Resources

Run `/retro --deep` for learning resources.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

- `markdownlint-cli2` for deterministic markdown quality checks
- `plugins/cwf/skills/refactor/scripts/check-links.sh` for local link validation
- `plugins/cwf/skills/refactor/scripts/doc-graph.mjs` for orphan/broken reference graph checks
- `plugins/cwf/scripts/provenance-check.sh` for provenance freshness checks
- `.claude/skills/plugin-deploy/scripts/check-consistency.sh` and `plugins/cwf/scripts/codex/sync-skills.sh` for plugin lifecycle validation

### Tool Gaps

- End-to-end executable check for `cwf:refactor --docs` contract parsing/runtime behavior is still documentation-driven.
- A dedicated deterministic test harness for docs-contract resolution/gating would reduce future regression risk.
