# Codebase Deep Review (John Ousterhout Lens)

Assigned identity confirmed from `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-experts.json`: `John Ousterhout` is present in `selected` (source: *A Philosophy of Software Design*, 2018/2021).

## Top 3 concerns (blocking risks)
1. **Error-level complexity concentration in one control script**  
   `plugins/cwf/scripts/cwf-live-state.sh` (1095 lines, error threshold 800) is a high-risk shallow module: too much behavior behind one script surface increases change amplification and hidden dependencies.
2. **Orchestration boundary is overloaded across multiple large scripts**  
   `plugins/cwf/scripts/check-run-gate-artifacts.sh` (766), `plugins/cwf/scripts/codex/sync-session-logs.sh` (781), `plugins/cwf/scripts/check-session.sh` (613), and `plugins/cwf/hooks/scripts/log-turn.sh` (751) indicate boundary logic is spread but still not modularized into deep, reusable units.
3. **Control-path readability debt at decision points**  
   Long-line findings in gate/guard scripts (`plugins/cwf/hooks/scripts/redirect-websearch.sh:14`, `plugins/cwf/hooks/scripts/workflow-gate.sh:15`, `plugins/cwf/hooks/scripts/read-guard.sh:87`) reduce interface clarity exactly where operational correctness is decided.

## Top 3 suggestions (high leverage)
1. **Create one deep module for runtime state operations first**  
   Extract state read/write/validation primitives from `plugins/cwf/scripts/cwf-live-state.sh` into a single internal module with a minimal command-style API; keep orchestration script thin.
2. **Separate policy from mechanism in gate/check scripts**  
   Move shared mechanics out of `plugins/cwf/scripts/check-run-gate-artifacts.sh`, `plugins/cwf/scripts/check-session.sh`, and `plugins/cwf/scripts/codex/post-run-checks.sh`; keep each entry script focused on policy decisions only.
3. **Standardize “simple interface, complex internals” for hook controls**  
   For `plugins/cwf/hooks/scripts/workflow-gate.sh`, `plugins/cwf/hooks/scripts/log-turn.sh`, and `plugins/cwf/hooks/scripts/read-guard.sh`, define small named helper interfaces and replace dense inline condition chains so each script exposes fewer concepts at once.

## Prioritized first action
Start with `plugins/cwf/scripts/cwf-live-state.sh`: produce a 3-part extraction plan (state I/O, transition validation, report/rendering) and implement only the first extraction seam before any new feature work. This directly attacks the sole error-level hotspot and establishes the deep-module pattern for the rest of the codebase.
<!-- AGENT_COMPLETE -->
