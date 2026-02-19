## Correctness Review

### Concerns (blocking)
- **[C1]** `check-script-deps` does not cover common local script edges, so strict mode can miss broken runtime dependencies.
  Evidence: dependency extraction only matches `plugins/cwf|${CWF_PLUGIN_DIR}|${CLAUDE_PLUGIN_ROOT}|$PLUGIN_ROOT` prefixes in `plugins/cwf/scripts/check-script-deps.sh:112`, while many real runtime edges are local includes such as `source "$SCRIPT_DIR/..."` (for example `plugins/cwf/hooks/scripts/check-markdown.sh:12`, `plugins/cwf/hooks/scripts/log-turn.sh:11`). A broken local include would not be surfaced by `bash plugins/cwf/scripts/check-script-deps.sh --strict`.
  Severity: moderate
- **[C2]** New async decision-journal persistence introduces an unlocked cross-process write race on live state.
  Evidence: async hook path writes journal entries from `plugins/cwf/hooks/scripts/log-turn.sh:717` (via `journal-append` at `plugins/cwf/hooks/scripts/log-turn.sh:191`), but live-state mutators (`plugins/cwf/scripts/cwf-live-state.sh:225`, `plugins/cwf/scripts/cwf-live-state.sh:391`, `plugins/cwf/scripts/cwf-live-state.sh:511`) use read-modify-write (`mktemp` + `mv`) without an inter-process lock. This can clobber concurrent updates (for example `remaining_gates` vs `decision_journal`) under overlapping hook/skill writes.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** Expand dependency extraction in `plugins/cwf/scripts/check-script-deps.sh` to include `$SCRIPT_DIR` / `${SCRIPT_DIR}` / relative `.sh` edges, then add a negative fixture test proving `--strict` fails on one intentionally broken local include.
- **[S2]** Add a shared lock helper (for example `flock` on a repo-local lock file) around all mutating commands in `plugins/cwf/scripts/cwf-live-state.sh` (`set`, `list-set`, `list-remove`, `journal-append`) to make concurrent hook/skill writes deterministic.
- **[S3]** Add a deterministic executable check for the new session-log confidence fields (currently policy-only in `plugins/cwf/skills/review/SKILL.md:552`) so criterion coverage is enforced by a gate, not only by prompt contract.

### Behavioral Criteria Assessment
- [x] Given hook blocking and allow scenarios / When strict hook tests run / Then block paths exit non-zero and allow paths exit zero — verified by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict` (Summary: `total=14 pass=14 fail=0`).
- [x] Given parser dedup and /tmp path filtering changes / When path-filter fixtures run / Then false positives are skipped and hazard-relevant paths still block — verified by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite path-filter` (6/6 pass).
- [x] Given AskUserQuestion tool_result data / When log-turn + compaction/restart simulation run / Then decisions persist and idempotency prevents duplicates — verified by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite decision-journal-e2e` (12/12 pass, idempotency assertion included).
- [x] Given review prompt line count is 1201+ / When provider routing resolves slots / Then external CLIs are skipped with cutoff provenance — contract and deterministic checker align in `plugins/cwf/skills/review/SKILL.md:175` and `bash plugins/cwf/scripts/check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 --strict` (pass).
- [ ] Given runtime script references are broken / When script dependency check runs / Then it exits non-zero with broken-edge diagnostics — partially met; `check-script-deps` passes on current tree but has coverage gaps for local `$SCRIPT_DIR` edges (`plugins/cwf/scripts/check-script-deps.sh:112`), so this criterion is not fully guaranteed.
- [x] Given README.ko.md and README.md heading structures diverge / When structure checker runs / Then it exits non-zero with missing/extra/reordered diagnostics — strict checker is present and passes on current state (`bash plugins/cwf/scripts/check-readme-structure.sh --strict`).
- [x] Given review mode code and session logs exist / When synthesis is generated / Then confidence note includes deterministic session-log cross-check keys — explicitly required by `plugins/cwf/skills/review/SKILL.md:552` and mandatory key list at `plugins/cwf/skills/review/SKILL.md:560`.
- [x] Given output-persistence instructions were extracted / When conformance checker runs / Then composing skills reference shared instructions and inline duplicates stay below threshold — verified by `bash plugins/cwf/scripts/check-shared-reference-conformance.sh --strict` (pass, inline markers `24/24`).

### Provenance
source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness
duration_ms: —
command: —

<!-- AGENT_COMPLETE -->
