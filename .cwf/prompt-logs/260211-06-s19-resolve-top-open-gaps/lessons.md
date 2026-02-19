### Mention-Only Start Contract

- **Expected**: User-provided `next-session.md` path would only request file viewing.
- **Actual**: The file included an explicit mention-only execution contract requiring full `cwf:run` orchestration.
- **Takeaway**: Treat handoff files as executable instructions when they declare mention-only behavior.

When a handoff file defines an execution contract on mention-only input -> execute the declared pipeline order unless user explicitly overrides.

### Gap-Fix Scope Control

- **Expected**: BL-003 could be solved by doc-only edits in retro/handoff.
- **Actual**: DEC-005 required alignment of both source-discovery contracts and runtime log output defaults.
- **Takeaway**: For migration gaps, update producer and consumer contracts together to avoid partial closure.

When a gap concerns artifact flow -> patch both producers (writers) and consumers (readers) in the same session.
