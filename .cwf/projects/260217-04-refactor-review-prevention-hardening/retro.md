# Retro — 260217-04 Refactor Review Prevention Hardening

- Date: 2026-02-17
- Mode: light (manual retro after run-stage remediation)
- Session dir: `.cwf/projects/260217-04-refactor-review-prevention-hardening`

## 1. Context Worth Remembering

- This session was explicitly **deferred-inclusive**: Pack A/B/C plus deferred D/F/H/I were all required in one wave.
- The key quality target was not feature expansion, but deterministic hardening for prevention/review/recovery flows.
- The user prioritized strict protocol fidelity (review slot ordering, external-slot handling, and explicit gate closure) over speed.
- Code review was performed with 6 slots and a deterministic external cutoff (`prompt_lines > 1200`) that routed external slots to fallback by policy.

## 2. Collaboration Preferences

- The user wants immediate continuation across remaining gates, not partial stop-and-explain loops.
- The user expects direct root-cause accountability for protocol drift (why it happened, where ambiguity existed, how to prevent recurrence).
- The user accepts strong execution autonomy, but only when the execution path is traceable through concrete artifacts (plan/review/synthesis/logs).
- The user explicitly rejected unnecessary scope growth (no historical artifact rewrite; no unrelated feature additions).

### Suggested Agent-Guide Updates

- Add a mandatory “protocol-critical checklist” before review start:
  1. external slot routing path fixed
  2. fallback policy fixed
  3. one-pass launch evidence recorded
- Add a deterministic post-review closure rule:
  - if synthesis is `Revise`, either apply fixes in-session or explicitly mark carry-over blockers in `lessons.md`.

## 3. Waste Reduction

### Waste A — Protocol drift before explicit correction

- Symptom: external-slot/protocol concerns required repeated user challenge before hard correction was fully accepted.
- 5 Whys:
  - Why repeated? Initial execution favored local momentum over strict contract replay.
  - Why momentum-first? The orchestration path optimized for completion throughput when ambiguity existed.
  - Why ambiguity existed? “Protocol strictness vs practical fallback path” did not have a single enforced deterministic gate.
  - Why no deterministic gate? The rule was described in SKILL prose, but not fully encoded as hard preflight checks.
  - Why prose-only? Several meta-process constraints are still convention-heavy rather than script-enforced.
- Durable fix: convert protocol-critical checks into executable gates where feasible.

### Waste B — Review findings required immediate post-synthesis remediation

- Symptom: review surfaced moderate/critical concerns that required additional implementation loop before downstream gates.
- 5 Whys:
  - Why surfaced late? Some failure modes (degraded dependency/fail-open paths) were under-specified in strict tests.
  - Why under-specified? Existing suites emphasized normal path determinism, less degraded-path determinism.
  - Why degraded paths missing? Prior hardening iterations focused on breadth of controls before depth of failure semantics.
  - Why sequence like this? Deferred-inclusive packing compressed changes into one cycle.
  - Why acceptable? User prioritized completion of deferred scope now; depth-hardening followed immediately in same session.
- Durable fix: include degraded-path fixture requirements in future plan gate matrix upfront.

## 4. Critical Decision Analysis (CDM)

### CDM-1: Defer external CLI attempts under deterministic cutoff

- Cue: review target size exceeded 1200 prompt lines.
- Decision: apply policy cutoff and route external slots to fallback directly.
- Why: deterministic reliability over unstable long-prompt external CLI behavior.
- Outcome: 6-slot review completed without slot loss; provenance remained explicit.
- Risk: reduced model-diversity signal when cutoff triggers.
- Guardrail: keep cutoff evidence mandatory in synthesis Confidence Note.

### CDM-2: Implement review blockers before refactor/retro closure

- Cue: synthesis verdict `Revise` with fail-open and dependency-coverage concerns.
- Decision: patch `workflow-gate`, `check-script-deps`, and `log-turn` before proceeding.
- Why: downstream phases should not normalize known blocker paths.
- Outcome: targeted checks passed after fixes (`shellcheck`, hook strict suite, script dependency strict check).
- Risk: review artifacts become temporally split (pre-fix review + post-fix patch).
- Guardrail: keep synthesis + post-fix verification evidence in same session directory.

### CDM-3: Keep ship stage document-only in this run

- Cue: user requested no live issue creation.
- Decision: prepare ship documentation artifact instead of executing `gh issue/pr` actions.
- Why: preserve session closure trace without external side effects.
- Outcome: run remains auditable while respecting user control gate.

## 5. Expert Lens

### Expert α Lens — Charles Perrow (Normal Accidents)

- Main signal: concentrated common-mode risk at gate dependency boundaries can nullify multiple downstream controls.
- Session implication: fail-open behavior in `workflow-gate` had disproportionately high systemic risk despite otherwise strong deterministic coverage.
- Recommendation:
  1. Maintain fail-closed defaults for protected actions under dependency degradation.
  2. Expand regression suites to include degraded dependency scenarios.

### Expert β Lens — Nancy Leveson (STAMP/STPA)

- Main signal: unsafe control actions emerge when controller state observation degrades but action channel remains permissive.
- Session implication: `allow` under missing critical sensing dependencies was a control-loop hazard.
- Recommendation:
  1. Treat missing critical controller dependencies as blocked control action for protected intents.
  2. Preserve deterministic evidence fields in synthesis for control-loop traceability.

## 6. Learning Resources

1. `plugins/cwf/references/context-recovery-protocol.md`
- Why: this session repeatedly depended on persisted state quality and restart resilience.
- Value: offers explicit persistence/criticality model for recovery artifacts.

2. `plugins/cwf/references/agent-patterns.md`
- Why: output persistence and provenance contracts were central to reliable multi-agent review execution.
- Value: provides standardized persistence semantics that reduce orchestration drift.

3. `plugins/cwf/references/expert-advisor-guide.md`
- Why: expert-slot consistency and roster usage were recurring quality expectations.
- Value: defines contrast-driven expert selection and roster maintenance requirements.

## 7. Relevant Tools (Capabilities Included)

### Used effectively

- `plugins/cwf/scripts/test-hook-exit-codes.sh --strict`
- `plugins/cwf/scripts/check-script-deps.sh --strict`
- `plugins/cwf/skills/refactor/scripts/quick-scan.sh`
- `shellcheck -x` on touched hook/script files
- `plugins/cwf/scripts/cwf-live-state.sh` (state resolution/read)

### Available but still weakly gated

- Protocol-level enforcement around expert-roster maintenance and review-slot strictness remains mostly convention-driven.
- Degraded-path deterministic fixtures are still narrower than normal-path fixtures.

### Follow-up tool candidates

- Add a deterministic degraded-path suite for `workflow-gate` dependency failures.
- Add a conformance check to verify code-mode synthesis includes mandatory `session_log_*` fields from actual generated artifacts.
