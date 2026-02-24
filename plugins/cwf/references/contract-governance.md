# Contract Governance

This document summarizes ownership and lifecycle policy for concept-governed contracts in the CWF plugin.

## Concept Index

- [expert](../concepts/expert.md)
- [contract](../concepts/contract.md)
- [decision-point](../concepts/decision-point.md)
- [tier-classification](../concepts/tier-classification.md)
- [agent-orchestration](../concepts/agent-orchestration.md)
- [handoff](../concepts/handoff.md)
- [provenance](../concepts/provenance.md)

## Ownership Model

- Concept definitions are owned under [plugins/cwf/concepts/](../concepts/README.md).
- Registry and deterministic checks are owned by concept-governance scaffolding.
- Skill and hook teams remain owners of implementation details, but they must declare concept bindings or explicit exclusions in the registry.

## Lifecycle Summary

1. Define or update concept docs under `plugins/cwf/concepts/*.md`.
2. Register concept metadata and bindings in [plugins/cwf/concepts/registry.yaml](../concepts/registry.yaml).
3. Add or update concept checker scripts under `plugins/cwf/concepts/checkers/`.
4. Run `bash plugins/cwf/scripts/check-concepts.sh --summary`.
5. Ship only when deterministic checks pass.

## Policy Rules

- Active skills and hook entries require at least one concept binding, unless explicitly excluded in registry.
- Exclusions are governed by `registry.yaml` policy and must include `owner`, `reason`, `tracked_ref`, and sunset metadata aligned with `exclusion_sunset_mode` (default: `release-based`).
- Concept checker aggregate format is standardized as `jsonl` via `registry.yaml` governance policy.
- Registry-listed target docs must contain registry-listed concept links.
- Concept checker scripts provide deterministic pass/warn/fail outcomes.
- Implementation changes should be committed in meaningful units with explicit boundary rationale instead of one end-of-session monolithic commit.

## Change Control

- Concept lifecycle changes should be additive where possible.
- Breaking renames require synchronized updates to registry bindings and checks.
- Exclusions are temporary and should include rationale in review discussion.
