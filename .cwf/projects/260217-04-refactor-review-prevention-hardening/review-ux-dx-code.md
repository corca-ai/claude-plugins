## UX/DX Review

### Concerns (blocking)
No blocking concerns identified.

### Suggestions (non-blocking)
- **[S1]** Add explicit missing-value guards for `--en`/`--ko` in `plugins/cwf/scripts/check-readme-structure.sh:37` and `plugins/cwf/scripts/check-readme-structure.sh:41` to return a clear actionable error instead of relying on `shift 2` failure behavior.
- **[S2]** Add a deterministic checker for code-mode synthesis `session_log_*` keys (similar to `plugins/cwf/scripts/check-review-routing.sh`) so the new contract in `plugins/cwf/skills/review/SKILL.md:547` and `plugins/cwf/skills/review/SKILL.md:640` is continuously enforced.
- **[S3]** Make `plugins/cwf/scripts/check-shared-reference-conformance.sh:97` resilient when no matches exist (for example, guard `rg` with `|| true`) so strict-mode failures are always reported via explicit conformance diagnostics.

### Behavioral Criteria Assessment
- [x] Given hook blocking and allow scenarios, when strict hook tests run, then each blocking path exits non-zero and each allow path exits zero — validated by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict` (`Summary: total=14 pass=14 fail=0`).
- [x] Given parser dedup and `/tmp` path filtering changes, when path-filter fixtures run, then false positives are skipped and hazard-relevant cases still block — validated in `suite_path_filter` assertions in `plugins/cwf/scripts/test-hook-exit-codes.sh:229` and execution PASS results.
- [x] Given AskUserQuestion tool_result data, when log-turn + compaction/restart simulation run, then decisions are persisted and idempotent — validated by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite decision-journal-e2e` (`Summary: total=12 pass=12 fail=0`) and checks in `plugins/cwf/scripts/test-hook-exit-codes.sh:298`.
- [x] Given review prompt line count is 1201+, when provider routing resolves external slots, then external CLI slots are skipped and cutoff evidence fields are defined — contract present in `plugins/cwf/skills/review/SKILL.md:176` and validated by `bash plugins/cwf/scripts/check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 --strict`.
- [x] Given runtime script references are broken, when script dependency check runs, then it exits non-zero with diagnostics — failure path is implemented in `plugins/cwf/scripts/check-script-deps.sh:147` and strict execution currently passes (`broken : 0`).
- [x] Given README heading structures diverge, when structure checker runs, then it exits non-zero with mismatch diagnostics — strict failure behavior is implemented in `plugins/cwf/scripts/check-readme-structure.sh:111` and `plugins/cwf/scripts/check-readme-structure.sh:157`; current aligned state passes strict check.
- [x] Given review mode code and session logs exist, when synthesis is generated, then confidence note includes deterministic session-log cross-check keys — required fields and policy are explicitly defined in `plugins/cwf/skills/review/SKILL.md:547` and `plugins/cwf/skills/review/SKILL.md:640`.
- [x] Given output-persistence instructions were extracted to shared reference, when conformance checker runs, then composing skills reference shared instructions and inline duplicates remain under threshold — validated by `bash plugins/cwf/scripts/check-shared-reference-conformance.sh --strict` and references in `plugins/cwf/references/agent-patterns.md:159` plus skill links.

### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: —
command: —
<!-- AGENT_COMPLETE -->
