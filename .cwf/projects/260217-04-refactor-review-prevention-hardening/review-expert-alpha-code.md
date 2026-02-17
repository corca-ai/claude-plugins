### Expert Reviewer α: Charles Perrow

**Framework Context**: Through normal accident theory, I examined where interactive complexity and tight coupling can turn local defects into system-wide control loss (*Normal Accidents*, 1984/1999). Behavioral criteria evidence from real execution is mostly positive (`test-hook-exit-codes --strict`, `--suite decision-journal-e2e`, `check-script-deps --strict`, `check-readme-structure --strict`, `check-review-routing --strict`, `check-shared-reference-conformance --strict` all passed), but one coupling hazard remains blocking.

#### Concerns (blocking)
- [high] Workflow gate parsing is fail-open under malformed-but-present live state, creating a common-mode bypass of the safety gate. `workflow-gate.sh` expects parser failures to block (`plugins/cwf/hooks/scripts/workflow-gate.sh:56`, `plugins/cwf/hooks/scripts/workflow-gate.sh:66`), but `cwf-live-state.sh get/list-get` returns success with empty values when extraction misses keys (`plugins/cwf/scripts/cwf-live-state.sh:367`, `plugins/cwf/scripts/cwf-live-state.sh:388`). Gate logic then allows progress on empty `active_pipeline` or empty `remaining_gates` (`plugins/cwf/hooks/scripts/workflow-gate.sh:116`, `plugins/cwf/hooks/scripts/workflow-gate.sh:140`). Reproduced in real execution: malformed indentation yielded `exit=0` with no block on `git push` intent; malformed `remaining_gates` yielded allow-warning despite active pipeline. This violates the plan’s fail-closed qualitative criterion and concentrates risk into a single parser mode.

#### Suggestions (non-blocking)
- Add strict query semantics to `cwf-live-state.sh` for gate use (for example `get --require-key`, `list-get --require-key`) and treat missing/unparseable key as non-zero; wire `workflow-gate.sh` to strict mode.
- Add a deterministic malformed-state suite to `plugins/cwf/scripts/test-hook-exit-codes.sh` that asserts block behavior for: malformed `active_pipeline`, malformed `remaining_gates`, and mismatched list indentation.
- Reduce duplicated `/tmp` filtering logic across `plugins/cwf/hooks/scripts/check-markdown.sh:14`, `plugins/cwf/hooks/scripts/check-shell.sh:14`, `plugins/cwf/hooks/scripts/check-links-local.sh:13`, and `plugins/cwf/hooks/scripts/check-deletion-safety.sh:86` via one shared helper to lower divergence-driven common-mode bugs.
- Strengthen criterion verification for review routing/session-log fields by adding an executable fixture path (not only token presence checks in `plugins/cwf/scripts/check-review-routing.sh:74`).

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: Charles Perrow
- framework: normal accident theory
- grounding: Normal Accidents (1984/1999)

<!-- AGENT_COMPLETE -->
