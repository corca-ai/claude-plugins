# refactor Skill File Map

File-level map for [refactor](SKILL.md).

- [README.md](README.md): File map for this skill directory.
- [SKILL.md](SKILL.md): Primary instructions and execution workflow for this skill.
- [references/codebase-contract.md](references/codebase-contract.md): Contract schema for repository-local codebase scan scoping.
- [references/docs-criteria.md](references/docs-criteria.md): Reference file used by this skill (docs-criteria).
- [references/docs-contract.md](references/docs-contract.md): Contract schema for repository-local docs review scoping.
- [references/docs-review-flow.md](references/docs-review-flow.md): Detailed docs-mode procedure flow extracted from SKILL.md.
- [references/docs-criteria.provenance.yaml](references/docs-criteria.provenance.yaml): Provenance sidecar for docs-criteria.md.
- [references/holistic-criteria.md](references/holistic-criteria.md): Reference file used by this skill (holistic-criteria).
- [references/holistic-criteria.provenance.yaml](references/holistic-criteria.provenance.yaml): Provenance sidecar for holistic-criteria.md.
- [references/review-criteria.md](references/review-criteria.md): Reference file used by this skill (review-criteria).
- [references/review-criteria.provenance.yaml](references/review-criteria.provenance.yaml): Provenance sidecar for review-criteria.md.
- [references/session-bootstrap.md](references/session-bootstrap.md): Shared session-directory bootstrap snippet and mode key map.
- [references/tidying-guide.md](references/tidying-guide.md): Reference file used by this skill (tidying-guide).
- [scripts/bootstrap-codebase-contract.sh](scripts/bootstrap-codebase-contract.sh): Helper script used by this skill (codebase contract bootstrap for codebase mode).
- [scripts/check-links.sh](scripts/check-links.sh): Helper script used by this skill (markdown link validation for docs mode).
- [scripts/check-codebase-contract-runtime.sh](scripts/check-codebase-contract-runtime.sh): Helper script used by this skill (codebase-contract runtime behavior check for codebase mode).
- [scripts/bootstrap-docs-contract.sh](scripts/bootstrap-docs-contract.sh): Helper script used by this skill (docs contract bootstrap for docs mode).
- [scripts/check-docs-contract-runtime.sh](scripts/check-docs-contract-runtime.sh): Helper script used by this skill (docs-contract runtime behavior check for docs mode).
- [scripts/codebase-quick-scan.sh](scripts/codebase-quick-scan.sh): Helper script used by this skill (contract-driven codebase quick scan).
- [scripts/codebase-quick-scan.py](scripts/codebase-quick-scan.py): Python backend for `codebase-quick-scan.sh` contract evaluation and findings aggregation.
- [scripts/select-codebase-experts.sh](scripts/select-codebase-experts.sh): Helper script used by this skill (fixed+context expert selection for codebase deep review).
- [scripts/doc-graph.mjs](scripts/doc-graph.mjs): Helper script used by this skill (doc graph/orphan analysis for docs mode).
- [scripts/quick-scan.sh](scripts/quick-scan.sh): Helper script used by this skill (quick-scan.sh).
- [scripts/tidy-target-commits.sh](scripts/tidy-target-commits.sh): Helper script used by this skill (tidy-target-commits.sh).
