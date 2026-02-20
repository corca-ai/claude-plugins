### Expert Reviewer α: Nancy Leveson

**Framework Context**: Systems safety engineering via STAMP/STPA — analyzing accidents and hazards as emergent properties of inadequate control structures rather than component failures. Source: *Engineering a Safer World: Systems Thinking Applied to Safety* (MIT Press, 2011).

#### Concerns (blocking)

- [HIGH] **Retry/fallback logic in `runtime-residual-smoke.sh` masks hazardous control actions rather than enforcing safety constraints.**

  The `run_case()` function (lines 203-308 of `scripts/runtime-residual-smoke.sh`) introduces a layered recovery strategy: per-case retries (`K46_TIMEOUT_RETRIES`, `S10_NO_OUTPUT_RETRIES`) followed by an S10-specific fallback prompt (`cwf:setup --hooks`). When all retry/fallback paths exhaust and still fail, the final failure is recorded — but when any single retry or fallback succeeds, the original failure evidence is overwritten via `cp "$attempt_log" "$log_file"` (line 263) or `cp "$fallback_log" "$log_file"` (line 293).

  In STAMP terms, this is a **flawed process model inside the controller**: the smoke script is a safety control structure intended to detect and surface runtime residuals. But the retry+fallback mechanism causes the controller to update its process model with "PASS" when the underlying controlled process (the Claude runtime) actually exhibited hazardous behavior (NO_OUTPUT, TIMEOUT) on earlier attempts. The summary TSV — which downstream gates consume — records only the final verdict, not the trajectory of transient failures.

  This matters because transient failures are *leading indicators* of systemic drift. Leveson's STAMP framework emphasizes that accidents emerge from gradual erosion of safety margins, not sudden breakdowns. A system that intermittently produces NO_OUTPUT on 2 of 3 attempts before a retry succeeds is exhibiting degraded control authority — the kind of signal that STAMP requires controllers to propagate upward, not absorb.

  Specific files/lines:
  - `scripts/runtime-residual-smoke.sh`, lines 253-258: retry loop absorbs transient failures
  - `scripts/runtime-residual-smoke.sh`, lines 262-266: successful retry overwrites original log
  - `scripts/runtime-residual-smoke.sh`, lines 268-302: fallback prompt overwrites original classification
  - `scripts/runtime-residual-smoke.sh`, line 304: summary TSV receives only the final result

  **Recommended control action**: The summary TSV should include a column for `attempts` and `transient_failures` so that downstream gates (strict mode, premerge) can apply threshold policies on transient failure rates — not just final outcomes. The retry evidence files (`.retry2`, `.retry3`, `.fallback-hooks`) are preserved on disk, which is good, but no structured metadata propagates their existence to consumers.

- [MEDIUM] **`classify_case_result()` communicates state through global variables (`RUN_RESULT`, `RUN_REASON`), creating an unsafe shared-state control channel.**

  `scripts/runtime-residual-smoke.sh`, lines 170-191: The `classify_case_result` function sets `RUN_RESULT` and `RUN_REASON` as implicit globals, which are then consumed by both the retry loop in `run_case()` and the fallback block. This pattern introduces coupling hazards: any future caller of `classify_case_result` must know to read these globals before the next call overwrites them.

  In STAMP, this is a control flaw where the communication channel between components lacks enforcement of message ordering. In shell scripting, this is a pragmatic compromise, but given that this function is now called in two separate contexts within `run_case()` (retry loop at line 250, fallback at line 289), the risk of a read-before-write race in future modifications is real. At minimum, the two global names should be documented as part of the function's contract.

#### Suggestions (non-blocking)

- **Expose transient failure metadata in structured form.** Beyond the TSV column suggestion above, consider emitting a `manifest.json` alongside `summary.tsv` that records per-run attempt counts, retry reasons, and fallback outcomes. This would allow automated analysis of failure drift across releases — a core STAMP recommendation for continuous monitoring of control effectiveness.

- **The HITL `context_refs` contract (`plugins/cwf/skills/hitl/references/hitl-state-model.md`, new lines in queue.json schema) is a strong safety control.** Requiring at least one related context reference per chunk before human review is directly analogous to what STAMP calls "adequate process model for the human controller": humans cannot make safe decisions about isolated code without understanding its control relationships. The `adjacent_fallback` relation type is a good degraded-mode design — it acknowledges that providing imperfect context is safer than providing no context. One improvement: the `rationale` field in `context_refs` should be mandatory and non-empty, enforced by validation, not just by documentation. A ref with `rationale: ""` provides no more safety assurance than a missing ref.

- **The setup SKILL.md routing guard change (prefix match to token-anywhere match) is a correct safety control tightening.** `plugins/cwf/skills/setup/SKILL.md`, lines 62-66: The prior prefix-only routing meant that `cwf:setup` embedded in a longer instruction could be misrouted to another skill family — a control authority violation. The token-anywhere match fixes this. However, the guard is specified in natural language ("detect by token match") rather than as a formal regex or parser rule. For a namespace routing guard that prevents skill misrouting — a safety-critical function — the specification should include the exact matching rule (e.g., `\bcwf:setup\b`) to prevent implementation drift across model versions.

- **The `next-prompt-dir.sh` inline sessions expansion (`sessions: []` to block format) is a good boundary hardening.** `plugins/cwf/scripts/next-prompt-dir.sh`, lines 165-176: handling the empty-array YAML form (`sessions: []`) prevents a state-file parsing failure that could cascade into session isolation violations. This is a textbook example of what STAMP calls "removing control flaws at component boundaries."

- **The `is_wait_input_log()` heuristic (line 163-168) is an increasingly fragile pattern detector.** The grep regex now contains 20+ alternation patterns for detecting WAIT_INPUT. Each new pattern is added reactively when a new prompt wording is observed. In STAMP terms, this is a controller whose process model must be manually updated every time the controlled process changes its output format. Consider requiring the Claude output to include a structured sentinel (e.g., `[WAIT_INPUT]` as a first-line marker) rather than relying on heuristic phrase matching. This would make the control channel reliable by design rather than by empirical tuning.

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: Nancy Leveson
- framework: STAMP/STPA (Systems-Theoretic Accident Model and Processes)
- grounding: *Engineering a Safer World: Systems Thinking Applied to Safety* (MIT Press, 2011)
<!-- AGENT_COMPLETE -->
