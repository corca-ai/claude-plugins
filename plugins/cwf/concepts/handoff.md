# Handoff

## Definition

Handoff is the governance concept for durable transfer of session or phase state so follow-up execution can recover without hidden memory.

## Ownership Boundaries

- Defines what artifacts must persist across sessions.
- Does not rely on transient chat context for critical state.

## Operational Rules

- Handoff artifacts must include scope, constraints, and next actions.
- Recovery must be possible from persisted files alone.

## Related Concepts

- [agent-orchestration](../concepts/agent-orchestration.md)
- [decision-point](../concepts/decision-point.md)
- [provenance](../concepts/provenance.md)

## Examples

- Session handoff file with unresolved questions and continuation instructions.
- Phase handoff between planning and implementation stages.
