### Expert Reviewer B: Sidney Dekker

**Framework Context**: Drift into failure -- how systems gradually migrate toward boundaries of safe operation through locally rational decisions, each appearing reasonable in isolation. Source: *Drift into Failure* (Ashgate, 2011).

#### Concerns (blocking)

- [HIGH] The retry-and-fallback mechanism in `runtime-residual-smoke.sh` constitutes a classic drift-into-failure pattern: it absorbs the variance signal rather than surfacing it.
  `scripts/runtime-residual-smoke.sh`, lines 233-301 (`run_case` retry loop + S10 fallback block)

  Dekker's framework holds that accidents and failures in complex systems are not caused by single dramatic breakdowns, but by the slow, incremental normalization of deviance. Each local decision -- "add a retry," "try a different prompt if the first fails," "classify the fallback result as PASS" -- is locally rational and well-intentioned. The problem is that the composite effect is a system that increasingly masks its own degradation signals.

  Specifically: when `S10` produces `NO_OUTPUT` after all retries, the script invokes `cwf:setup --hooks` as a fallback and, if that succeeds, records the run as `PASS/WAIT_INPUT`. The original failure mode (`NO_OUTPUT` on `cwf:setup`) is preserved only in `.retry2` / `.retry3` / `.fallback-hooks` log files, but the summary TSV -- the artifact that gates deployment -- records a `PASS`. This means the gate's authority is conditional on someone inspecting auxiliary log files, which experience shows no one does once the gate is green.

  This is exactly the pattern Dekker describes in drift scenarios: a safety barrier (the strict gate) is nominally present but has been incrementally adapted so that it can no longer detect the condition it was designed to catch. The system now needs two things to go wrong simultaneously (the primary prompt fails AND the fallback fails) before the gate reports failure, whereas it previously needed only one. The safety margin has narrowed, and nobody made a conscious decision to accept that trade-off.

  **Recommendation**: Keep the retry mechanism but decouple the reporting from the masking. Add a separate summary column (e.g., `retries`, `fallback_used`) to `summary.tsv` so that the gate can remain strict on `NO_OUTPUT` while still providing retry-based recovery as an operational convenience. In strict mode, a run that required fallback recovery should count toward a `degraded_count`, and the gate should have a threshold for degraded runs, not silently reclassify them as PASS.

- [MEDIUM] The `is_wait_input_log` heuristic grows by accretion without a governing invariant, creating a classification boundary that drifts silently.
  `scripts/runtime-residual-smoke.sh`, lines 163-168 (the grep pattern)

  The WAIT_INPUT classifier is a single extended regex with 20+ disjunctive patterns. Each new pattern was locally rational -- "this particular phrasing appeared in logs, so add it." But Dekker's work shows that accretive rule sets like this drift toward two failure modes simultaneously: (a) false negatives, where a new phrasing variant is not yet in the list, and (b) false positives, where a broad pattern like `would you like to` matches output that is not actually a user-input prompt.

  There is no structural test that validates the classifier against known-good and known-bad samples. The fixture test (`runtime-residual-smoke-fixtures.sh`) mocks the entire Claude invocation, so it never exercises the classifier against real output content. The classifier's correctness is assumed, not verified -- a classic condition for silent drift.

  **Recommendation**: Extract the classifier into a standalone function with its own fixture file containing labeled positive/negative samples. Test the classifier directly against these samples in the fixture suite. This creates a regression net that prevents silent drift of the classification boundary.

#### Suggestions (non-blocking)

- The HITL skill update (`plugins/cwf/skills/hitl/SKILL.md`) requiring `Related Context + Causal Lens` for every chunk is a strong structural countermeasure against drift. In Dekker's terms, it forces the reviewer to reconstruct the system context around each change rather than evaluating fragments in isolation. The `adjacent_fallback` escape hatch (`plugins/cwf/skills/hitl/references/hitl-state-model.md`, `context_refs` contract) is well-designed: it acknowledges that perfect semantic matching is not always possible while still mandating that at least one contextual anchor be present. This is exactly the kind of "defense in depth that acknowledges fallibility" Dekker advocates.

- The `next-prompt-dir.sh` inline `sessions: []` fix (`plugins/cwf/scripts/next-prompt-dir.sh`, lines 165-181) is a good example of closing a YAML shape compatibility gap, but it introduces two separate code paths for the same logical operation (append session entry). Dekker's drift model warns that divergent paths handling the same semantic operation tend to drift apart over time as patches are applied to one but not the other. Consider refactoring toward a single canonical path that normalizes both shapes before performing the append. The fixture coverage added in `scripts/tests/next-prompt-dir-fixtures.sh` (inline session tests, lines 111-135) mitigates this risk well for now.

- The `setup/SKILL.md` routing change from prefix-only to anywhere-in-input token matching (`plugins/cwf/skills/setup/SKILL.md`, Namespace Routing Guard) expands the activation surface. While this resolves the immediate routing miss, it introduces a wider trigger surface that could cause unintended skill activation if `cwf:setup` appears in quoted references or log output pasted into prompts. This is minor and likely acceptable, but worth monitoring.

- The six `retro-light` directories created on a single day (`.cwf/projects/260220-01` through `260220-06`) are a visible artifact of the kind of repetitive debugging loop that Dekker would call a "practical drift signal" -- the system is being exercised harder than its design envelope assumed. The retro outputs themselves repeatedly flag this pattern (e.g., K46-run1.log: "retro-light 디렉토리가 6개 누적"). The fact that the system recognizes its own drift but does not structurally prevent it is worth addressing: consider a day-level deduplication guard or a warning threshold in the bootstrap script.

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: Sidney Dekker
- framework: drift into failure, local rationality, just culture
- grounding: *Drift into Failure* (Ashgate, 2011)
<!-- AGENT_COMPLETE -->
