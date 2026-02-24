# Agent Orchestration

## Definition

Agent Orchestration is the governance concept for sequencing, delegating, and coordinating specialized agents while preserving deterministic checkpoints.

## Ownership Boundaries

- Defines delegation contracts and aggregation responsibilities.
- Does not permit uncontrolled fan-out without verification joins.

## Operational Rules

- Orchestration must maintain explicit stage ordering and evidence joins.
- Parallel work must converge through a deterministic synthesis step.

## Related Concepts

- [decision-point](../concepts/decision-point.md)
- [handoff](../concepts/handoff.md)
- [provenance](../concepts/provenance.md)

## Examples

- Review skill coordinating multiple reviewers and combining verdicts.
- Run skill chaining stage transitions with gate checks.
