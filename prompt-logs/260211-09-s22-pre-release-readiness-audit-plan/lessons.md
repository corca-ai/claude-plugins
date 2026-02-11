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
