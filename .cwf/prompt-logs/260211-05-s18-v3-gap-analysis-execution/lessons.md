# Lessons: S18 — Executing the Hardened Gap-Analysis Protocol

### Scope Freeze works only when every artifact echoes the same RANGE

- **Observation**: Range drift risk is eliminated when all downstream artifacts
  explicitly restate the frozen RANGE.
- **Takeaway**: Semantic checks should validate RANGE propagation, not only file
  existence.

### Full-bucket manifesting prevents silent omission

- **Observation**: Bucket-level collection exposed corpus breadth (`prompt-logs`,
  `sessions`, `sessions-codex`, `plugins/cwf`, state/docs files).
- **Takeaway**: Declared include buckets and intake commands must remain
  structurally coupled.

### Stable IDs enable closure contracts across artifacts

- **Observation**: `UTT-*`, `GAP-*`, `CW-*`, `BL-*` provided deterministic
  cross-file linkage for closure checks.
- **Takeaway**: Coverage workflows need ID contracts before synthesis starts.

### Redaction at extraction-time scales better than post-hoc cleanup

- **Observation**: Applying masking/truncation during utterance indexing kept
  compliance checks simple and automatable.
- **Takeaway**: Treat redaction as a first-pass transform, then validate with a
  deterministic scan.

### Bidirectional passes reveal asymmetric blind spots

- **Observation**: Early->late emphasized intent debt; late->early emphasized
  present-contract omissions.
- **Takeaway**: Keep both passes mandatory; each catches a different failure mode.
