# Holistic Convention Compliance (Rerun)

## Findings

1. **Aligned scope-aware contract between `setup` and `update` (Compliant)**  
   The latest changes are structurally consistent with shared conventions for phase ordering, language declaration, rules/references placement, and explicit scope handling.  
   Evidence: `plugins/cwf/skills/setup/SKILL.md:10`, `plugins/cwf/skills/setup/SKILL.md:12`, `plugins/cwf/skills/setup/SKILL.md:1049`, `plugins/cwf/skills/setup/SKILL.md:1061`, `plugins/cwf/skills/update/SKILL.md:10`, `plugins/cwf/skills/update/SKILL.md:12`, `plugins/cwf/skills/update/SKILL.md:310`, `plugins/cwf/skills/update/SKILL.md:321`, `plugins/cwf/skills/setup/SKILL.md:255`, `plugins/cwf/skills/update/SKILL.md:25`.

2. **Safety confirmation policy is asymmetric across setup vs update (Gap)**  
   `setup` requires an explicit second confirmation before mutating user-global Codex paths from non-user context, but `update` currently relies on scope choice/update confirmation without an equivalent second guard before user-global reconciliation. This creates a UX-policy mismatch for the same risk surface.  
   Evidence: `plugins/cwf/skills/setup/SKILL.md:309`, `plugins/cwf/skills/setup/SKILL.md:312`, `plugins/cwf/skills/update/SKILL.md:54`, `plugins/cwf/skills/update/SKILL.md:59`, `plugins/cwf/skills/update/SKILL.md:233`, `plugins/cwf/skills/update/SKILL.md:245`.

3. **Missing-dependency interaction contract is implemented in setup but not mirrored in update (Gap)**  
   `setup` follows the interactive install/retry contract for missing runtime dependencies, while `update` directly executes dependency-sensitive commands (`claude`, `jq`) without an explicit install-now/commands-only decision path. This is inconsistent with global missing dependency handling expectations.  
   Evidence: `plugins/cwf/skills/setup/SKILL.md:193`, `plugins/cwf/skills/setup/SKILL.md:211`, `plugins/cwf/skills/setup/SKILL.md:227`, `plugins/cwf/skills/update/SKILL.md:79`, `plugins/cwf/skills/update/SKILL.md:82`.

4. **Scope-aware additions increased setup complexity beyond quick-scan thresholds (Risk)**  
   The scope-aware behavior is functionally coherent, but `setup` now remains a high-size outlier, increasing drift risk and review cost for future cross-skill changes.  
   Evidence: `.cwf/projects/260217-06-setup-update-scope-aware/refactor-quick-scan.json` (`setup`: 4475 words / 1078 lines, warning).

## Cross-Skill Pattern Opportunities

1. **Extract a shared "scope-aware Codex mutation guard" reference**  
   Create one shared reference that standardizes: scope detection, target scope override rules, and non-user -> user-global second-confirmation behavior. Apply it to both `setup` and `update` to remove policy drift.

2. **Standardize dependency preflight pattern for mutating operational skills**  
   Reuse setup's install-now/commands-only/skip triage pattern for `update` (and later other mutation-heavy skills) so missing-tool handling is behaviorally consistent across CWF runtime operations.

3. **Introduce deterministic contract checks for scope-aware skills**  
   Add a lightweight gate script that validates required scope-aware clauses (resolve scope first, explicit user-global escalation confirmation, check-mode non-mutation, reconcile summary/rollback output) in `setup` and `update`.

## Priority Actions

1. **P1 - Align user-global escalation confirmation in `cwf:update` with `cwf:setup`**  
   Add explicit second confirmation when selected target is `user` from non-user context before reconciliation commands run.

2. **P1 - Add missing-dependency interactive fallback to `cwf:update`**  
   Reuse the setup dependency decision contract so update does not hard-fail on missing `jq`/runtime tools without remediation choice.

3. **P2 - Reduce setup drift surface by extracting shared scope-aware policy text**  
   Move repeated scope guard policy into a shared reference and keep `setup`/`update` SKILL docs focused on skill-specific flow.

<!-- AGENT_COMPLETE -->
