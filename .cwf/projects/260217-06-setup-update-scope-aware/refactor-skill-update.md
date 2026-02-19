## Refactor Review: update
### Summary
- Deep refactor review rerun completed for `plugins/cwf/skills/update/SKILL.md` plus referenced scope-aware scripts and README/script-map changes introduced by `6665d30`.
- Scope-aware direction is coherent: detection (`detect-plugin-scope.sh`), skill sync (`sync-skills.sh`), wrapper management (`install-wrapper.sh`), and docs are now aligned on `user|project|local`.
- Prior alias-risk concerns are partially resolved: aliases that invoke `codex` by command name are now explicitly covered and observable via status output, but stale-wrapper and alias-bypass edge cases remain.

### Findings
- `plugins/cwf/skills/update/SKILL.md:238` only reconciles wrapper when `wrapper_active=true`.  
  `plugins/cwf/scripts/codex/install-wrapper.sh:89` defines active as link target exactly equal to current `WRAPPER_SRC`.  
  Result: a stale wrapper symlink (old plugin cache path after update) is marked inactive and skipped, so the documented stale-wrapper reconciliation path can be missed.
- Alias-risk status: improved but not fully closed.
  - Resolved part: docs now clarify alias behavior when alias calls `codex` and wrapper status surfaces command resolution (`README.md:459`, `plugins/cwf/scripts/codex/install-wrapper.sh:100`, `plugins/cwf/scripts/codex/install-wrapper.sh:159`).
  - Remaining part: aliases/functions that pin an absolute/non-wrapper binary path bypass this protection; project/local scope also depends on shell PATH precedence, so alias behavior is still environment-dependent.

### Suggested Actions
- Update reconciliation gate in `update` skill logic: treat existing wrapper link presence as reconcile candidate, not only `Active: true`.
  - Practical condition: if wrapper link exists at scope destination OR `which -a codex` contains scope wrapper path, run `install-wrapper.sh --enable`.
- Add one explicit note to update/setup docs: aliases that call absolute paths (or shell functions masking `codex`) are out of scope and require manual adjustment.
- Add a deterministic check snippet in update report output:
  - `install-wrapper.sh --scope ... --status`
  - `type -a codex`
  - if project/local: confirm `{projectRoot}/.codex/bin` precedence in current shell.

<!-- AGENT_COMPLETE -->
