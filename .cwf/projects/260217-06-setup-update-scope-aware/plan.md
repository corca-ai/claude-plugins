# Plan — setup-update-scope-aware

## Task
"Design scope-aware behavior for `cwf:setup` and `cwf:update` across Claude plugin scopes, with clear WHAT/WHY contracts and minimal HOW detail."

## Scope Summary
- **Goal**: Define a stable behavior contract for scope-aware setup/update, especially where Codex integration currently writes to user-global paths.
- **Key Decisions**:
  - Should Codex integration remain user-global by default regardless of plugin scope?
  - What should happen when CWF is installed in `project`/`local` scope?
  - How should `cwf:update` detect and repair stale Codex symlinks after cache version changes?
  - How should conflicts be handled when `user` + `project` + `local` installations coexist?
- **Known Constraints**:
  - Claude plugin payloads are cache-backed (`~/.claude/plugins/cache/.../<version>`) even for `project`/`local` scope.
  - Current Codex integration targets are user-global (`~/.agents/*`, `~/.local/bin/codex`).
  - CWF is not yet published to marketplace main, so full CWF scope E2E validation is deferred.
  - Another agent is refactoring in parallel; this plan intentionally focuses on WHAT/WHY only.

## Product Intent
- **Separate concerns**: Claude plugin installation scope and Codex integration scope are related but not identical; both must be explicit to users.
- **Least surprise**: A command executed in `project` or `local` context should not silently mutate user-global Codex state.
- **Recoverability**: Scope or version drift must be detectable and repairable by deterministic update behavior.
- **Determinism under coexistence**: Multi-scope installations must produce one predictable active behavior per cwd.

## Proposed Contract Changes (WHAT + WHY)

### 1. Scope-aware setup entry contract
- **What**: `cwf:setup` resolves currently installed scopes and current execution context, then explicitly declares which scope it is operating on and which Codex surfaces it will change.
- **Why**: Prevents accidental global side effects and makes scope decisions auditable.

### 2. Codex integration policy by scope
- **What**: `cwf:setup --codex` and `cwf:setup --codex-wrapper` become scope-aware and require explicit confirmation when a non-user scope run would modify user-global paths.
- **Why**: Aligns behavior with user expectation that project/local operations stay bounded unless intentionally escalated.

### 3. Update contract for cache-version drift
- **What**: `cwf:update` becomes scope-aware and includes post-update Codex integration reconciliation for the selected scope when symlink targets no longer match active install paths.
- **Why**: Plugin cache paths are versioned; without reconciliation, Codex links can remain stale after update.

### 4. Multi-scope coexistence policy
- **What**: Define precedence and conflict reporting when the same plugin exists in multiple scopes in one cwd.
- **Why**: Removes ambiguity and prevents non-deterministic behavior during setup/update flows.

### 5. Safety/reporting contract
- **What**: Setup/update output must include "before vs after" scope/integration summary and explicit rollback guidance for changed surfaces.
- **Why**: Makes operational impact clear and reversible.

## Target Surfaces (Design Scope)
- `plugins/cwf/skills/setup/SKILL.md`
- `plugins/cwf/skills/update/SKILL.md`
- `plugins/cwf/scripts/codex/sync-skills.sh`
- `plugins/cwf/scripts/codex/install-wrapper.sh`
- `README.md`
- `README.ko.md`

## Out of Scope
- Low-level command choreography and script implementation detail.
- Full behavioral verification on marketplace-distributed `cwf` before publish.
- Unrelated refactor stream currently handled by another agent.

## Decision Log

| # | Decision Point | Evidence / Source (artifact or URL + confidence) | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|---------------------------------------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | Setup/Update should be scope-aware | `.cwf/projects/260217-06-setup-update-scope-aware/plan.md` + local CLI scope help output (`claude plugin install/update --help`) (High) | Keep current user-global Codex integration behavior regardless of scope | Adopt scope-aware contract direction | resolved | planning session | 2026-02-17T18:04:00Z |
| 2 | Default Codex target for `project/local` scope | Current behavior evidence from `plugins/cwf/scripts/codex/sync-skills.sh` (user-global paths) (High) | A) always user-global, B) default project-bounded with explicit global opt-in | TBD pending policy choice after publish-time E2E | open | TBD | TBD |
| 3 | Whether `cwf:update` should auto-reconcile Codex links | Versioned cache model + current update skill contract gap (Medium) | A) notify-only, B) auto-reconcile with summary, C) interactive choice | Prefer auto-reconcile with explicit report (final wording TBD) | open | TBD | TBD |
| 4 | Multi-scope precedence model | CLI supports `user/project/local` scopes (High) | A) fixed precedence, B) explicit scope prompt every run | TBD (needs final UX decision) | open | TBD | TBD |

## Commit Strategy
- **Per step** for design-surface changes:
  - setup contract update
  - update contract update
  - codex script policy alignment
  - docs alignment
  - deterministic checks (if needed)

## Success Criteria

```gherkin
Scenario: Setup reports scope and integration impact explicitly
  Given CWF is installed in at least one scope
  When the user runs cwf:setup with Codex integration options
  Then setup reports the active scope and target Codex paths before applying changes

Scenario: Project/local context does not silently mutate user-global Codex state
  Given CWF is invoked from a project/local scope context
  When setup/update would affect ~/.agents or ~/.local/bin/codex
  Then the operation requires explicit user confirmation for user-global mutation

Scenario: Update repairs stale Codex linkage after plugin version change
  Given plugin installPath changed after update
  When Codex integration is enabled for the selected scope
  Then update reconciles or explicitly flags stale Codex links in the same run

Scenario: Multi-scope coexistence is deterministic
  Given user and project/local CWF installations coexist
  When setup/update is executed in a project
  Then one precedence rule is applied and conflicts are surfaced clearly
```

## Deferred Actions

- [ ] Finalize default policy for Codex integration target under `project/local` scope (global-by-default vs project-bounded-by-default).
- [ ] Validate final policy against marketplace-published CWF in a clean machine.
- [ ] Add/update deterministic checks only for contract parts that can be mechanically validated.
