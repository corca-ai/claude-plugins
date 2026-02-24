# Tier Classification

## Definition

Tier Classification is the governance concept for separating deterministic, advisory, and contextual policy layers across skills and runtime checks.

## Ownership Boundaries

- Classifies rules by authority level and enforcement behavior.
- Does not allow prose policy to override deterministic gate outputs.

## Operational Rules

- Deterministic tier owns pass/fail authority.
- Advisory tier informs decisions without mutating gate outcomes.

## Related Concepts

- [contract](../concepts/contract.md)
- [expert](../concepts/expert.md)
- [provenance](../concepts/provenance.md)

## Examples

- Hook scripts are deterministic tier; narrative summaries are advisory tier.
- Context capture artifacts are contextual tier inputs to later decisions.
