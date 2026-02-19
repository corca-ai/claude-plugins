# Holistic Workflow Coherence (Rerun)
## Findings
1. [High] `--skip ship` conflicts with mandatory ship gate.
- `cwf:run` advertises `--skip ship` and skip semantics (`plugins/cwf/skills/run/SKILL.md:17`, `plugins/cwf/skills/run/SKILL.md:377`), but completion still enforces `--stage ship` unconditionally (`plugins/cwf/skills/run/SKILL.md:401`).
- ship gate requires `ship.md` schema (`plugins/cwf/scripts/check-run-gate-artifacts.sh:501`, `plugins/cwf/scripts/check-run-gate-artifacts.sh:556`).
- Result: intentional ship skip can still fail strict closure.

2. [High] Scope resolution in setup/update is fail-open to `user`.
- Both skills resolve scope with `detect-plugin-scope.sh ... || true` and fallback to `user` (`plugins/cwf/skills/setup/SKILL.md:258`, `plugins/cwf/skills/setup/SKILL.md:265`, `plugins/cwf/skills/update/SKILL.md:28`, `plugins/cwf/skills/update/SKILL.md:35`).
- This can violate the new “non-user context must not silently mutate user-global paths” contract when scope detection is unavailable/invalid.

3. [Medium] Update restart boundary is advisory only; downstream run/ship have no guard.
- Update says restart is required (`plugins/cwf/skills/update/SKILL.md:196`), but run/ship have no restart-required state check before execution.
- Result: same session can continue with stale loaded behavior after update.

4. [Medium] `blocking_decisions_pending` can be desynchronized at run completion.
- Run correctly tracks debt during clarify (`plugins/cwf/skills/run/SKILL.md:260`, `plugins/cwf/skills/run/SKILL.md:267`) but force-clears at completion (`plugins/cwf/skills/run/SKILL.md:412`).
- This can under-report unresolved defer-blocking debt when ship is skipped/stopped.

5. [Low] Trigger/invocation naming is inconsistent at run→ship boundary.
- Run stage table uses `cwf:ship` (`plugins/cwf/skills/run/SKILL.md:133`), while ship quick start and trigger contract are `/ship` (`plugins/cwf/skills/ship/SKILL.md:14`).
- This is mostly documentation-level ambiguity but reduces routing clarity.

## Data-Flow / Trigger Gaps
- Setup→Run: Phase 2.10 writes `CWF_RUN_AMBIGUITY_MODE` (`plugins/cwf/skills/setup/SKILL.md:779`), and run reads it (`plugins/cwf/skills/run/SKILL.md:36`), but run has no explicit fallback prompt when neither config file exists nor setup was ever run.
- Setup/Update scope flow: target-scope override is defined (`plugins/cwf/skills/update/SKILL.md:59`), but post-override normalization of `selected_project_root` is not explicitly re-specified before reconciliation commands.
- Update→Run/Ship: no persisted “restart required” signal in live/session artifacts, so downstream stages cannot deterministically block/warn.
- Run→Ship closure: skip path lacks an alternate artifact contract equivalent to `ship.md`, despite strict ship-stage gate at completion.

## Priority Actions
1. Make run completion ship-gate aware of skip decisions.
- If ship is skipped, either omit `--stage ship` at completion or require a minimal “ship-skipped” artifact with deterministic schema.

2. Replace fail-open scope fallback with explicit scope confirmation for mutating phases.
- On scope-detection failure, stop and ask target scope instead of defaulting to `user`.
- Recompute `selected_project_root` immediately after any scope override.

3. Add update→run/ship restart handshake.
- Persist `restart_required` state after successful update and enforce preflight warning/block in run and ship until acknowledged.

4. Preserve ambiguity debt truth at run completion.
- Derive final `blocking_decisions_pending` from `run-ambiguity-decisions.md` counts, not unconditional false.

5. Normalize ship invocation naming across skills.
- Align on one canonical surface (`/ship` or `cwf:ship`) and document explicit mapping in run stage table.

<!-- AGENT_COMPLETE -->
