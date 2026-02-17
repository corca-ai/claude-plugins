## Refactor Review: setup

### Summary
- Reviewed `plugins/cwf/skills/setup/SKILL.md` and the scope-aware scripts (`plugins/cwf/scripts/codex/install-wrapper.sh`, `plugins/cwf/scripts/codex/sync-skills.sh`, `plugins/cwf/scripts/detect-plugin-scope.sh`) after commit `6665d30`.
- Provenance for deep-review criteria is fresh (`plugins/cwf/skills/refactor/references/review-criteria.provenance.yaml`: fresh at 13 skills / 18 hooks).
- Improved vs previous findings:
  - The prior SSOT gap is addressed: post-install re-detection + `cwf-state.yaml` rewrite is now explicitly mandated (`plugins/cwf/skills/setup/SKILL.md:235` and `plugins/cwf/skills/setup/SKILL.md:1053`).
  - Codex integration is now scope-aware with explicit non-user override confirmation, and the three scripts implement scope routing cleanly.
- Residual risks remain: oversized SKILL payload, unsafe `eval` parsing in scope resolution instructions, and duplicated procedural content in `Rules`.

### Findings
#### [Medium] SKILL payload is still above deep-review size thresholds (and grew)
**What**: `setup` SKILL is now `4,475` words / `1,078` lines, which exceeds the warning thresholds (`>3,000` words, `>500` lines) and is larger than the prior review baseline (`4,063` words / `957` lines).
**Where**: `plugins/cwf/skills/setup/SKILL.md` (overall), criteria in `plugins/cwf/skills/refactor/references/review-criteria.md` section 1.
**Suggestion**: Move command-heavy procedural blocks (especially Codex integration variants and verification/rollback details) into setup-local references and keep SKILL.md focused on routing + invariants.

#### [Medium] Scope parsing uses `eval` on command output
**What**: Phase 2.4.1 instructs `eval "$scope_info"` after calling `detect-plugin-scope.sh`. This is brittle for values containing shell-sensitive characters or spaces, and it introduces unnecessary command interpretation in a low-freedom path.
**Where**: `plugins/cwf/skills/setup/SKILL.md:264`, producer script output at `plugins/cwf/scripts/detect-plugin-scope.sh:156`.
**Suggestion**: Replace `eval` with explicit key parsing (`while IFS='=' read -r key value ...`) and/or emit safely escaped values from the script.

#### [Low] Rules section still duplicates phase-level procedures
**What**: The `Rules` block repeats behavior already defined in earlier phases (explicit prompts, post-install re-detection, full-setup optional integrations), keeping two edit surfaces for the same policy.
**Where**: `plugins/cwf/skills/setup/SKILL.md:1049`.
**Suggestion**: Keep only non-derivable invariants in `Rules`; link to phase anchors for procedural details.

### Suggested Actions
1. Reduce SKILL body size below review thresholds by extracting Codex scope workflows and verification/rollback examples into setup-local references (effort: medium).
2. Remove `eval`-based scope parsing and adopt deterministic key parsing from `detect-plugin-scope.sh` output (effort: small).
3. De-duplicate `Rules` to invariant-only statements and keep procedures single-sourced in phase sections (effort: small).

<!-- AGENT_COMPLETE -->
