### README Must Carry Boundary and Rationale, Not Only Feature List

- **Expected**: architecture/concept explanation in README is enough for release.
- **Actual**: release readiness also requires explicit boundary framing ("what this is / is not") plus decision rationale.
- **Takeaway**: first-user comprehension depends on explicit scope and reasoning contracts, not just capability enumeration.

When validating release docs -> audit README for scope boundaries and decision rationale as first-class criteria.

### Discoverability Audit Is Not Redundant With Generic Docs Review

- **Expected**: AGENTS/entry-path review might be covered implicitly by `refactor --docs`.
- **Actual**: discoverability and self-containment are a separate quality axis that needs explicit gate criteria.
- **Takeaway**: docs consistency checks and entry-path usability checks should be tracked as distinct release gates.

When defining release audits -> treat discoverability architecture as an independent pass/fail criterion.

### Planned Skill Count (11) Drifted From Current Repository State (12)

- **Expected**: execution scope for deep skill review is fixed to 11 CWF skills.
- **Actual**: repository currently has 12 skill directories under `plugins/cwf/skills/` (`run` exists in addition to the original 11).
- **Takeaway**: execution contracts that hardcode inventory counts need an explicit drift rule ("audit all currently present active skills unless user freezes scope").

When executing a pre-designed full-coverage audit -> reconcile planned inventory with live repository inventory before starting coverage.

### Execution Contract Drift: Commit Gate Not Applied During Artifact Build

- **Expected**: during execution, commit in meaningful units instead of accumulating all artifact edits uncommitted.
- **Actual**: S23 pre-Step4 artifacts were drafted in one uncommitted batch on `marketplace-v3`.
- **Takeaway**: execution contracts need an explicit mid-run checkpoint (`git status` + commit-unit decision) before writing the second artifact onward.

When executing mention-only handoff contracts -> enforce a commit checkpoint after first artifact unit to prevent end-loaded commits.

### Session Sequencing Must Match User Intent: Remediation Before Interactive Walkthrough

- **Expected**: S24 executes interactive Step 4 first, then produces final readiness synthesis.
- **Actual**: user clarified preferred order is detailed No-Go remediation discussion + implementation first, then interactive walkthrough.
- **Takeaway**: when handoff contains multiple valid phase orderings, explicit user intent should lock the phase sequence before execution starts.

When preparing next-session handoff for mixed autonomous/interactive work -> include a phase-order lock and per-phase outputs so mention-only execution follows the intended sequence.
