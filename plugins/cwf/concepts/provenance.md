# Provenance

## Definition

Provenance is the governance concept for traceability of facts, decisions, artifacts, and runtime actions back to explicit evidence sources.

## Ownership Boundaries

- Requires source attribution for generated decisions and outputs.
- Does not permit unverifiable claims to drive deterministic gates.

## Operational Rules

- Significant assertions must include source pointers or artifact paths.
- Mutation history should remain inspectable for recovery and audit.

## Related Concepts

- [contract](../concepts/contract.md)
- [handoff](../concepts/handoff.md)
- [tier-classification](../concepts/tier-classification.md)

## Examples

- Hook logs recording decisions for session replay.
- Provenance sidecars for generated reference documents.
