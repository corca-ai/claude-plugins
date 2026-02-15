# Doc Change Backlog — S26

## Classification Legend

- `AUTO_EXISTING`: already enforced by deterministic gates.
- `AUTO_CANDIDATE`: should move into deterministic gates.
- `NON_AUTOMATABLE`: judgment-based prose guidance.

## Backlog

1. `AUTO_CANDIDATE` — Add deterministic fixture tests for date rollover semantics in prompt-dir allocation scripts.
Reason: recurring boundary confusion should be prevented by executable checks, not prose reminders.
Status: Done.

2. `NON_AUTOMATABLE` — Keep chunk-level interactive review intent/focus/risk notes in session log.
Reason: review reasoning quality and context clarity require human judgment.
Status: Pending.

3. `AUTO_CANDIDATE` — Formalize commit-boundary split (`tidy` vs `behavior/policy`) in review workflow.
Reason: repeated mixed commits increase rollback/debug cost; workflow should make boundary explicit.
Status: Done.

4. `NON_AUTOMATABLE` — Define provenance freshness operating policy for routine push decisions.
Reason: enforcement severity policy needs explicit team-level trade-off agreement.
Status: Pending.

5. `AUTO_CANDIDATE` — Narrow markdownlint deterministic command scope to exclude vendored markdown under `scripts/node_modules/**`.
Reason: baseline run produced high-volume third-party noise (`1955` findings), obscuring repository-owned doc signals.
Status: Done.

6. `AUTO_EXISTING` — Fix broken graph references detected by `doc-graph` in `plugins/cwf/skills/setup/SKILL.md` (`raw: path`).
Reason: deterministic graph gate already flags this as `broken_ref_count`.
Status: Done.

7. `NON_AUTOMATABLE` — Decide whether to deduplicate routing text in `CLAUDE.md` (`line 3` vs `line 7-8`).
Reason: requires editorial judgment on adapter readability vs explicitness.
Status: Pending.

8. `NON_AUTOMATABLE` — Decide whether `cwf-index.md` line-3 self-link (`[cwf-index.md](cwf-index.md)`) should be kept.
Reason: it's template-consistent but may be low-signal redundancy in same-file context.
Status: Done (superseded by AGENTS-first policy; file removed).

9. `NON_AUTOMATABLE` — Confirm AGENTS-only default entrypoint while preserving explicit `--cap-index` as optional path.
Reason: balances policy clarity (single default) with user-controlled discoverability artifact generation.
Status: Done.

10. `NON_AUTOMATABLE` — Decide whether generated `repo-index.md` header self-link (`[repo-index.md](repo-index.md)`) should be kept.
Reason: template consistency vs low-signal redundancy trade-off.
Status: Done (superseded by AGENTS-managed index policy; file removed).

11. `NON_AUTOMATABLE` — Apply AGENTS-managed repository index policy for this repository.
Reason: keep a single discoverability surface and reduce generated-file drift.
Status: Done.

12. `NON_AUTOMATABLE` — Decide whether README framing should merge "What CWF Is" and "Why CWF?" sections.
Reason: potential onboarding-length reduction vs conceptual clarity trade-off.
Status: Pending.

13. `NON_AUTOMATABLE` — Clarify review-gate sequencing in README plan/impl descriptions.
Reason: users may miss that implementation normally proceeds after plan review and is followed by code review.
Status: Done.

14. `NON_AUTOMATABLE` — Resolve `README.md` retro default-mode wording conflict (`light by default` vs `deep by default`).
Reason: contradictory defaults in adjacent lines weaken operator trust and can cause wrong command expectations.
Status: Done (resolved to deep-default wording).
