# Lessons: S17 — Hardening a Handoff Protocol

### Scope declaration must equal manifest intake

- **Observation**: Declaring broad scope while collecting a narrow manifest creates
  silent omission risk and false confidence.
- **Decision**: Require bucket-level manifest coverage for every declared include
  source and block Phase 1 when incomplete.
- **Takeaway**: Intake and declared scope must be structurally coupled.

### Mutable HEAD breaks reproducibility

- **Observation**: `42d2cd9..HEAD` can drift during long analysis sessions.
- **Decision**: Freeze `END_SHA` at session start and require all range queries
  to use the frozen `RANGE`.
- **Takeaway**: Reproducibility needs an explicit freeze artifact, not convention.

### Existence checks are insufficient for closure-heavy analysis

- **Observation**: File-existence completion criteria can pass even when gaps are
  not traceable into the backlog.
- **Decision**: Add semantic completion gates (gap closure, one-way closure,
  evidence minimums, redaction compliance).
- **Takeaway**: Coverage workflows need semantic pass/fail, not only artifact
  presence.

### Stable IDs prevent cross-artifact drift

- **Observation**: Without stable IDs, candidates and backlog items can diverge
  during editing.
- **Decision**: Introduce `UTT-*`, `GAP-*`, `CW-*`, `BL-*` ID contracts.
- **Takeaway**: Traceability must be explicit and enforceable.
