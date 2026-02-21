# Sections 1-3 Working Summary (for deep retro batch agents)

## Session Objective

- User question: Why were post-`0.8.1` bugs not caught autonomously, and can we run a deep retro on changes after `0.8.1`.
- Immediate trigger: `cwf:update` showed stale `Current version == Latest version` behavior in a real user environment while direct `claude plugin update` succeeded.

## Evidence Snapshot

1. Update implementation compares against cached plugin payload path candidates, not marketplace manifest truth:
   - `plugins/cwf/skills/update/SKILL.md` (Phase 1 cache scan)
   - `plugins/cwf/skills/update/references/scope-reconcile.md` (cache-root resolution)
2. Prior audit already flagged portability brittleness around update cache roots:
   - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-f.md`
3. Nested-session behavior can block marketplace refresh, yielding cached-only latest inference:
   - `.cwf/projects/260219-01-pre-release-audit-pass2/iter2/artifacts/skill-smoke-260219-145730-postfix/12-update_.log`
4. Release metadata sync drift was previously observed as a lesson:
   - `.cwf/projects/260219-01-pre-release-audit-pass2/lessons.md` (Release Metadata Drift)
5. Version bump history from `0.8.1` onward:
   - `0.8.2` (`6d530cf`) → `0.8.3` (`08e6997`) → `0.8.4` (`4b1849c`) → `0.8.5` (`799d603`) → `0.8.6` (`24ac0ce`) → `0.8.7` (`b34c7b9`) → `0.8.8` (`b4c2c3c`)

## Working Diagnosis (Sections 1-3 basis)

- The team optimized for deterministic gate coverage and broad smoke throughput, but update correctness relied on proxy signals (cache snapshots) rather than source-of-truth metadata.
- Test contexts over-indexed on local/nested execution and under-indexed on real user update paths (top-level marketplace sync + scope-specific plugin update).
- Existing lessons captured symptoms (timeout, metadata drift, setup variance), but ownership/application routing did not force immediate hardening of update-specific invariants.

## Candidate Structural Causes for 5-Whys

1. Oracle mismatch: cache-based latest check treated as truth.
2. Environment realism gap: nested smoke behavior treated as representative.
3. Gate granularity gap: no explicit release gate asserting `marketplace manifest version == reported latest version path` for update flows.
4. Prioritization gap: iteration focus skewed to runtime timeout closure (`K46`, `S10`) over update semantic correctness in user environments.

