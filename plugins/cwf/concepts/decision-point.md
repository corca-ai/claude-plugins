# Decision Point

## Definition

Decision Point is the governance concept for explicit control gates where execution branches based on deterministic evidence or human confirmation.

## Ownership Boundaries

- Names gate conditions, branch outcomes, and required justification.
- Does not hide branch logic behind implicit conversational context.

## Operational Rules

- Each decision point must declare trigger, owner, and next action.
- Human-required decisions must be explicit and resumable.

## Related Concepts

- [contract](../concepts/contract.md)
- [agent-orchestration](../concepts/agent-orchestration.md)
- [handoff](../concepts/handoff.md)

## Examples

- Pre-implementation human gate before `impl` starts.
- Strict checker fail leading to execution stop.
