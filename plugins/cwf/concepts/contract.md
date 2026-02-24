# Contract

## Definition

Contract is the governance concept that captures deterministic constraints, required inputs/outputs, and pass/fail conditions between workflow components.

## Ownership Boundaries

- Declares machine-checkable obligations and stable interfaces.
- Does not encode subjective rationale as a replacement for checks.

## Operational Rules

- Contracts should be executable or directly verifiable by scripts.
- Contract updates must preserve backward compatibility or state migration.

## Related Concepts

- [decision-point](../concepts/decision-point.md)
- [tier-classification](../concepts/tier-classification.md)
- [provenance](../concepts/provenance.md)

## Examples

- Hook manifests require valid commands and deterministic outcomes.
- Plan contracts define mandatory sections and evaluation criteria.
