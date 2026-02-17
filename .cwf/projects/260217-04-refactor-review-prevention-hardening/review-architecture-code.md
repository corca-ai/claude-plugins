## Architecture Review

### Concerns (blocking)
- **[C1]** `check-script-deps.sh` has a blind spot for `${PLUGIN_ROOT}`-style references, so runtime dependency edges are under-reported.
  Evidence: matcher/normalizer only handle `$PLUGIN_ROOT` (no-brace form) in `plugins/cwf/scripts/check-script-deps.sh:65` and `plugins/cwf/scripts/check-script-deps.sh:112`, while actual runtime references use `${PLUGIN_ROOT}` in `plugins/cwf/hooks/scripts/log-turn.sh:19`, `plugins/cwf/hooks/scripts/log-turn.sh:20`, `plugins/cwf/hooks/scripts/compact-context.sh:20`, and `plugins/cwf/hooks/scripts/compact-context.sh:21`.
  Impact: broken internal script edges can bypass the new deterministic dependency gate, so Success Criteria #5 is only partially enforced.
  Severity: moderate

- **[C2]** Decision-journal persistence is fail-open and silent on write failure, which weakens the compaction/restart recovery contract.
  Evidence: journal capture exits early when prerequisites are missing (`plugins/cwf/hooks/scripts/log-turn.sh:146`, `plugins/cwf/hooks/scripts/log-turn.sh:149`) and suppresses append errors (`plugins/cwf/hooks/scripts/log-turn.sh:191`). The recovery contract treats decision-journal persistence as a required resilience mechanism (`plugins/cwf/references/context-recovery-protocol.md:13`).
  Impact: AskUserQuestion decisions can be dropped without signal, causing recovery behavior to diverge from persisted-state expectations.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** Expand dependency edge extraction to include `${PLUGIN_ROOT}` and non-`.sh` runtime artifacts (for example `.pl`) in `plugins/cwf/scripts/check-script-deps.sh` to reduce false negatives.
- **[S2]** Extract shared path-filter helpers (`resolve_abs_path`, `is_external_tmp_path`) into a common hook utility to reduce copy/paste drift across `plugins/cwf/hooks/scripts/check-markdown.sh`, `plugins/cwf/hooks/scripts/check-shell.sh`, and `plugins/cwf/hooks/scripts/check-links-local.sh`.
- **[S3]** Add a deterministic checker for code-mode synthesis `session_log_*` fields (not only doc-contract presence) so Success Criteria #7 is runtime-validated, not specification-validated only.

### Behavioral Criteria Assessment
- [x] Given hook blocking and allow scenarios, when strict hook tests run, then blocking paths and allow paths behave as expected — verified by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict` (14/14 pass).
- [x] Given parser dedup and `/tmp` path filtering changes, when path-filter fixtures run, then false positives are skipped and hazard-relevant cases still block — covered in strict suite `path-filter` results.
- [x] Given AskUserQuestion tool_result data, when log-turn plus compaction simulation run, then decisions persist with idempotency/replay safety — verified by `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite decision-journal-e2e` (12/12 pass).
- [x] Given review prompt line count is 1201+, when routing resolves external slots, then external CLI is skipped with deterministic cutoff metadata — verified by `bash plugins/cwf/scripts/check-review-routing.sh --line-count 1199 --line-count 1200 --line-count 1201 --strict`.
- [ ] Given runtime script references are broken, when dependency check runs, then it exits non-zero with complete broken-edge diagnostics — partially unmet due `${PLUGIN_ROOT}` edge extraction gap (`plugins/cwf/scripts/check-script-deps.sh:112`).
- [x] Given README heading structures diverge, when structure checker runs, then it exits non-zero with diagnostics — behavior implemented in `plugins/cwf/scripts/check-readme-structure.sh` and baseline strict run passes when aligned.
- [x] Given review mode code and session logs exist, when synthesis is generated, then confidence note includes deterministic `session_log_*` keys — contract is explicitly enforced in `plugins/cwf/skills/review/SKILL.md:550` and `plugins/cwf/skills/review/SKILL.md:643`.
- [x] Given output-persistence extraction to shared reference, when conformance checker runs, then composing skills reference shared instructions and duplicate blocks are bounded — verified by `bash plugins/cwf/scripts/check-shared-reference-conformance.sh --strict` (PASS, inline markers 24/24).

### Provenance
source: FALLBACK
tool: claude-task-fallback
reviewer: Architecture
duration_ms: —
command: —

<!-- AGENT_COMPLETE -->
