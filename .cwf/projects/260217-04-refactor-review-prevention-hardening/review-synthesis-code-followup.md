## Review Synthesis Follow-up (Post-Revise Fixes)

### Scope
Follow-up remediation for blockers raised in `review-synthesis-code.md`:
- `workflow-gate` fail-open degradation paths
- `check-script-deps` dependency-edge coverage gaps
- `log-turn` silent decision journal append failure path

### Applied Changes
- `plugins/cwf/hooks/scripts/workflow-gate.sh`
  - Added protected-action fail-closed behavior when critical dependencies are missing.
  - Added malformed/missing live-state key detection for gate-critical reads.
  - Reworked JSON field extraction to support degraded dependency mode safely.
- `plugins/cwf/scripts/check-script-deps.sh`
  - Added `${PLUGIN_ROOT}`/`$PLUGIN_ROOT`, `${CWF_PLUGIN_DIR}`/`$CWF_PLUGIN_DIR`, `${CLAUDE_PLUGIN_ROOT}`/`$CLAUDE_PLUGIN_ROOT` normalization parity.
  - Added `${SCRIPT_DIR}`/`$SCRIPT_DIR` edge extraction.
  - Expanded edge matching to include `.pl` runtime references.
  - Ignored full-line comments during edge extraction to reduce false positives.
- `plugins/cwf/hooks/scripts/log-turn.sh`
  - Replaced silent `journal-append` suppression with explicit warning emission on append failure.

### Deterministic Verification
- `shellcheck -x plugins/cwf/hooks/scripts/workflow-gate.sh plugins/cwf/hooks/scripts/log-turn.sh plugins/cwf/scripts/check-script-deps.sh` → pass
- `bash plugins/cwf/scripts/test-hook-exit-codes.sh --strict` → pass (`14/14`)
- `bash plugins/cwf/scripts/check-script-deps.sh --strict` → pass (`broken: 0`)

### Updated Status
- Previously flagged blocker paths are remediated in this session.
- No new deterministic gate regressions were observed in post-fix checks.
- Residual work is now pipeline closure work (`retro`, ship-doc artifacting), not blocker remediation.
