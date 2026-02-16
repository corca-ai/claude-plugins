## Review Synthesis

### Verdict: Conditional Pass
All 12 behavioral criteria pass across all 6 reviewers. Multiple moderate concerns were identified — most notably code duplication (flagged by 4/6 reviewers), a fixed temp file race condition (3/6), and a trailing delimiter mismatch (2/6). No critical or security-severity concerns.

### Behavioral Criteria Verification
- [x] BDD-1: Delete file with runtime callers → hook exits 1 BLOCKED — Security, UX/DX, Correctness, Architecture, Expert α, Expert β: all confirmed via `json_block` at diff lines 329-335
- [x] BDD-2: Delete file with no callers → hook exits 0 — All reviewers: confirmed via exit 0 at diff lines 241, 275, 317
- [x] BDD-3: grep fails or parse error → fail-closed exit 1 — All reviewers: confirmed via SEARCH_FAILED flag and jq-missing block
- [x] BDD-4: rm -rf node_modules → excluded, exit 0 — All reviewers: confirmed via case statement skip + --exclude-dir
- [x] BDD-5: Broken link → triage protocol reference — All reviewers: confirmed in check-links-local.sh diff line 345 + agent-patterns.md triage matrix
- [x] BDD-6: Triage contradicts analysis → follow original — All reviewers: confirmed in impl/SKILL.md Rule 16
- [x] BDD-7: cwf:run active + review-code pending + ship → blocked — All reviewers: confirmed via list_contains + prompt_requests_blocked_action
- [x] BDD-8: Stage completes → remaining_gates updated — All reviewers: confirmed via list-set/list-remove + run/SKILL.md integration
- [x] BDD-9: Stale pipeline → cleanup prompt — All reviewers: confirmed via session ID comparison at diff lines 515-517
- [x] BDD-10: Active pipeline + empty gates → stale warning — All reviewers: confirmed at diff lines 526-528
- [x] BDD-11: 500-line prompt → 180s timeout — All reviewers: confirmed via review/SKILL.md scaling table
- [x] BDD-12: 100-line prompt → 120s timeout — All reviewers: confirmed via review/SKILL.md scaling table

### Concerns (must address)

- **Security C1 + UX/DX C3 + Architecture C4** [moderate]: Fixed temp file `/tmp/cwf-deletion-safety.err` creates a TOCTOU race condition and concurrent session collision. Use `mktemp` instead.
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff line 203

- **UX/DX C2 + Architecture C1 + Expert α + Expert β** [moderate]: ~90 lines of AWK list/scalar extraction logic duplicated between `workflow-gate.sh` and `cwf-live-state.sh`, plus `trim_ws`/`strip_quotes`/`normalize_scalar` duplicated again in `check-deletion-safety.sh`. Three independent copies will drift. `cwf-live-state.sh` already exists as a sourceable library. Source it instead of inlining.
  Files: `workflow-gate.sh` (lines 75-131, 427-476), `check-deletion-safety.sh` (lines 100-113), `cwf-live-state.sh` (lines 76-91, 706-738)

- **UX/DX C1 + Correctness C2** [moderate]: `caller_preview` built with `"; "` separator but trimmed with `%, ` (comma-space). Trailing `"; "` is never stripped. Fix: `${caller_preview%; }`.
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 325-327

- **Correctness C1** [moderate]: `list-remove` CLI handler bumps `state_version` independently on both files, causing version drift. `list-set` correctly captures version from effective state and writes same value to root state. `list-remove` should follow the same pattern.
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 1038-1047

- **Security C2 + Architecture C3** [moderate]: `cwf_live_sanitize_yaml_value` comment claims to neutralize `{ } :` but code only replaces `[ ]`. Either implement the full sanitization or correct the comment.
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 645-655

### Suggestions (optional improvements)

- **Security S1 + UX/DX C4**: `workflow-gate.sh` exits 0 (fail-open) when jq missing, while `check-deletion-safety.sh` blocks. Inconsistency is a design choice (advisory vs safety), but worth documenting the rationale or at least emitting a warning via `json_allow`.
- **UX/DX S1**: `check-deletion-safety.sh` has no `timeout` in hooks.json. Consider 10s explicit timeout for grep-rl on large repos.
- **UX/DX S2**: `--help` output uses `sed -n '3,22p'` but header has grown; truncation risk.
- **UX/DX S3**: `hooks/README.md` not updated with new hook entries.
- **UX/DX S4 + Expert β**: `cwf_live_sanitize_yaml_value` replaces `[]` with fullwidth chars — lossy transformation that could corrupt legitimate brackets. Document prominently or use proper YAML quoting only.
- **UX/DX S5**: Korean terms in regex need inline comments for non-Korean contributors.
- **UX/DX S7**: Stale pipeline warning command is not copy-pasteable (lacks full path).
- **Correctness S3**: `combined_hits` conditional with `:` is dead code / debugging residue.
- **Correctness S4**: `CALLER_LINES` 6-limit is global across all deleted files, not per-file.
- **Expert β**: `remaining_gates` is a derived quantity from `phase` — maintaining it as independent mutable state creates tight coupling. Consider deriving from phase + stage table.
- **Expert β**: Detection boundary for `prompt_requests_blocked_action` regex should be documented like deletion hook's boundary.
- **Expert α**: Rule 16 (Proposal C) is an administrative control, not engineered — correctly paired with Proposal A's hook but should not count as independent defense layer.

### Commit Boundary Guidance
- `tidy`: comment fix in sanitize function, separator fix, dead code removal, documentation updates (hooks/README.md, detection boundary comments, Korean term comments)
- `behavior-policy`: mktemp for temp file, source shared functions from cwf-live-state.sh, list-remove version sync fix
- Split into separate commits: tidy first, then behavior-policy.
- After first unit, run `git status --short`, confirm boundary, then commit before next unit.

### Confidence Note
- **Reviewer consensus**: Code duplication was the most widely-flagged concern (4/6 reviewers). Fixed temp file race was second (3/6). These two are high-confidence findings.
- **Reviewer disagreement**: Expert α (James Reason) gave Pass; Expert β (Charles Perrow) raised 2 blocking concerns. Conservative default applies — stricter assessment wins for verdict determination.
- **Expert identity deviation**: Expert β was assigned Sidney Dekker but independently selected Charles Perrow. Both are Normal Accident Theory-adjacent frameworks; the analysis quality is unaffected.
- **Base: marketplace-v3 (fallback — logical parent branch, 6 commits ahead)**
- **Slot 3 (codex) FAILED → fallback. Cause: timeout after 180s (EXIT_CODE=124). Codex attempted to create and run test harnesses, exceeding the time budget. → `codex auth login`.**
- **Slot 4 (gemini) succeeded: REAL_EXECUTION, 138874ms**

### Reviewer Provenance
| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | FALLBACK | claude-task-fallback | — |
| Architecture | REAL_EXECUTION | gemini | 138874ms |
| Expert Alpha (James Reason) | REAL_EXECUTION | claude-task | — |
| Expert Beta (Charles Perrow) | REAL_EXECUTION | claude-task | — |
