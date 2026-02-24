# CWF Concept Governance

This directory defines governance concepts used by CWF runtime artifacts. The registry (`registry.yaml`) is the source of truth for concept bindings, reference-link checks, and concept checker execution.

## Concept Index

- [expert](../concepts/expert.md)
- [contract](../concepts/contract.md)
- [decision-point](../concepts/decision-point.md)
- [tier-classification](../concepts/tier-classification.md)
- [agent-orchestration](../concepts/agent-orchestration.md)
- [handoff](../concepts/handoff.md)
- [provenance](../concepts/provenance.md)

## Files

- `registry.yaml`: concept metadata, binding matrix, exclusions, and link targets.
- `checkers/`: one deterministic checker script per concept.
- `*.md`: concept definitions and governance expectations.

## Validation Entry Point

Run:

```bash
bash plugins/cwf/scripts/check-concepts.sh --summary
```

For ownership/lifecycle policy, see [contract-governance](../references/contract-governance.md).
