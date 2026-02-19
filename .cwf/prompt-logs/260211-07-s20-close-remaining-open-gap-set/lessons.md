### Semantic Gate Delivery With Backward Compatibility

- **Expected**: semantic checks might require replacing existing `check-session.sh` paths.
- **Actual**: adding opt-in `--semantic-gap` enabled semantic integrity checks without altering existing `--impl`/default behavior.
- **Takeaway**: first-wave semantic enforcement can ship safely as additive mode before becoming default.

When introducing stronger validation -> prefer additive mode first, then promote to default after false-positive review.

### Unknown-to-Resolved Requires Explicit Trace

- **Expected**: GAP-003 might remain Unknown due to historical ambiguity.
- **Actual**: a dedicated trace from source intent lines to current implementation lines provided enough evidence for binary closure.
- **Takeaway**: Unknown states should be treated as missing traceability, not permanent classification.

When a gap is Unknown -> produce an intent-to-implementation trace table before discussing new implementation scope.

### Env Decoupling Needs Repository-Wide Consistency

- **Expected**: moving config emphasis from `~/.claude/.env` to shell profiles with backward compatibility would reduce Claude-specific coupling across skills/hooks.
- **Actual**: loading policy is mixed; some scripts implement 3-tier loading (`env -> .env -> profiles`), while others still source only `~/.claude/.env`.
- **Takeaway**: decoupling is only complete when both runtime scripts and user-facing docs follow the same primary/fallback contract.

When reducing runtime coupling -> adopt one shared env-loading helper contract and enforce it with a deterministic repo check.
