### Expert Reviewer α: James Reason

**Framework Context**: Organizational accident causation via the Swiss cheese model — latent conditions at managerial and organizational levels align with active failures at the sharp end to produce system accidents. Source: *Managing the Risks of Organizational Accidents* (Ashgate, 1997).

#### Concerns (blocking)

- [HIGH] **Proposal A (Deletion Safety Gate) relies on a prose defense that is itself vulnerable to the failure mode it addresses.** The document correctly identifies that AGENTS.md-level rules are compaction-vulnerable (Section 6, Proposal E rationale: "문서는 컴팩션에 취약하지만, hooks는 매 turn마다 새로 주입되므로 컴팩션을 살아남는다"). Yet Proposal A is implemented as rule text in `plugins/cwf/skills/impl/SKILL.md` — which is loaded once at skill invocation, not injected per-turn. In the Swiss cheese model, this is a defense layer with a known hole: it works when the agent reads the skill doc at the start of impl, but fails under the same compaction conditions that caused the original incident. For a P0 item labeled "do now," this is internally inconsistent. Either Proposal A must be coupled to a deterministic gate (e.g., a PreToolUse hook on `Bash` that greps for `git rm` and injects a caller-check reminder), or it should be demoted to P1 with an explicit note that E+G is the structural fix.
  - Section 6, Proposal A vs. Proposal E rationale (lines 163-181 vs. 237-275)

- [HIGH] **The proposal set lacks a recovery/detection layer — all seven proposals are prevention-only.** In defense-in-depth, the critical question is not only "how do we prevent the next hole from aligning?" but "how do we detect when holes have aligned before the accident reaches the user?" The incident narrative itself demonstrates this gap: the pre-push hook *did* detect the broken link (a downstream symptom of the deletion), but the agent treated it as a cosmetic issue and removed the signal rather than investigating the cause (Section 5, lines 146-153). This means the system had a detection layer that fired correctly, but the response protocol turned detection into signal elimination. Proposal B (Broken-Link Triage) partially addresses this by specifying a triage protocol, but it remains a prose rule — not a deterministic gate. A structurally complete defense requires at least one detection-and-halt mechanism: when a pre-push hook finds that a `git rm`'d file is referenced by a runtime script, the hook should *block the push*, not merely advise. This is what Proposal D would provide, but it is ranked P3. Given that Proposal D is the only proposal that functions as a hard, deterministic, compaction-immune detection layer, its ranking deserves reconsideration.
  - Section 6, Proposal D (lines 222-235) and Priority Matrix (lines 311-322)

- [MEDIUM] **Proposal E+G introduces a single point of reliance on `cwf-state.yaml` without addressing its own failure modes.** The design makes `cwf-state.yaml` the sole carrier of workflow state that the hook reads every turn. But the document does not address: (1) what happens if the state file is corrupted, deleted, or has stale data from a previous session; (2) what happens if `cwf:run` crashes or is interrupted before writing `remaining_gates`; (3) what happens if an agent modifies `cwf-state.yaml` directly (since it is a plain YAML file any agent can edit). In Reason's framework, these are *latent conditions* — they do not cause failures immediately, but they create the preconditions for a future aligned-holes incident. The proposal needs a "state file integrity" section: validation on read, staleness detection (e.g., session ID mismatch), and a fallback behavior when the file is absent or malformed.
  - Section 6, Proposal E implementation details (lines 265-273) and Proposal G (lines 293-307)

#### Suggestions (non-blocking)

- **Reframe the priority matrix using defense-in-depth layers, not individual proposal strength.** The current matrix (Section 7) ranks proposals by "prevention strength" and "effort," which is a cost-benefit lens. Reason's framework would instead ask: "Which layers of defense does each proposal occupy, and where are the remaining gaps?" A layered view would be:

  | Layer | Defense type | Proposals | Gap? |
  |-------|-------------|-----------|------|
  | 1. Prevention (organizational) | Workflow gate enforcement | E+G | No |
  | 2. Prevention (task-level) | Deletion safety, fidelity check | A, C | Compaction-vulnerable |
  | 3. Detection (automated) | Script dependency graph | D | Not yet implemented |
  | 4. Detection (agent-mediated) | Broken-link triage, session log review | B, F | Agent compliance required |
  | 5. Recovery | — | *None* | **Open gap** |

  This view immediately reveals two structural gaps: Layer 3 is deferred to P3, and Layer 5 (recovery — e.g., automatic restoration of deleted runtime files when a caller is found) does not exist at all. Prioritization should aim for at least one defense at each layer.

- **The 5 Whys analysis (Section 2) stops one level too early.** Why #5 identifies that "cwf:review was not executed on code changes" — but does not ask why the system design allowed a state where cwf:run could be started, its analysis phase completed, and its implementation phase entered, all without any mechanism to ensure the remaining gates would eventually fire. The deeper answer is that cwf:run's gate sequence existed only as an agent's in-memory plan, with no externalized state and no enforcement mechanism. This is precisely the "latent condition" that Proposal E+G addresses, but the 5 Whys should explicitly arrive at this conclusion to make the causal chain complete. As written, there is a logical gap between Why #5 ("review was not run") and the structural cause statement ("fidelity loss in analysis-to-triage"). These are two different failure chains that happened to co-occur in the same incident — the document should separate them clearly rather than presenting one structural cause.

- **Consider the "migration of violations" phenomenon.** Reason documents how organizations, after an incident, implement controls that address the specific failure but inadvertently push risk to adjacent areas. The current proposal set heavily targets file deletion scenarios (A, B, D) because the incident involved a deleted file. But the deeper pattern — "compaction causes gate skipping" — applies equally to non-deletion scenarios: a compaction during cwf:run could cause an agent to skip the `clarify` stage and proceed directly to `plan` with wrong assumptions, or skip `retro` and lose session learnings. Proposal E+G is the correct structural response because it is gate-general, not deletion-specific. The document should explicitly note that A, B, and D are *incident-specific* hardening while E+G is *class-general* hardening, to prevent future prioritization from treating them as interchangeable.

- **The "signal chain" diagram (Section 2) is excellent incident documentation — formalize it as a reusable template.** The chain from "deep review recommendation" through "triage distortion" to "implementation of the inverse action" to "signal elimination by agent" is a four-stage degradation pattern. This pattern (correct signal generated, distorted during summarization, inverted during execution, residual signal eliminated) is likely to recur. Adding this as a named anti-pattern (e.g., "Signal Inversion Chain") in `agent-patterns.md` would make it available for future reviews to reference.

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: James Reason
- framework: Swiss cheese model / organizational accident causation / defense-in-depth
- grounding: "Managing the Risks of Organizational Accidents" (Ashgate, 1997)
<!-- AGENT_COMPLETE -->
