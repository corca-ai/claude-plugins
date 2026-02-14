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
