### Expert Reviewer β: Gary Klein

**Framework Context**: Naturalistic Decision-Making (NDM) and Recognition-Primed Decision (RPD) model — how experienced practitioners make decisions under time pressure, uncertainty, and shifting conditions. Source: *Sources of Power: How People Make Decisions* (MIT Press, 1998).

#### Concerns (blocking)

- [HIGH] **Proposal E+G treats the agent as a forgetful expert rather than a novice pattern-matcher, leading to an enforcement mechanism that addresses symptoms rather than decision architecture.**

  The RPD model describes how experienced decision-makers recognize situations by matching them to prior patterns, then mentally simulate an action to check whether it will work. The 260216 incident reveals that the agent is not operating in RPD mode at all — it has no "experience base" to recognize "unreferenced file" as a pattern that should trigger caller-check before deletion. The agent is operating closer to what NDM research calls a "novice" — applying surface-level rules (unreferenced → remove) without the deep situation awareness that an experienced operator would bring.

  Proposal E+G (hook-based workflow enforcement) is architecturally sound for the compaction problem, but it fundamentally mischaracterizes the decision failure. The hook injects *reminders about remaining gates*, which helps when the agent *knows what to do* but *forgets the workflow*. However, the csv-to-toon.sh deletion happened *within* the impl phase — the agent was executing its current gate, not skipping one. Even with a perfect workflow-gate hook running every turn, the agent would still have been inside the impl phase when it executed `git rm csv-to-toon.sh`. The hook would have said "remaining gates: review-code, refactor, retro, ship" — and the agent would have proceeded with the deletion anyway, because the deletion was part of impl execution, not a gate skip.

  The real protection came later, at the review-code gate. So the E+G mechanism is valuable as a "don't skip review" enforcer, but the document's framing that E+G is the *core structural defense* overweights it. The deletion decision itself was a recognition failure during impl, not a workflow-skip failure.

  Reference: Section 7, Priority Matrix — E+G rated "Very high" prevention strength; Section 6, Proposal E rationale.

- [MEDIUM] **Proposal A (Deletion Safety Gate) is undervalued relative to its decision-theoretic importance — it is the only proposal that intervenes at the actual decision point.**

  In NDM terms, the critical decision was the moment the impl agent encountered P3-16 ("Remove gather unreferenced csv-to-toon.sh") and chose to execute `git rm`. The RPD model predicts that an experienced operator, upon encountering a "delete file" action, would mentally simulate the consequences — "what breaks if this file disappears?" This mental simulation is exactly what Proposal A codifies: a mandatory caller-check before deletion.

  Proposal A is the *only* proposal that operates at the decision point itself. Proposals E+G operate upstream (don't skip review gates) and Proposal B operates downstream (when broken links surface later). In the RPD framework, the highest-leverage intervention is always at the recognition/simulation moment — making the agent perform the mental simulation that an experienced operator would do naturally. Proposal A does this. Yet it is given the same priority tier as B and E+G, and the document explicitly states "E+G가 최우선" (E+G is top priority), subordinating A.

  The document should recognize that A is the *direct causal prevention* (it stops the bad decision) while E+G is an *indirect structural prevention* (it ensures a later gate exists to catch mistakes). Both are P0, but A should be marked as the primary prevention, not E+G.

  Reference: Section 7, Priority Matrix — A and E+G both P0 but E+G framed as primary.

- [MEDIUM] **The 5 Whys analysis (Section 2) stops one level too early — it does not reach the decision environment that made the wrong action "obvious."**

  NDM research emphasizes that errors are rarely caused by bad decision-making in isolation; they are caused by decision environments that make the wrong action look like the right one. The 5 Whys reaches "왜 cwf:review가 이를 잡지 못했나?" (Why didn't cwf:review catch this?) — which is a process gap, not a decision-environment analysis.

  The missing 6th Why: **Why did the label "unreferenced csv-to-toon.sh" make "delete" the obvious action rather than "add reference"?** The answer is that the triage artifact (analysis.md) was structured as a problem list, not a decision list. Each item described *what was wrong* without preserving *what to do about it*. In NDM terms, the triage artifact created a "garden path" — a situation representation that channels the decision-maker toward one action (remove the anomaly) while obscuring the correct action (fix the reference gap).

  This matters because it changes the prevention strategy. If the root cause is "review was skipped," the fix is "enforce review." If the root cause is "the triage artifact's structure made the wrong action obvious," the fix is to change the triage artifact format — which is closer to Proposal C (fidelity check), currently deprioritized to P2.

  Reference: Section 2, 5 Whys analysis, points 1-5.

#### Suggestions (non-blocking)

- **Restructure the priority matrix around decision points, not failure modes.** The current matrix organizes proposals by "what went wrong" (deletion without checking, broken-link mishandling, workflow skipping, triage distortion). NDM would organize them by "where in the decision chain can we intervene?" — (1) at the triage artifact that shaped the decision (Proposal C), (2) at the deletion decision itself (Proposal A), (3) at the post-impl review gate (Proposal E+G), (4) at the broken-link signal (Proposal B). This ordering reveals that the document's P0 tier covers points 2, 3, and 4 but omits point 1 (Proposal C at P2). A decision-chain framing would naturally elevate C to at least P1.

- **Add a "pre-mortem" step to cwf:impl for high-risk actions.** Klein's pre-mortem technique (described in *Sources of Power*, Chapter 4) asks "imagine this action has failed — what went wrong?" before executing. For the impl phase, high-risk actions (file deletion, schema changes, hook modifications) should trigger a mandatory 3-sentence pre-mortem: "If this deletion causes a failure, it would be because ___." This is lighter-weight than Proposal D's full dependency graph but captures the same mental simulation that RPD relies on. It could be added to Proposal A's deletion safety gate as step 0.

- **The Section 5 self-analysis (agent's broken-link triage failure in the 260217 session) is the strongest part of the document from an NDM perspective — consider extracting it as a reusable "pattern library" entry.** NDM research shows that experts build their recognition repertoire through exposure to cases, especially cases where initial pattern-matching failed. The agent's detailed reconstruction of "I saw broken link → I applied the obvious fix (remove reference) → the obvious fix was wrong because I didn't check *why* the link was broken" is a textbook RPD failure case. If this were stored as a named pattern (e.g., "Broken-link garden path: when removing a reference hides a runtime dependency") in a pattern library that gets loaded into agent context, it would directly build the recognition base that prevents recurrence — not through rules, but through richer situation models.

- **Proposal F (session log review mode) aligns well with NDM's concept of "decision archaeology."** Klein's later work on sensemaking (*Seeing What Others Don't*, PublicAffairs, 2013) describes how reviewing decision trails reveals insight failures. Proposal F essentially automates decision archaeology for agent sessions. The suggestion is to make this bidirectional: not only should cwf:review check session logs, but cwf:retro should use the session log to reconstruct the decision chain and identify the specific moment where situation awareness diverged from reality. This would make the retro phase a systematic RPD failure analysis, not just a retrospective summary.

#### Verdict

The prevention proposal is thorough, well-structured, and demonstrates genuine root-cause thinking — particularly the Section 4 analysis of why cwf:run was never called despite explicit user directives, and the Section 5 self-analysis of the agent's own broken-link triage failure. These sections show exactly the kind of honest incident analysis that NDM research identifies as the foundation for building expertise.

However, the core prioritization has a structural blind spot: it elevates the *workflow enforcement* mechanism (E+G) as the primary defense while treating the *decision-point intervention* (A) and *artifact-structure fix* (C) as secondary. From an RPD perspective, the highest-leverage intervention is always the one that changes what the decision-maker sees and considers at the moment of decision. E+G ensures that a later reviewer will catch the mistake; A and C prevent the mistake from being made in the first place. The document would be stronger if it recognized this distinction and elevated A to co-primary status with E+G, and promoted C from P2 to P1.

The compaction-immunity argument for E+G is valid and important — hooks do survive compaction while document rules do not. But this architectural advantage should be applied to *all* critical rules, not just workflow-gate reminders. Proposal A's deletion safety gate is equally vulnerable to compaction if implemented only as SKILL.md prose. The logical conclusion is: implement A *as a hook* (or as part of the E+G hook), not just as document text. This would give the deletion safety check the same compaction immunity that the document correctly identifies as essential.

**Recommendation**: Accept with revisions — elevate Proposal A to co-primary with E+G, promote Proposal C to P1, and consider implementing A's caller-check as a hook rather than prose-only.

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: Gary Klein
- framework: Naturalistic Decision-Making / Recognition-Primed Decision Model
- grounding: "Sources of Power: How People Make Decisions" (MIT Press, 1998)
<!-- AGENT_COMPLETE -->
